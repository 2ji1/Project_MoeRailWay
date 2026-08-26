extends "res://tests/support/prototype_test.gd"

const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackGeometryResolverScript = preload("res://src/domain/track/track_geometry_resolver.gd")
const TrackGeometryResolutionScript = preload("res://src/domain/track/track_geometry_resolution.gd")


func run() -> PackedStringArray:
	_test_endpoint_reshape_full_curve_does_not_retain_unrelated_predecessor()
	_test_endpoint_reshape_anchor_path_retires_stable_pieces_atomically()
	_test_endpoint_reshape_five_straight_records_are_not_a_generic_horizon()
	_test_endpoint_reshape_endpoint_owner_and_incoming_supports_are_concrete()
	_test_endpoint_reshape_locked_boundary_downgrades_the_template()
	_test_endpoint_reshape_construction_completion_does_not_lock()
	_test_endpoint_reshape_stable_paths_retire_whole_pieces()
	_test_ordered_append_growth_and_transactional_rollback()
	_test_built_head_reflows_without_geometry_lock()
	_test_construction_excess_and_group_assignment()
	_test_cancellation_stops_at_locked_piece()
	_test_recovery_refunds_composite_curve_one_cell_at_a_time()
	_test_partial_recovery_preserves_locked_curve_sampling()
	_test_recovery_preserves_surviving_predecessor_geometry()
	_test_recovery_keeps_group_ids_unique()
	_test_full_prune_then_relock_uses_fresh_owner_group_ids()
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
	_test_prepare_and_pose_share_inclusive_boundary_owner()
	_test_epsilon_sliver_preserves_raw_owner_for_prepare_and_pose()
	_test_prepare_transaction_rejects_after_staging_without_mutation()
	_test_zero_extent_internal_wait_does_not_lock_successor_reflow()
	_test_departure_forward_boundary_and_route_end_ownership()
	_test_two_sided_outside_epsilon_stitch_continuity()
	_test_prepared_built_curve_recovers_same_serials_without_ledger_mutation()
	return finish()


func _test_endpoint_reshape_five_straight_records_are_not_a_generic_horizon() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(3, 0), Vector2i(4, 0),
	]), 5, "Five straight records append")
	var pieces = track.get_geometry_pieces()
	print("Endpoint reshape: five straight records are not a generic horizon")
	assert_equal(pieces.size(), 5, "Each straight record retains its concrete owner")
	assert_equal(pieces[0].first_route_serial, 1, "First straight owner starts at serial one")
	assert_equal(pieces[-1].last_route_serial, 5, "Endpoint owner reaches serial five")
	assert_true(pieces[0].locked, "Retirement locks only the stable predecessor pieces")
	assert_true(pieces[1].locked, "Retirement keeps support span concrete")
	assert_false(pieces[2].locked, "First incoming support remains editable")
	assert_false(pieces[3].locked, "Second incoming support remains editable")
	assert_false(pieces[4].locked, "Endpoint owner remains editable")


func _test_endpoint_reshape_full_curve_does_not_retain_unrelated_predecessor() -> void:
	var track = _reflow_runtime()
	var predecessor = TrackGeometryPieceScript.new()
	predecessor.kind = TrackGeometryPieceScript.Kind.STRAIGHT
	predecessor.first_route_serial = 1
	predecessor.last_route_serial = 1
	var endpoint = TrackGeometryPieceScript.new()
	endpoint.kind = TrackGeometryPieceScript.Kind.CURVE_3X3
	endpoint.first_route_serial = 2
	endpoint.last_route_serial = 6
	var pieces: Array[TrackGeometryPieceScript] = [predecessor, endpoint]
	var records: Array[TrackCellRecordScript] = []
	for serial in range(1, 7):
		records.append(TrackCellRecordScript.new(serial, Vector2i(serial - 1, 0), float(serial - 1)))
	print("Endpoint reshape: full curve does not retain unrelated predecessor")
	assert_equal(
		track._stable_retirement_index(pieces, records),
		0,
		"A full-size endpoint curve needs no unrelated predecessor support"
	)


