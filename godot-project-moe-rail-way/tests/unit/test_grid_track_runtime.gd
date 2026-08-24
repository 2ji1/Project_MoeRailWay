extends "res://tests/support/prototype_test.gd"

const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")


func run() -> PackedStringArray:
	_test_ordered_append_growth_and_transactional_rollback()
	_test_construction_locks_piece_and_builds_one_cell_atomically()
	_test_construction_excess_and_group_assignment()
	_test_cancellation_stops_at_locked_piece()
	_test_recovery_refunds_composite_curve_one_cell_at_a_time()
	_test_partial_recovery_preserves_locked_curve_sampling()
	_test_recovery_preserves_surviving_predecessor_geometry()
	_test_recovery_keeps_group_ids_unique()
	_test_locked_endpoint_rejects_disconnected_rebranch()
	_test_runtime_applies_nonzero_grid_origin_to_sampling()
	_test_failed_anchor_reflow_retains_last_valid_geometry()
	_test_recovered_interval_is_not_reported_as_contacted()
	_test_recovered_cell_can_be_contacted_by_new_geometry()
	_test_detached_observations_and_conservation()
	return finish()


func _test_ordered_append_growth_and_transactional_rollback() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	]), 5, "Ordered buffer accepts five route cells")
	assert_equal(track.get_available_track_cells(), 13, "Curve growth charges five cells once")
	assert_equal(track.get_geometry_pieces().size(), 1, "Growth reclassifies to one curve")
	_assert_conservation(track, "After curve growth")

	track.advance_construction(5.0)
	var before_records := track.get_cell_records()
	var before_available: int = track.get_available_track_cells()
	assert_equal(track.append_cells([
		Vector2i(1, 2), Vector2i(0, 2),
	]), 0, "Tentative locked-footprint conflict stops the buffer")
	assert_equal(track.get_cell_records().size(), before_records.size(), "Only tentative cell rolls back")
	assert_equal(track.get_available_track_cells(), before_available, "Tentative rejection refunds once")
	assert_equal(track.get_endpoint_cell(), Vector2i(2, 2), "Rejected suffix does not skip ahead")
	_assert_conservation(track, "After tentative rollback")


func _test_construction_locks_piece_and_builds_one_cell_atomically() -> void:
	var track = _make_three_by_three_curve_runtime()
	var before = track.get_geometry_pieces()[0].duplicate_piece()
	assert_equal(track.advance_construction(0.25), 0.25, "Quarter cell progress consumed")
	var records = track.get_cell_records()
	assert_equal(records[0].state, TrackCellRecordScript.State.BUILDING, "Active cell building")
	assert_equal(records[0].build_progress, 0.25, "Quarter progress")
	assert_true(track.get_geometry_pieces()[0].locked, "Whole piece locked")
	assert_equal(track.get_built_end_distance_cells(), 0.0, "Building remains blocked")

	var late_anchors: Array[RouteContactAnchorScript] = [
		RouteContactAnchorScript.new(&"late_d", Vector2i(2, 1)),
	]
	track.set_contact_anchors(late_anchors)
	var after = track.get_geometry_pieces()[0]
	assert_equal(after.kind, before.kind, "Locked kind unchanged")
	assert_equal(after.centerline, before.centerline, "Locked centerline unchanged")
	assert_equal(after.footprint_cells, before.footprint_cells, "Locked footprint unchanged")
	assert_equal(track.advance_construction(0.75), 0.75, "Remaining progress consumed")
	assert_equal(track.get_cell_records()[0].state, TrackCellRecordScript.State.BUILT, "Cell becomes built")
	assert_equal(track.get_built_end_distance_cells(), 1.0, "Built prefix advances")
	_assert_conservation(track, "After atomic construction")


func _test_construction_excess_and_group_assignment() -> void:
	var track = _make_three_by_three_curve_runtime()
	var records = track.get_cell_records()
	var group_id: int = records[0].geometry_group_id
	for record in records:
		assert_equal(record.geometry_group_id, group_id, "Whole curve shares one group")
	assert_equal(track.advance_construction(1.5), 1.5, "Construction consumes excess")
	records = track.get_cell_records()
	assert_equal(records[0].state, TrackCellRecordScript.State.BUILT, "First cell built")
	assert_equal(records[1].state, TrackCellRecordScript.State.BUILDING, "Second cell building")
	assert_equal(records[1].build_progress, 0.5, "Excess advances second cell")
	var building_count := 0
	for record in records:
		assert_true(record.geometry_locked, "Construction locks every group record")
		if record.state == TrackCellRecordScript.State.BUILDING:
			building_count += 1
	assert_equal(building_count, 1, "At most one cell is BUILDING")
	_assert_conservation(track, "After excess construction")


