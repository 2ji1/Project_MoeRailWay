extends "res://tests/support/prototype_test.gd"

const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")


func run() -> PackedStringArray:
	_test_fractional_construction_locks_and_builds_atomically()
	_test_locked_piece_rejects_reflow_and_cancellation()
	_test_recovery_refunds_one_cell_without_renormalizing_geometry()
	_test_refunded_cell_stitches_to_immutable_locked_predecessor()
	_test_facade_forwards_prepare_before_pose_capture()
	return finish()


func _config() -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		7, 20.0, 1,
		1.0, 18, 2, 2.0, 1.0, 1,
		Vector2(340.0, 340.0), Vector2i(8, 8), 40.0, Vector2(10.0, 10.0),
		&"curve_departure", Vector2(30.0, 30.0), Vector2i(0, 0)
	)


func _curve_track() -> TrackSystemScript:
	var track = TrackSystemScript.new(_config())
	var cells: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(3, 1), Vector2i(3, 2),
	]
	track.apply_left_input(TrackInputFrameScript.new(
		cells, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		true, true, false, false
	))
	assert_equal(track.get_cell_records().size(), 5, "Curve fixture accepts five cells")
	assert_equal(track.get_geometry_pieces().size(), 1, "Five cells resolve as one piece")
	assert_equal(
		track.get_geometry_pieces()[0].kind,
		TrackGeometryPieceScript.Kind.CURVE_3X3,
		"Fixture resolves a 3x3 curve"
	)
	return track


func _append_curve_support(track: TrackSystemScript) -> void:
	track.apply_left_input(TrackInputFrameScript.new(
		[Vector2i(3, 3)], Vector2i(3, 2), true, Vector2i(-1, -1), false,
		true, true, false, false
	))
	assert_equal(track.get_cell_records().size(), 6, "G appends after the provisional B through F curve")
	var pieces = track.get_geometry_pieces()
	assert_true(pieces[0].locked, "G causes the whole B through F curve to enter the ledger")
	assert_equal(pieces[0].exit_support_route_serial, 6, "G is the curve exit support")


func _test_fractional_construction_locks_and_builds_atomically() -> void:
	var track = _curve_track()
	assert_equal(track.advance_construction(0.25), 0.25, "Quarter-cell progress consumed")
	var records = track.get_cell_records()
	assert_equal(records[0].state, TrackCellRecordScript.State.BUILDING, "First interval building")
	assert_equal(records[0].build_progress, 0.25, "Fractional build progress retained")
	assert_equal(track.get_built_end_distance_cells(), 0.0, "Building interval is blocked")
	assert_false(track.get_geometry_pieces()[0].locked, "Starting construction leaves the piece provisional")
	for record in records:
		assert_false(record.geometry_locked, "Construction does not assign geometry locks")
	assert_equal(track.advance_construction(1.25), 1.25, "Excess construction is consumed")
	records = track.get_cell_records()
	assert_equal(records[0].state, TrackCellRecordScript.State.BUILT, "First interval built atomically")
	assert_equal(records[1].state, TrackCellRecordScript.State.BUILDING, "Second interval building")
	assert_equal(records[1].build_progress, 0.5, "Excess advances the next interval")
	assert_equal(track.get_built_end_distance_cells(), 1.0, "Only completed intervals are traversable")


func _test_locked_piece_rejects_reflow_and_cancellation() -> void:
	var track = _curve_track()
	track.advance_construction(0.25)
	assert_false(track.get_geometry_pieces()[0].locked, "Construction alone leaves the curve provisional")
	_append_curve_support(track)
	var before = track.get_geometry_pieces()[0]
	var anchors: Array[RouteContactAnchorScript] = [
		RouteContactAnchorScript.new(&"late_anchor", Vector2i(7, 7)),
	]
	track.set_contact_anchors(anchors)
	var after = track.get_geometry_pieces()[0]
	assert_equal(after.kind, before.kind, "Locked kind never reflows")
	assert_equal(after.centerline, before.centerline, "Locked centerline never reflows")
	assert_equal(after.footprint_cells, before.footprint_cells, "Locked footprint never reflows")
	var record_count := track.get_cell_records().size()
	assert_true(track.apply_right_input(TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, Vector2i(3, 1), true,
		false, false, false, true
	)), "Right edge is consumed")
	assert_equal(track.get_cell_records().size(), record_count, "Cancellation cannot cut a horizon-locked piece")