func _test_endpoint_reshape_anchor_path_retires_stable_pieces_atomically() -> void:
	var track = _reflow_runtime()
	var cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0),
	]
	track._sequence.append_candidates(cells)
	track.set_contact_anchors([
		RouteContactAnchorScript.new(&"endpoint_anchor", Vector2i(5, 0)),
	])
	var pieces = track.get_geometry_pieces()
	print("Endpoint reshape: anchor path retires stable pieces atomically")
	assert_equal(pieces.size(), 6, "Anchor path retains concrete piece ownership")
	assert_true(pieces[0].locked, "Anchor path retires the first complete piece")
	assert_true(pieces[1].locked, "Anchor path retires the second complete piece")
	assert_true(pieces[2].locked, "Anchor path retires the third complete piece")
	assert_false(pieces[3].locked, "Anchor path retains the first incoming support")
	assert_false(pieces[4].locked, "Anchor path retains the second incoming support")
	assert_false(pieces[5].locked, "Anchor path retains the endpoint owner")
	assert_equal(track._locked_ledger.size(), 3, "Anchor path stages the same whole-piece ledger")
	if track._locked_ledger.size() >= 3:
		assert_equal(track._locked_ledger[0].first_route_serial, 1, "Anchor ledger preserves first serial")
		assert_equal(track._locked_ledger[2].last_route_serial, 3, "Anchor ledger preserves last serial")
		assert_equal(track._locked_ledger[2].exit_support_route_serial, 4, "Anchor ledger preserves exit support")
	_assert_conservation(track, "Anchor path preserves inventory conservation")
	assert_true(track.get_contact_observations()[0].contacted, "Anchor path publishes contact observation")


func _test_endpoint_reshape_endpoint_owner_and_incoming_supports_are_concrete() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0),
	]), 6, "Concrete owner fixture appends")
	var pieces = track.get_geometry_pieces()
	var endpoint_owner = _piece_containing(pieces, 6)
	var first_support = _piece_containing(pieces, 4)
	var second_support = _piece_containing(pieces, 5)
	print("Endpoint reshape: endpoint owner and incoming supports are concrete")
	assert_not_null(endpoint_owner, "Endpoint route serial has a concrete owner")
	assert_not_null(first_support, "First incoming support has a concrete owner")
	assert_not_null(second_support, "Second incoming support has a concrete owner")
	if endpoint_owner == null or first_support == null or second_support == null:
		return
	assert_equal(endpoint_owner.first_route_serial, 6, "Endpoint owner starts at the active endpoint")
	assert_equal(endpoint_owner.last_route_serial, 6, "Endpoint owner ends at the active endpoint")
	assert_equal(first_support.first_route_serial, 4, "First support is the immediately preceding route")
	assert_equal(second_support.first_route_serial, 5, "Second support is the nearest preceding route")
	assert_false(first_support.locked, "First support remains editable")
	assert_false(second_support.locked, "Second support remains editable")


func _test_endpoint_reshape_locked_boundary_downgrades_the_template() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(3, 0), Vector2i(4, 0),
	]), 5, "Downgrade fixture appends")
	assert_true(track.prepare_for_train_sampling(0.0, 3.0), "Prefix preparation establishes a locked boundary")
	var locked_before = _piece_containing(track.get_geometry_pieces(), 3).duplicate_piece()
	assert_equal(track.append_cells([Vector2i(4, 1), Vector2i(4, 2)]), 2, "Turn after locked boundary appends")
	var pieces = track.get_geometry_pieces()
	var downgraded = _piece_containing(pieces, 4)
	print("Endpoint reshape: locked boundary downgrades the template")
	assert_not_null(downgraded, "Downgraded endpoint template has an owner")
	if downgraded == null:
		return
	assert_equal(downgraded.kind, TrackGeometryPieceScript.Kind.CURVE_2X2, "One available support selects 2x2")
	assert_equal(downgraded.first_route_serial, 4, "Downgrade starts after the locked boundary")
	assert_equal(downgraded.last_route_serial, 6, "Downgrade owns its complete three-record span")
	var locked_after = _piece_containing(pieces, 3)
	assert_equal(locked_after.centerline, locked_before.centerline, "Locked boundary geometry is immutable")
	assert_equal(locked_after.first_route_serial, locked_before.first_route_serial, "Locked serial span is retained")
	assert_equal(locked_after.last_route_serial, locked_before.last_route_serial, "Locked serial end is retained")


