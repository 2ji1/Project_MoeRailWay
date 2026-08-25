extends "res://tests/support/prototype_test.gd"

const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackGeometryResolverScript = preload("res://src/domain/track/track_geometry_resolver.gd")
const TrackGeometryResolutionScript = preload("res://src/domain/track/track_geometry_resolution.gd")


func run() -> PackedStringArray:
	_test_ordered_append_growth_and_transactional_rollback()
	_test_built_head_reflows_without_geometry_lock()
	_test_construction_excess_and_group_assignment()
	_test_cancellation_stops_at_locked_piece()
	_test_recovery_refunds_composite_curve_one_cell_at_a_time()
	_test_partial_recovery_preserves_locked_curve_sampling()
	_test_recovery_preserves_surviving_predecessor_geometry()
	_test_recovery_keeps_group_ids_unique()
	_test_locked_endpoint_rejects_disconnected_rebranch()
	_test_runtime_applies_nonzero_grid_origin_to_sampling()
	_test_recovered_interval_is_not_reported_as_contacted()
	_test_recovered_cell_can_be_contacted_by_new_geometry()
	_test_detached_observations_and_conservation()
	_test_twenty_construction_steps_keep_completed_head_reflowable()
	_test_sixth_head_record_locks_whole_curve_and_supports_exit()
	_test_support_piece_locks_later_without_mutating_predecessor_metadata()
	_test_cancellation_rolls_back_exactly_when_support_is_in_suffix()
	_test_cancel_from_inside_wholly_provisional_piece_removes_only_eligible_suffix()
	_test_rejected_append_rolls_back_only_tentative_suffix()
	_test_locked_prefix_and_provisional_suffix_are_contiguous()
	_test_horizon_locks_complete_one_two_and_three_cell_pieces()
	_test_rejected_eligible_cancel_restores_route_inventory_and_ledger()
	_test_suffix_after_exit_support_remains_cancelable_and_support_expires_after_recovery()
	_test_horizon_rejection_after_first_staged_ledger_piece_is_atomic()
	_test_rejected_recovery_after_removal_is_atomic()
	_test_successful_recovery_clears_active_anchor_observation()
	_test_authoritative_anchor_failure_preserves_mixed_derived_contacts()
	_test_contact_observations_follow_active_slice_not_ledger_history()
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
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "Sixth record locks the curve horizon")
	var before_records := track.get_cell_records()
	var before_available: int = track.get_available_track_cells()
	assert_equal(track.append_cells([
		Vector2i(0, 2), Vector2i(0, 3),
	]), 0, "Invalid endpoint candidate stops the buffer")
	assert_equal(track.get_cell_records().size(), before_records.size(), "Invalid candidate leaves route unchanged")
	assert_equal(track.get_available_track_cells(), before_available, "Invalid candidate leaves inventory unchanged")
	assert_equal(track.get_endpoint_cell(), Vector2i(2, 3), "Rejected suffix does not skip ahead")
	_assert_conservation(track, "After tentative rollback")


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
		assert_false(record.geometry_locked, "Construction does not lock any group record")
		if record.state == TrackCellRecordScript.State.BUILDING:
			building_count += 1
	assert_equal(building_count, 1, "At most one cell is BUILDING")
	_assert_conservation(track, "After excess construction")


func _test_cancellation_stops_at_locked_piece() -> void:
	var track = _make_three_by_three_curve_runtime()
	var support_cells: Array[Vector2i] = [Vector2i(2, 3)]
	assert_equal(track.append_cells(support_cells), 1, "G creates the horizon lock")
	var pieces = track.get_geometry_pieces()
	assert_true(pieces[0].locked, "B through F are horizon locked")
	assert_equal(pieces[0].exit_support_route_serial, 6, "G is the locked curve exit support")
	assert_false(track.cancel_ghost_suffix(Vector2i(2, 3)), "Cancellation cannot remove an active exit support")
	assert_equal(track.get_cell_records().size(), 6, "Support cancellation removes nothing")
	_assert_conservation(track, "After rejected cancellation")


