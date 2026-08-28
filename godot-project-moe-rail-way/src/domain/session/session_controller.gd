class_name SessionController
extends RefCounted

const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")
const WarpPairSystemScript = preload("res://src/domain/warp/warp_pair_system.gd")
const CargoSystemScript = preload("res://src/domain/cargo/cargo_system.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")
const CargoSlotRecordScript = preload("res://src/domain/cargo/cargo_slot_record.gd")

const DISTANCE_EPSILON := 0.0001

signal snapshot_published(snapshot: SessionSnapshotScript)
signal session_completed(result: SessionResultScript)

enum State {
	READY,
	PREPARING_DEPARTURE,
	RUNNING,
	COMPLETED,
}

var _state: State = State.READY
var _start_config: SessionStartConfigScript
var _track_system: TrackSystemScript
var _train_system: TrainSystemScript
var _warp_pair_system: WarpPairSystemScript
var _cargo_system: CargoSystemScript
var _total_ticks: int
var _elapsed_ticks := 0
var _remaining_ticks: int
var _running_tick_index := 0
var _ticks_per_second: int
var _seconds_per_tick: float
var _construction_cells_per_tick: float
var _snapshot: SessionSnapshotScript
var _cached_tick_pose: Dictionary = {"position": Vector2.ZERO, "heading": Vector2.RIGHT}


func _init(
	start_config: SessionStartConfigScript,
	track_system: TrackSystemScript,
	train_system: TrainSystemScript,
	warp_pair_system: WarpPairSystemScript = null,
	cargo_system: CargoSystemScript = null
) -> void:
	assert(start_config != null, "Session start config is required")
	assert(track_system != null, "Track system is required")
	assert(train_system != null, "Train system is required")
	assert(
		(warp_pair_system == null) == (cargo_system == null),
		"Warp pair and cargo systems must both be provided or both be null"
	)
	_start_config = start_config
	_track_system = track_system
	_train_system = train_system
	_warp_pair_system = warp_pair_system
	_cargo_system = cargo_system
	_ticks_per_second = _start_config.simulation_ticks_per_second
	_total_ticks = maxi(
		1,
		int(ceil(_start_config.session_duration_seconds * float(_ticks_per_second)))
	)
	_remaining_ticks = _total_ticks
	_seconds_per_tick = 1.0 / float(_ticks_per_second)
	_construction_cells_per_tick = _start_config.build_cells_per_second * _seconds_per_tick
	assert(_seconds_per_tick > 0.0, "Tick duration must be positive")
	assert(_construction_cells_per_tick > 0.0, "Construction progress must be positive")
	_snapshot = _create_snapshot()


func start() -> void:
	if _state != State.READY:
		return
	_state = State.PREPARING_DEPARTURE
	_publish_snapshot()


func advance_tick(input_frame: TrackInputFrameScript = null) -> void:
	if _state == State.READY or _state == State.COMPLETED:
		return
	var running_tick_index_before := _running_tick_index
	var warp_tick_checkpoint := {}
	if _state == State.RUNNING:
		if _warp_cargo_enabled():
			warp_tick_checkpoint = _warp_pair_system.create_running_tick_checkpoint()
		_begin_warp_running_tick()
	var frame: TrackInputFrameScript = (
		input_frame if input_frame != null else TrackInputFrameScript.empty()
	)
	var right_won := _track_system.apply_right_input(frame)
	if not right_won:
		_track_system.apply_left_input(frame)

	_track_system.advance_construction(_construction_cells_per_tick)
	var track_end_requested := false
	var previous_train_distance := 0.0
	var train_moved := false
	if (
		_state == State.PREPARING_DEPARTURE
		and _track_system.get_built_end_distance_cells() + DISTANCE_EPSILON
			>= float(_start_config.departure_required_built_cells)
	):
		var departure_through := minf(
			_start_config.train_speed_cells_per_second * _seconds_per_tick,
			_track_system.get_built_end_distance_cells()
		)
		if not _prepare_or_abort(0.0, departure_through):
			return
		_begin_warp_running_tick()
		_train_system.depart(0.0)
		_train_system.capture_pose(_track_system)
		_state = State.RUNNING
		track_end_requested = _train_system.advance_tick(_track_system, _seconds_per_tick)
		_cached_tick_pose = _train_system.capture_pose(_track_system)
		train_moved = true
	elif _state == State.RUNNING:
		var current_distance := _train_system.get_route_distance_cells()
		previous_train_distance = current_distance
		var through_distance := minf(
			current_distance + _start_config.train_speed_cells_per_second * _seconds_per_tick,
			_track_system.get_built_end_distance_cells()
		)
		if not _prepare_or_abort(current_distance, through_distance):
			_restore_aborted_warp_running_tick(
				warp_tick_checkpoint,
				running_tick_index_before
			)
			return
		track_end_requested = _train_system.advance_tick(_track_system, _seconds_per_tick)
		_cached_tick_pose = _train_system.capture_pose(_track_system)
		train_moved = true

	if _state == State.RUNNING and train_moved:
		if _warp_cargo_enabled():
			var contact_hits := _track_system.get_contact_hits_between(
				previous_train_distance,
				_train_system.get_route_distance_cells()
			)
			_warp_pair_system.resolve_contact_hits(
				_running_tick_index,
				contact_hits,
				_cargo_system
			)
			_install_warp_anchors()
		_track_system.recover_behind(
			_train_system.get_route_distance_cells() - float(_start_config.recovery_lag_cells)
		)
		if _warp_cargo_enabled():
			_warp_pair_system.expire_after_contact(_running_tick_index, _cargo_system)
			_install_warp_anchors()

	var regular_expiry_requested := false
	if _state == State.RUNNING:
		_elapsed_ticks = mini(_total_ticks, _elapsed_ticks + 1)
		_remaining_ticks = _total_ticks - _elapsed_ticks
		regular_expiry_requested = _remaining_ticks == 0

	if regular_expiry_requested:
		_complete(SessionResultScript.Reason.REGULAR_TIME_EXPIRED)
	elif track_end_requested:
		_complete(SessionResultScript.Reason.TRACK_END_REACHED)
	else:
		_publish_snapshot()