func _test_endpoint_reshape_construction_completion_does_not_lock() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	]), 3, "Construction fixture appends")
	assert_equal(track.advance_construction(3.0), 3.0, "Construction fixture completes")
	print("Endpoint reshape: construction completion does not lock")
	for piece in track.get_geometry_pieces():
		assert_false(piece.locked, "Construction completion leaves geometry unlocked")


func _test_endpoint_reshape_stable_paths_retire_whole_pieces() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Stable path curve appends")
	var initial_curve = _piece_containing(track.get_geometry_pieces(), 1)
	assert_not_null(initial_curve, "Stable path has an L-shaped owner")
	if initial_curve != null:
		assert_equal(initial_curve.kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "L-shaped route resolves as CURVE_3X3")
		assert_equal(initial_curve.nominal_length_cells, 5, "L-shaped CURVE_3X3 owns nominal length five")
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "Stable path successor appends")
	var curve = _piece_containing(track.get_geometry_pieces(), 1)
	print("Endpoint reshape: stable paths retire whole pieces")
	assert_not_null(curve, "Stable path retains a complete curve owner")
	if curve == null:
		return
	assert_true(curve.locked, "Retirement locks the complete curve piece")
	assert_equal(curve.first_route_serial, 1, "Retirement preserves curve first serial")
	assert_equal(curve.last_route_serial, 5, "Retirement preserves curve last serial")
	assert_equal(curve.exit_support_route_serial, 6, "Retirement preserves exit support serial")
	assert_false(track.cancel_ghost_suffix(Vector2i(2, 3)), "Exit support remains cancellation-ineligible")
	assert_equal(track.append_cells([Vector2i(2, 4)]), 1, "Stable path appends a suffix beyond its support")
	var available_before_cancel: int = track.get_available_track_cells()
	assert_true(track.cancel_ghost_suffix(Vector2i(2, 4)), "Stable path cancels an eligible suffix")
	assert_equal(track.get_available_track_cells(), available_before_cancel + 1, "Suffix cancellation refunds one inventory cell")
	assert_equal(track.get_cell_records()[-1].route_serial, 6, "Successful cancellation preserves the support endpoint serial")
	track.set_contact_anchors([
		RouteContactAnchorScript.new(&"stable_support", Vector2i(2, 3)),
	])
	assert_equal(track.get_geometry_pieces()[0].first_route_serial, 1, "Anchor re-resolution preserves ledger first serial")
	assert_equal(track.get_geometry_pieces()[0].last_route_serial, 5, "Anchor re-resolution preserves ledger last serial")
	assert_true(track.get_contact_observations()[0].contacted, "Anchor re-resolution publishes contact")
	assert_equal(track.advance_construction(6.0), 6.0, "Stable path builds before recovery")
	assert_equal(track.recover_behind(1.0), 1, "Stable path recovers one cell")
	assert_equal(track.get_available_track_cells(), track.get_total_track_cells() - 5, "Recovery refunds one complete active record")
	assert_equal(track._recovered_end_distance_cells, 1.0, "Recovery frontier advances by one nominal cell")
	assert_true(track._recovered_cells_by_piece.has("1:5"), "Recovery retains ledger piece facts")
	var surviving_curve = _piece_containing(track.get_geometry_pieces(), 2)
	assert_not_null(surviving_curve, "Recovery keeps the whole ledger piece")
	if surviving_curve != null:
		assert_equal(surviving_curve.first_route_serial, 1, "Recovery keeps ledger first serial")
		assert_equal(surviving_curve.last_route_serial, 5, "Recovery keeps ledger last serial")
	assert_true(track.prepare_for_train_sampling(1.5, 4.5), "Stable path preparation succeeds")
	_assert_conservation(track, "Stable path preserves inventory after recovery and preparation")

	var prepare_track = _reflow_runtime()
	assert_equal(prepare_track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	]), 3, "Prepare postcondition fixture appends")
	assert_equal(prepare_track.advance_construction(3.0), 3.0, "Prepare postcondition fixture builds")
	var available_before_prepare: int = prepare_track.get_available_track_cells()
	assert_true(prepare_track.prepare_for_train_sampling(0.0, 0.0), "Prepare postcondition locks the sampled owner")
	var prepared_owner = _piece_containing(prepare_track.get_geometry_pieces(), 1)
	assert_not_null(prepared_owner, "Prepared owner remains concrete")
	if prepared_owner != null:
		assert_true(prepared_owner.locked, "Prepare locks a complete piece")
		assert_equal(prepared_owner.first_route_serial, 1, "Prepare preserves owner first serial")
		assert_equal(prepared_owner.last_route_serial, 1, "Prepare preserves owner last serial")
		assert_equal(prepared_owner.exit_support_route_serial, 2, "Prepare preserves successor support metadata")
	assert_equal(prepare_track.get_available_track_cells(), available_before_prepare, "Prepare does not charge inventory")
	_assert_conservation(prepare_track, "Prepare preserves inventory conservation")


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
	assert_true(track.prepare_for_train_sampling(0.5, 4.5), "Curve samples prepare before recovery")
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
	assert_true(track.prepare_for_train_sampling(1.5, 1.5), "Initial surviving predecessor sample prepares")
	var surviving_position: Vector2 = track.get_position_at_distance_cells(1.5)
	assert_equal(track.advance_construction(1.0), 1.0, "Leading piece builds")
	assert_equal(track.recover_behind(1.0), 1, "Leading piece fully recovers")
	assert_true(track.prepare_for_train_sampling(1.5, 1.5), "Post-recovery surviving predecessor sample prepares")
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