func _test_recovery_refunds_composite_curve_one_cell_at_a_time() -> void:
	var track = _make_fully_built_three_by_three_curve_runtime()
	assert_equal(track.recover_behind(1.0), 1, "First cell recovered")
	assert_equal(track.get_available_track_cells(), 13, "First refund")
	assert_equal(track.recover_behind(2.0), 1, "Second cell recovered")
	assert_equal(track.get_available_track_cells(), 14, "Second refund")
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
	assert_equal(track.get_built_end_distance_cells(), 6.0, "Recovery does not renormalize built distance")


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
	var track = _make_fully_built_three_by_three_curve_runtime()
	assert_equal(track.recover_behind(1.0), 1, "Oldest curve interval recovers")
	var records = track.get_cell_records()
	assert_true(records[0].geometry_locked, "Surviving B through F ledger interval stays locked")
	assert_false(records[-1].geometry_locked, "G remains provisional without another horizon trigger")
	assert_true(records[0].geometry_group_id != records[-1].geometry_group_id, "Ledger and successor groups stay distinct")
	assert_equal(track.advance_construction(1.0), 0.0, "Completed construction cannot assign a new lock")
	assert_false(track.get_cell_records()[-1].geometry_locked, "Construction alone leaves the successor provisional")


func _test_locked_endpoint_rejects_disconnected_rebranch() -> void:
	var track = _make_three_by_three_curve_runtime()
	var appended_cells: Array[Vector2i] = [Vector2i(2, 3), Vector2i(2, 4)]
	assert_equal(track.append_cells(appended_cells), 2, "G and later suffix append")
	assert_true(track.cancel_ghost_suffix(Vector2i(2, 4)), "Only the suffix beyond G cancels")
	var locked_before = track.get_geometry_pieces()[0].duplicate_piece()
	var before_available: int = track.get_available_track_cells()
	var disconnected_cells: Array[Vector2i] = [Vector2i(0, 0)]
	assert_equal(track.append_cells(disconnected_cells), 0, "Disconnected branch is rejected")
	assert_equal(track.get_available_track_cells(), before_available, "Rejected branch leaves inventory unchanged")
	assert_equal(track.get_endpoint_cell(), Vector2i(2, 3), "Rejected branch preserves the fixed support endpoint")
	var locked_after = track.get_geometry_pieces()[0]
	assert_equal(locked_after.centerline, locked_before.centerline, "Locked curve endpoint remains immutable")
	assert_equal(locked_after.exit_support_route_serial, 6, "Locked curve support continuity remains intact")
	var continuation_cells: Array[Vector2i] = [Vector2i(2, 4)]
	assert_equal(track.append_cells(continuation_cells), 1, "Original continuation reconnects after the fixed support")


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


