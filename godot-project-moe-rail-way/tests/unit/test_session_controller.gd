extends "res://tests/support/prototype_test.gd"

const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")


class TogglePrepareTrackSystem extends TrackSystemScript:
	var allow_prepare := true
	var prepare_calls := 0
	var pose_sample_calls := 0
	var recovery_calls := 0
	func prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool:
		prepare_calls += 1
		if not allow_prepare:
			return false
		return super.prepare_for_train_sampling(current_distance, through_distance)
	func get_pose_sample_at_distance(route_distance: float) -> Dictionary:
		pose_sample_calls += 1
		return super.get_pose_sample_at_distance(route_distance)
	func recover_behind(route_distance_cells: float) -> int:
		recovery_calls += 1
		return super.recover_behind(route_distance_cells)


func run() -> PackedStringArray:
	_test_preparation_freezes_timer_and_departure_moves_same_tick()
	_test_fractional_duration_rounds_up()
	_test_terminal_snapshot_precedes_result_and_completion_is_inert()
	_test_controller_requests_prepare_once_before_departure()
	_test_prepare_failure_keeps_preparing_snapshot_and_time_unchanged()
	_test_prepare_failure_keeps_running_without_recovery_or_events()
	_test_terminal_snapshot_pose_precedes_reason_only_result_after_full_recovery()
	return finish()


func _config(
	duration_seconds: float = 2.5,
	ticks_per_second: int = 2,
	train_speed_cells: float = 0.25,
	build_cells_per_second: float = 0.5,
	total_cells: int = 8,
	recovery_lag: int = 1
) -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		1, duration_seconds, ticks_per_second,
		train_speed_cells, total_cells, recovery_lag, 1.0, build_cells_per_second, 1,
		Vector2(240.0, 160.0), Vector2i(6, 4), 40.0, Vector2.ZERO,
		&"controller_departure", Vector2(20.0, 20.0), Vector2i(0, 0)
	)


func _fixture(config: SessionStartConfigScript) -> Dictionary:
	var track = TrackSystemScript.new(config)
	var train = TrainSystemScript.new(config.train_speed_cells_per_second)
	var controller = SessionControllerScript.new(config, track, train)
	return {"track": track, "train": train, "controller": controller}


func _draw_frame(cells: Array[Vector2i]) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		cells, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		true, true, false, false
	)


func _snapshot_values(snapshot) -> Dictionary:
	var records: Array[Dictionary] = []
	for record in snapshot.get_cell_records():
		records.append({"serial": record.route_serial, "state": record.state, "progress": record.build_progress})
	return {
		"state": snapshot.get_state(), "elapsed": snapshot.get_elapsed_ticks(),
		"remaining": snapshot.get_remaining_ticks(), "distance": snapshot.get_train_route_distance_cells(),
		"position": snapshot.get_train_position(), "heading": snapshot.get_train_heading(), "records": records,
	}


func _test_preparation_freezes_timer_and_departure_moves_same_tick() -> void:
	var config = _config()
	var fixture := _fixture(config)
	var controller = fixture.controller
	controller.start()
	var one_cell: Array[Vector2i] = [Vector2i(1, 0)]
	controller.advance_tick(_draw_frame(one_cell))
	for _tick in range(2):
		controller.advance_tick()
		assert_equal(controller.get_snapshot().get_remaining_ticks(), 5, "Preparation timer is frozen")
	controller.advance_tick()
	var snapshot = controller.get_snapshot()
	assert_equal(controller.get_state(), SessionControllerScript.State.RUNNING, "Construction starts departure")
	assert_equal(snapshot.get_built_end_distance_cells(), 1.0, "Construction completed first")
	assert_equal(snapshot.get_train_route_distance_cells(), 0.125, "Departure movement occurs in the same tick")
	assert_equal(snapshot.get_remaining_ticks(), 4, "Running timer advances after departure")