func _test_full_prune_then_relock_uses_fresh_owner_group_ids() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "B through F curve appends")
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "G locks B through F")
	assert_equal(track.append_cells([
		Vector2i(2, 4), Vector2i(2, 5), Vector2i(2, 6),
		Vector2i(3, 6), Vector2i(4, 6),
	]), 5, "H through L independently lock G")
	assert_equal(track.advance_construction(11.0), 11.0, "B through L build before recovery")
	assert_equal(track.recover_behind(5.0), 5, "B through F fully recover and prune")
	var surviving_g = _piece_containing(track.get_geometry_pieces(), 6)
	assert_not_null(surviving_g, "G survives the leading ledger prune")
	if surviving_g == null:
		return
	assert_true(surviving_g.locked, "G remains independently locked")
	var surviving_group_id: int = surviving_g.group_id
	assert_equal(track.append_cells([Vector2i(5, 6)]), 1, "M triggers the next horizon lock")
	var pieces = track.get_geometry_pieces()
	var new_locked_owner = _piece_containing(pieces, 7)
	assert_not_null(new_locked_owner, "H has an active owner after relocking")
	if new_locked_owner == null:
		return
	assert_true(new_locked_owner.locked, "Horizon independently locks the new owner")
	assert_equal(surviving_g.group_id, surviving_group_id, "Surviving locked owner keeps its group ID")
	assert_equal(
		new_locked_owner.group_id,
		surviving_group_id + 1,
		"New ledger lock uses the group ID after the surviving ledger maximum"
	)
	var active_owner_group_ids: Dictionary = {}
	for piece in pieces:
		assert_false(
			active_owner_group_ids.has(piece.group_id),
			"Every active owner group ID is distinct"
		)
		active_owner_group_ids[piece.group_id] = true


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
	assert_true(zero.prepare_for_train_sampling(1.5, 1.5), "Zero-origin sample prepares")
	assert_true(shifted.prepare_for_train_sampling(1.5, 1.5), "Shifted-origin sample prepares")
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