func _test_built_head_reflows_without_geometry_lock() -> void:
	var track = GridTrackRuntimeScript.new(Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_equal(track.append_cells([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]), 3, "Initial straights")
	assert_equal(track.advance_construction(3.0), 3.0, "Initial cells build")
	assert_false(track.get_geometry_pieces()[0].locked, "Built head is still provisional")
	assert_equal(track.append_cells([Vector2i(2, 1), Vector2i(2, 2)]), 2, "Turn completes")
	assert_equal(track.get_geometry_pieces()[0].kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Built cells reclassify")
	for record in track.get_cell_records().slice(0, 3):
		assert_equal(record.state, TrackCellRecordScript.State.BUILT, "Reclassification keeps built state")


func _test_twenty_construction_steps_keep_completed_head_reflowable() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var additions := {
		0: Vector2i(0, 0), # B
		21: Vector2i(1, 0), # C
		42: Vector2i(2, 0), # D
		63: Vector2i(2, 1), # E
		84: Vector2i(2, 2), # F
	}
	var completion_ticks: Array[int] = []
	for input_tick in range(85):
		if additions.has(input_tick):
			assert_equal(track.append_cells([additions[input_tick]]), 1, "Accepted route cell at tick %d" % input_tick)
		var states_before = track.get_cell_records()
		track.advance_construction(1.0 / 20.0)
		var states_after = track.get_cell_records()
		for index in range(states_after.size()):
			if states_before[index].state != TrackCellRecordScript.State.BUILT and states_after[index].state == TrackCellRecordScript.State.BUILT:
				completion_ticks.append(input_tick)
	assert_equal(completion_ticks, [19, 40, 61, 82], "B through E each use 20 construction steps")
	assert_equal(track.get_cell_records()[4].state, TrackCellRecordScript.State.BUILDING, "F receives its same-tick first step")
	assert_equal(track.get_cell_records()[4].build_progress, 1.0 / 20.0, "F first step is one twentieth")
	assert_equal(track.get_geometry_pieces()[0].kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "B through F resolves as 3x3")
	assert_false(track.get_geometry_pieces()[0].locked, "Completed B through E remains reflowable")


class _RejectingResolver extends TrackGeometryResolverScript:
	func resolve(
		_departure_cell: Vector2i,
		records: Array,
		_locked_pieces: Array,
		_anchors: Array,
		_grid_origin_units: Vector2,
		_grid_size: Vector2i,
		_cell_size_units: float
	) -> RefCounted:
		return TrackGeometryResolutionScript.rejected(records[-1].route_serial, &"test_reject")


class _RejectAfterFirstLedgerCandidateResolver extends TrackGeometryResolverScript:
	var resolve_calls_with_ledger := 0
	func resolve(
		departure_cell: Vector2i,
		records: Array,
		locked_pieces: Array,
		anchors: Array,
		grid_origin_units: Vector2,
		grid_size: Vector2i,
		cell_size_units: float
	) -> RefCounted:
		if not locked_pieces.is_empty():
			resolve_calls_with_ledger += 1
			return TrackGeometryResolutionScript.rejected(records[-1].route_serial, &"reject_after_first_ledger_candidate")
		return super.resolve(departure_cell, records, locked_pieces, anchors, grid_origin_units, grid_size, cell_size_units)


class _RejectAfterRecoveryRemovalResolver extends TrackGeometryResolverScript:
	func resolve(
		departure_cell: Vector2i,
		records: Array,
		locked_pieces: Array,
		anchors: Array,
		grid_origin_units: Vector2,
		grid_size: Vector2i,
		cell_size_units: float
	) -> RefCounted:
		if records.size() == 5 and not locked_pieces.is_empty():
			return TrackGeometryResolutionScript.rejected(records[-1].route_serial, &"reject_after_recovery_removal")
		return super.resolve(departure_cell, records, locked_pieces, anchors, grid_origin_units, grid_size, cell_size_units)


func _reflow_runtime() -> GridTrackRuntimeScript:
	return GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)


func _reflow_curve_cells() -> Array[Vector2i]:
	return [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	]


func _record_values(records: Array) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for record in records:
		values.append({
			"serial": record.route_serial,
			"cell": record.cell,
			"distance": record.route_distance_start_cells,
			"state": record.state,
			"progress": record.build_progress,
			"group": record.geometry_group_id,
			"locked": record.geometry_locked,
		})
	return values


func _piece_values(pieces: Array) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for piece in pieces:
		values.append({
			"serials": Vector2i(piece.first_route_serial, piece.last_route_serial),
			"kind": piece.kind,
			"distance": piece.absolute_start_distance_cells,
			"length": piece.nominal_length_cells,
			"footprint": piece.footprint_cells,
			"centerline": piece.centerline,
			"active_start": piece.active_local_start_cells,
			"active_end": piece.active_local_end_cells,
			"locked": piece.locked,
			"support": piece.exit_support_route_serial,
		})
	return values


func _recovery_observation_values(track: GridTrackRuntimeScript) -> Dictionary:
	return {
		"records": _record_values(track.get_cell_records()),
		"inventory": track.get_available_track_cells(),
		"pieces": _piece_values(track.get_geometry_pieces()),
		"built_end": track.get_built_end_distance_cells(),
		"recovered_cells_by_piece": track._recovered_cells_by_piece.duplicate(true),
		"recovered_end_distance_cells": track._recovered_end_distance_cells,
		"contact_observations": track.get_contact_observations().duplicate(true),
	}


func _piece_containing(pieces: Array, route_serial: int):
	for piece in pieces:
		if piece.contains_serial(route_serial):
			return piece
	return null


func _assert_record_piece_sync(track: GridTrackRuntimeScript) -> void:
	var pieces = track.get_geometry_pieces()
	for record in track.get_cell_records():
		var owners: Array = []
		for piece in pieces:
			if piece.contains_serial(record.route_serial):
				owners.append(piece)
		assert_equal(owners.size(), 1, "Every active record has exactly one owning piece")
		if owners.size() == 1:
			var owner = owners[0]
			assert_equal(record.geometry_group_id, owner.group_id, "Record group matches owning piece")
			assert_equal(record.geometry_locked, owner.locked, "Record lock matches owning piece")


func _assert_locked_prefix_through(pieces: Array, target_serial: int) -> void:
	var reached_target := false
	var saw_provisional := false
	for piece in pieces:
		if piece.locked:
			assert_false(saw_provisional, "No interior locked island exists")
		else:
			saw_provisional = true
		if not reached_target:
			assert_true(piece.locked, "Every predecessor through the required owner is locked")
			if piece.contains_serial(target_serial):
				reached_target = true
	assert_true(reached_target, "Required owner exists in the active piece sequence")


func _test_sixth_head_record_locks_whole_curve_and_supports_exit() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Five-cell curve")
	assert_equal(track.advance_construction(5.0), 5.0, "Head can already be built")
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "G appends")
	var pieces = track.get_geometry_pieces()
	assert_true(pieces[0].locked, "B through F locks as one ledger piece")
	assert_equal(pieces[0].exit_support_route_serial, 6, "G serial is exit support")
	var support_piece = _piece_containing(pieces, 6)
	assert_not_null(support_piece, "G has active geometry")
	if support_piece != null:
		assert_false(support_piece.locked, "Support geometry remains independently provisional")
	var locked_ghost_track = _reflow_runtime()
	locked_ghost_track.append_cells(_reflow_curve_cells())
	locked_ghost_track.append_cells([Vector2i(2, 3)])
	assert_equal(locked_ghost_track.get_cell_records()[0].state, TrackCellRecordScript.State.RESERVED_GHOST, "Locked record can remain a construction ghost")
	assert_false(locked_ghost_track.cancel_ghost_suffix(Vector2i(0, 0)), "Locked non-support ghost cannot cancel")
	assert_false(locked_ghost_track.cancel_ghost_suffix(Vector2i(2, 3)), "Exit-support ghost cannot cancel")