func _test_recovery_refunds_one_cell_without_renormalizing_geometry() -> void:
	var track = _curve_track()
	_append_curve_support(track)
	assert_equal(track.advance_construction(6.0), 6.0, "All six intervals build")
	assert_true(track.prepare_for_train_sampling(0.5, 4.5), "Initial samples prepare the locked curve")
	var recovered_position := track.get_position_at_distance_cells(0.5)
	var surviving_position := track.get_position_at_distance_cells(4.5)
	assert_equal(track.recover_behind(1.0), 1, "First cutoff recovers one cell")
	assert_equal(track.get_available_track_cells(), 13, "First cell refunds exactly once")
	assert_equal(track.recover_behind(2.0), 1, "Second cutoff recovers one cell")
	assert_equal(track.get_available_track_cells(), 14, "Second cell refunds exactly once")
	assert_equal(track.get_built_end_distance_cells(), 6.0, "Built distance remains absolute")
	assert_true(track.prepare_for_train_sampling(0.5, 0.5), "Recovered prefix sample remains prepared")
	assert_equal(
		track.get_position_at_distance_cells(0.5),
		recovered_position,
		"Full locked ledger remains sampleable"
	)
	assert_true(track.prepare_for_train_sampling(4.5, 4.5), "Surviving sample remains prepared")
	assert_equal(
		track.get_position_at_distance_cells(4.5),
		surviving_position,
		"Surviving sample never moves"
	)
	var piece = track.get_geometry_pieces()[0]
	assert_equal(piece.active_local_start_cells, 2.0, "Active slice begins after recovered cells")
	assert_equal(piece.active_local_end_cells, 5.0, "Active slice preserves the original end")


func _test_refunded_cell_stitches_to_immutable_locked_predecessor() -> void:
	var track = _curve_track()
	_append_curve_support(track)
	assert_equal(track.advance_construction(6.0), 6.0, "B through G build before recovery")
	var locked_before = track.get_geometry_pieces()[0].duplicate_piece()
	assert_equal(track.recover_behind(1.0), 1, "Rear cell refunds one curve interval")
	var continued_pieces = track.get_geometry_pieces()
	assert_equal(continued_pieces.size(), 2, "Active locked curve retains one provisional support successor")
	if continued_pieces.size() != 2:
		return
	var predecessor = continued_pieces[0]
	var successor = continued_pieces[1]
	assert_true(predecessor.locked, "Surviving B through F ledger remains locked")
	assert_false(successor.locked, "The G support remains provisional")
	assert_equal(
		successor.absolute_start_distance_cells,
		predecessor.absolute_start_distance_cells + float(predecessor.nominal_length_cells),
		"Stitched pieces are adjacent by absolute nominal distance"
	)
	assert_equal(
		predecessor.centerline,
		locked_before.centerline,
		"Recovery never mutates the locked predecessor"
	)
	assert_equal(
		successor.centerline[0],
		predecessor.centerline[-1],
		"Unlocked successor starts at the immutable locked endpoint"
	)
	var predecessor_end: Dictionary = predecessor.sample_nominal(
		float(predecessor.nominal_length_cells)
	)
	var successor_start: Dictionary = successor.sample_nominal(0.0)
	assert_equal(successor_start.position, predecessor_end.position, "Position is continuous at stitch")
	assert_true(
		successor_start.heading.is_equal_approx(predecessor_end.heading),
		"Heading is continuous at stitch"
	)


func _test_facade_forwards_prepare_before_pose_capture() -> void:
	var track_system = _curve_track()
	track_system.advance_construction(5.0)
	assert_true(track_system.prepare_for_train_sampling(1.0, 1.0), "Facade prepares predecessor at boundary")
	var pose = track_system.get_pose_sample_at_distance(1.0)
	assert_true(pose.has("position") and pose.has("heading"), "Facade returns pose pair")