func _test_prepared_built_curve_recovers_same_serials_without_ledger_mutation() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "B through F append as one route candidate")
	assert_equal(track.advance_construction(5.0), 5.0, "B through F are built before preparation")
	var provisional = track.get_geometry_pieces()[0]
	assert_equal(provisional.kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Built B through F is a provisional 3x3 curve")
	assert_false(provisional.locked, "Built B through F remains provisional before preparation")
	var pre_prepare_geometry = _geometry_values(provisional)
	assert_true(track.prepare_for_train_sampling(0.0, 0.0), "Prepare locks the complete B through F owner")
	var prepared = track.get_geometry_pieces()[0]
	assert_true(prepared.locked, "Prepared B through F curve is whole-piece locked")
	assert_equal(_geometry_values(prepared), pre_prepare_geometry, "Preparation preserves B through F geometry")
	assert_equal(prepared.exit_support_route_serial, -1, "Prepared B through F has no successor support")
	var immutable_ledger = _immutable_ledger_values(prepared)
	assert_equal(track.append_cells([Vector2i(2, 3)]), 1, "G appends only after B through F preparation")
	for cutoff in [1, 2, 3]:
		var before_inventory := track.get_available_track_cells()
		assert_equal(track.recover_behind(float(cutoff)), 1, "Cutoff %d recovers exactly one B through F serial" % cutoff)
		assert_equal(track.get_available_track_cells(), before_inventory + 1, "Cutoff %d refunds exactly one inventory cell" % cutoff)
		var pieces = track.get_geometry_pieces()
		assert_equal(pieces.size(), 2, "Cutoff %d retains locked B through F and provisional G pieces" % cutoff)
		var active = pieces[0]
		var g_piece = pieces[1]
		assert_true(active.locked, "Surviving B through F slice remains locked at cutoff %d" % cutoff)
		assert_equal(_immutable_ledger_values(active), immutable_ledger, "Cutoff %d preserves B through F ledger identity and geometry" % cutoff)
		assert_equal(active.active_local_start_cells, float(cutoff), "Active slice start advances by one at cutoff %d" % cutoff)
		assert_equal(active.active_local_end_cells, 5.0, "Active slice end remains the B through F nominal end")
		assert_equal(g_piece.first_route_serial, 6, "G remains the successor serial at cutoff %d" % cutoff)
		assert_equal(g_piece.last_route_serial, 6, "G remains one nominal route record at cutoff %d" % cutoff)
		assert_false(g_piece.locked, "G remains a provisional suffix at cutoff %d" % cutoff)
		_assert_locked_prefix_then_provisional(pieces, "Cutoff %d keeps locked B through F before provisional G" % cutoff)
		var records = track.get_cell_records()
		assert_equal(records.size(), 6 - cutoff, "Cutoff %d retains exactly the B through F suffix plus G" % cutoff)
		for index in range(5 - cutoff):
			assert_equal(records[index].route_serial, cutoff + index + 1, "Cutoff %d retains the expected B through F serial" % cutoff)
			assert_equal(records[index].state, TrackCellRecordScript.State.BUILT, "Surviving B through F serial stays built")
			assert_true(records[index].geometry_locked, "Surviving B through F serial stays locked")
		assert_equal(records[-1].route_serial, 6, "G remains the active route endpoint serial")
		assert_equal(records[-1].state, TrackCellRecordScript.State.RESERVED_GHOST, "G remains a genuine provisional ghost suffix")
		assert_false(records[-1].geometry_locked, "G record remains unlocked")
		_assert_conservation(track, "Cutoff %d conserves the B through F route inventory" % cutoff)


func _geometry_values(piece: TrackGeometryPieceScript) -> Dictionary:
	return {
		"kind": piece.kind,
		"first_route_serial": piece.first_route_serial,
		"last_route_serial": piece.last_route_serial,
		"nominal_length_cells": piece.nominal_length_cells,
		"absolute_start_distance_cells": piece.absolute_start_distance_cells,
		"footprint_cells": piece.footprint_cells.duplicate(),
		"centerline": piece.centerline.duplicate(),
		"exit_support_route_serial": piece.exit_support_route_serial,
	}


func _immutable_ledger_values(piece: TrackGeometryPieceScript) -> Dictionary:
	var values = _geometry_values(piece)
	values["group_id"] = piece.group_id
	return values


func _assert_locked_prefix_then_provisional(pieces: Array[TrackGeometryPieceScript], message: String) -> void:
	assert_equal(pieces.size(), 2, message)
	if pieces.size() != 2:
		return
	assert_true(pieces[0].locked, message)
	assert_false(pieces[1].locked, message)
	assert_equal(pieces[0].last_route_serial + 1, pieces[1].first_route_serial, message)
	var saw_provisional := false
	for piece in pieces:
		if not piece.locked:
			saw_provisional = true
		else:
			assert_false(saw_provisional, message)


func run_unprepared_pose_probe() -> bool:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Probe fixture appends provisional head")
	var pose = track.get_pose_sample_at_distance(0.0)
	if pose.is_empty():
		return false
	print("POSE_FALLBACK")
	return true


func _boundary_runtime() -> GridTrackRuntimeScript:
	var track = _reflow_runtime()
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1),
	]), 4, "Boundary fixture appends")
	assert_equal(track.advance_construction(4.0), 4.0, "Boundary fixture builds")
	assert_equal(track.get_geometry_pieces().size(), 2, "Boundary fixture has predecessor and successor")
	return track