func _test_fractional_duration_rounds_up() -> void:
	var config = _config(2.25, 2, 0.1, 10.0)
	var fixture := _fixture(config)
	var controller = fixture.controller
	controller.start()
	var cells: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
	]
	controller.advance_tick(_draw_frame(cells))
	assert_equal(controller.get_snapshot().get_total_ticks(), 5, "Fractional duration rounds up")


func _test_terminal_snapshot_precedes_result_and_completion_is_inert() -> void:
	var config = _config(1.0, 1, 0.1, 10.0)
	var fixture := _fixture(config)
	var controller = fixture.controller
	var events: Array[String] = []
	var reasons: Array[int] = []
	controller.snapshot_published.connect(func(snapshot):
		if snapshot.get_state() == SessionControllerScript.State.COMPLETED:
			events.append("snapshot")
	)
	controller.session_completed.connect(func(result):
		events.append("result")
		reasons.append(result.get_reason())
	)
	controller.start()
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	controller.advance_tick(_draw_frame(cells))
	assert_equal(events, ["snapshot", "result"], "Terminal snapshot precedes result")
	assert_equal(reasons, [SessionResultScript.Reason.REGULAR_TIME_EXPIRED], "Regular expiry completes")
	var terminal = controller.get_snapshot()
	var endpoint_before: Vector2i = fixture.track.get_endpoint_cell()
	controller.start()
	controller.advance_tick(_draw_frame([Vector2i(3, 0)]))
	assert_true(controller.get_snapshot() == terminal, "Post-completion snapshot is inert")
	assert_equal(fixture.track.get_endpoint_cell(), endpoint_before, "Post-completion input is inert")


func _test_controller_requests_prepare_once_before_departure() -> void:
	var config = _config(5.0, 1, 1.0, 10.0)
	var track = TogglePrepareTrackSystem.new(config)
	var train = TrainSystemScript.new(1.0)
	var controller = SessionControllerScript.new(config, track, train)
	controller.start()
	controller.advance_tick(_draw_frame([Vector2i(1, 0)]))
	assert_equal(track.prepare_calls, 1, "Controller requests prepare exactly once before departure")


func _test_prepare_failure_keeps_preparing_snapshot_and_time_unchanged() -> void:
	var config = _config(5.0, 1, 1.0, 10.0)
	var track = TogglePrepareTrackSystem.new(config)
	var train = TrainSystemScript.new(1.0)
	var controller = SessionControllerScript.new(config, track, train)
	controller.start()
	track.allow_prepare = false
	var before = _snapshot_values(controller.get_snapshot())
	var pose_calls_before = track.pose_sample_calls
	var recovery_calls_before = track.recovery_calls
	controller.advance_tick(_draw_frame([Vector2i(1, 0)]))
	assert_equal(controller.get_state(), SessionControllerScript.State.PREPARING_DEPARTURE, "Preparing remains")
	assert_equal(_snapshot_values(controller.get_snapshot()), before, "Prior snapshot values remain cached")
	assert_equal(train.get_route_distance_cells(), 0.0, "No departure or advance")
	assert_equal(track.get_cell_records()[0].state, TrackCellRecordScript.State.BUILT, "Earlier construction phase remains committed")
	assert_equal(track.prepare_calls, 1, "Preparation was attempted once")
	assert_equal(track.pose_sample_calls, pose_calls_before, "Preparing failure performs no pose capture")
	assert_equal(track.recovery_calls, recovery_calls_before, "Preparing failure performs no recovery")


