extends "res://tests/support/prototype_test.gd"

const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")
const NominalTrainMotionScript = preload("res://src/domain/train/nominal_train_motion.gd")


func run() -> PackedStringArray:
	_test_five_cell_curve_matches_five_straight_cell_time()
	_test_train_cannot_enter_building_cell()
	_test_position_and_heading_are_continuous_across_piece_boundaries()
	_test_inactive_repeated_depart_and_no_reverse()
	_test_recovery_preserves_absolute_train_distance()
	return finish()


func _test_five_cell_curve_matches_five_straight_cell_time() -> void:
	var curve_track = _make_built_three_by_three_curve_track()
	var straight_track = _make_built_straight_track(5)
	var curve_train = NominalTrainMotionScript.new(1.0)
	var straight_train = NominalTrainMotionScript.new(1.0)
	curve_train.depart(0.0)
	straight_train.depart(0.0)
	for tick in range(299):
		assert_false(curve_train.advance(5.0, 1.0 / 60.0), "Curve remains before end")
		assert_false(straight_train.advance(5.0, 1.0 / 60.0), "Straight remains before end")
	assert_true(curve_train.advance(5.0, 1.0 / 60.0), "Curve reaches end on tick 300")
	assert_true(straight_train.advance(5.0, 1.0 / 60.0), "Straight reaches end on tick 300")
	assert_true(is_equal_approx(curve_train.get_route_distance_cells(), 5.0), "Curve nominal distance")
	assert_true(is_equal_approx(straight_train.get_route_distance_cells(), 5.0), "Straight nominal distance")
	assert_false(
		curve_track.get_position_at_distance_cells(2.5).is_equal_approx(
			straight_track.get_position_at_distance_cells(2.5)
		),
		"Different geometry shares the same nominal timing"
	)


func _test_train_cannot_enter_building_cell() -> void:
	var track = _make_one_built_one_building_track()
	var train = NominalTrainMotionScript.new(1.0)
	train.depart(0.0)
	assert_true(train.advance(track.get_built_end_distance_cells(), 2.0), "Building cell blocks movement")
	assert_equal(train.get_route_distance_cells(), 1.0, "Train clamps to built prefix")


func _test_position_and_heading_are_continuous_across_piece_boundaries() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1),
	]), 4, "Boundary fixture accepts four cells")
	assert_equal(track.advance_construction(4.0), 4.0, "Boundary fixture builds")
	var pieces = track.get_geometry_pieces()
	assert_equal(pieces.size(), 2, "Boundary fixture has two pieces")
	for index in range(pieces.size() - 1):
		var boundary: float = pieces[index].absolute_start_distance_cells + pieces[index].nominal_length_cells
		var before_position: Vector2 = track.get_position_at_distance_cells(boundary - 0.0001)
		var after_position: Vector2 = track.get_position_at_distance_cells(boundary + 0.0001)
		var before_heading: Vector2 = track.get_heading_at_distance_cells(boundary - 0.0001)
		var after_heading: Vector2 = track.get_heading_at_distance_cells(boundary + 0.0001)
		assert_true(before_position.distance_to(after_position) < 0.1, "Position is continuous across piece boundary")
		assert_true(before_heading.dot(after_heading) > 0.999, "Heading is continuous across piece boundary")


func _test_inactive_repeated_depart_and_no_reverse() -> void:
	var train = NominalTrainMotionScript.new(2.0)
	assert_false(train.is_active(), "Train begins inactive")
	assert_false(train.advance(5.0, 1.0), "Inactive advance is a no-op")
	assert_equal(train.get_route_distance_cells(), 0.0, "Inactive train does not move")
	train.depart(1.0)
	train.depart(0.0)
	assert_equal(train.get_route_distance_cells(), 1.0, "Repeated depart does not reset active train")
	assert_true(train.advance(0.5, 1.0), "Behind endpoint requests track end")
	assert_equal(train.get_route_distance_cells(), 1.0, "Behind endpoint never reverses train")


func _test_recovery_preserves_absolute_train_distance() -> void:
	var track = _make_built_straight_track(5)
	var train = NominalTrainMotionScript.new(1.0)
	train.depart(3.0)
	var before_position: Vector2 = track.get_position_at_distance_cells(3.0)
	assert_equal(track.recover_behind(2.0), 2, "Two cells recover behind train")
	assert_equal(track.get_position_at_distance_cells(3.0), before_position, "Track sampling stays absolute")
	assert_false(train.advance(track.get_built_end_distance_cells(), 0.5), "Train remains before built end")
	assert_equal(train.get_route_distance_cells(), 3.5, "Recovery does not renormalize train distance")


func _make_built_three_by_three_curve_track():
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	]), 5, "Curve fixture cells")
	assert_equal(track.advance_construction(5.0), 5.0, "Curve fixture built")
	return track


func _make_built_straight_track(cell_count: int):
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var cells: Array[Vector2i] = []
	for index in range(cell_count):
		cells.append(Vector2i(index, 0))
	assert_equal(track.append_cells(cells), cell_count, "Straight fixture cells")
	assert_equal(track.advance_construction(float(cell_count)), float(cell_count), "Straight fixture built")
	return track


func _make_one_built_one_building_track():
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	assert_equal(track.append_cells(cells), 2, "Building fixture cells")
	assert_equal(track.advance_construction(1.5), 1.5, "Second cell remains building")
	return track
