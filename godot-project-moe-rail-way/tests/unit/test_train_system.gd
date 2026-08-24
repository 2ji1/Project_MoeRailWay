extends "res://tests/support/prototype_test.gd"

const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")


func run() -> PackedStringArray:
	_test_inactive_and_repeated_departure()
	_test_nominal_progress_and_sampling_delegate_to_track()
	_test_building_interval_blocks_and_endpoint_requests_completion()
	_test_recovery_preserves_absolute_train_distance()
	return finish()


func _config() -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		9, 20.0, 1,
		1.0, 10, 1, 2.0, 1.0, 1,
		Vector2(420.0, 260.0), Vector2i(10, 6), 40.0, Vector2(10.0, 10.0),
		&"train_departure", Vector2(30.0, 30.0), Vector2i(0, 0)
	)


func _straight_track(build_cells: float) -> TrackSystemScript:
	var track = TrackSystemScript.new(_config())
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	track.apply_left_input(TrackInputFrameScript.new(
		cells, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		true, true, false, false
	))
	track.advance_construction(build_cells)
	return track


func _test_inactive_and_repeated_departure() -> void:
	var track = _straight_track(3.0)
	var train = TrainSystemScript.new(1.0)
	assert_false(train.advance_tick(track, 1.0), "Inactive train is a no-op")
	assert_equal(train.get_route_distance_cells(), 0.0, "Inactive distance remains zero")
	train.depart(0.5)
	train.depart(2.0)
	assert_true(train.is_active(), "Departure activates the train")
	assert_equal(train.get_route_distance_cells(), 0.5, "Repeated departure is ignored")


func _test_nominal_progress_and_sampling_delegate_to_track() -> void:
	var track = _straight_track(3.0)
	var train = TrainSystemScript.new(1.0)
	train.depart()
	assert_false(train.advance_tick(track, 0.5), "Half a nominal cell remains before the end")
	assert_equal(train.get_route_distance_cells(), 0.5, "Nominal progress is measured in cells")
	assert_equal(
		train.get_position(track),
		track.get_position_at_distance_cells(0.5),
		"Position delegates to resolved geometry"
	)
	assert_equal(
		train.get_heading(track),
		track.get_heading_at_distance_cells(0.5),
		"Heading delegates to resolved geometry"
	)
	assert_true(is_equal_approx(train.get_heading(track).length(), 1.0), "Heading is normalized")


func _test_building_interval_blocks_and_endpoint_requests_completion() -> void:
	var building_track = _straight_track(0.5)
	var blocked_train = TrainSystemScript.new(1.0)
	blocked_train.depart()
	assert_true(blocked_train.advance_tick(building_track, 1.0), "Building interval requests track end")
	assert_equal(blocked_train.get_route_distance_cells(), 0.0, "Building interval remains blocked")
	var built_track = _straight_track(3.0)
	var train = TrainSystemScript.new(1.0)
	train.depart()
	assert_true(train.advance_tick(built_track, 3.0), "Exact built endpoint requests track end")
	assert_equal(train.get_route_distance_cells(), 3.0, "Train clamps to exact built endpoint")


func _test_recovery_preserves_absolute_train_distance() -> void:
	var track = _straight_track(3.0)
	var train = TrainSystemScript.new(1.0)
	train.depart()
	assert_false(train.advance_tick(track, 2.0), "Train advances before final endpoint")
	var before := train.get_route_distance_cells()
	assert_equal(track.recover_behind(1.0), 1, "Rear cell recovers")
	assert_equal(train.get_route_distance_cells(), before, "Recovery does not renormalize train distance")
	assert_equal(train.get_position(track), track.get_position_at_distance_cells(before), "Sampling remains absolute")