func _test_prepare_failure_keeps_running_without_recovery_or_events() -> void:
	var config = _config(5.0, 1, 0.25, 10.0)
	var track = TogglePrepareTrackSystem.new(config)
	var train = TrainSystemScript.new(1.0)
	var controller = SessionControllerScript.new(config, track, train)
	controller.start()
	controller.advance_tick(_draw_frame([Vector2i(1, 0), Vector2i(2, 0)]))
	assert_equal(controller.get_state(), SessionControllerScript.State.RUNNING, "Fixture reaches running")
	track.allow_prepare = false
	var events: Array[String] = []
	controller.snapshot_published.connect(func(_snapshot): events.append("snapshot"))
	controller.session_completed.connect(func(_result): events.append("result"))
	var before = _snapshot_values(controller.get_snapshot())
	var distance_before = train.get_route_distance_cells()
	var elapsed_before = controller.get_snapshot().get_elapsed_ticks()
	var remaining_before = controller.get_snapshot().get_remaining_ticks()
	var pose_calls_before = track.pose_sample_calls
	var recovery_calls_before = track.recovery_calls
	var prepare_calls_before = track.prepare_calls
	controller.advance_tick()
	assert_equal(controller.get_state(), SessionControllerScript.State.RUNNING, "Running remains")
	assert_equal(_snapshot_values(controller.get_snapshot()), before, "No snapshot publication")
	assert_equal(events, [], "No completion or snapshot event")
	assert_equal(train.get_route_distance_cells(), distance_before, "Running distance remains unchanged")
	assert_equal(track.prepare_calls, prepare_calls_before + 1, "Running failure attempts preparation once")
	assert_equal(track.pose_sample_calls, pose_calls_before, "Running failure performs no pose capture")
	assert_equal(track.recovery_calls, recovery_calls_before, "Running failure performs no recovery")
	assert_equal(controller.get_snapshot().get_elapsed_ticks(), elapsed_before, "Running failure does not advance elapsed time")
	assert_equal(controller.get_snapshot().get_remaining_ticks(), remaining_before, "Running failure does not consume remaining time")
	track.allow_prepare = true
	controller.advance_tick()
	assert_equal(controller.get_snapshot().get_elapsed_ticks(), elapsed_before + 1, "Next successful tick advances elapsed exactly once")
	assert_equal(controller.get_snapshot().get_remaining_ticks(), remaining_before - 1, "Next successful tick consumes remaining exactly once")
	assert_equal(track.pose_sample_calls, pose_calls_before + 1, "Only the successful tick captures a running pose")
	assert_equal(track.recovery_calls, recovery_calls_before + 1, "Only the successful tick recovers")


func _test_terminal_snapshot_pose_precedes_reason_only_result_after_full_recovery() -> void:
	var config = _config(5.0, 1, 1.0, 10.0, 1, 0)
	var track = TogglePrepareTrackSystem.new(config)
	track.apply_left_input(_draw_frame([Vector2i(1, 0)]))
	track.advance_construction(1.0)
	var train = TrainSystemScript.new(1.0)
	var expected_pose = track.get_geometry_pieces()[0].sample_nominal(1.0)
	var controller = SessionControllerScript.new(config, track, train)
	controller.start()
	var events: Array[String] = []
	var terminal_snapshots: Array = []
	controller.snapshot_published.connect(func(snapshot):
		events.append("snapshot")
		terminal_snapshots.append(snapshot)
	)
	controller.session_completed.connect(func(result):
		events.append("result")
		assert_equal(result.get_reason(), SessionResultScript.Reason.TRACK_END_REACHED, "Reason unchanged")
	)
	controller.advance_tick()
	assert_equal(events, ["snapshot", "result"], "Snapshot publishes first")
	assert_equal(terminal_snapshots.size(), 1, "Terminal tick publishes exactly one snapshot")
	assert_equal(track.get_cell_records().size(), 0, "Zero recovery lag prunes the final piece")
	if terminal_snapshots.size() == 1:
		var terminal_snapshot = terminal_snapshots[0]
		assert_true(terminal_snapshot.get_train_position().is_equal_approx(expected_pose.position), "Pre-recovery pose retained")
		assert_true(terminal_snapshot.get_train_heading().is_equal_approx(expected_pose.heading), "Pre-recovery heading retained")