func get_snapshot() -> SessionSnapshotScript:
	return _snapshot


func get_state() -> State:
	return _state


func _prepare_or_abort(current_distance: float, through_distance: float) -> bool:
	return _track_system.prepare_for_train_sampling(current_distance, through_distance)


func _restore_aborted_warp_running_tick(
	checkpoint: Dictionary,
	running_tick_index_before: int
) -> void:
	if not _warp_cargo_enabled() or checkpoint.is_empty():
		return
	_warp_pair_system.restore_running_tick_checkpoint(checkpoint)
	_running_tick_index = running_tick_index_before
	_install_warp_anchors()


func _complete(reason: SessionResultScript.Reason) -> void:
	if _state == State.COMPLETED:
		return
	if _warp_cargo_enabled():
		_warp_pair_system.void_nonterminal(_running_tick_index, _cargo_system)
		_install_warp_anchors()
	_track_system.terminate_for_session_completion()
	_state = State.COMPLETED
	_publish_snapshot()
	var delivered_pair_count := 0
	var base_delivery_reward_total := 0
	if _warp_cargo_enabled():
		delivered_pair_count = _cargo_system.get_delivered_pair_count()
		base_delivery_reward_total = _cargo_system.get_base_delivery_reward_total()
	session_completed.emit(SessionResultScript.new(
		reason,
		_total_ticks,
		_elapsed_ticks,
		_remaining_ticks,
		delivered_pair_count,
		base_delivery_reward_total
	))


func _publish_snapshot() -> void:
	_snapshot = _create_snapshot()
	snapshot_published.emit(_snapshot)


func _create_snapshot() -> SessionSnapshotScript:
	var train_active := _train_system.is_active()
	var train_distance := _train_system.get_route_distance_cells()
	var train_position := Vector2(_start_config.departure_position)
	var train_heading := Vector2.RIGHT
	if train_active:
		train_position = _cached_tick_pose.position
		train_heading = _cached_tick_pose.heading
	var built_end := _track_system.get_built_end_distance_cells()
	var built_distance_ahead := maxf(0.0, built_end - train_distance)
	var estimated_track_end_seconds := 0.0
	var warning_urgent := false
	if train_active:
		estimated_track_end_seconds = (
			built_distance_ahead / _start_config.train_speed_cells_per_second
		)
		warning_urgent = estimated_track_end_seconds <= _start_config.urgent_warning_seconds
	var departure_built_cells := mini(
		_start_config.departure_required_built_cells,
		int(floor(built_end + DISTANCE_EPSILON))
	)
	var warp_pair_records: Array[WarpPairRecordScript] = []
	var cargo_slot_records: Array[CargoSlotRecordScript] = []
	var occupied_cargo_slots := 0
	var total_cargo_slots := 0
	var delivered_pair_count := 0
	var base_delivery_reward_total := 0
	var warp_cargo_events: Array[Dictionary] = []
	if _warp_cargo_enabled():
		warp_pair_records = _warp_pair_system.get_pair_records()
		cargo_slot_records = _cargo_system.get_slot_records()
		occupied_cargo_slots = _cargo_system.get_occupied_slot_count()
		total_cargo_slots = _cargo_system.get_total_slot_count()
		delivered_pair_count = _cargo_system.get_delivered_pair_count()
		base_delivery_reward_total = _cargo_system.get_base_delivery_reward_total()
		warp_cargo_events = _warp_pair_system.get_tick_events()
	return SessionSnapshotScript.new(
		_total_ticks,
		_elapsed_ticks,
		_remaining_ticks,
		_ticks_per_second,
		true,
		int(_state),
		_track_system.get_cell_records(),
		_track_system.get_geometry_pieces(),
		_track_system.get_contact_observations(),
		built_end,
		_track_system.get_available_track_cells(),
		_track_system.get_total_track_cells(),
		_track_system.get_grid_origin_units(),
		departure_built_cells,
		_start_config.departure_required_built_cells,
		built_distance_ahead,
		train_active,
		train_distance,
		train_position,
		train_heading,
		estimated_track_end_seconds,
		warning_urgent,
		_start_config.departure_candidate_id,
		_start_config.departure_cell,
		_track_system.is_endpoint_gesture_eligible(),
		_track_system.is_runtime_gesture_active(),
		warp_pair_records,
		cargo_slot_records,
		occupied_cargo_slots,
		total_cargo_slots,
		delivered_pair_count,
		base_delivery_reward_total,
		warp_cargo_events
	)


func _begin_warp_running_tick() -> void:
	if not _warp_cargo_enabled():
		return
	_running_tick_index += 1
	_warp_pair_system.begin_running_tick(_running_tick_index)
	_install_warp_anchors()


func _install_warp_anchors() -> void:
	if not _warp_cargo_enabled():
		return
	_track_system.set_contact_anchors(_warp_pair_system.get_route_contact_anchors())


func _warp_cargo_enabled() -> bool:
	return _warp_pair_system != null and _cargo_system != null