func _test_cancellation_stops_at_locked_piece() -> void:
	var track = _make_three_by_three_curve_runtime()
	track.advance_construction(0.25)
	assert_false(track.cancel_ghost_suffix(Vector2i(2, 1)), "Cancellation cannot cut a locked piece")
	assert_equal(track.get_cell_records().size(), 5, "Locked cancellation removes nothing")
	_assert_conservation(track, "After rejected cancellation")


func _test_recovery_refunds_composite_curve_one_cell_at_a_time() -> void:
	var track = _make_fully_built_three_by_three_curve_runtime()
	assert_equal(track.recover_behind(1.0), 1, "First cell recovered")
	assert_equal(track.get_available_track_cells(), 14, "First refund")
	assert_equal(track.recover_behind(2.0), 1, "Second cell recovered")
	assert_equal(track.get_available_track_cells(), 15, "Second refund")
	_assert_conservation(track, "After two recoveries")


func _test_partial_recovery_preserves_locked_curve_sampling() -> void:
	var track = _make_fully_built_three_by_three_curve_runtime()
	var recovered_prefix_position: Vector2 = track.get_position_at_distance_cells(0.5)
	var survivor_position: Vector2 = track.get_position_at_distance_cells(4.5)
	track.recover_behind(2.0)
	assert_equal(track.get_position_at_distance_cells(0.5), recovered_prefix_position, "Train sampling keeps the full locked ledger")
	assert_equal(track.get_position_at_distance_cells(4.5), survivor_position, "Sampling survives partial recovery")
	var piece = track.get_geometry_pieces()[0]
	assert_equal(piece.active_local_start_cells, 2.0, "Visible slice starts after recovery")
	assert_equal(piece.active_local_end_cells, 5.0, "Visible slice keeps original end")
	assert_equal(track.get_built_end_distance_cells(), 5.0, "Recovery does not renormalize built distance")


func _test_recovery_preserves_surviving_predecessor_geometry() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(0, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	]), 3, "Predecessor fixture accepts three cells")
	var surviving_position: Vector2 = track.get_position_at_distance_cells(1.5)
	assert_equal(track.advance_construction(1.0), 1.0, "Leading piece builds")
	assert_equal(track.recover_behind(1.0), 1, "Leading piece fully recovers")
	assert_equal(
		track.get_position_at_distance_cells(1.5),
		surviving_position,
		"Recovery preserves the first surviving interval geometry"
	)


func _test_recovery_keeps_group_ids_unique() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(0, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	]), 3, "Three straight groups append")
	assert_equal(track.advance_construction(2.0), 2.0, "Two straight groups build")
	assert_equal(track.recover_behind(1.0), 1, "Oldest straight group recovers")
	var records = track.get_cell_records()
	assert_true(records[0].geometry_locked, "Surviving built group stays locked")
	assert_false(records[1].geometry_locked, "Following ghost group stays unlocked")
	assert_true(records[0].geometry_group_id != records[1].geometry_group_id, "Locked and ghost pieces keep unique group IDs")
	track.advance_construction(1.0)
	records = track.get_cell_records()
	assert_true(records[1].geometry_locked, "Following group locks independently")
	assert_true(records[0].geometry_group_id != records[1].geometry_group_id, "Construction preserves distinct group IDs")


func _test_locked_endpoint_rejects_disconnected_rebranch() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(0, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(1, 0), Vector2i(2, 0),
	]), 2, "Locked endpoint fixture accepts two cells")
	assert_equal(track.advance_construction(1.0), 1.0, "First straight locks")
	assert_true(track.cancel_ghost_suffix(Vector2i(2, 0)), "Unlocked continuation cancels")
	var before_available: int = track.get_available_track_cells()
	assert_equal(track.append_cells([Vector2i(1, 1)]), 0, "Disconnected branch is rejected")
	assert_equal(track.get_available_track_cells(), before_available, "Rejected branch refunds tentative cell")
	assert_equal(track.get_endpoint_cell(), Vector2i(1, 0), "Rejected branch preserves locked endpoint")
	assert_equal(track.append_cells([Vector2i(2, 0)]), 1, "Original locked continuation reconnects")


