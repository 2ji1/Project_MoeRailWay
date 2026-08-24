class_name SessionController
extends RefCounted

const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")

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
var _total_ticks: int
var _elapsed_ticks := 0
var _remaining_ticks: int
var _ticks_per_second: int
var _seconds_per_tick: float
var _construction_cells_per_tick: float
var _snapshot: SessionSnapshotScript


func _init(
	start_config: SessionStartConfigScript,
	track_system: TrackSystemScript,
	train_system: TrainSystemScript
) -> void:
	assert(start_config != null, "Session start config is required")
	assert(track_system != null, "Track system is required")
	assert(train_system != null, "Train system is required")
	_start_config = start_config
	_track_system = track_system
	_train_system = train_system
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
	var frame: TrackInputFrameScript = (
		input_frame if input_frame != null else TrackInputFrameScript.empty()
	)
	var right_won := _track_system.apply_right_input(frame)
	if not right_won:
		_track_system.apply_left_input(frame)

	_track_system.advance_construction(_construction_cells_per_tick)
	if (
		_state == State.PREPARING_DEPARTURE
		and _track_system.get_built_end_distance_cells() + DISTANCE_EPSILON
			>= float(_start_config.departure_required_built_cells)
	):
		_state = State.RUNNING
		_train_system.depart(0.0)

	var track_end_requested := false
	if _state == State.RUNNING:
		track_end_requested = _train_system.advance_tick(_track_system, _seconds_per_tick)
		_track_system.recover_behind(
			_train_system.get_route_distance_cells() - float(_start_config.recovery_lag_cells)
		)

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


func _complete(reason: SessionResultScript.Reason) -> void:
	if _state == State.COMPLETED:
		return
	_state = State.COMPLETED
	_publish_snapshot()
	session_completed.emit(SessionResultScript.new(
		reason,
		_total_ticks,
		_elapsed_ticks,
		_remaining_ticks
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
		train_position = _train_system.get_position(_track_system)
		train_heading = _train_system.get_heading(_track_system)
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
		_start_config.departure_cell
	)