func _test_support_piece_locks_later_without_mutating_predecessor_metadata() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	track.append_cells([Vector2i(2, 3)])
	var predecessor_before = _piece_values(track.get_geometry_pieces())[0]
	assert_equal(track.append_cells([
		Vector2i(2, 4), Vector2i(2, 5), Vector2i(2, 6),
		Vector2i(3, 6), Vector2i(4, 6),
	]), 5, "Five-record continuation exceeds the head horizon")
	var support_piece = _piece_containing(track.get_geometry_pieces(), 6)
	assert_not_null(support_piece, "G still has a piece")
	if support_piece != null:
		assert_true(support_piece.locked, "Support piece later locks by ordinary horizon enforcement")
		var predecessor = _piece_containing(track.get_geometry_pieces(), 1)
		assert_not_null(predecessor, "Original locked predecessor survives")
		if predecessor != null:
			assert_equal(support_piece.centerline[0], predecessor.centerline[-1], "Continuation from fixed G stitches position")
			assert_true(support_piece.sample_nominal(0.0).heading.dot(predecessor.sample_nominal(float(predecessor.nominal_length_cells)).heading) > 0.999, "Continuation from fixed G stitches heading")
	_assert_record_piece_sync(track)
	assert_equal(_piece_values(track.get_geometry_pieces())[0]["support"], predecessor_before["support"], "Predecessor support metadata remains immutable")


func _test_cancellation_rolls_back_exactly_when_support_is_in_suffix() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	track.append_cells([Vector2i(2, 3)])
	var before_records = _record_values(track.get_cell_records())
	var before_inventory = track.get_available_track_cells()
	var before_pieces = _piece_values(track.get_geometry_pieces())
	assert_false(track.cancel_ghost_suffix(Vector2i(2, 3)), "Support target is ineligible")
	assert_equal(_record_values(track.get_cell_records()), before_records, "Records unchanged")
	assert_equal(track.get_available_track_cells(), before_inventory, "Inventory unchanged")
	assert_equal(_piece_values(track.get_geometry_pieces()), before_pieces, "Ledger geometry unchanged")


func _test_cancel_from_inside_wholly_provisional_piece_removes_only_eligible_suffix() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Curve head appends")
	var target = track.get_cell_records()[2]
	assert_true(track.cancel_ghost_suffix(target.cell), "Target inside provisional curve is legal")
	assert_equal(track.get_cell_records().size(), 2, "Target-to-end suffix is removed")
	assert_equal(track.get_available_track_cells(), track.get_total_track_cells() - 2, "Refund is exact")


func _test_rejected_append_rolls_back_only_tentative_suffix() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	var records_before = _record_values(track.get_cell_records())
	var pieces_before = _piece_values(track.get_geometry_pieces())
	var inventory_before = track.get_available_track_cells()
	track._resolver = _RejectingResolver.new()
	assert_equal(track.append_cells([Vector2i(2, 3)]), 0, "Resolver-rejected tentative continuation rejects")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Valid prefix serials stay intact")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Last valid geometry stays intact")
	assert_equal(track.get_available_track_cells(), inventory_before, "Tentative inventory rolls back")