func _test_runtime_applies_nonzero_grid_origin_to_sampling() -> void:
	var zero = GridTrackRuntimeScript.new(
		Vector2i(0, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var shifted = GridTrackRuntimeScript.new(
		Vector2i(0, 0), 18, Vector2(10.0, 10.0), Vector2i(8, 8), 40.0
	)
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	assert_equal(zero.append_cells(cells), 2, "Zero-origin fixture")
	assert_equal(shifted.append_cells(cells), 2, "Shifted fixture")
	assert_equal(shifted.get_grid_origin_units(), Vector2(10.0, 10.0), "Origin retained")
	assert_equal(
		shifted.get_position_at_distance_cells(1.5),
		zero.get_position_at_distance_cells(1.5) + Vector2(10.0, 10.0),
		"Runtime sampling shares centered origin"
	)


func _test_failed_anchor_reflow_retains_last_valid_geometry() -> void:
	var track = _make_fully_built_three_by_three_curve_runtime()
	var before = track.get_geometry_pieces()[0].duplicate_piece()
	var late_anchors: Array[RouteContactAnchorScript] = [
		RouteContactAnchorScript.new(&"late_d", Vector2i(2, 1)),
	]
	track.set_contact_anchors(late_anchors)
	var after = track.get_geometry_pieces()[0]
	assert_equal(after.kind, before.kind, "Failed locked reflow retains kind")
	assert_equal(after.centerline, before.centerline, "Failed locked reflow retains centerline")
	var observations: Array = track.get_contact_observations()
	assert_equal(observations.size(), 1, "Anchor observation retained")
	assert_false(observations[0].contact_possible, "Failed reflow reports impossible contact")
	assert_false(observations[0].contacted, "Failed reflow reports no contact")


func _test_recovered_interval_is_not_reported_as_contacted() -> void:
	var track = _make_fully_built_three_by_three_curve_runtime()
	assert_equal(track.recover_behind(1.0), 1, "First interval recovers")
	var recovered_anchors: Array[RouteContactAnchorScript] = [
		RouteContactAnchorScript.new(&"recovered_a", Vector2i(0, 0)),
	]
	track.set_contact_anchors(recovered_anchors)
	var observations: Array = track.get_contact_observations()
	assert_equal(observations.size(), 1, "Recovered anchor observation retained")
	assert_false(observations[0].contact_possible, "Recovered interval cannot provide contact")
	assert_false(observations[0].contacted, "Recovered interval is not contacted")


func _test_recovered_cell_can_be_contacted_by_new_geometry() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1),
	]), 3, "Disposable route accepts three cells")
	assert_equal(track.advance_construction(3.0), 3.0, "Disposable route builds")
	assert_equal(track.recover_behind(3.0), 3, "Disposable route fully recovers")
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	]), 5, "New curve reuses route after recovery")
	var reused_anchors: Array[RouteContactAnchorScript] = [
		RouteContactAnchorScript.new(&"reused_inner", Vector2i(1, 1)),
	]
	track.set_contact_anchors(reused_anchors)
	var observations: Array = track.get_contact_observations()
	assert_true(observations[0].contact_possible, "New active centerline can contact a historical coordinate")
	assert_true(observations[0].contacted, "Historical recovery does not blacklist current contact")


func _test_detached_observations_and_conservation() -> void:
	var track = _make_three_by_three_curve_runtime()
	var records = track.get_cell_records()
	var pieces = track.get_geometry_pieces()
	records[0].cell = Vector2i(99, 99)
	pieces[0].centerline[0] += Vector2(999, 999)
	assert_true(track.get_cell_records()[0].cell != Vector2i(99, 99), "Record observation is detached")
	assert_true(track.get_geometry_pieces()[0].centerline[0] != pieces[0].centerline[0], "Piece observation is detached")
	_assert_conservation(track, "After detached observation mutation")
	assert_true(track.cancel_ghost_suffix(Vector2i(2, 1)), "Unlocked ghost suffix cancels")
	_assert_conservation(track, "After cancellation")


func _make_three_by_three_curve_runtime():
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	]), 5, "3x3 fixture accepts five cells")
	return track


func _make_fully_built_three_by_three_curve_runtime():
	var track = _make_three_by_three_curve_runtime()
	assert_equal(track.advance_construction(5.0), 5.0, "Fixture builds five cells")
	return track


func _assert_conservation(track, message: String) -> void:
	assert_equal(
		track.get_available_track_cells() + track.get_cell_records().size(),
		track.get_total_track_cells(),
		message
	)