func _canonical_test_distance(distance: float, boundary: float, epsilon: float) -> float:
	return boundary if absf(distance - boundary) <= epsilon else distance


func _test_prepare_and_pose_share_inclusive_boundary_owner() -> void:
	var probe = _boundary_runtime()
	var boundary: float = probe.get_geometry_pieces()[0].absolute_start_distance_cells + float(probe.get_geometry_pieces()[0].nominal_length_cells)
	var epsilon := GridTrackRuntimeScript.NOMINAL_BOUNDARY_EPSILON
	var distances := [boundary - epsilon, boundary, boundary + epsilon, boundary - epsilon * 1.01, boundary + epsilon * 1.01]
	var owner_indexes := [0, 0, 0, 0, 1]
	var local_distances := [boundary, boundary, boundary, boundary - epsilon * 1.01, epsilon * 1.01]
	for index in range(distances.size()):
		var track = _boundary_runtime()
		var distance: float = distances[index]
		var canonical := _canonical_test_distance(distance, boundary, epsilon)
		assert_true(track.prepare_for_train_sampling(distance, distance), "Preparation succeeds at %s" % distance)
		var expected_owner = track.get_geometry_pieces()[owner_indexes[index]]
		assert_true(expected_owner.locked, "Prepared owner is locked")
		_assert_locked_prefix_through(track.get_geometry_pieces(), expected_owner.last_route_serial)
		assert_true(is_equal_approx(canonical - expected_owner.absolute_start_distance_cells, local_distances[index]), "Canonical local distance has the expected owner-relative value")
		var expected = expected_owner.sample_nominal(canonical - expected_owner.absolute_start_distance_cells)
		var pose = track.get_pose_sample_at_distance(distance)
		assert_true(pose.position.is_equal_approx(expected.position), "Pose uses canonical prepared owner")
		assert_true(pose.heading.is_equal_approx(expected.heading), "Heading uses canonical prepared owner")