func _test_locked_prefix_and_provisional_suffix_are_contiguous() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	track.append_cells([Vector2i(2, 3)])
	var saw_provisional := false
	for piece in track.get_geometry_pieces():
		if not piece.locked:
			saw_provisional = true
		else:
			assert_false(saw_provisional, "No interior locked island")


func _test_horizon_locks_complete_one_two_and_three_cell_pieces() -> void:
	var fixtures: Array[Array] = [
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4), Vector2i(0, 5)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4)],
		_reflow_curve_cells() + [Vector2i(2, 3)],
	]
	var kinds := [TrackGeometryPieceScript.Kind.CURVE_1X1, TrackGeometryPieceScript.Kind.CURVE_2X2, TrackGeometryPieceScript.Kind.CURVE_3X3]
	for index in range(fixtures.size()):
		var track = _reflow_runtime()
		var fixture: Array[Vector2i] = []
		for cell in fixtures[index]:
			fixture.append(cell)
		assert_equal(track.append_cells(fixture), fixture.size(), "Fixture appends")
		assert_equal(track.get_geometry_pieces()[0].kind, kinds[index], "Fixture resolves requested curve kind")
		assert_true(track.get_geometry_pieces()[0].locked, "Horizon exits only at whole piece boundary")
		_assert_record_piece_sync(track)


func _test_rejected_eligible_cancel_restores_route_inventory_and_ledger() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	var records_before = _record_values(track.get_cell_records())
	var inventory_before = track.get_available_track_cells()
	var pieces_before = _piece_values(track.get_geometry_pieces())
	track._resolver = _RejectingResolver.new()
	assert_false(track.cancel_ghost_suffix(Vector2i(2, 0)), "Resolver-rejected eligible suffix cancel fails")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Cancel failure restores records")
	assert_equal(track.get_available_track_cells(), inventory_before, "Cancel failure restores inventory")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Cancel failure restores ledger-observable geometry")


func _test_suffix_after_exit_support_remains_cancelable_and_support_expires_after_recovery() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	track.append_cells([Vector2i(2, 3), Vector2i(2, 4)])
	assert_true(track.cancel_ghost_suffix(Vector2i(2, 4)), "Suffix strictly after support remains eligible")
	assert_false(track.cancel_ghost_suffix(Vector2i(2, 3)), "Active support remains ineligible")
	track.advance_construction(5.0)
	track.recover_behind(5.0)
	assert_true(track.cancel_ghost_suffix(Vector2i(2, 3)), "Pruned predecessor releases former support eligibility")


func _test_horizon_rejection_after_first_staged_ledger_piece_is_atomic() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Initial five-record candidate prefix resolves")
	var records_before = _record_values(track.get_cell_records())
	var inventory_before = track.get_available_track_cells()
	var pieces_before = _piece_values(track.get_geometry_pieces())
	var resolver = _RejectAfterFirstLedgerCandidateResolver.new()
	track._resolver = resolver
	assert_equal(track.append_cells([Vector2i(2, 3)]), 0, "Post-ledger resolution rejects append")
	assert_equal(resolver.resolve_calls_with_ledger, 1, "Failure occurs after exactly one staged ledger candidate")
	assert_equal(_record_values(track.get_cell_records()), records_before, "No partial record commit")
	assert_equal(track.get_available_track_cells(), inventory_before, "No partial inventory commit")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "No partial ledger expansion")
	track._resolver = TrackGeometryResolverScript.new()
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "Subsequent valid append remains legal")
	assert_equal(track.get_cell_records()[-1].route_serial, 6, "Rejected append did not consume route serial")


func _test_rejected_recovery_after_removal_is_atomic() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Recovery fixture curve appends")
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "Recovery fixture support appends")
	assert_equal(track.advance_construction(6.0), 6.0, "Recovery fixture builds sequentially")
	track.set_contact_anchors([RouteContactAnchorScript.new(&"recovery_active_b", Vector2i(0, 0))])
	var before = _recovery_observation_values(track)
	var before_contacts: Array = before["contact_observations"]
	assert_equal(before_contacts.size(), 1, "Active B anchor publishes one observation before rejected recovery")
	assert_true(before_contacts[0].contact_possible and before_contacts[0].contacted, "Active B anchor is true before rejected recovery")
	track._resolver = _RejectAfterRecoveryRemovalResolver.new()
	assert_equal(track.recover_behind(1.0), 0, "Post-removal resolver rejection returns no recovered cells")
	assert_equal(_recovery_observation_values(track), before, "Recovery rejection preserves records, inventory, pieces, ledger support, recovered map/end, contacts, active ends, and built end")
	var after = track.get_contact_observations()
	assert_equal(after.size(), 1, "Rejected recovery retains the active B anchor observation")
	assert_true(after[0].contact_possible and after[0].contacted, "Rejected recovery retains active B true/true observation")


