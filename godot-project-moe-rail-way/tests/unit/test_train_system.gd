extends "res://tests/support/prototype_test.gd"

const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")


func run() -> PackedStringArray:
	_test_inactive_and_repeated_departure()
	_test_nominal_progress_and_sampling_delegate_to_track()
	_test_building_interval_blocks_and_endpoint_requests_completion()
	_test_recovery_preserves_absolute_train_distance()
	_test_capture_pose_is_the_only_pair_sampler()
	_test_durability_is_clamped_and_one_way()
	return finish()


func _test_durability_is_clamped_and_one_way() -> void:
	var train = TrainSystemScript.new(1.0, 100.0)
	assert_equal(train.get_maximum_durability(), 100.0, "Durability maximum is copied")
	assert_equal(train.get_current_durability(), 100.0, "Train starts at maximum durability")
	assert_equal(train.apply_damage(12.5), 12.5, "Finite damage applies exactly")
	assert_equal(train.get_current_durability(), 87.5, "Current durability decreases")
	assert_equal(train.apply_damage(100.0), 87.5, "Damage clamps to remaining durability")
	assert_equal(train.get_current_durability(), 0.0, "Durability clamps at zero")
	assert_true(train.is_durability_depleted(), "Zero durability is depleted")
	assert_equal(train.apply_damage(1.0), 0.0, "Repeated damage after depletion is a no-op")


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
		true, false, true, false, cells[-1], true
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
	assert_true(track.prepare_for_train_sampling(0.5, 0.5), "Current train owner is prepared")
	var pose = train.capture_pose(track)
	assert_equal(
		train.get_position(track),
		pose.position,
		"Position convenience accessor uses captured pair"
	)
	assert_equal(
		train.get_heading(track),
		pose.heading,
		"Heading convenience accessor uses captured pair"
	)
	assert_true(is_equal_approx(pose.heading.length(), 1.0), "Heading is normalized")


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
	assert_true(track.prepare_for_train_sampling(before, before), "Recovery leaves the current owner prepared")
	assert_equal(train.get_position(track), track.get_position_at_distance_cells(before), "Sampling remains absolute")


func _test_capture_pose_is_the_only_pair_sampler() -> void:
	var train = TrainSystemScript.new(1.0)
	var config = _config()
	var track = TrackSystemScript.new(config)
	track.apply_left_input(TrackInputFrameScript.new([
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)
	], Vector2i(0, 0), true, Vector2i(-1, -1), false, true, false, true, false, Vector2i(2, 2), true))
	track.advance_construction(4.0)
	var pieces = track.get_geometry_pieces()
	var boundary: float = pieces[0].absolute_start_distance_cells + float(pieces[0].nominal_length_cells)
	var epsilon := GridTrackRuntimeScript.NOMINAL_BOUNDARY_EPSILON
	assert_true(track.prepare_for_train_sampling(boundary + epsilon, boundary + epsilon), "Prepared at inclusive boundary")
	train.depart(boundary + epsilon)
	var pose = train.capture_pose(track)
	assert_true(pose.has("position") and pose.has("heading"), "Typed pose pair keys")
	var expected = pieces[0].sample_nominal(float(pieces[0].nominal_length_cells))
	assert_true(pose.position.is_equal_approx(expected.position), "Pair uses canonical facade sample")
	assert_true(pose.heading.is_equal_approx(expected.heading), "Pair heading uses canonical facade sample")