func _test_epsilon_sliver_preserves_raw_owner_for_prepare_and_pose() -> void:
	var probe = _boundary_runtime()
	var boundary: float = probe.get_geometry_pieces()[0].absolute_start_distance_cells + float(probe.get_geometry_pieces()[0].nominal_length_cells)
	var epsilon := GridTrackRuntimeScript.NOMINAL_BOUNDARY_EPSILON
	var sliver := epsilon * 1.001
	var distances := [boundary - sliver, boundary + sliver]
	var owner_indexes := [0, 1]
	for index in range(distances.size()):
		var distance: float = distances[index]
		assert_true(
			distance < boundary - epsilon or distance > boundary + epsilon,
			"Epsilon sliver is outside the inclusive canonical bound"
		)
		var track = _boundary_runtime()
		assert_true(track.prepare_for_train_sampling(distance, distance), "Epsilon sliver prepares its raw-side owner")
		var pieces = track.get_geometry_pieces()
		var owner = pieces[owner_indexes[index]]
		assert_true(owner.locked, "Epsilon sliver raw owner is locked")
		_assert_locked_prefix_through(pieces, owner.last_route_serial)
		if owner_indexes[index] == 0:
			assert_false(pieces[1].locked, "Lower epsilon sliver leaves the successor provisional")
		var raw_local_distance: float = distance - owner.absolute_start_distance_cells
		var expected = owner.sample_nominal(raw_local_distance)
		var pose = track.get_pose_sample_at_distance(distance)
		assert_true(pose.position.is_equal_approx(expected.position), "Epsilon sliver pose position keeps the raw owner")
		assert_true(pose.heading.is_equal_approx(expected.heading), "Epsilon sliver pose heading keeps the raw owner")


func _test_prepare_transaction_rejects_after_staging_without_mutation() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Prepare fixture appends")
	var records_before = _record_values(track.get_cell_records())
	var inventory_before = track.get_available_track_cells()
	var pieces_before = _piece_values(track.get_geometry_pieces())
	var resolver = _RejectAfterFirstLedgerCandidateResolver.new()
	track._resolver = resolver
	assert_false(track.prepare_for_train_sampling(0.0, 1.0), "Preparation rejects only after ledger staging")
	assert_equal(resolver.resolve_calls_with_ledger, 1, "Prepare reached its staged-ledger re-resolution")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Prepare failure restores records")
	assert_equal(track.get_available_track_cells(), inventory_before, "Prepare failure restores inventory")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Prepare failure restores ledger-visible pieces")


func _test_two_sided_outside_epsilon_stitch_continuity() -> void:
	var track = _boundary_runtime()
	var predecessor = track.get_geometry_pieces()[0]
	var boundary: float = predecessor.absolute_start_distance_cells + float(predecessor.nominal_length_cells)
	var epsilon := GridTrackRuntimeScript.NOMINAL_BOUNDARY_EPSILON
	var before_distance := boundary - epsilon * 1.01
	var after_distance := boundary + epsilon * 1.01
	assert_true(track.prepare_for_train_sampling(before_distance, after_distance), "Forward interval prepares both outside-epsilon owners")
	_assert_locked_prefix_through(track.get_geometry_pieces(), track.get_geometry_pieces()[1].last_route_serial)
	var before = track.get_pose_sample_at_distance(before_distance)
	var after = track.get_pose_sample_at_distance(after_distance)
	assert_true(before.heading.is_equal_approx(after.heading), "Two-sided stitch heading remains approximately continuous")
	var separation: float = before.position.distance_to(after.position)
	var nominal_travel_upper_bound := epsilon * 2.02 * 40.0
	assert_true(separation > 0.0, "Two-sided samples remain spatially distinct")
	assert_true(separation <= nominal_travel_upper_bound, "Two-sided samples stay within their known nominal travel bound")


