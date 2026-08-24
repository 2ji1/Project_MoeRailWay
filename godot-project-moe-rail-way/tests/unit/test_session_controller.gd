extends "res://tests/support/prototype_test.gd"

const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")


func run() -> PackedStringArray:
	_test_preparation_freezes_timer_and_departure_moves_same_tick()
	_test_fractional_duration_rounds_up()
	_test_terminal_snapshot_precedes_result_and_completion_is_inert()
	return finish()


func _config(
	duration_seconds: float = 2.5,
	ticks_per_second: int = 2,
	train_speed_cells: float = 0.25,
	build_cells_per_second: float = 0.5,
	total_cells: int = 8
) -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		1, duration_seconds, ticks_per_second,
		train_speed_cells, total_cells, 1, 1.0, build_cells_per_second, 1,
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