func _test_successful_recovery_clears_active_anchor_observation() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Control recovery curve appends")
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "Control recovery support appends")
	assert_equal(track.advance_construction(6.0), 6.0, "Control recovery builds sequentially")
	track.set_contact_anchors([RouteContactAnchorScript.new(&"recovery_active_b", Vector2i(0, 0))])
	var before = track.get_contact_observations()
	assert_equal(before.size(), 1, "Control has one active B anchor observation")
	assert_true(before[0].contact_possible and before[0].contacted, "Control active B anchor begins true/true")
	assert_equal(track.recover_behind(1.0), 1, "Successful recovery removes B")
	var after = track.get_contact_observations()
	assert_equal(after.size(), 1, "Recovered anchor remains authoritative as an observation")
	assert_false(after[0].contact_possible or after[0].contacted, "Recovered B leaves the active slice and publishes false/false")


class _RejectAnchorReresolutionResolver extends TrackGeometryResolverScript:
	var reject_anchor_reresolution := false
	func resolve(
		departure_cell: Vector2i,
		records: Array,
		locked_pieces: Array,
		anchors: Array,
		grid_origin_units: Vector2,
		grid_size: Vector2i,
		cell_size_units: float
	) -> RefCounted:
		if reject_anchor_reresolution and not anchors.is_empty():
			return TrackGeometryResolutionScript.rejected(records[-1].route_serial, &"injected_anchor_reresolution_reject")
		return super.resolve(departure_cell, records, locked_pieces, anchors, grid_origin_units, grid_size, cell_size_units)


func _test_authoritative_anchor_failure_preserves_mixed_derived_contacts() -> void:
	var track = _reflow_runtime()
	var resolver = _RejectAnchorReresolutionResolver.new()
	track._resolver = resolver
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Initial valid geometry is accepted")
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "Initial ledger geometry is accepted")
	var records_before = _record_values(track.get_cell_records())
	var pieces_before = _piece_values(track.get_geometry_pieces())
	resolver.reject_anchor_reresolution = true
	var anchors: Array[RouteContactAnchorScript] = [
		RouteContactAnchorScript.new(&"still_contacted", Vector2i(0, 0)),
		RouteContactAnchorScript.new(&"unsatisfied", Vector2i(0, 2)),
	]
	track.set_contact_anchors(anchors)
	var observations = track.get_contact_observations()
	assert_equal(_record_values(track.get_cell_records()), records_before, "Anchor failure preserves records")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Injected anchor failure preserves ledger-observable geometry")
	assert_equal(observations.size(), 2, "Both authoritative anchors publish observations")
	assert_equal(observations[0].anchor_id, &"still_contacted", "First authoritative anchor identity is copied")
	assert_equal(observations[0].cell, Vector2i(0, 0), "First authoritative anchor cell is copied")
	assert_equal(observations[1].anchor_id, &"unsatisfied", "Second authoritative anchor identity is copied")
	assert_equal(observations[1].cell, Vector2i(0, 2), "Second authoritative anchor cell is copied")
	assert_true(observations[0].contact_possible and observations[0].contacted, "Still-contacted anchor stays true")
	assert_false(observations[1].contact_possible or observations[1].contacted, "Unsatisfied anchor is false")


func _test_contact_observations_follow_active_slice_not_ledger_history() -> void:
	var track = _reflow_runtime()
	track.append_cells(_reflow_curve_cells())
	track.append_cells([Vector2i(2, 3)])
	track.advance_construction(6.0)
	track.recover_behind(1.0)
	track.set_contact_anchors([RouteContactAnchorScript.new(&"recovered", Vector2i(0, 0))])
	assert_false(track.get_contact_observations()[0].contacted, "Recovered slice does not contact")


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
	var support_cells: Array[Vector2i] = [Vector2i(2, 3)]
	assert_equal(track.append_cells(support_cells), 1, "Fixture appends G to lock B through F")
	assert_equal(track.advance_construction(6.0), 6.0, "Fixture builds B through G")
	return track


func _assert_conservation(track, message: String) -> void:
	assert_equal(
		track.get_available_track_cells() + track.get_cell_records().size(),
		track.get_total_track_cells(),
		message
	)