func _test_zero_extent_internal_wait_does_not_lock_successor_reflow() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]), 3, "Three-straight boundary fixture appends")
	assert_equal(track.advance_construction(1.0), 1.0, "Only B builds to the internal boundary")
	assert_equal(track.get_built_end_distance_cells(), 1.0, "Built endpoint is exactly the zero-forward boundary")
	var before_prepare_successor = _piece_containing(track.get_geometry_pieces(), 2)
	assert_not_null(before_prepare_successor, "Successor owning C and D exists before prepare")
	assert_equal(track.get_cell_records()[1].state, TrackCellRecordScript.State.RESERVED_GHOST, "C remains a ghost before zero-extent prepare")
	assert_equal(track.get_cell_records()[2].state, TrackCellRecordScript.State.RESERVED_GHOST, "D remains a ghost before zero-extent prepare")
	if before_prepare_successor != null:
		assert_false(before_prepare_successor.locked, "Successor owning C and D is provisional before prepare")
	assert_true(track.prepare_for_train_sampling(1.0, 1.0), "Wait preparation succeeds")
	assert_equal(track.get_built_end_distance_cells(), 1.0, "Zero-forward prepare does not advance built endpoint")
	var predecessor = _piece_containing(track.get_geometry_pieces(), 1)
	var second_straight = _piece_containing(track.get_geometry_pieces(), 2)
	assert_not_null(predecessor, "Boundary predecessor exists")
	assert_not_null(second_straight, "Second straight exists")
	if predecessor != null:
		assert_true(predecessor.locked, "Zero-extent wait locks only the predecessor")
		_assert_locked_prefix_through(track.get_geometry_pieces(), predecessor.last_route_serial)
	if second_straight != null:
		assert_false(second_straight.locked, "Zero-extent wait leaves later records provisional")
	assert_equal(track.get_cell_records()[1].state, TrackCellRecordScript.State.RESERVED_GHOST, "Zero-extent wait leaves C ghost")
	assert_equal(track.get_cell_records()[2].state, TrackCellRecordScript.State.RESERVED_GHOST, "Zero-extent wait leaves D ghost")
	assert_equal(track.append_cells([Vector2i(3, 0), Vector2i(3, 1)]), 2, "Turn records after the locked boundary append")
	var reflowed = _piece_containing(track.get_geometry_pieces(), 3)
	assert_not_null(reflowed, "Provisional D through F span exists")
	if reflowed != null:
		assert_equal(reflowed.kind, TrackGeometryPieceScript.Kind.CURVE_2X2, "D through F reflows as 2x2 without crossing locked B")
		assert_false(reflowed.locked, "Reflowed future curve remains provisional before entry")


func _test_departure_forward_boundary_and_route_end_ownership() -> void:
	var departure_track = _reflow_runtime()
	departure_track.append_cells([Vector2i(0, 0)])
	departure_track.advance_construction(1.0)
	assert_true(departure_track.prepare_for_train_sampling(0.0, 0.0), "Departure prepares existing entry piece")
	assert_true(_piece_containing(departure_track.get_geometry_pieces(), 1).locked, "Departure entry locks")
	var boundary_track = _reflow_runtime()
	boundary_track.append_cells([Vector2i(0, 0), Vector2i(1, 0)])
	boundary_track.advance_construction(2.0)
	assert_true(boundary_track.prepare_for_train_sampling(1.0, 1.1), "Forward interval enters successor")
	assert_true(_piece_containing(boundary_track.get_geometry_pieces(), 2).locked, "Forward boundary locks successor")
	_assert_locked_prefix_through(boundary_track.get_geometry_pieces(), 2)
	var route_end_track = _reflow_runtime()
	route_end_track.append_cells([Vector2i(0, 0)])
	route_end_track.advance_construction(1.0)
	assert_true(route_end_track.prepare_for_train_sampling(1.0, 1.0), "Route end prepares predecessor")
	assert_equal(route_end_track.get_geometry_pieces().size(), 1, "Route end never invents successor")


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
