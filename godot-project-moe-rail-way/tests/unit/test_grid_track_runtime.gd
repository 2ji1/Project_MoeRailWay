extends "res://tests/support/prototype_test.gd"

const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackGeometryResolverScript = preload("res://src/domain/track/track_geometry_resolver.gd")
const TrackGeometryResolutionScript = preload("res://src/domain/track/track_geometry_resolution.gd")


func run() -> PackedStringArray:
	_test_endpoint_reshape_legal_operation_requires_concrete_candidate()
	_test_endpoint_reshape_identical_template_is_not_a_legal_operation()
	_test_endpoint_reshape_supported_straight_head_has_non_degenerate_targets()
	_test_endpoint_reshape_recovered_prefix_uses_active_predecessor()
	_test_endpoint_reshape_populated_origin_observations_are_detached()
	_test_endpoint_reshape_gesture_begin_captures_detached_origin()
	_test_endpoint_reshape_editable_span_has_deterministic_targets()
	_test_endpoint_reshape_active_gesture_defers_construction_and_recovery()
	_test_endpoint_reshape_right_left_straight_back_preserves_fixed_prefix()
	_test_endpoint_reshape_one_gesture_extends_after_selected_target()
	_test_endpoint_reshape_consecutive_gesture_retains_current_template()
	_test_endpoint_reshape_control_cells_are_omitted()
	_test_endpoint_reshape_target_reentry_rebuilds_from_origin()
	_test_endpoint_reshape_invalid_bounds_preserve_last_valid()
	_test_endpoint_reshape_invalid_overlap_preserve_last_valid()
	_test_endpoint_reshape_anchor_compatible_downgrade_preserves_observations()
	_test_endpoint_reshape_duplicate_preserves_last_valid()
	_test_endpoint_reshape_insufficient_inventory_preserves_last_valid()
	_test_endpoint_reshape_empty_departure_and_straight_accept_ordinary_extension()
	_test_endpoint_reshape_locked_endpoint_accepts_only_extension()
	_test_endpoint_reshape_gesture_rejects_illegal_starts()
	_test_endpoint_reshape_finalize_applies_retirement()
	_test_endpoint_reshape_full_curve_does_not_retain_unrelated_predecessor()
	_test_endpoint_reshape_anchor_path_retires_stable_pieces_atomically()
	_test_endpoint_reshape_five_straight_records_are_not_a_generic_horizon()
	_test_endpoint_reshape_endpoint_owner_and_incoming_supports_are_concrete()
	_test_endpoint_reshape_locked_boundary_downgrades_the_template()
	_test_endpoint_reshape_construction_completion_does_not_lock()
	_test_endpoint_reshape_stable_paths_retire_whole_pieces()
	_test_endpoint_reshape_abort_restores_exact_origin()
	_test_endpoint_reshape_locked_and_prepared_geometry_reject_mutation()
	_test_endpoint_reshape_locked_boundary_rejects_template_mutation()
	_test_endpoint_reshape_replacement_overlap_terminates_last_valid()
	_test_endpoint_reshape_extension_overlap_terminates_last_valid()
	_test_endpoint_reshape_nonoverlap_remains_active()
	_test_endpoint_reshape_train_lock_survives_begin_prepare_update_and_abort()
	_test_endpoint_reshape_candidate_contact_does_not_contaminate_origin_abort()
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


func _test_endpoint_reshape_legal_operation_requires_concrete_candidate() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 1), 1, Vector2.ZERO, Vector2i(4, 4), 40.0
	)
	assert_equal(track.append_cells([Vector2i(0, 1)]), 1, "Zero-inventory straight endpoint appends")
	print("Endpoint reshape fix: legal operation validates concrete alternatives")
	assert_false(
		track.gesture_has_legal_operation(Vector2i(0, 1)),
		"Zero-inventory one-cell straight endpoint has no replacement or extension"
	)
	assert_equal(
		track.gesture_begin(Vector2i(0, 1)),
		{},
		"Gesture begin rejects an endpoint without a concrete operation"
	)
	var invalid_alternative = GridTrackRuntimeScript.new(
		Vector2i(-1, 1), 3, Vector2.ZERO, Vector2i(4, 4), 40.0
	)
	var invalid_cells: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
	assert_equal(invalid_alternative.append_cells(invalid_cells), 3, "Invalid alternative fixture appends")
	invalid_alternative._resolver = _RejectingResolver.new()
	assert_false(
		invalid_alternative.gesture_has_legal_operation(Vector2i(2, 1)),
		"Resolver-rejected alternatives do not create legal operation"
	)


func _test_endpoint_reshape_identical_template_is_not_a_legal_operation() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 3, Vector2.ZERO, Vector2i(4, 1), 40.0
	)
	assert_equal(
		track.append_cells([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]),
		3,
		"Exhausted boundary straight fixture appends"
	)
	print("Endpoint reshape fix: identical template requires a real mutation")
	assert_false(
		track.gesture_has_legal_operation(Vector2i(2, 0)),
		"Identical straight template is not a legal operation"
	)
	assert_equal(
		track.gesture_begin(Vector2i(2, 0)),
		{},
		"Identical-only boundary endpoint cannot begin a gesture"
	)


func _test_endpoint_reshape_supported_straight_head_has_non_degenerate_targets() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 3), 5, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var cells: Array[Vector2i] = [
		Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3),
		Vector2i(3, 3), Vector2i(4, 3),
	]
	assert_equal(track.append_cells(cells), 5, "Supported straight endpoint appends")
	print("Endpoint reshape fix: supported straight span preserves targets")
	var result = track.gesture_begin(Vector2i(4, 3))
	assert_true(result is Dictionary, "Supported straight endpoint starts a gesture")
	if not result is Dictionary:
		return
	var span: Dictionary = result["editable_span"]
	var targets: Dictionary = result["targets"]
	assert_equal(span["first_route_serial"], 3, "Span starts at first retained support")
	assert_equal(span["last_route_serial"], 5, "Span ends at concrete endpoint owner")
	assert_equal(span["entry_predecessor_cell"], Vector2i(1, 3), "Span keeps fixed entry predecessor")
	assert_equal(targets["straight"], Vector2i(4, 3), "Supported straight target remains distinct")
	assert_equal(targets["left"], Vector2i(3, 4), "Supported left target uses full span")
	assert_equal(targets["right"], Vector2i(3, 2), "Supported right target uses full span")
	if track.gesture_is_active():
		track.gesture_finalize()


func _test_endpoint_reshape_recovered_prefix_uses_active_predecessor() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 3), 8, Vector2.ZERO, Vector2i(5, 8), 40.0
	)
	var cells: Array[Vector2i] = [
		Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3),
		Vector2i(3, 3), Vector2i(4, 3),
	]
	assert_equal(track.append_cells(cells), 5, "Recovered-prefix straight fixture appends")
	assert_equal(track.advance_construction(5.0), 5.0, "Recovered-prefix straight fixture builds")
	assert_equal(track.recover_behind(2.0), 2, "Recovered-prefix straight fixture removes its prefix")
	print("Endpoint reshape fix: recovered prefix preserves active predecessor targets")
	var result = track.gesture_begin(Vector2i(4, 3))
	assert_true(result is Dictionary, "Recovered-prefix supported endpoint starts a gesture")
	if not result is Dictionary:
		return
	var span: Dictionary = result["editable_span"]
	var targets: Dictionary = result["targets"]
	assert_equal(span["first_index"], 0, "Recovered span starts at active index zero")
	assert_equal(span["first_route_serial"], 3, "Recovered span keeps the first active support serial")
	assert_equal(span["entry_predecessor_cell"], Vector2i(1, 3), "Recovered span uses the active predecessor")
	assert_equal(span["incoming_heading"], Vector2i(1, 0), "Recovered span keeps the incoming heading")
	assert_equal(targets["straight"], Vector2i(4, 3), "Recovered straight target uses the active predecessor")
	assert_equal(targets["left"], Vector2i(3, 4), "Recovered left target uses the active predecessor")
	assert_equal(targets["right"], Vector2i(3, 2), "Recovered right target uses the active predecessor")
	if track.gesture_is_active():
		track.gesture_finalize()


func _test_endpoint_reshape_populated_origin_observations_are_detached() -> void:
	var track = _reflow_runtime()
	var cells: Array[Vector2i] = _reflow_curve_cells()
	cells.append(Vector2i(2, 3))
	assert_equal(track.append_cells(cells), 6, "Populated origin fixture appends")
	track.set_contact_anchors([
		RouteContactAnchorScript.new(&"origin_anchor", Vector2i(0, 0)),
	])
	assert_equal(track.advance_construction(2.5), 2.5, "Populated origin fixture leaves construction state")
	assert_equal(track.recover_behind(1.0), 1, "Populated origin fixture leaves recovery map")
	var authoritative_records := _record_values(track.get_cell_records())
	var authoritative_pieces := _piece_values(track.get_geometry_pieces())
	var authoritative_ledger := _piece_values(track._locked_ledger)
	var authoritative_recovery := _recovery_observation_values(track)
	var authoritative_anchor_cell: Vector2i = track._anchors[0].cell
	print("Endpoint reshape fix: populated origin observations stay detached")
	var result = track.gesture_begin(track.get_endpoint_cell())
	assert_true(result is Dictionary, "Populated origin begins")
	if not result is Dictionary:
		return
	assert_true(result["locked_ledger"].size() > 0, "Origin includes populated ledger")
	assert_true(result["anchors"].size() > 0, "Origin includes populated anchors")
	assert_true(result["recovery"]["recovered_cells_by_piece"].size() > 0, "Origin includes populated recovery map")
	assert_true(result["construction"].size() > 0, "Origin includes construction records")
	assert_true(result["contact_observations"].size() > 0, "Origin includes contact observations")
	result["route_records"][0].cell = Vector2i(99, 99)
	result["pieces"][0].centerline[0] = Vector2(999.0, 999.0)
	result["locked_ledger"][0].centerline[0] = Vector2(998.0, 998.0)
	result["anchors"][0].cell = Vector2i(98, 98)
	var recovery_keys: Array = result["recovery"]["recovered_cells_by_piece"].keys()
	assert_true(recovery_keys.size() > 0, "Returned recovery contains an existing piece key")
	if not recovery_keys.is_empty():
		var recovery_inner: Dictionary = result["recovery"]["recovered_cells_by_piece"][recovery_keys[0]]
		var recovered_cell_keys: Array = recovery_inner.keys()
		assert_true(recovered_cell_keys.size() > 0, "Returned recovery contains an existing inner cell")
		if not recovered_cell_keys.is_empty():
			result["recovery"]["recovered_cells_by_piece"][recovery_keys[0]][recovered_cell_keys[0]] = false
	result["construction"][0].build_progress = 99.0
	result["contact_observations"][0].contacted = true
	var stored = track.call("get_gesture_origin_observation")
	assert_equal(_record_values(stored["route_records"]), authoritative_records, "Stored origin records are detached")
	assert_equal(_piece_values(stored["pieces"]), authoritative_pieces, "Stored origin pieces are detached")
	assert_equal(_piece_values(stored["locked_ledger"]), authoritative_ledger, "Stored origin ledger is detached")
	assert_equal(stored["anchors"][0].cell, Vector2i(0, 0), "Stored origin anchors are detached")
	assert_equal(stored["recovery"]["recovered_cells_by_piece"], authoritative_recovery["recovered_cells_by_piece"], "Stored origin recovery is detached")
	assert_equal(_record_values(stored["construction"]), authoritative_records, "Stored origin construction is detached")
	assert_equal(stored["contact_observations"], authoritative_recovery["contact_observations"], "Stored origin contacts are detached")
	assert_equal(_record_values(track.get_cell_records()), authoritative_records, "Authoritative records remain unchanged")
	assert_equal(_piece_values(track.get_geometry_pieces()), authoritative_pieces, "Authoritative pieces remain unchanged")
	assert_equal(_piece_values(track._locked_ledger), authoritative_ledger, "Authoritative ledger remains unchanged")
	assert_equal(track._anchors[0].cell, authoritative_anchor_cell, "Authoritative anchors remain unchanged")
	assert_equal(_recovery_observation_values(track), authoritative_recovery, "Authoritative recovery remains unchanged")
	track.gesture_finalize()


func _test_endpoint_reshape_gesture_begin_captures_detached_origin() -> void:
	var track = _make_fully_built_three_by_three_curve_runtime()
	var endpoint: Vector2i = track.get_endpoint_cell()
	print("Endpoint reshape: gesture begin captures detached origin")
	assert_true(track.has_method("gesture_begin"), "Gesture begin contract exists")
	if not track.has_method("gesture_begin"):
		return
	var result = track.call("gesture_begin", endpoint)
	assert_true(result is Dictionary, "Gesture begin returns an origin observation")
	if not result is Dictionary:
		return
	assert_true(result.has("route_records"), "Origin captures route records")
	assert_true(result.has("pieces"), "Origin captures geometry pieces")
	assert_true(result.has("locked_ledger"), "Origin captures immutable ledger")
	assert_true(result.has("recovery"), "Origin captures recovery state")
	assert_true(result.has("construction"), "Origin captures construction state")
	assert_equal(result["route_records"].size(), track.get_cell_records().size(), "Origin route count matches")
	var detached_records = result["route_records"]
	if detached_records.size() > 0:
		detached_records[0].cell = Vector2i(99, 99)
	assert_equal(track.get_cell_records()[0].cell, Vector2i(0, 0), "Origin records are detached")
	var detached_pieces = result["pieces"]
	if detached_pieces.size() > 0:
		detached_pieces[0].centerline[0] = Vector2(999.0, 999.0)
	assert_false(
		track.get_geometry_pieces()[0].centerline[0].is_equal_approx(Vector2(999.0, 999.0)),
		"Origin pieces are detached"
	)
	assert_true(track.has_method("gesture_is_active"), "Gesture active contract exists")
	if track.has_method("gesture_is_active"):
		assert_true(track.call("gesture_is_active"), "Gesture begin marks runtime active")
	assert_true(track.has_method("gesture_finalize"), "Gesture finalize contract exists")
	if track.has_method("gesture_finalize"):
		track.call("gesture_finalize")
	if track.has_method("gesture_is_active"):
		assert_false(track.call("gesture_is_active"), "Finalize clears active state")
	assert_equal(track.call("get_gesture_origin_observation"), {}, "Finalize discards transient origin")


func _test_endpoint_reshape_editable_span_has_deterministic_targets() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 3), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var curve_cells: Array[Vector2i] = [
		Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3),
		Vector2i(2, 2), Vector2i(2, 1),
	]
	assert_equal(track.append_cells(curve_cells), 5, "Target fixture appends")
	var endpoint: Vector2i = track.get_endpoint_cell()
	print("Endpoint reshape: editable span has deterministic targets")
	assert_true(track.has_method("gesture_begin"), "Gesture begin target contract exists")
	if not track.has_method("gesture_begin"):
		return
	var result = track.call("gesture_begin", endpoint)
	assert_true(result is Dictionary, "Target begin returns an observation")
	if not result is Dictionary:
		return
	assert_true(result.has("editable_span"), "Begin exposes editable span")
	assert_true(result.has("targets"), "Begin exposes template targets")
	if not result.has("editable_span") or not result.has("targets"):
		return
	var span: Dictionary = result["editable_span"]
	var targets: Dictionary = result["targets"]
	assert_equal(span["entry_predecessor_cell"], Vector2i(-1, 3), "Entry predecessor is fixed")
	assert_equal(span["first_route_serial"], 1, "Editable span starts at curve serial")
	assert_equal(span["last_route_serial"], 5, "Editable span ends at curve serial")
	assert_equal(targets["straight"], Vector2i(4, 3), "Straight target is deterministic")
	assert_equal(targets["left"], Vector2i(2, 5), "Left target is deterministic")
	assert_equal(targets["right"], Vector2i(2, 1), "Right target is deterministic")
	var detached_targets: Dictionary = result["targets"]
	detached_targets["straight"] = Vector2i(99, 99)
	var second = track.call("get_gesture_target_endpoints")
	assert_equal(second["straight"], Vector2i(4, 3), "Target observations are detached")
	if track.has_method("gesture_finalize"):
		track.call("gesture_finalize")


func _test_endpoint_reshape_active_gesture_defers_construction_and_recovery() -> void:
	var track = _reflow_runtime()
	var deferral_cells: Array[Vector2i] = _reflow_curve_cells()
	deferral_cells.append(Vector2i(2, 3))
	assert_equal(track.append_cells(deferral_cells), 6, "Deferral fixture appends")
	track.set_contact_anchors([
		RouteContactAnchorScript.new(&"gesture_origin", Vector2i(0, 0)),
	])
	assert_equal(track.advance_construction(2.5), 2.5, "Deferral fixture leaves unfinished construction")
	assert_equal(track.recover_behind(1.0), 1, "Deferral fixture records a recovered prefix")
	var endpoint: Vector2i = track.get_endpoint_cell()
	var records_before := _record_values(track.get_cell_records())
	var pieces_before := _piece_values(track.get_geometry_pieces())
	var inventory_before: int = track.get_available_track_cells()
	var recovery_before := _recovery_observation_values(track)
	print("Endpoint reshape: active gesture defers construction and recovery")
	assert_true(track.has_method("gesture_begin"), "Gesture begin deferral contract exists")
	if not track.has_method("gesture_begin"):
		return
	var began = track.call("gesture_begin", endpoint)
	assert_true(began is Dictionary, "Deferral fixture starts a gesture")
	if not began is Dictionary:
		return
	for tick in range(3):
		assert_equal(track.advance_construction(0.75), 0.0, "Construction is deferred on tick %d" % tick)
		assert_equal(track.recover_behind(5.0), 0, "Recovery is deferred on tick %d" % tick)
		assert_equal(_record_values(track.get_cell_records()), records_before, "Active gesture preserves route and build state on tick %d" % tick)
		assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Active gesture preserves geometry on tick %d" % tick)
		assert_equal(track.get_available_track_cells(), inventory_before, "Active gesture preserves inventory on tick %d" % tick)
		assert_equal(_recovery_observation_values(track), recovery_before, "Active gesture preserves recovery on tick %d" % tick)
	assert_true(track.has_method("gesture_finalize"), "Gesture finalize deferral contract exists")
	if track.has_method("gesture_finalize"):
		track.call("gesture_finalize")


func _test_endpoint_reshape_right_left_straight_back_preserves_fixed_prefix() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var origin_cells: Array[Vector2i] = [
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0),
	]
	assert_equal(track.append_cells(origin_cells), 6, "Reshape sequence fixture appends")
	assert_equal(track.advance_construction(6.0), 6.0, "Reshape sequence fixture builds")
	var origin_records := _record_values(track.get_cell_records())
	var origin_prefix := origin_records[0]
	var origin_prefix_piece = _piece_containing(track.get_geometry_pieces(), 1)
	assert_not_null(origin_prefix_piece, "Reshape sequence has a fixed prefix owner")
	var origin_prefix_piece_values := {}
	if origin_prefix_piece != null:
		origin_prefix_piece_values = _piece_values([origin_prefix_piece])[0]
	var origin_inventory: int = track.get_available_track_cells()
	print("Endpoint reshape: right left straight back preserves fixed prefix")
	assert_true(track.has_method("gesture_update"), "Gesture update contract exists")
	if not track.has_method("gesture_update"):
		return
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Reshape sequence begins from the endpoint")
	if not began is Dictionary:
		return
	var targets: Dictionary = began["targets"]
	var left_cells: Array[Vector2i] = [targets["left"]]
	var straight_cells: Array[Vector2i] = [targets["straight"]]
	var right_cells: Array[Vector2i] = [targets["right"]]
	for selection in [left_cells, straight_cells, right_cells]:
		assert_true(track.call("gesture_update", selection), "Template target publishes a candidate")
		var records := _record_values(track.get_cell_records())
		assert_equal(records[0], origin_prefix, "Fixed prefix record survives template replacement")
		assert_equal(track.get_available_track_cells(), origin_inventory, "Template replacement preserves inventory")
		var prefix_piece = _piece_containing(track.get_geometry_pieces(), 1)
		assert_not_null(prefix_piece, "Fixed prefix owner survives template replacement")
		if prefix_piece != null:
			assert_equal(_piece_values([prefix_piece])[0], origin_prefix_piece_values, "Fixed prefix geometry survives template replacement")
	var final_records := _record_values(track.get_cell_records())
	assert_equal(final_records, origin_records, "Returning to the right target rebuilds the origin route")
	track.call("gesture_finalize")


func _test_endpoint_reshape_one_gesture_extends_after_selected_target() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0),
	]), 6, "Extension fixture appends")
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Extension fixture begins a gesture")
	if not began is Dictionary:
		return
	var targets: Dictionary = began["targets"]
	var target_only: Array[Vector2i] = [targets["left"]]
	var invalid_suffix: Array[Vector2i] = [Vector2i(6, 4)]
	var first_suffix_frame: Array[Vector2i] = [Vector2i(4, 4)]
	var second_suffix_frame: Array[Vector2i] = [Vector2i(5, 4)]
	print("Endpoint reshape: one gesture extends after selected target")
	assert_true(track.has_method("gesture_update"), "Gesture update extension contract exists")
	if not track.has_method("gesture_update"):
		return
	assert_true(track.call("gesture_update", target_only), "Target publishes in the first update frame")
	assert_equal(track.get_cell_records().size(), 6, "Target frame publishes the replacement span")
	var target_frame_records := _record_values(track.get_cell_records())
	var target_frame_pieces := _piece_values(track.get_geometry_pieces())
	var target_frame_inventory: int = track.get_available_track_cells()
	assert_false(track.call("gesture_update", invalid_suffix), "Invalid later suffix frame is rejected")
	assert_equal(_record_values(track.get_cell_records()), target_frame_records, "Invalid later frame preserves last-valid records")
	assert_equal(_piece_values(track.get_geometry_pieces()), target_frame_pieces, "Invalid later frame preserves last-valid pieces")
	assert_equal(track.get_available_track_cells(), target_frame_inventory, "Invalid later frame preserves last-valid inventory")
	assert_true(track.call("gesture_update", first_suffix_frame), "First suffix frame uses the persisted target")
	assert_true(track.call("gesture_update", second_suffix_frame), "Second suffix frame uses accumulated input facts")
	var records = track.get_cell_records()
	assert_equal(records.size(), 8, "One gesture appends two post-target records")
	if records.size() < 8:
		return
	assert_equal(records[5].cell, targets["left"], "Selected template endpoint is retained")
	assert_equal(records[6].cell, Vector2i(4, 4), "First post-target cell is appended")
	assert_equal(records[7].cell, Vector2i(5, 4), "Second post-target cell is appended")
	assert_equal(records[6].route_serial, 7, "First suffix receives a fresh serial")
	assert_equal(records[7].route_serial, 8, "Second suffix receives a fresh serial")
	assert_equal(track.get_endpoint_cell(), Vector2i(5, 4), "One gesture reaches the suffix endpoint")
	assert_equal(track.get_available_track_cells(), 10, "Suffix charges one inventory cell per record")
	track.call("gesture_finalize")


func _test_endpoint_reshape_consecutive_gesture_retains_current_template() -> void:
	var straight_track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 12, Vector2.ZERO, Vector2i(12, 8), 40.0
	)
	var straight_cells: Array[Vector2i] = [
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
	]
	assert_true(
		straight_track.gesture_begin(Vector2i(-1, 2)) is Dictionary,
		"Consecutive straight fixture begins its first gesture"
	)
	assert_true(
		straight_track.gesture_update(straight_cells),
		"Consecutive straight fixture publishes three records"
	)
	assert_true(
		straight_track.gesture_finalize(),
		"Consecutive straight fixture finalizes its first gesture"
	)
	assert_equal(straight_track.get_cell_records().size(), 3, "Consecutive straight fixture keeps three records")
	assert_false(straight_track.get_geometry_pieces()[0].locked, "Consecutive straight endpoint remains unlocked")
	var straight_endpoint := straight_track.get_endpoint_cell()
	var straight_available := straight_track.get_available_track_cells()
	assert_true(
		straight_track.gesture_begin(straight_endpoint) is Dictionary,
		"Consecutive straight fixture begins its fresh gesture"
	)
	assert_true(
		straight_track.gesture_update([Vector2i(3, 2)]),
		"Fresh straight gesture immediately extends beyond its current template"
	)
	var straight_records = straight_track.get_cell_records()
	assert_equal(straight_records.size(), 4, "Fresh straight gesture publishes one new record")
	if straight_records.size() == 4:
		assert_equal(straight_records[-1].cell, Vector2i(3, 2), "Fresh straight gesture advances the endpoint")
	assert_equal(
		straight_track.get_available_track_cells(), straight_available - 1,
		"Fresh straight gesture charges exactly one inventory cell"
	)
	assert_true(straight_track._sequence.is_conservation_valid(), "Fresh straight gesture preserves conservation")
	assert_true(straight_track.gesture_finalize(), "Fresh straight gesture finalizes successfully")

	var curve_track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 12, Vector2.ZERO, Vector2i(12, 10), 40.0
	)
	var curve_cells: Array[Vector2i] = [
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(2, 3), Vector2i(2, 4),
	]
	assert_true(
		curve_track.gesture_begin(Vector2i(-1, 2)) is Dictionary,
		"Consecutive curve fixture begins its first gesture"
	)
	assert_true(curve_track.gesture_update(curve_cells), "Consecutive curve fixture publishes five records")
	assert_true(curve_track.gesture_finalize(), "Consecutive curve fixture finalizes its first gesture")
	assert_equal(curve_track.get_cell_records().size(), 5, "Consecutive curve fixture keeps five records")
	assert_equal(
		curve_track.get_geometry_pieces()[0].kind,
		TrackGeometryPieceScript.Kind.CURVE_3X3,
		"Consecutive curve fixture resolves a complete curve"
	)
	assert_false(curve_track.get_geometry_pieces()[0].locked, "Consecutive curve endpoint remains unlocked")
	var curve_endpoint := curve_track.get_endpoint_cell()
	var curve_available := curve_track.get_available_track_cells()
	assert_true(
		curve_track.gesture_begin(curve_endpoint) is Dictionary,
		"Consecutive curve fixture begins its fresh gesture"
	)
	assert_true(
		curve_track.gesture_update([Vector2i(2, 5)]),
		"Fresh curve gesture immediately extends beyond its current template"
	)
	var curve_records = curve_track.get_cell_records()
	assert_equal(curve_records.size(), 6, "Fresh curve gesture publishes one new record")
	if curve_records.size() == 6:
		assert_equal(curve_records[-1].cell, Vector2i(2, 5), "Fresh curve gesture advances the endpoint")
	assert_equal(
		curve_track.get_available_track_cells(), curve_available - 1,
		"Fresh curve gesture charges exactly one inventory cell"
	)
	assert_true(curve_track._sequence.is_conservation_valid(), "Fresh curve gesture preserves conservation")
	assert_true(curve_track.gesture_finalize(), "Fresh curve gesture finalizes successfully")


func _test_endpoint_reshape_control_cells_are_omitted() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0),
	]), 6, "Control-cell fixture appends")
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Control-cell fixture begins a gesture")
	if not began is Dictionary:
		return
	var targets: Dictionary = began["targets"]
	var control_only: Array[Vector2i] = [
		Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 2),
		Vector2i(3, 2), Vector2i(3, 3),
	]
	var target_only: Array[Vector2i] = [targets["left"]]
	var records_before := _record_values(track.get_cell_records())
	var pieces_before := _piece_values(track.get_geometry_pieces())
	var inventory_before: int = track.get_available_track_cells()
	var ledger_before := _piece_values(track._locked_ledger)
	var observations_before := track.get_contact_observations().duplicate(true)
	print("Endpoint reshape: control cells are omitted")
	assert_true(track.has_method("gesture_update"), "Gesture update control-cell contract exists")
	if not track.has_method("gesture_update"):
		return
	assert_false(track.call("gesture_update", control_only), "Control-only motion publishes nothing before a target")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Control-only motion preserves last-valid records")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Control-only motion preserves last-valid pieces")
	assert_equal(track.get_available_track_cells(), inventory_before, "Control-only motion preserves last-valid inventory")
	assert_equal(_piece_values(track._locked_ledger), ledger_before, "Control-only motion preserves last-valid ledger")
	assert_equal(track.get_contact_observations(), observations_before, "Control-only motion preserves last-valid observations")
	assert_true(track.call("gesture_update", target_only), "Selected target publishes after control motion")
	var records = track.get_cell_records()
	assert_equal(records.size(), 6, "Control motion does not append extra records")
	var record_cells: Array[Vector2i] = []
	for record in records:
		record_cells.append(record.cell)
	for control in [Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 2)]:
		assert_false(record_cells.has(control), "Control cell is not a route record")
	track.call("gesture_finalize")


func _test_endpoint_reshape_target_reentry_rebuilds_from_origin() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0),
	]), 6, "Re-entry fixture appends")
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Re-entry fixture begins a gesture")
	if not began is Dictionary:
		return
	var targets: Dictionary = began["targets"]
	var left_with_suffix: Array[Vector2i] = [targets["left"], Vector2i(4, 4)]
	var straight_only: Array[Vector2i] = [targets["straight"]]
	print("Endpoint reshape: target re-entry rebuilds from origin")
	assert_true(track.has_method("gesture_update"), "Gesture update re-entry contract exists")
	if not track.has_method("gesture_update"):
		return
	assert_true(track.call("gesture_update", left_with_suffix), "Initial target and suffix publish")
	assert_equal(track.get_cell_records().size(), 7, "Initial target retains its suffix")
	assert_true(track.call("gesture_update", straight_only), "Re-entered target publishes")
	var records = track.get_cell_records()
	assert_equal(records.size(), 6, "Re-entry discards the prior candidate suffix")
	if records.size() < 6:
		return
	var expected_cells: Array[Vector2i] = [
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2),
	]
	for index in range(expected_cells.size()):
		assert_equal(records[index].cell, expected_cells[index], "Re-entry rebuilds route from the origin")
	assert_false(records.any(func(record): return record.cell == Vector2i(4, 4)), "Re-entry does not compose suffix")
	assert_equal(track.get_available_track_cells(), 12, "Re-entry restores origin inventory before replacement")
	var reentered_with_suffix: Array[Vector2i] = [targets["straight"], Vector2i(6, 2)]
	assert_true(track.call("gesture_update", reentered_with_suffix), "Re-entry can extend the new candidate")
	var reentered_records = track.get_cell_records()
	assert_equal(reentered_records.size(), 7, "Re-entry keeps the new suffix")
	if reentered_records.size() == 7:
		assert_equal(reentered_records[-1].route_serial, 8, "Re-entry never reuses a consumed suffix serial")
		assert_equal(reentered_records[-1].route_distance_start_cells, 6.0, "Re-entry preserves monotonic suffix distance")
	assert_true(track.call("gesture_finalize"), "Re-entry finalizes the serial-gap candidate")
	var reshaped_began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(reshaped_began is Dictionary, "Serial-gap fixture begins a new gesture")
	if not reshaped_began is Dictionary:
		return
	var reshaped_targets: Dictionary = reshaped_began["targets"]
	var reshaped_target: Array[Vector2i] = [reshaped_targets["left"]]
	assert_true(track.call("gesture_update", reshaped_target), "New gesture reshapes the serial-gap span")
	var reshaped_records = track.get_cell_records()
	assert_equal(reshaped_records.size(), 7, "Serial-gap reshape preserves active record count")
	if reshaped_records.size() == 7:
		assert_equal(reshaped_records[4].route_serial, 5, "Serial-gap reshape preserves the first span serial")
		assert_equal(reshaped_records[5].route_serial, 6, "Serial-gap reshape preserves the second span serial")
		assert_equal(reshaped_records[6].route_serial, 8, "Serial-gap reshape preserves the later span serial")
	assert_equal(track._sequence._active_cells.size(), reshaped_records.size(), "Serial-gap reshape preserves active uniqueness")
	track.call("gesture_finalize")


func _test_endpoint_reshape_invalid_bounds_preserve_last_valid() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 18, Vector2.ZERO, Vector2i(6, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0),
	]), 6, "Bounds fixture appends")
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Bounds fixture begins a gesture")
	if not began is Dictionary:
		return
	var targets: Dictionary = began["targets"]
	var valid_cells: Array[Vector2i] = [targets["left"], Vector2i(4, 4)]
	assert_true(track.call("gesture_update", valid_cells), "Bounds fixture publishes a valid candidate")
	var records_before := _record_values(track.get_cell_records())
	var pieces_before := _piece_values(track.get_geometry_pieces())
	var inventory_before: int = track.get_available_track_cells()
	var ledger_before := _piece_values(track._locked_ledger)
	var contacts_before := track.get_contact_observations().duplicate(true)
	var origin_before: Dictionary = track.call("get_gesture_origin_observation")
	var origin_records_before := _record_values(origin_before["route_records"])
	var origin_pieces_before := _piece_values(origin_before["pieces"])
	var invalid_cells: Array[Vector2i] = [
		targets["straight"], Vector2i(6, 2),
	]
	print("Endpoint reshape: invalid bounds preserve last valid")
	assert_true(track.has_method("gesture_update"), "Gesture update bounds contract exists")
	if not track.has_method("gesture_update"):
		return
	assert_false(track.call("gesture_update", invalid_cells), "Out-of-bounds candidate is rejected")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Bounds rejection preserves last-valid records")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Bounds rejection preserves last-valid pieces")
	assert_equal(track.get_available_track_cells(), inventory_before, "Bounds rejection preserves last-valid inventory")
	assert_equal(_piece_values(track._locked_ledger), ledger_before, "Bounds rejection preserves last-valid ledger")
	assert_equal(track.get_contact_observations(), contacts_before, "Bounds rejection preserves last-valid observations")
	var origin_after: Dictionary = track.call("get_gesture_origin_observation")
	assert_equal(_record_values(origin_after["route_records"]), origin_records_before, "Bounds rejection preserves origin records")
	assert_equal(_piece_values(origin_after["pieces"]), origin_pieces_before, "Bounds rejection preserves origin pieces")
	assert_equal(origin_after["inventory"], origin_before["inventory"], "Bounds rejection preserves origin inventory")
	assert_equal(origin_after["contact_observations"], origin_before["contact_observations"], "Bounds rejection preserves origin observations")
	track.call("gesture_finalize")


func _test_endpoint_reshape_invalid_overlap_preserve_last_valid() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0),
	]), 6, "Overlap fixture appends")
	assert_equal(track.get_cell_records().size(), 6, "Overlap fixture appends six route records")
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Overlap fixture begins a gesture")
	if not began is Dictionary:
		return
	var valid_cells: Array[Vector2i] = [began["targets"]["left"], Vector2i(4, 4)]
	assert_true(track.call("gesture_update", valid_cells), "Overlap fixture publishes a valid candidate")
	var records_before := _record_values(track.get_cell_records())
	var pieces_before := _piece_values(track.get_geometry_pieces())
	var inventory_before: int = track.get_available_track_cells()
	var ledger_before := _piece_values(track._locked_ledger)
	var contacts_before := track.get_contact_observations().duplicate(true)
	var origin_before: Dictionary = track.call("get_gesture_origin_observation")
	var origin_records_before := _record_values(origin_before["route_records"])
	var origin_pieces_before := _piece_values(origin_before["pieces"])
	assert_true(track._gesture_origin_locked_ledger.size() > 0, "Overlap fixture carries a real locked footprint")
	var invalid_cells: Array[Vector2i] = [Vector2i(4, 5), Vector2i(5, 5), Vector2i(5, 4)]
	print("Endpoint reshape: invalid overlap preserve last valid")
	assert_true(track.has_method("gesture_update"), "Gesture update overlap contract exists")
	if not track.has_method("gesture_update"):
		return
	var candidate_sequence = track._gesture_origin_sequence.duplicate_sequence()
	var candidate_templates: Array = track.call("_template_cells", track._gesture_editable_span)
	var candidate_template_cells: Array[Vector2i] = []
	for cell in candidate_templates[1]:
		candidate_template_cells.append(cell)
	assert_true(
		candidate_sequence.replace_span_in_place(
			track._gesture_editable_span["first_route_serial"],
			track._gesture_editable_span["last_route_serial"],
			candidate_template_cells
		),
		"Overlap fixture rebuilds the selected template"
	)
	for cell in [Vector2i(4, 4), Vector2i(4, 5), Vector2i(5, 5), Vector2i(5, 4)]:
		assert_not_null(candidate_sequence.try_append_candidate(cell), "Overlap fixture stages each suffix cell")
	var overlap_resolution = track._resolver.resolve(
		track._departure_cell,
		candidate_sequence.get_records(),
		track._gesture_origin_locked_ledger,
		track._gesture_origin_anchors,
		track._grid_origin_units,
		track._grid_size,
		track._cell_size_units
	)
	assert_false(overlap_resolution.is_valid, "Production resolver rejects the overlapping footprint")
	assert_equal(overlap_resolution.reason, &"final_overlap", "Production resolver reports final overlap")
	assert_false(track.call("gesture_update", invalid_cells), "Overlapping candidate is rejected")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Overlap rejection preserves last-valid records")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Overlap rejection preserves last-valid pieces")
	assert_equal(track.get_available_track_cells(), inventory_before, "Overlap rejection preserves last-valid inventory")
	assert_equal(_piece_values(track._locked_ledger), ledger_before, "Overlap rejection preserves last-valid ledger")
	assert_equal(track.get_contact_observations(), contacts_before, "Overlap rejection preserves last-valid observations")
	var origin_after: Dictionary = track.call("get_gesture_origin_observation")
	assert_equal(_record_values(origin_after["route_records"]), origin_records_before, "Overlap rejection preserves origin records")
	assert_equal(_piece_values(origin_after["pieces"]), origin_pieces_before, "Overlap rejection preserves origin pieces")
	track.call("gesture_finalize")


func _test_endpoint_reshape_anchor_compatible_downgrade_preserves_observations() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0),
	]), 6, "Anchor fixture appends")
	track.set_contact_anchors([
		RouteContactAnchorScript.new(&"reshape_anchor", Vector2i(2, 4)),
	])
	var origin_records := _record_values(track.get_cell_records())
	var origin_pieces := _piece_values(track.get_geometry_pieces())
	var origin_inventory: int = track.get_available_track_cells()
	var origin_ledger := _piece_values(track._locked_ledger)
	var origin_recovery := _recovery_observation_values(track)
	var origin_contacts := track.get_contact_observations().duplicate(true)
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Anchor fixture begins a gesture")
	if not began is Dictionary:
		return
	var targets: Dictionary = began["targets"]
	var origin_observation: Dictionary = track.call("get_gesture_origin_observation")
	print("Endpoint reshape: anchor-compatible downgrade preserves observations")
	assert_true(track.has_method("gesture_update"), "Gesture update anchor contract exists")
	if not track.has_method("gesture_update"):
		return
	var candidate_sequence = track._gesture_origin_sequence.duplicate_sequence()
	var candidate_templates: Array = track.call("_template_cells", track._gesture_editable_span)
	var candidate_template_cells: Array[Vector2i] = []
	for cell in candidate_templates[1]:
		candidate_template_cells.append(cell)
	assert_true(
		candidate_sequence.replace_span_in_place(
			track._gesture_editable_span["first_route_serial"],
			track._gesture_editable_span["last_route_serial"],
			candidate_template_cells
		),
		"Anchor fixture rebuilds the selected template"
	)
	var candidate_route_cells: Array[Vector2i] = []
	for record in candidate_sequence.get_records():
		candidate_route_cells.append(record.cell)
	assert_false(
		candidate_route_cells.has(track._gesture_origin_anchors[0].cell),
		"Anchor fixture keeps the authoritative anchor off the route centerline"
	)
	var anchor_free_resolution = track._resolver.resolve(
		track._departure_cell,
		candidate_sequence.get_records(),
		track._gesture_origin_locked_ledger,
		[],
		track._grid_origin_units,
		track._grid_size,
		track._cell_size_units
	)
	assert_true(anchor_free_resolution.is_valid, "Without an authoritative anchor the larger curve is accepted")
	var anchor_free_curve = _piece_containing(anchor_free_resolution.pieces, 3)
	assert_not_null(anchor_free_curve, "Anchor-free resolution publishes the larger curve")
	if anchor_free_curve != null:
		assert_equal(anchor_free_curve.kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Anchor-free resolution keeps the larger curve template")
		assert_true(anchor_free_curve.footprint_cells.has(Vector2i(2, 4)), "Authoritative anchor lies in the larger curve footprint")
	var anchor_resolution = track._resolver.resolve(
		track._departure_cell,
		candidate_sequence.get_records(),
		track._gesture_origin_locked_ledger,
		track._gesture_origin_anchors,
		track._grid_origin_units,
		track._grid_size,
		track._cell_size_units
	)
	assert_true(anchor_resolution.is_valid, "Authoritative anchor accepts a compatible downgraded curve")
	var anchored_curve = _piece_containing(anchor_resolution.pieces, 3)
	assert_not_null(anchored_curve, "Anchored resolution publishes the smaller curve")
	if anchored_curve != null:
		assert_equal(anchored_curve.kind, TrackGeometryPieceScript.Kind.CURVE_2X2, "Authoritative anchor deterministically downgrades the curve")
		assert_false(anchored_curve.footprint_cells.has(Vector2i(2, 4)), "Downgraded footprint no longer overlaps the anchor")
	var anchored_target: Array[Vector2i] = [targets["left"]]
	assert_true(track.call("gesture_update", anchored_target), "Anchor-compatible target publishes through the runtime resolver")
	var current_records := track.get_cell_records()
	assert_equal(current_records.size(), origin_records.size(), "Downgrade keeps the route record count")
	for index in range(candidate_route_cells.size()):
		assert_equal(current_records[index].cell, candidate_route_cells[index], "Downgrade publishes the selected route cell %d" % index)
	for index in range(current_records.size()):
		assert_equal(current_records[index].route_serial, origin_records[index]["serial"], "Downgrade preserves route serial %d" % index)
		assert_equal(current_records[index].route_distance_start_cells, origin_records[index]["distance"], "Downgrade preserves route distance %d" % index)
		assert_equal(current_records[index].state, origin_records[index]["state"], "Downgrade preserves construction state %d" % index)
		assert_equal(current_records[index].build_progress, origin_records[index]["progress"], "Downgrade preserves construction progress %d" % index)
	assert_equal(track.get_available_track_cells(), origin_inventory, "Downgrade preserves inventory")
	assert_equal(_piece_values(track._locked_ledger), origin_ledger, "Downgrade preserves the locked ledger")
	assert_equal(track._recovered_cells_by_piece, origin_recovery["recovered_cells_by_piece"], "Downgrade preserves recovery cells")
	assert_equal(track._recovered_end_distance_cells, origin_recovery["recovered_end_distance_cells"], "Downgrade preserves recovery distance")
	assert_equal(track.get_contact_observations(), origin_contacts, "Downgrade preserves authoritative anchor observations")
	var runtime_curve = _piece_containing(track.get_geometry_pieces(), 3)
	assert_not_null(runtime_curve, "Runtime publishes the downgraded curve")
	if runtime_curve != null and anchored_curve != null:
		assert_equal(runtime_curve.kind, anchored_curve.kind, "Runtime uses the resolver's smaller curve")
	var origin_after: Dictionary = track.call("get_gesture_origin_observation")
	assert_equal(_record_values(origin_after["route_records"]), _record_values(origin_observation["route_records"]), "Downgrade preserves detached origin route observations")
	assert_equal(_piece_values(origin_after["pieces"]), _piece_values(origin_observation["pieces"]), "Downgrade preserves detached origin geometry observations")
	assert_equal(_piece_values(origin_after["locked_ledger"]), _piece_values(origin_observation["locked_ledger"]), "Downgrade preserves detached origin ledger observations")
	assert_equal(origin_after["anchors"][0].anchor_id, origin_observation["anchors"][0].anchor_id, "Downgrade preserves detached authoritative anchor identity")
	assert_equal(origin_after["anchors"][0].cell, origin_observation["anchors"][0].cell, "Downgrade preserves detached authoritative anchor cell")
	assert_equal(origin_after["recovery"], origin_observation["recovery"], "Downgrade preserves detached origin recovery observations")
	assert_equal(_record_values(origin_after["construction"]), _record_values(origin_observation["construction"]), "Downgrade preserves detached origin construction observations")
	assert_equal(origin_after["inventory"], origin_observation["inventory"], "Downgrade preserves detached origin inventory observation")
	assert_equal(origin_after["contact_observations"], origin_observation["contact_observations"], "Downgrade preserves detached origin contact observations")
	_assert_record_piece_sync(track)
	_assert_conservation(track, "Anchor-compatible downgrade preserves transaction conservation")
	track.call("gesture_finalize")


func _test_endpoint_reshape_duplicate_preserves_last_valid() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0),
	]), 6, "Duplicate fixture appends")
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Duplicate fixture begins a gesture")
	if not began is Dictionary:
		return
	var targets: Dictionary = began["targets"]
	var valid_cells: Array[Vector2i] = [targets["left"], Vector2i(4, 4)]
	assert_true(track.call("gesture_update", valid_cells), "Duplicate fixture publishes a last-valid candidate")
	var records_before := _record_values(track.get_cell_records())
	var pieces_before := _piece_values(track.get_geometry_pieces())
	var inventory_before: int = track.get_available_track_cells()
	var ledger_before := _piece_values(track._locked_ledger)
	var observations_before := track.get_contact_observations().duplicate(true)
	var origin_before: Dictionary = track.call("get_gesture_origin_observation")
	var origin_values_before := {
		"records": _record_values(origin_before["route_records"]),
		"pieces": _piece_values(origin_before["pieces"]),
		"ledger": _piece_values(origin_before["locked_ledger"]),
		"inventory": origin_before["inventory"],
		"observations": origin_before["contact_observations"].duplicate(true),
	}
	var invalid_cells: Array[Vector2i] = [
		targets["left"], Vector2i(4, 4), Vector2i(4, 4),
	]
	print("Endpoint reshape: duplicate preserves last valid")
	assert_true(track.has_method("gesture_update"), "Gesture update duplicate contract exists")
	if not track.has_method("gesture_update"):
		return
	assert_false(track.call("gesture_update", invalid_cells), "Duplicate candidate is rejected")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Duplicate rejection preserves last-valid records")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Duplicate rejection preserves last-valid pieces")
	assert_equal(track.get_available_track_cells(), inventory_before, "Duplicate rejection preserves last-valid inventory")
	assert_equal(_piece_values(track._locked_ledger), ledger_before, "Duplicate rejection preserves last-valid ledger")
	assert_equal(track.get_contact_observations(), observations_before, "Duplicate rejection preserves last-valid observations")
	var origin_after: Dictionary = track.call("get_gesture_origin_observation")
	assert_equal(_record_values(origin_after["route_records"]), origin_values_before["records"], "Duplicate rejection preserves origin records")
	assert_equal(_piece_values(origin_after["pieces"]), origin_values_before["pieces"], "Duplicate rejection preserves origin pieces")
	assert_equal(_piece_values(origin_after["locked_ledger"]), origin_values_before["ledger"], "Duplicate rejection preserves origin ledger")
	assert_equal(origin_after["inventory"], origin_values_before["inventory"], "Duplicate rejection preserves origin inventory")
	assert_equal(origin_after["contact_observations"], origin_values_before["observations"], "Duplicate rejection preserves origin observations")
	track.call("gesture_finalize")


func _test_endpoint_reshape_insufficient_inventory_preserves_last_valid() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 6, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0),
	]), 6, "Insufficient-inventory fixture appends")
	assert_equal(track.get_available_track_cells(), 0, "Insufficient-inventory fixture is exhausted")
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Insufficient-inventory fixture begins a gesture")
	if not began is Dictionary:
		return
	var targets: Dictionary = began["targets"]
	var records_before := _record_values(track.get_cell_records())
	var pieces_before := _piece_values(track.get_geometry_pieces())
	var inventory_before: int = track.get_available_track_cells()
	var ledger_before := _piece_values(track._locked_ledger)
	var observations_before := track.get_contact_observations().duplicate(true)
	var origin_before: Dictionary = track.call("get_gesture_origin_observation")
	var origin_values_before := {
		"records": _record_values(origin_before["route_records"]),
		"pieces": _piece_values(origin_before["pieces"]),
		"ledger": _piece_values(origin_before["locked_ledger"]),
		"inventory": origin_before["inventory"],
		"observations": origin_before["contact_observations"].duplicate(true),
	}
	var invalid_cells: Array[Vector2i] = [targets["left"], Vector2i(4, 4)]
	print("Endpoint reshape: insufficient inventory preserves last valid")
	assert_true(track.has_method("gesture_update"), "Gesture update inventory contract exists")
	if not track.has_method("gesture_update"):
		return
	assert_false(track.call("gesture_update", invalid_cells), "Insufficient-inventory candidate is rejected")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Inventory rejection preserves last-valid records")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Inventory rejection preserves last-valid pieces")
	assert_equal(track.get_available_track_cells(), inventory_before, "Inventory rejection preserves last-valid inventory")
	assert_equal(_piece_values(track._locked_ledger), ledger_before, "Inventory rejection preserves last-valid ledger")
	assert_equal(track.get_contact_observations(), observations_before, "Inventory rejection preserves last-valid observations")
	var origin_after: Dictionary = track.call("get_gesture_origin_observation")
	assert_equal(_record_values(origin_after["route_records"]), origin_values_before["records"], "Inventory rejection preserves origin records")
	assert_equal(_piece_values(origin_after["pieces"]), origin_values_before["pieces"], "Inventory rejection preserves origin pieces")
	assert_equal(_piece_values(origin_after["locked_ledger"]), origin_values_before["ledger"], "Inventory rejection preserves origin ledger")
	assert_equal(origin_after["inventory"], origin_values_before["inventory"], "Inventory rejection preserves origin inventory")
	assert_equal(origin_after["contact_observations"], origin_values_before["observations"], "Inventory rejection preserves origin observations")
	track.call("gesture_finalize")


func _test_endpoint_reshape_empty_departure_and_straight_accept_ordinary_extension() -> void:
	var empty_track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 5, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var empty_began = empty_track.call("gesture_begin", empty_track.get_endpoint_cell())
	assert_true(empty_began is Dictionary, "Empty-departure fixture begins a gesture")
	if not empty_began is Dictionary:
		return
	print("Endpoint reshape: empty departure and straight endpoints accept ordinary extension")
	assert_true(empty_track.has_method("gesture_update"), "Gesture update ordinary-extension contract exists")
	if not empty_track.has_method("gesture_update"):
		return
	var empty_first_frame: Array[Vector2i] = [Vector2i(0, 0)]
	var empty_second_frame: Array[Vector2i] = [Vector2i(1, 0)]
	assert_true(empty_track.call("gesture_update", empty_first_frame), "Empty departure accepts the first ordinary extension frame")
	assert_true(empty_track.call("gesture_update", empty_second_frame), "Empty departure accepts the second ordinary extension frame")
	var empty_records = empty_track.get_cell_records()
	assert_equal(empty_records.size(), 2, "Empty departure creates two fresh records")
	if empty_records.size() == 2:
		assert_equal(empty_records[0].cell, Vector2i(0, 0), "Empty departure keeps first appended cell")
		assert_equal(empty_records[1].cell, Vector2i(1, 0), "Empty departure keeps second appended cell")
		assert_equal(empty_records[0].route_serial, 1, "Empty departure starts fresh serials at one")
		assert_equal(empty_records[1].route_serial, 2, "Empty departure increments serials monotonically")
		assert_equal(empty_records[0].route_distance_start_cells, 0.0, "Empty departure starts nominal distance at zero")
		assert_equal(empty_records[1].route_distance_start_cells, 1.0, "Empty departure increments nominal distance")
	assert_equal(empty_track.get_available_track_cells(), 3, "Empty departure charges ordinary extension inventory")
	assert_true(empty_track._sequence.is_conservation_valid(), "Empty departure preserves conservation")
	empty_track.call("gesture_finalize")

	var straight_track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 6, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(straight_track.append_cells([
		Vector2i(0, 2), Vector2i(1, 2),
	]), 2, "Straight-endpoint fixture appends")
	var straight_began = straight_track.call("gesture_begin", straight_track.get_endpoint_cell())
	assert_true(straight_began is Dictionary, "Straight-endpoint fixture begins a gesture")
	if not straight_began is Dictionary:
		return
	var straight_first_frame: Array[Vector2i] = [Vector2i(2, 2)]
	var straight_second_frame: Array[Vector2i] = [Vector2i(3, 2)]
	assert_true(straight_track.call("gesture_update", straight_first_frame), "Straight endpoint accepts the first ordinary extension frame")
	assert_true(straight_track.call("gesture_update", straight_second_frame), "Straight endpoint accepts the second ordinary extension frame")
	var straight_records = straight_track.get_cell_records()
	assert_equal(straight_records.size(), 4, "Straight endpoint creates fresh extension records")
	if straight_records.size() == 4:
		assert_equal(straight_records[2].cell, Vector2i(2, 2), "Straight endpoint keeps the first appended cell")
		assert_equal(straight_records[2].route_serial, 3, "Straight endpoint receives the first monotonic serial")
		assert_equal(straight_records[2].route_distance_start_cells, 2.0, "Straight endpoint receives the first nominal distance")
		assert_equal(straight_records[3].cell, Vector2i(3, 2), "Straight endpoint keeps the second appended cell")
		assert_equal(straight_records[3].route_serial, 4, "Straight endpoint receives the second monotonic serial")
		assert_equal(straight_records[3].route_distance_start_cells, 3.0, "Straight endpoint receives the second nominal distance")
	assert_equal(straight_track.get_available_track_cells(), 2, "Straight endpoint charges ordinary extension inventory")
	assert_true(straight_track._sequence.is_conservation_valid(), "Straight endpoint preserves conservation")
	straight_track.call("gesture_finalize")


func _test_endpoint_reshape_locked_endpoint_accepts_only_extension() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 2), 6, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
	]), 3, "Locked-endpoint fixture appends")
	assert_true(track.prepare_for_train_sampling(0.0, 3.0), "Locked-endpoint fixture prepares through the endpoint")
	var locked_before := _piece_values(track.get_geometry_pieces())
	assert_true(locked_before.size() > 0, "Locked-endpoint fixture has locked geometry")
	for piece in track.get_geometry_pieces():
		assert_true(piece.locked, "Locked-endpoint fixture locks every existing piece")
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Locked endpoint begins an extension gesture")
	if not began is Dictionary:
		return
	print("Endpoint reshape: locked endpoint accepts only extension")
	assert_true(track.has_method("gesture_update"), "Gesture update locked-endpoint contract exists")
	if not track.has_method("gesture_update"):
		return
	var rejected_template_cells: Array[Vector2i] = [Vector2i(4, 2)]
	assert_false(track.call("gesture_update", rejected_template_cells), "Locked endpoint rejects template replacement")
	assert_equal(_piece_values(track.get_geometry_pieces()), locked_before, "Rejected replacement preserves locked geometry")
	var extension_cells: Array[Vector2i] = [Vector2i(3, 2)]
	assert_true(track.call("gesture_update", extension_cells), "Locked endpoint accepts a legal adjacent extension")
	var records = track.get_cell_records()
	assert_equal(records.size(), 4, "Locked endpoint adds one extension record")
	if records.size() == 4:
		assert_equal(records[-1].cell, Vector2i(3, 2), "Locked endpoint appends the adjacent cell")
		assert_false(records[-1].geometry_locked, "New extension remains outside locked geometry")
	var locked_after: Array = []
	for piece in track.get_geometry_pieces():
		if piece.locked:
			locked_after.append(piece)
	assert_equal(_piece_values(locked_after), locked_before, "Legal extension does not change locked geometry")
	assert_equal(track.get_available_track_cells(), 2, "Locked endpoint charges only the extension cell")
	assert_true(track._sequence.is_conservation_valid(), "Locked endpoint preserves conservation")
	track.call("gesture_finalize")


func _test_endpoint_reshape_gesture_rejects_illegal_starts() -> void:
	var nonendpoint_track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 5, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(nonendpoint_track.append_cells([Vector2i(0, 0)]), 1, "Nonendpoint fixture appends")
	var outside_track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 5, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var illegal_first_step_track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 5, Vector2.ZERO, Vector2i(1, 1), 40.0
	)
	assert_equal(illegal_first_step_track.append_cells([Vector2i(0, 0)]), 1, "Illegal-first-step fixture appends")
	var insufficient_inventory_track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 1, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(insufficient_inventory_track.append_cells([Vector2i(0, 0)]), 1, "Insufficient-inventory fixture appends")
	print("Endpoint reshape: gesture rejects illegal starts")
	assert_true(nonendpoint_track.has_method("gesture_begin"), "Gesture begin nonendpoint contract exists")
	assert_true(outside_track.has_method("gesture_begin"), "Gesture begin outside-grid contract exists")
	assert_true(illegal_first_step_track.has_method("gesture_begin"), "Gesture begin illegal-first-step contract exists")
	assert_true(insufficient_inventory_track.has_method("gesture_begin"), "Gesture begin inventory contract exists")
	if (
		not nonendpoint_track.has_method("gesture_begin")
		or not outside_track.has_method("gesture_begin")
		or not illegal_first_step_track.has_method("gesture_begin")
		or not insufficient_inventory_track.has_method("gesture_begin")
	):
		return
	assert_equal(nonendpoint_track.call("gesture_begin", Vector2i(0, 1)), {}, "Nonendpoint start is rejected")
	assert_equal(outside_track.call("gesture_begin", Vector2i(8, 0)), {}, "Outside-grid start is rejected")
	assert_equal(
		illegal_first_step_track.call("gesture_begin", illegal_first_step_track.get_endpoint_cell()),
		{},
		"Illegal first step start is rejected"
	)
	assert_equal(
		insufficient_inventory_track.call("gesture_begin", insufficient_inventory_track.get_endpoint_cell()),
		{},
		"Insufficient-inventory start is rejected"
	)


func _test_endpoint_reshape_finalize_applies_retirement() -> void:
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 12, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var initial_cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2),
	]
	assert_equal(track.append_cells(initial_cells), 6, "Finalize fixture appends")
	assert_equal(track.advance_construction(6.0), 6.0, "Finalize fixture builds complete pieces")
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Finalize fixture begins a gesture")
	if not began is Dictionary:
		return
	assert_true(track.has_method("gesture_update"), "Gesture update finalize fixture contract exists")
	if not track.has_method("gesture_update"):
		return
	var finalize_target_cells: Array[Vector2i] = [began["targets"]["left"]]
	assert_true(track.call("gesture_update", finalize_target_cells), "Finalize fixture publishes the selected template")
	var extension_cells: Array[Vector2i] = [Vector2i(3, 3)]
	assert_true(track.call("gesture_update", extension_cells), "Finalize fixture publishes a suffix candidate")
	assert_equal(track.get_cell_records().size(), 7, "Finalize fixture retains the complete suffix candidate")
	assert_equal(track._locked_ledger.size(), 1, "Finalize defers new retirement while the gesture is active")
	print("Endpoint reshape: finalize applies retirement")
	assert_true(track.has_method("gesture_finalize"), "Gesture finalize retirement contract exists")
	if not track.has_method("gesture_finalize"):
		return
	assert_true(track.call("gesture_finalize"), "Finalize retires stable complete pieces")
	assert_false(track.gesture_is_active(), "Finalize clears the transient gesture")
	assert_equal(track.call("get_gesture_origin_observation"), {}, "Finalize clears detached origin observation")
	var records = track.get_cell_records()
	assert_equal(records.size(), 7, "Finalize preserves the published route")
	if records.size() == 7:
		for index in range(records.size()):
			assert_equal(records[index].route_serial, index + 1, "Finalize preserves monotonic serial %d" % (index + 1))
			assert_equal(records[index].route_distance_start_cells, float(index), "Finalize preserves monotonic distance %d" % (index + 1))
			assert_equal(records[index].state, TrackCellRecordScript.State.BUILT if index < 6 else TrackCellRecordScript.State.RESERVED_GHOST, "Finalize preserves build identity %d" % (index + 1))
	var ledger = track._locked_ledger
	assert_equal(ledger.size(), 2, "Finalize adds one whole-piece ledger entry")
	if ledger.size() == 2:
		assert_equal(ledger[0].first_route_serial, 1, "Finalize keeps the leading one-record span")
		assert_equal(ledger[0].last_route_serial, 1, "Finalize does not split the leading span")
		assert_equal(ledger[0].exit_support_route_serial, 2, "Finalize retains the leading exit support")
		assert_equal(ledger[1].first_route_serial, 2, "Finalize starts the complete curve span")
		assert_equal(ledger[1].last_route_serial, 6, "Finalize retires the complete five-record curve")
		assert_equal(ledger[1].nominal_length_cells, 5, "Finalize keeps the curve nominal length")
		assert_equal(ledger[1].kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Finalize keeps the curve kind")
		assert_equal(ledger[1].exit_support_route_serial, 7, "Finalize records the suffix exit support")
	for piece in ledger:
		var span_length: int = piece.last_route_serial - piece.first_route_serial + 1
		assert_true([1, 3, 5].has(span_length), "Finalize retires only complete 1/3/5-record pieces")
		assert_equal(piece.nominal_length_cells, span_length, "Finalize ledger span is never split")
		assert_true(piece.locked, "Finalize ledger pieces are immutable")
	assert_equal(track.get_available_track_cells(), 5, "Finalize does not charge or refund inventory")
	assert_true(track._sequence.is_conservation_valid(), "Finalize preserves conservation")


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
	var began = track.gesture_begin(track.get_endpoint_cell())
	assert_true(began is Dictionary and not began.is_empty(), "Five straight replacement starts from the endpoint")
	if began is Dictionary and not began.is_empty():
		var replacement_cells: Array[Vector2i] = [began["targets"]["left"]]
		assert_true(track.gesture_update(replacement_cells), "Five straight replacement publishes a curve candidate")
	assert_true(track.gesture_finalize(), "Five straight replacement finalizes before sampling")
	assert_true(track.prepare_for_train_sampling(0.0, 1.0), "Five straight replacement samples the stable prefix")
	var stable_pieces = track.get_geometry_pieces()
	assert_true(stable_pieces[0].locked, "Five straight stable prefix keeps the first owner immutable")
	assert_true(stable_pieces[1].locked, "Five straight stable prefix keeps the second owner immutable")
	assert_false(stable_pieces[2].locked, "Five straight replacement keeps endpoint owner and supports mutable")
	var stable_records = track.get_cell_records()
	assert_false(stable_records[2].geometry_locked, "Five straight replacement keeps the first incoming support record mutable")
	assert_false(stable_records[3].geometry_locked, "Five straight replacement keeps the second incoming support record mutable")
	assert_false(stable_records[4].geometry_locked, "Five straight replacement keeps the endpoint record mutable")


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
	var cancellation_ledger_before = track._locked_ledger[0].duplicate_piece()
	var available_before_cancel: int = track.get_available_track_cells()
	assert_true(track.cancel_ghost_suffix(Vector2i(2, 4)), "Stable path cancels an eligible suffix")
	assert_equal(track.get_available_track_cells(), available_before_cancel + 1, "Suffix cancellation refunds one inventory cell")
	assert_equal(track.get_cell_records()[-1].route_serial, 6, "Successful cancellation preserves the support endpoint serial")
	var cancellation_ledger_after = track._locked_ledger[0]
	assert_equal(cancellation_ledger_after.group_id, cancellation_ledger_before.group_id, "Cancellation preserves retained ledger group identity")
	assert_equal(cancellation_ledger_after.locked, cancellation_ledger_before.locked, "Cancellation preserves retained ledger lock state")
	assert_equal(cancellation_ledger_after.first_route_serial, cancellation_ledger_before.first_route_serial, "Cancellation preserves retained ledger first serial")
	assert_equal(cancellation_ledger_after.last_route_serial, cancellation_ledger_before.last_route_serial, "Cancellation preserves retained ledger last serial")
	assert_equal(cancellation_ledger_after.exit_support_route_serial, cancellation_ledger_before.exit_support_route_serial, "Cancellation preserves retained ledger exit support")
	var anchor_ledger_before = cancellation_ledger_after.duplicate_piece()
	track.set_contact_anchors([
		RouteContactAnchorScript.new(&"stable_support", Vector2i(2, 3)),
	])
	var anchor_ledger_after = track._locked_ledger[0]
	assert_equal(anchor_ledger_after.group_id, anchor_ledger_before.group_id, "Anchor re-resolution preserves ledger group identity")
	assert_equal(anchor_ledger_after.locked, anchor_ledger_before.locked, "Anchor re-resolution preserves ledger lock state")
	assert_equal(anchor_ledger_after.first_route_serial, anchor_ledger_before.first_route_serial, "Anchor re-resolution preserves ledger first serial")
	assert_equal(anchor_ledger_after.last_route_serial, anchor_ledger_before.last_route_serial, "Anchor re-resolution preserves ledger last serial")
	assert_equal(anchor_ledger_after.exit_support_route_serial, anchor_ledger_before.exit_support_route_serial, "Anchor re-resolution preserves ledger exit support")
	assert_equal(track.get_geometry_pieces()[0].first_route_serial, 1, "Anchor re-resolution preserves ledger first serial")
	assert_equal(track.get_geometry_pieces()[0].last_route_serial, 5, "Anchor re-resolution preserves ledger last serial")
	assert_true(track.get_contact_observations()[0].contacted, "Anchor re-resolution publishes contact")
	var recovery_ledger_before = track._locked_ledger[0].duplicate_piece()
	assert_equal(track.advance_construction(6.0), 6.0, "Stable path builds before recovery")
	assert_equal(track.recover_behind(1.0), 1, "Stable path recovers one cell")
	assert_equal(track.get_available_track_cells(), track.get_total_track_cells() - 5, "Recovery refunds one complete active record")
	assert_equal(track._recovered_end_distance_cells, 1.0, "Recovery frontier advances by one nominal cell")
	assert_true(track._recovered_cells_by_piece.has("1:5"), "Recovery retains ledger piece facts")
	var recovery_ledger_after = track._locked_ledger[0]
	assert_equal(recovery_ledger_after.group_id, recovery_ledger_before.group_id, "Recovery preserves surviving ledger group identity")
	assert_equal(recovery_ledger_after.locked, recovery_ledger_before.locked, "Recovery preserves surviving ledger lock state")
	assert_equal(recovery_ledger_after.first_route_serial, recovery_ledger_before.first_route_serial, "Recovery preserves surviving ledger first serial")
	assert_equal(recovery_ledger_after.last_route_serial, recovery_ledger_before.last_route_serial, "Recovery preserves surviving ledger last serial")
	assert_equal(recovery_ledger_after.exit_support_route_serial, recovery_ledger_before.exit_support_route_serial, "Recovery preserves surviving ledger exit support")
	assert_equal(recovery_ledger_after.nominal_length_cells, recovery_ledger_before.nominal_length_cells, "Recovery preserves surviving ledger nominal length")
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
	var prepared_before = _piece_containing(prepare_track.get_geometry_pieces(), 1).duplicate_piece()
	var expected_prepare_support: int = prepare_track.get_cell_records()[1].route_serial
	var available_before_prepare: int = prepare_track.get_available_track_cells()
	assert_true(prepare_track.prepare_for_train_sampling(0.0, 0.0), "Prepare postcondition locks the sampled owner")
	var prepared_owner = _piece_containing(prepare_track.get_geometry_pieces(), 1)
	assert_not_null(prepared_owner, "Prepared owner remains concrete")
	if prepared_owner != null:
		assert_equal(prepared_owner.group_id, prepared_before.group_id, "Prepare preserves owner group identity")
		assert_true(prepared_owner.locked, "Prepare locks a complete piece")
		assert_equal(prepared_owner.first_route_serial, prepared_before.first_route_serial, "Prepare preserves owner first serial")
		assert_equal(prepared_owner.last_route_serial, prepared_before.last_route_serial, "Prepare preserves owner last serial")
		assert_equal(prepared_owner.nominal_length_cells, prepared_before.nominal_length_cells, "Prepare preserves owner nominal length")
		assert_equal(prepared_owner.exit_support_route_serial, expected_prepare_support, "Prepare preserves successor support metadata")
	assert_equal(prepare_track.get_available_track_cells(), available_before_prepare, "Prepare does not charge inventory")
	_assert_conservation(prepare_track, "Prepare preserves inventory conservation")


func _test_endpoint_reshape_abort_restores_exact_origin() -> void:
	var track = _reflow_runtime()
	assert_equal(track.append_cells(_reflow_curve_cells()), 5, "Abort fixture appends curve")
	assert_equal(track.append_cells([Vector2i(2, 3), Vector2i(2, 4)]), 2, "Abort fixture appends editable suffix")
	track.set_contact_anchors([
		RouteContactAnchorScript.new(&"abort_anchor", Vector2i(2, 3)),
	])
	assert_equal(track.advance_construction(7.0), 7.0, "Abort fixture builds route")
	assert_equal(track.recover_behind(1.0), 1, "Abort fixture records recovery state")
	var endpoint: Vector2i = track.get_endpoint_cell()
	var origin_records := _record_values(track.get_cell_records())
	var origin_pieces := _piece_values(track.get_geometry_pieces())
	var origin_ledger := _piece_values(track._locked_ledger)
	var origin_anchors := _anchor_values(track._anchors)
	var origin_recovery := _recovery_observation_values(track)
	var origin_contacts: Array = track.get_contact_observations().duplicate(true)
	var origin_inventory: int = track.get_available_track_cells()
	print("Endpoint reshape: abort restores exact origin")
	assert_true(track.has_method("gesture_begin"), "Abort fixture has gesture begin")
	if not track.has_method("gesture_begin"):
		return
	var origin = track.call("gesture_begin", endpoint)
	assert_true(origin is Dictionary, "Abort fixture captures origin")
	if not origin is Dictionary:
		return
	var abort_cells: Array[Vector2i] = [Vector2i(3, 4)]
	assert_true(track.call("gesture_update", abort_cells), "Abort fixture publishes changed candidate")
	assert_true(_record_values(track.get_cell_records()) != origin_records, "Abort fixture changes route before abort")
	assert_true(track.get_available_track_cells() != origin_inventory, "Abort fixture changes inventory before abort")
	var consumed_serials: Array[int] = []
	for record in track.get_cell_records():
		consumed_serials.append(record.route_serial)
	assert_true(consumed_serials.size() > 0, "Abort fixture records candidate serials")
	var candidate_construction_before := _record_values(track.get_cell_records())
	var candidate_ledger_before := _piece_values(track._locked_ledger)
	var candidate_recovery_cells_before: Dictionary = track._recovered_cells_by_piece.duplicate(true)
	var candidate_recovery_frontier_before: float = track._recovered_end_distance_cells
	var candidate_anchors_before := _anchor_values(track._anchors)
	var candidate_contacts_before: Array = track.get_contact_observations().duplicate(true)
	var detached_origin: Dictionary = track.call("get_gesture_origin_observation")
	assert_true(detached_origin is Dictionary and not detached_origin.is_empty(), "Abort fixture retains detached origin after publication")
	if not detached_origin is Dictionary or detached_origin.is_empty():
		return
	var detached_origin_values := _abort_origin_values(detached_origin)
	_assert_abort_origin_detached(track, detached_origin, detached_origin_values, "after publication")
	var perturbed_record = track._sequence._records[0]
	var perturbed_state: TrackCellRecordScript.State = TrackCellRecordScript.State.BUILDING
	if perturbed_record.state == perturbed_state:
		perturbed_state = TrackCellRecordScript.State.BUILT
	perturbed_record.state = perturbed_state
	var perturbed_progress := 0.25
	if is_equal_approx(perturbed_record.build_progress, perturbed_progress):
		perturbed_progress = 0.75
	perturbed_record.build_progress = perturbed_progress
	assert_true(
		_record_values(track.get_cell_records()) != candidate_construction_before,
		"Abort fixture perturbation changes construction and build progress"
	)
	_assert_abort_origin_detached(track, detached_origin, detached_origin_values, "after construction perturbation")
	assert_true(track._locked_ledger.size() > 0, "Abort fixture has ledger state to perturb")
	if not track._locked_ledger.is_empty():
		track._locked_ledger[0].group_id += 100
	assert_true(
		_piece_values(track._locked_ledger) != candidate_ledger_before,
		"Abort fixture perturbation changes ledger group identity"
	)
	_assert_abort_origin_detached(track, detached_origin, detached_origin_values, "after ledger perturbation")
	var recovery_keys: Array = track._recovered_cells_by_piece.keys()
	assert_true(recovery_keys.size() > 0, "Abort fixture has recovery state to perturb")
	if not recovery_keys.is_empty():
		var recovered_cells: Dictionary = track._recovered_cells_by_piece[recovery_keys[0]]
		var recovered_cell_keys: Array = recovered_cells.keys()
		assert_true(recovered_cell_keys.size() > 0, "Abort fixture has a recovered cell to perturb")
		if not recovered_cell_keys.is_empty():
			recovered_cells[recovered_cell_keys[0]] = not recovered_cells[recovered_cell_keys[0]]
	assert_true(
		track._recovered_cells_by_piece.duplicate(true) != candidate_recovery_cells_before,
		"Abort fixture perturbation changes nested recovery"
	)
	assert_equal(
		track._recovered_end_distance_cells,
		candidate_recovery_frontier_before,
		"Abort fixture keeps recovery frontier isolated from nested perturbation"
	)
	_assert_abort_origin_detached(track, detached_origin, detached_origin_values, "after recovery perturbation")
	assert_true(track._anchors.size() > 0, "Abort fixture has anchor state to perturb")
	if not track._anchors.is_empty():
		var perturbed_anchor_cell := Vector2i(7, 7)
		if track._anchors[0].cell == perturbed_anchor_cell:
			perturbed_anchor_cell = Vector2i(7, 8)
		track._anchors[0].cell = perturbed_anchor_cell
	assert_true(
		_anchor_values(track._anchors) != candidate_anchors_before,
		"Abort fixture perturbation changes anchors"
	)
	_assert_abort_origin_detached(track, detached_origin, detached_origin_values, "after anchor perturbation")
	assert_true(track._contact_observations.size() > 0, "Abort fixture has contact state to perturb")
	if not track._contact_observations.is_empty():
		track._contact_observations[0].contacted = not track._contact_observations[0].contacted
	assert_true(
		track.get_contact_observations() != candidate_contacts_before,
		"Abort fixture perturbation changes contacts"
	)
	_assert_abort_origin_detached(track, detached_origin, detached_origin_values, "after contact perturbation")
	assert_true(track.has_method("gesture_abort"), "Gesture abort contract exists")
	if not track.has_method("gesture_abort"):
		return
	assert_true(track.call("gesture_abort"), "Gesture abort restores the origin")
	assert_false(track.gesture_is_active(), "Gesture abort clears active state")
	assert_equal(track.call("get_gesture_origin_observation"), {}, "Gesture abort clears transient origin")
	assert_equal(_record_values(track.get_cell_records()), origin_records, "Abort restores route records")
	assert_equal(_piece_values(track.get_geometry_pieces()), origin_pieces, "Abort restores geometry pieces")
	assert_equal(_piece_values(track._locked_ledger), origin_ledger, "Abort restores immutable ledger")
	assert_equal(_anchor_values(track._anchors), origin_anchors, "Abort restores anchors")
	assert_equal(_recovery_observation_values(track), origin_recovery, "Abort restores recovery and construction")
	assert_equal(track.get_contact_observations(), origin_contacts, "Abort restores contact observations")
	assert_equal(track.get_available_track_cells(), origin_inventory, "Abort restores inventory")
	assert_true(track._gesture_origin_sequence == null, "Gesture abort clears origin sequence")
	assert_true(track._gesture_origin_pieces.is_empty(), "Gesture abort clears origin pieces")
	assert_true(track._gesture_origin_locked_ledger.is_empty(), "Gesture abort clears origin ledger")
	assert_true(track._gesture_origin_anchors.is_empty(), "Gesture abort clears origin anchors")
	assert_true(track._gesture_origin_recovered_cells_by_piece.is_empty(), "Gesture abort clears origin recovery")
	assert_equal(track._gesture_origin_recovered_end_distance_cells, 0.0, "Gesture abort clears origin recovery frontier")
	assert_true(track._gesture_origin_contacts.is_empty(), "Gesture abort clears origin contacts")
	assert_true(track._gesture_editable_span.is_empty(), "Gesture abort clears editable span")
	assert_true(track._gesture_target_endpoints.is_empty(), "Gesture abort clears target endpoints")
	assert_equal(track._gesture_selected_template_index, -1, "Gesture abort clears selected template")
	assert_true(track._gesture_suffix_input_facts.is_empty(), "Gesture abort clears suffix input facts")
	assert_true(track._gesture_ordinary_input_facts.is_empty(), "Gesture abort clears ordinary input facts")
	var maximum_consumed_serial := 0
	for serial in consumed_serials:
		maximum_consumed_serial = maxi(maximum_consumed_serial, serial)
	var fresh_cell: Array[Vector2i] = [Vector2i(3, 4)]
	assert_equal(track.append_cells(fresh_cell), 1, "Abort permits a fresh ordinary append")
	var fresh_record = track.get_cell_records()[-1]
	assert_true(fresh_record.route_serial > maximum_consumed_serial, "Fresh append skips every consumed candidate serial")
	assert_equal(fresh_record.route_distance_start_cells, origin_records[-1]["distance"] + 1.0, "Fresh append keeps nominal distance")
	assert_true(track._sequence.is_conservation_valid(), "Fresh append preserves conservation")
	var active_cells: Dictionary = {}
	for record in track.get_cell_records():
		assert_false(active_cells.has(record.cell), "Fresh append preserves active-cell uniqueness")
		active_cells[record.cell] = true
	var after_append_records := _record_values(track.get_cell_records())
	var after_append_pieces := _piece_values(track.get_geometry_pieces())
	var after_append_ledger := _piece_values(track._locked_ledger)
	var after_append_recovery := _recovery_observation_values(track)
	var after_append_anchors := _anchor_values(track._anchors)
	var after_append_contacts: Array = track.get_contact_observations().duplicate(true)
	var after_append_inventory: int = track.get_available_track_cells()
	var after_append_next_route_serial: int = track._sequence._next_route_serial
	var after_append_next_nominal_start_cells: float = track._sequence._next_nominal_start_cells
	var after_append_active_predecessor_cell: Vector2i = track._sequence._active_predecessor_cell
	var after_append_active_cells: Dictionary = track._sequence._active_cells.duplicate(true)
	assert_false(track.call("gesture_abort"), "Inactive gesture abort returns false")
	assert_equal(_record_values(track.get_cell_records()), after_append_records, "Inactive abort preserves records")
	assert_equal(_piece_values(track.get_geometry_pieces()), after_append_pieces, "Inactive abort preserves pieces")
	assert_equal(_piece_values(track._locked_ledger), after_append_ledger, "Inactive abort preserves ledger")
	assert_equal(_recovery_observation_values(track), after_append_recovery, "Inactive abort preserves recovery")
	assert_equal(_anchor_values(track._anchors), after_append_anchors, "Inactive abort preserves anchors")
	assert_equal(track.get_contact_observations(), after_append_contacts, "Inactive abort preserves contacts")
	assert_equal(track.get_available_track_cells(), after_append_inventory, "Inactive abort preserves inventory")
	assert_equal(track._sequence._next_route_serial, after_append_next_route_serial, "Inactive abort preserves next route serial")
	assert_equal(
		track._sequence._next_nominal_start_cells,
		after_append_next_nominal_start_cells,
		"Inactive abort preserves next nominal start distance"
	)
	assert_equal(
		track._sequence._active_predecessor_cell,
		after_append_active_predecessor_cell,
		"Inactive abort preserves active predecessor cell"
	)
	assert_equal(track._sequence._active_cells, after_append_active_cells, "Inactive abort preserves active cells")


func _test_endpoint_reshape_locked_and_prepared_geometry_reject_mutation() -> void:
	var track = _make_three_by_three_curve_runtime()
	var prepared_anchors: Array[RouteContactAnchorScript] = [
		RouteContactAnchorScript.new(&"prepared_anchor", Vector2i(7, 7)),
	]
	track.set_contact_anchors(prepared_anchors)
	assert_equal(track.advance_construction(5.0), 5.0, "Prepared fixture builds curve")
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Prepared fixture starts a reshape gesture")
	if not began is Dictionary:
		return
	assert_true(track.prepare_for_train_sampling(0.0, 5.0), "Prepared fixture locks the active curve")
	assert_true(track._locked_ledger.size() > 0, "Prepared fixture records the locked curve")
	for piece in track.get_geometry_pieces():
		assert_true(piece.locked, "Prepared fixture leaves geometry locked")
	var records_before := _record_values(track.get_cell_records())
	var pieces_before := _piece_values(track.get_geometry_pieces())
	var ledger_before := _piece_values(track._locked_ledger)
	var inventory_before: int = track.get_available_track_cells()
	var recovery_before := _recovery_observation_values(track)
	var contacts_before: Array = track.get_contact_observations().duplicate(true)
	var locked_anchor_before := _anchor_values(track._anchors)
	print("Endpoint reshape: locked and prepared geometry reject mutation")
	assert_true(track.has_method("gesture_update"), "Prepared fixture has gesture update")
	if not track.has_method("gesture_update"):
		return
	var target_cells: Array[Vector2i] = [began["targets"]["straight"]]
	assert_false(track.call("gesture_update", target_cells), "Prepared geometry rejects template mutation")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Prepared rejection preserves records")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Prepared rejection preserves pieces")
	assert_equal(_piece_values(track._locked_ledger), ledger_before, "Prepared rejection preserves ledger")
	assert_equal(track.get_available_track_cells(), inventory_before, "Prepared rejection preserves inventory")
	assert_equal(_recovery_observation_values(track), recovery_before, "Prepared rejection preserves recovery")
	assert_equal(track.get_contact_observations(), contacts_before, "Prepared rejection preserves contacts")
	assert_equal(_anchor_values(track._anchors), locked_anchor_before, "Prepared rejection preserves anchors")
	track.call("gesture_abort")


func _test_endpoint_reshape_locked_boundary_rejects_template_mutation() -> void:
	var track = _make_three_by_three_curve_runtime()
	var boundary_anchors: Array[RouteContactAnchorScript] = [
		RouteContactAnchorScript.new(&"boundary_anchor", Vector2i(7, 7)),
	]
	track.set_contact_anchors(boundary_anchors)
	assert_equal(track.advance_construction(2.5), 2.5, "Boundary fixture leaves construction progress")
	var began = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(began is Dictionary, "Boundary fixture starts a reshape gesture")
	if not began is Dictionary:
		return
	var endpoint_piece = track._pieces[-1]
	var locked_boundary = endpoint_piece.duplicate_piece()
	locked_boundary.locked = true
	track._pieces[-1].locked = true
	track._locked_ledger.append(locked_boundary)
	track._sequence.apply_resolved_geometry(track._pieces)
	var records_before := _record_values(track.get_cell_records())
	var pieces_before := _piece_values(track.get_geometry_pieces())
	var ledger_before := _piece_values(track._locked_ledger)
	var inventory_before: int = track.get_available_track_cells()
	var recovery_before := _recovery_observation_values(track)
	var contacts_before: Array = track.get_contact_observations().duplicate(true)
	var anchors_before := _anchor_values(track._anchors)
	print("Endpoint reshape: locked boundary rejects template mutation")
	var target_cells: Array[Vector2i] = [began["targets"]["straight"]]
	assert_false(track.call("gesture_update", target_cells), "Locked boundary rejects template mutation")
	assert_equal(_record_values(track.get_cell_records()), records_before, "Locked boundary preserves records")
	assert_equal(_piece_values(track.get_geometry_pieces()), pieces_before, "Locked boundary preserves pieces")
	assert_equal(_piece_values(track._locked_ledger), ledger_before, "Locked boundary preserves ledger")
	assert_equal(track.get_available_track_cells(), inventory_before, "Locked boundary preserves inventory")
	assert_equal(_recovery_observation_values(track), recovery_before, "Locked boundary preserves construction and recovery")
	assert_equal(track.get_contact_observations(), contacts_before, "Locked boundary preserves contact observations")
	assert_equal(_anchor_values(track._anchors), anchors_before, "Locked boundary preserves anchors")
	track.call("gesture_abort")


func _test_endpoint_reshape_replacement_overlap_terminates_last_valid() -> void:
	print("Endpoint reshape: replacement overlap terminates last valid")
	var track = _make_three_by_three_curve_runtime()
	assert_true(track.has_method("gesture_begin"), "Replacement overlap exposes gesture begin")
	if not track.has_method("gesture_begin"):
		return
	var origin = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(origin is Dictionary and not origin.is_empty(), "Replacement overlap starts a gesture")
	if not origin is Dictionary or origin.is_empty():
		return
	var target: Vector2i = origin["targets"]["straight"]
	assert_true(track.has_method("gesture_update"), "Replacement overlap exposes gesture update")
	if not track.has_method("gesture_update"):
		return
	var target_cells: Array[Vector2i] = [target]
	assert_true(track.call("gesture_update", target_cells), "Replacement overlap publishes a candidate")
	var candidate_records := _record_values(track.get_cell_records())
	var candidate_route_content := _route_content_values(track.get_cell_records())
	var candidate_route_full := _route_sampling_values(track.get_cell_records())
	var candidate_geometry_content := _piece_content_values(track.get_geometry_pieces())
	var candidate_geometry_full := _piece_sampling_values(track.get_geometry_pieces())
	var candidate_ledger_full := _piece_sampling_values(track._locked_ledger)
	var candidate_inventory: int = track.get_available_track_cells()
	var candidate_recovery_content := _recovery_content_values(track)
	var candidate_recovery_full := _recovery_sampling_values(track)
	var candidate_contacts: Array = track.get_contact_observations().duplicate(true)
	var candidate_anchors := _anchor_values(track._anchors)
	assert_equal(candidate_ledger_full, [], "Replacement candidate starts without locked ledger")
	var expected_route := candidate_route_full.duplicate(true)
	expected_route[0]["locked"] = true
	expected_route[1]["locked"] = true
	var expected_geometry := candidate_geometry_full.duplicate(true)
	expected_geometry[0]["locked"] = true
	expected_geometry[0]["support"] = 2
	expected_geometry[1]["locked"] = true
	expected_geometry[1]["support"] = 3
	var expected_ledger: Array = [expected_geometry[0].duplicate(true), expected_geometry[1].duplicate(true)]
	var expected_recovery := candidate_recovery_full.duplicate(true)
	expected_recovery["records"] = expected_route.duplicate(true)
	expected_recovery["pieces"] = expected_geometry.duplicate(true)
	assert_true(track.has_method("prepare_for_train_sampling"), "Replacement overlap exposes preparation")
	if not track.has_method("prepare_for_train_sampling"):
		return
	assert_true(track.call("prepare_for_train_sampling", 0.0, 1.0), "Replacement overlap preparation succeeds")
	assert_false(track.call("gesture_is_active"), "Replacement overlap terminates before locking")
	assert_equal(_route_content_values(track.get_cell_records()), candidate_route_content, "Replacement overlap preserves candidate route cells and build state")
	assert_equal(_piece_content_values(track.get_geometry_pieces()), candidate_geometry_content, "Replacement overlap preserves candidate geometry shape")
	assert_equal(track.get_available_track_cells(), candidate_inventory, "Replacement overlap preserves candidate inventory")
	assert_equal(_recovery_content_values(track), candidate_recovery_content, "Replacement overlap preserves candidate recovery content")
	assert_equal(track.get_contact_observations(), candidate_contacts, "Replacement overlap preserves candidate contact observations")
	assert_equal(_anchor_values(track._anchors), candidate_anchors, "Replacement overlap preserves candidate anchors")
	assert_equal(_route_sampling_values(track.get_cell_records()), expected_route, "Replacement overlap permits only expected route lock transitions")
	assert_equal(_piece_sampling_values(track.get_geometry_pieces()), expected_geometry, "Replacement overlap permits only expected piece lock/support transitions")
	assert_equal(_piece_sampling_values(track._locked_ledger), expected_ledger, "Replacement overlap adds exactly the expected stable ledger pieces")
	assert_equal(_recovery_sampling_values(track), expected_recovery, "Replacement overlap applies the expected stable recovery state")
	assert_equal(expected_route[0]["serial"], 1, "Replacement expected first route serial is one")
	assert_equal(expected_route[1]["serial"], 2, "Replacement expected second route serial is two")
	assert_true(expected_route[0]["locked"] and expected_route[1]["locked"], "Replacement expected sampled route owners are locked")
	assert_false(expected_route[2]["locked"] or expected_route[3]["locked"] or expected_route[4]["locked"], "Replacement expected endpoint owner and two supports remain mutable")
	assert_equal(expected_geometry[0]["group"], 0, "Replacement expected first owner group is unchanged")
	assert_equal(expected_geometry[1]["group"], 1, "Replacement expected second owner group is unchanged")
	assert_equal(expected_geometry[0]["support"], 2, "Replacement expected first owner support is serial two")
	assert_equal(expected_geometry[1]["support"], 3, "Replacement expected second owner support is serial three")
	assert_false(expected_geometry[2]["locked"] or expected_geometry[3]["locked"] or expected_geometry[4]["locked"], "Replacement expected mutable geometry suffix is unchanged")
	for index in range(2, expected_route.size()):
		assert_equal(expected_route[index], candidate_route_full[index], "Replacement unaffected route entry %d remains candidate-identical" % index)
	for index in range(2, expected_geometry.size()):
		assert_equal(expected_geometry[index], candidate_geometry_full[index], "Replacement unaffected piece entry %d remains candidate-identical" % index)
	assert_equal(_record_values(track.get_cell_records())[0].cell, candidate_records[0].cell, "Replacement overlap keeps the last valid candidate")
	assert_true(track.get_geometry_pieces()[0].locked, "Replacement overlap locks only after preserving the candidate")
	var failed = _make_three_by_three_curve_runtime()
	var failed_origin = failed.call("gesture_begin", failed.get_endpoint_cell())
	if failed_origin is Dictionary and not failed_origin.is_empty():
		var failed_target_cells: Array[Vector2i] = [failed_origin["targets"]["straight"]]
		assert_true(failed.call("gesture_update", failed_target_cells), "Failed-retirement fixture publishes a candidate")
		var failed_route_before := _route_sampling_values(failed.get_cell_records())
		var failed_pieces_before := _piece_sampling_values(failed.get_geometry_pieces())
		var failed_ledger_before := _piece_sampling_values(failed._locked_ledger)
		var failed_inventory_before: int = failed.get_available_track_cells()
		var failed_recovery_before := _recovery_sampling_values(failed)
		var failed_anchors_before := _anchor_values(failed._anchors)
		var failed_contacts_before: Array = failed.get_contact_observations().duplicate(true)
		failed._resolver = _RejectingResolver.new()
		assert_false(failed.call("prepare_for_train_sampling", 0.0, 1.0), "Stable retirement failure returns false")
		assert_false(failed.call("gesture_is_active"), "Stable retirement failure ends the gesture")
		assert_equal(_route_sampling_values(failed.get_cell_records()), failed_route_before, "Stable retirement failure preserves all route state")
		assert_equal(_piece_sampling_values(failed.get_geometry_pieces()), failed_pieces_before, "Stable retirement failure preserves all piece state")
		assert_equal(_piece_sampling_values(failed._locked_ledger), failed_ledger_before, "Stable retirement failure preserves all ledger state")
		assert_equal(failed.get_available_track_cells(), failed_inventory_before, "Stable retirement failure preserves inventory")
		assert_equal(_recovery_sampling_values(failed), failed_recovery_before, "Stable retirement failure preserves all recovery state")
		assert_equal(_anchor_values(failed._anchors), failed_anchors_before, "Stable retirement failure preserves anchors")
		assert_equal(failed.get_contact_observations(), failed_contacts_before, "Stable retirement failure preserves contacts")
		var failed_route_after_first := _route_sampling_values(failed.get_cell_records())
		var failed_pieces_after_first := _piece_sampling_values(failed.get_geometry_pieces())
		var failed_ledger_after_first := _piece_sampling_values(failed._locked_ledger)
		var failed_recovery_after_first := _recovery_sampling_values(failed)
		var failed_anchors_after_first := _anchor_values(failed._anchors)
		var failed_contacts_after_first: Array = failed.get_contact_observations().duplicate(true)
		assert_false(failed.call("prepare_for_train_sampling", 0.0, 1.0), "Stable retirement failure is idempotent")
		assert_false(failed.call("gesture_is_active"), "Repeated stable retirement failure keeps the gesture inactive")
		assert_equal(_route_sampling_values(failed.get_cell_records()), failed_route_after_first, "Repeated stable retirement failure preserves all route state")
		assert_equal(_piece_sampling_values(failed.get_geometry_pieces()), failed_pieces_after_first, "Repeated stable retirement failure preserves all piece state")
		assert_equal(_piece_sampling_values(failed._locked_ledger), failed_ledger_after_first, "Repeated stable retirement failure preserves all ledger state")
		assert_equal(failed.get_available_track_cells(), failed_inventory_before, "Repeated stable retirement failure preserves inventory")
		assert_equal(_recovery_sampling_values(failed), failed_recovery_after_first, "Repeated stable retirement failure preserves all recovery state")
		assert_equal(_anchor_values(failed._anchors), failed_anchors_after_first, "Repeated stable retirement failure preserves anchors")
		assert_equal(failed.get_contact_observations(), failed_contacts_after_first, "Repeated stable retirement failure preserves contacts")


func _test_endpoint_reshape_extension_overlap_terminates_last_valid() -> void:
	print("Endpoint reshape: extension overlap terminates last valid")
	var track = _make_three_by_three_curve_runtime()
	var origin = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(origin is Dictionary and not origin.is_empty(), "Extension overlap starts a gesture")
	if not origin is Dictionary or origin.is_empty():
		return
	var target: Vector2i = origin["targets"]["straight"]
	var extension := Vector2i(target.x, target.y + 1)
	var extension_cells: Array[Vector2i] = [target, extension]
	assert_true(track.call("gesture_update", extension_cells), "Extension overlap publishes a suffix candidate")
	var candidate_records := _record_values(track.get_cell_records())
	var candidate_route_content := _route_content_values(track.get_cell_records())
	var candidate_route_full := _route_sampling_values(track.get_cell_records())
	var candidate_geometry_content := _piece_content_values(track.get_geometry_pieces())
	var candidate_geometry_full := _piece_sampling_values(track.get_geometry_pieces())
	var candidate_ledger_full := _piece_sampling_values(track._locked_ledger)
	var candidate_inventory: int = track.get_available_track_cells()
	var candidate_recovery_content := _recovery_content_values(track)
	var candidate_recovery_full := _recovery_sampling_values(track)
	var candidate_contacts: Array = track.get_contact_observations().duplicate(true)
	var candidate_anchors := _anchor_values(track._anchors)
	assert_equal(candidate_ledger_full, [], "Extension candidate starts without locked ledger")
	var expected_route := candidate_route_full.duplicate(true)
	for index in range(expected_route.size()):
		expected_route[index]["locked"] = true
	var expected_geometry := candidate_geometry_full.duplicate(true)
	for index in range(expected_geometry.size()):
		expected_geometry[index]["locked"] = true
	expected_geometry[0]["support"] = 2
	expected_geometry[1]["support"] = 3
	expected_geometry[2]["support"] = 4
	expected_geometry[3]["support"] = -1
	var expected_ledger: Array = []
	for piece in expected_geometry:
		expected_ledger.append(piece.duplicate(true))
	var expected_recovery := candidate_recovery_full.duplicate(true)
	expected_recovery["records"] = expected_route.duplicate(true)
	expected_recovery["pieces"] = expected_geometry.duplicate(true)
	assert_true(track.call("prepare_for_train_sampling", 5.0, 5.5), "Extension overlap preparation succeeds")
	assert_false(track.call("gesture_is_active"), "Extension overlap terminates before locking")
	assert_equal(_route_content_values(track.get_cell_records()), candidate_route_content, "Extension overlap preserves candidate route cells and build state")
	assert_equal(_piece_content_values(track.get_geometry_pieces()), candidate_geometry_content, "Extension overlap preserves candidate geometry shape")
	assert_equal(track.get_available_track_cells(), candidate_inventory, "Extension overlap preserves candidate inventory")
	assert_equal(_piece_sampling_values(track._locked_ledger), expected_ledger, "Extension overlap adds exactly the expected stable ledger pieces")
	assert_equal(_recovery_content_values(track), candidate_recovery_content, "Extension overlap preserves candidate recovery content")
	assert_equal(track.get_contact_observations(), candidate_contacts, "Extension overlap preserves candidate contact observations")
	assert_equal(_anchor_values(track._anchors), candidate_anchors, "Extension overlap preserves candidate anchors")
	assert_equal(_route_sampling_values(track.get_cell_records()), expected_route, "Extension overlap permits only expected route lock transitions")
	assert_equal(_piece_sampling_values(track.get_geometry_pieces()), expected_geometry, "Extension overlap permits only expected piece lock/support transitions")
	assert_equal(_recovery_sampling_values(track), expected_recovery, "Extension overlap applies the expected stable recovery state")
	assert_equal(expected_route.size(), 6, "Extension expected route has six serials")
	assert_equal(expected_geometry[0]["serials"], Vector2i(1, 1), "Extension expected first owner serial span is one")
	assert_equal(expected_geometry[3]["serials"], Vector2i(4, 6), "Extension expected curve owner serial span is four through six")
	assert_equal(expected_geometry[0]["support"], 2, "Extension expected first owner support is serial two")
	assert_equal(expected_geometry[1]["support"], 3, "Extension expected second owner support is serial three")
	assert_equal(expected_geometry[2]["support"], 4, "Extension expected third owner support is serial four")
	assert_equal(expected_geometry[3]["support"], -1, "Extension expected terminal curve has no exit support")
	for index in range(expected_route.size()):
		assert_equal(expected_route[index]["group"], candidate_route_full[index]["group"], "Extension route group %d remains candidate-identical" % index)
	for index in range(expected_geometry.size()):
		assert_equal(expected_geometry[index]["group"], candidate_geometry_full[index]["group"], "Extension piece group %d remains candidate-identical" % index)
	assert_equal(_record_values(track.get_cell_records())[-1].cell, candidate_records[-1].cell, "Extension overlap keeps the last valid candidate")


func _test_endpoint_reshape_nonoverlap_remains_active() -> void:
	print("Endpoint reshape: nonoverlap remains active")
	var track = _boundary_runtime()
	assert_true(track.call("prepare_for_train_sampling", 0.0, 1.0), "Nonoverlap fixture locks a fixed prefix")
	var origin = track.call("gesture_begin", track.get_endpoint_cell())
	assert_true(origin is Dictionary and not origin.is_empty(), "Nonoverlap starts a gesture")
	if not origin is Dictionary or origin.is_empty():
		return
	var was_active := bool(track.call("gesture_is_active"))
	var result := bool(track.call("prepare_for_train_sampling", 0.0, 0.5))
	assert_true(result, "Nonoverlap preparation succeeds")
	assert_true(was_active, "Nonoverlap began active")
	assert_true(track.call("gesture_is_active"), "Nonoverlap keeps the gesture active")


func _test_endpoint_reshape_train_lock_survives_begin_prepare_update_and_abort() -> void:
	print("Endpoint reshape: begin then prepare preserves immutable train locks through update and abort")
	var update_track = _make_retained_predecessor_curve_2x2_runtime()
	var abort_track = _make_retained_predecessor_curve_2x2_runtime()
	_assert_train_lock_fixture_shape(update_track, "Update fixture")
	_assert_train_lock_fixture_shape(abort_track, "Abort fixture")
	_assert_begin_prepare_update_preserves_train_lock(update_track)
	_assert_begin_prepare_abort_preserves_train_lock(abort_track)


func _make_retained_predecessor_curve_2x2_runtime() -> GridTrackRuntimeScript:
	var track = _boundary_runtime()
	track.set_contact_anchors([
		RouteContactAnchorScript.new(&"retained_predecessor", Vector2i(0, 0)),
	])
	return track


func _assert_train_lock_fixture_shape(track: GridTrackRuntimeScript, label: String) -> void:
	var records = track.get_cell_records()
	var pieces = track.get_geometry_pieces()
	assert_equal(records.size(), 4, "%s has a four-record route" % label)
	assert_equal(pieces.size(), 2, "%s has a predecessor and CURVE_2X2 endpoint" % label)
	if records.size() < 4 or pieces.size() < 2:
		return
	assert_equal(pieces[0].kind, TrackGeometryPieceScript.Kind.STRAIGHT, "%s retained predecessor is straight" % label)
	assert_equal(pieces[1].kind, TrackGeometryPieceScript.Kind.CURVE_2X2, "%s endpoint owner is CURVE_2X2" % label)
	assert_false(pieces[0].locked, "%s retained predecessor starts unlocked" % label)
	assert_false(pieces[1].locked, "%s endpoint owner starts unlocked" % label)
	assert_false(records[0].geometry_locked, "%s retained predecessor record starts unlocked" % label)
	assert_true(track.get_contact_observations()[0].contacted, "%s retains a contacted anchor fact" % label)


func _assert_begin_prepare_update_preserves_train_lock(track: GridTrackRuntimeScript) -> void:
	var endpoint: Vector2i = track.get_endpoint_cell()
	var origin: Dictionary = track.call("gesture_begin", endpoint)
	assert_true(origin is Dictionary and not origin.is_empty(), "Update fixture begins at the CURVE_2X2 endpoint")
	if not origin is Dictionary or origin.is_empty():
		return
	var origin_span: Dictionary = origin["editable_span"].duplicate(true)
	var origin_targets: Dictionary = origin["targets"].duplicate(true)
	var origin_watermark: int = track._gesture_origin_sequence._next_route_serial
	assert_equal(origin_span["record_count"], 3, "Update fixture origin owns the CURVE_2X2 span")
	assert_true(track.call("prepare_for_train_sampling", 0.0, 0.5), "Update fixture non-overlap preparation succeeds")
	assert_true(track.call("gesture_is_active"), "Update fixture preparation keeps the gesture active")
	var prepared_record = _record_values(track.get_cell_records())[0].duplicate(true)
	var prepared_piece = _piece_values(track.get_geometry_pieces())[0].duplicate(true)
	var prepared_ledger := _piece_values(track._locked_ledger)
	var prepared_pose: Dictionary = track.get_pose_sample_at_distance(0.0)
	var prepared_recovery := _train_lock_recovery_facts(track)
	var prepared_anchors := _anchor_values(track._anchors)
	var prepared_contacts: Array = track.get_contact_observations().duplicate(true)
	var target_cells: Array[Vector2i] = [origin_targets["straight"]]
	assert_true(track.call("gesture_update", target_cells), "Update fixture publishes a valid template update")
	assert_true(track.call("gesture_is_active"), "Update fixture remains active after valid update")
	var updated_record = _record_values(track.get_cell_records())[0]
	var updated_piece = _piece_values(track.get_geometry_pieces())[0]
	assert_equal(updated_record, prepared_record, "Updated candidate preserves the prepared prefix route lock facts")
	assert_equal(updated_piece, prepared_piece, "Updated candidate preserves the prepared prefix piece identity and support")
	assert_equal(_piece_values(track._locked_ledger), prepared_ledger, "Updated candidate preserves the prepared ledger group identity and serial span")
	assert_equal(track.get_pose_sample_at_distance(0.0), prepared_pose, "Updated candidate preserves the prepared prefix pose sample")
	assert_equal(_train_lock_recovery_facts(track), prepared_recovery, "Updated candidate preserves recovery facts")
	assert_equal(_anchor_values(track._anchors), prepared_anchors, "Updated candidate preserves anchor facts")
	assert_equal(track.get_contact_observations(), prepared_contacts, "Updated candidate preserves contact facts")
	assert_equal(track.get_gesture_editable_span(), origin_span, "Updated candidate preserves the editable origin span")
	assert_equal(track.get_gesture_target_endpoints(), origin_targets, "Updated candidate preserves origin target semantics")
	assert_equal(track._gesture_origin_sequence._next_route_serial, origin_watermark, "Updated candidate preserves the origin serial watermark")
	assert_equal(track._sequence._next_route_serial, origin_watermark, "Updated candidate does not consume a replacement serial")
	assert_true(track.call("gesture_finalize"), "Update fixture finalizes after the valid update")
	assert_equal(_piece_values(track._locked_ledger), prepared_ledger, "Finalized update preserves the prepared ledger")


func _assert_begin_prepare_abort_preserves_train_lock(track: GridTrackRuntimeScript) -> void:
	var endpoint: Vector2i = track.get_endpoint_cell()
	var origin: Dictionary = track.call("gesture_begin", endpoint)
	assert_true(origin is Dictionary and not origin.is_empty(), "Abort fixture begins at the CURVE_2X2 endpoint")
	if not origin is Dictionary or origin.is_empty():
		return
	var origin_span: Dictionary = origin["editable_span"].duplicate(true)
	var origin_targets: Dictionary = origin["targets"].duplicate(true)
	var origin_watermark: int = track._gesture_origin_sequence._next_route_serial
	assert_true(track.call("prepare_for_train_sampling", 0.0, 0.5), "Abort fixture non-overlap preparation succeeds")
	assert_true(track.call("gesture_is_active"), "Abort fixture preparation keeps the gesture active")
	var prepared_route := _route_sampling_values(track.get_cell_records())
	var prepared_pieces := _piece_sampling_values(track.get_geometry_pieces())
	var prepared_ledger := _piece_sampling_values(track._locked_ledger)
	var prepared_recovery := _train_lock_recovery_facts(track)
	var prepared_anchors := _anchor_values(track._anchors)
	var prepared_contacts: Array = track.get_contact_observations().duplicate(true)
	var prepared_pose: Dictionary = track.get_pose_sample_at_distance(0.0)
	assert_true(track.call("gesture_abort"), "Abort fixture aborts the active gesture")
	assert_false(track.call("gesture_is_active"), "Abort fixture clears only the transient gesture state")
	assert_equal(_route_sampling_values(track.get_cell_records()), prepared_route, "Abort preserves prepared route lock flags and span")
	assert_equal(_piece_sampling_values(track.get_geometry_pieces()), prepared_pieces, "Abort preserves prepared piece identity and exit support")
	assert_equal(_piece_sampling_values(track._locked_ledger), prepared_ledger, "Abort preserves prepared ledger group identity")
	assert_equal(_train_lock_recovery_facts(track), prepared_recovery, "Abort preserves prepared recovery facts")
	assert_equal(_anchor_values(track._anchors), prepared_anchors, "Abort preserves prepared anchor facts")
	assert_equal(track.get_contact_observations(), prepared_contacts, "Abort preserves prepared contact facts")
	assert_equal(track.get_pose_sample_at_distance(0.0), prepared_pose, "Abort preserves the prepared prefix pose sample")
	assert_equal(track.get_endpoint_cell(), endpoint, "Abort preserves the editable endpoint")
	assert_equal(track._sequence._next_route_serial, origin_watermark, "Abort preserves the serial watermark")
	assert_equal(origin_span["record_count"], 3, "Abort fixture keeps the CURVE_2X2 editable span semantics")
	assert_true(origin_targets.has("straight"), "Abort fixture retains the original target semantics before restoration")


func _test_endpoint_reshape_candidate_contact_does_not_contaminate_origin_abort() -> void:
	print("Endpoint reshape: candidate contact does not contaminate origin abort snapshot")
	var track = _boundary_runtime()
	track.set_contact_anchors([
		RouteContactAnchorScript.new(&"origin_curve_only", Vector2i(2, 1)),
	])
	var expected_origin_cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1),
	]
	var expected_origin_contacts: Array[Dictionary] = [{
		"anchor_id": &"origin_curve_only",
		"cell": Vector2i(2, 1),
		"contact_possible": true,
		"contacted": true,
	}]
	var expected_candidate_contacts: Array[Dictionary] = [{
		"anchor_id": &"origin_curve_only",
		"cell": Vector2i(2, 1),
		"contact_possible": false,
		"contacted": false,
	}]
	var expected_origin_anchors: Array[Dictionary] = [{
		"anchor_id": &"origin_curve_only",
		"cell": Vector2i(2, 1),
	}]
	var origin_records := _route_sampling_values(track.get_cell_records())
	var origin_recovery := _train_lock_recovery_facts(track)
	var origin_inventory: int = track.get_available_track_cells()
	assert_equal(origin_records.size(), 4, "Origin-contact fixture has four route records")
	for index in range(expected_origin_cells.size()):
		assert_equal(origin_records[index]["serial"], index + 1, "Origin route serial is hand-derived")
		assert_equal(origin_records[index]["cell"], expected_origin_cells[index], "Origin route cell is hand-derived")
	assert_equal(track.get_contact_observations(), expected_origin_contacts, "Origin curve contacts its anchor")
	assert_equal(_anchor_values(track._anchors), expected_origin_anchors, "Origin anchor is detached and exact")
	assert_true(track.has_method("gesture_begin"), "Contact divergence fixture exposes gesture begin")
	if not track.has_method("gesture_begin"):
		return
	var origin: Dictionary = track.call("gesture_begin", Vector2i(2, 1))
	assert_true(origin is Dictionary and not origin.is_empty(), "Contact divergence fixture begins at the endpoint")
	if not origin is Dictionary or origin.is_empty():
		return
	assert_equal(origin["targets"]["straight"], Vector2i(3, 0), "Straight replacement target is hand-derived")
	assert_true(track.has_method("gesture_update"), "Contact divergence fixture exposes gesture update")
	if not track.has_method("gesture_update"):
		return
	var straight_target: Array[Vector2i] = [Vector2i(3, 0)]
	assert_true(track.call("gesture_update", straight_target), "Different valid straight candidate publishes")
	assert_equal(track.get_contact_observations(), expected_candidate_contacts, "Candidate loses the origin-only contact")
	assert_true(track.has_method("prepare_for_train_sampling"), "Contact divergence fixture exposes preparation")
	if not track.has_method("prepare_for_train_sampling"):
		return
	assert_true(
		track.call("prepare_for_train_sampling", 0.0, 0.5),
		"Non-overlap preparation locks the retained predecessor after candidate update"
	)
	assert_true(track.call("gesture_is_active"), "Non-overlap preparation keeps the gesture active")
	var prepared_prefix_record := _record_values(track.get_cell_records())[0]
	var prepared_prefix_piece := _piece_values(track.get_geometry_pieces())[0]
	var prepared_ledger := _piece_values(track._locked_ledger)
	var prepared_recovery := _train_lock_recovery_facts(track)
	var prepared_pose: Dictionary = track.get_pose_sample_at_distance(0.0)
	var prepared_serial: int = track._sequence._next_route_serial
	var staged_origin: Dictionary = track.call("get_gesture_origin_observation")
	assert_true(staged_origin is Dictionary and not staged_origin.is_empty(), "Preparation refreshes the detached origin")
	if not staged_origin is Dictionary or staged_origin.is_empty():
		return
	var staged_origin_records := _route_sampling_values(staged_origin["route_records"])
	var staged_origin_pieces := _piece_sampling_values(staged_origin["pieces"])
	var staged_origin_ledger := _piece_sampling_values(staged_origin["locked_ledger"])
	var staged_origin_recovery := {
		"built_end": origin_recovery["built_end"],
		"recovered_cells_by_piece": staged_origin["recovery"]["recovered_cells_by_piece"].duplicate(true),
		"recovered_end_distance_cells": staged_origin["recovery"]["recovered_end_distance_cells"],
	}
	assert_equal(staged_origin["contact_observations"], expected_origin_contacts, "Staged origin retains origin contact expectation")
	assert_true(prepared_prefix_record["locked"], "Preparation locks the retained predecessor record")
	assert_true(prepared_prefix_piece["locked"], "Preparation locks the retained predecessor piece")
	assert_equal(prepared_ledger.size(), 1, "Preparation creates one retained predecessor ledger entry")
	assert_equal(track.get_contact_observations(), expected_candidate_contacts, "Preparation retains candidate contact facts before abort")
	assert_true(track.call("gesture_abort"), "Contact divergence fixture aborts the active gesture")
	assert_equal(_route_sampling_values(track.get_cell_records()), staged_origin_records, "Abort restores exact origin route records")
	assert_equal(_piece_sampling_values(track.get_geometry_pieces()), staged_origin_pieces, "Abort restores exact origin geometry pieces")
	assert_equal(_piece_sampling_values(track._locked_ledger), staged_origin_ledger, "Abort restores exact origin ledger")
	assert_equal(_anchor_values(track._anchors), expected_origin_anchors, "Abort restores exact origin anchors")
	assert_equal(_train_lock_recovery_facts(track), staged_origin_recovery, "Abort restores exact origin recovery")
	assert_equal(track.get_contact_observations(), expected_origin_contacts, "Abort restores origin-only contact observations")
	assert_equal(track.get_available_track_cells(), origin_inventory, "Abort restores origin inventory")
	assert_equal(track.get_cell_records()[0].cell, expected_origin_cells[0], "Abort restores the origin prefix cell")
	assert_equal(track.get_cell_records()[-1].cell, expected_origin_cells[-1], "Abort restores the origin curve endpoint cell")
	assert_equal(_record_values(track.get_cell_records())[0], prepared_prefix_record, "Abort preserves prepared prefix record lock facts")
	assert_equal(_piece_values(track.get_geometry_pieces())[0], prepared_prefix_piece, "Abort preserves prepared prefix piece group/support facts")
	assert_equal(_piece_values(track._locked_ledger), prepared_ledger, "Abort preserves prepared ledger identity and serial span")
	assert_equal(_train_lock_recovery_facts(track), prepared_recovery, "Abort preserves post-begin train recovery facts")
	assert_equal(track.get_pose_sample_at_distance(0.0), prepared_pose, "Abort preserves post-begin train pose sample")
	assert_equal(track._sequence._next_route_serial, prepared_serial, "Abort preserves post-begin serial watermark")
	assert_equal(track.get_available_track_cells(), origin_inventory, "Abort preserves post-begin inventory conservation")
	assert_false(track.call("gesture_is_active"), "Abort clears only transient gesture state")


func _train_lock_recovery_facts(track: GridTrackRuntimeScript) -> Dictionary:
	return {
		"built_end": track.get_built_end_distance_cells(),
		"recovered_cells_by_piece": track._recovered_cells_by_piece.duplicate(true),
		"recovered_end_distance_cells": track._recovered_end_distance_cells,
	}


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
			"group": piece.group_id,
			"kind": piece.kind,
			"distance": piece.absolute_start_distance_cells,
			"length": piece.nominal_length_cells,
			"footprint": piece.footprint_cells,
			"centerline": piece.centerline,
			"active_start": piece.active_local_start_cells,
			"active_end": piece.active_local_end_cells,
			"support": piece.exit_support_route_serial,
			"locked": piece.locked,
		})
	return values


func _route_sampling_values(records: Array) -> Array[Dictionary]:
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


func _piece_sampling_values(pieces: Array) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for piece in pieces:
		values.append({
			"serials": Vector2i(piece.first_route_serial, piece.last_route_serial),
			"group": piece.group_id,
			"kind": piece.kind,
			"distance": piece.absolute_start_distance_cells,
			"length": piece.nominal_length_cells,
			"footprint": piece.footprint_cells,
			"centerline": piece.centerline,
			"active_start": piece.active_local_start_cells,
			"active_end": piece.active_local_end_cells,
			"support": piece.exit_support_route_serial,
			"locked": piece.locked,
		})
	return values


func _route_content_values(records: Array) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for record in records:
		values.append({
			"serial": record.route_serial,
			"cell": record.cell,
			"distance": record.route_distance_start_cells,
			"state": record.state,
			"progress": record.build_progress,
		})
	return values


func _piece_content_values(pieces: Array) -> Array[Dictionary]:
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
		})
	return values


func _recovery_content_values(track: GridTrackRuntimeScript) -> Dictionary:
	return {
		"records": _route_content_values(track.get_cell_records()),
		"pieces": _piece_content_values(track.get_geometry_pieces()),
		"built_end": track.get_built_end_distance_cells(),
		"recovered_cells_by_piece": track._recovered_cells_by_piece.duplicate(true),
		"recovered_end_distance_cells": track._recovered_end_distance_cells,
	}


func _recovery_sampling_values(track: GridTrackRuntimeScript) -> Dictionary:
	return {
		"records": _route_sampling_values(track.get_cell_records()),
		"pieces": _piece_sampling_values(track.get_geometry_pieces()),
		"built_end": track.get_built_end_distance_cells(),
		"recovered_cells_by_piece": track._recovered_cells_by_piece.duplicate(true),
		"recovered_end_distance_cells": track._recovered_end_distance_cells,
	}


func _anchor_values(anchors: Array) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for anchor in anchors:
		values.append({"anchor_id": anchor.anchor_id, "cell": anchor.cell})
	return values


func _abort_origin_values(origin: Dictionary) -> Dictionary:
	return {
		"records": _record_values(origin["route_records"]),
		"pieces": _piece_values(origin["pieces"]),
		"ledger": _piece_values(origin["locked_ledger"]),
		"anchors": _anchor_values(origin["anchors"]),
		"recovery_cells": origin["recovery"]["recovered_cells_by_piece"].duplicate(true),
		"recovery_frontier": origin["recovery"]["recovered_end_distance_cells"],
		"construction": _record_values(origin["construction"]),
		"inventory": origin["inventory"],
		"contacts": origin["contact_observations"].duplicate(true),
	}


func _assert_abort_origin_detached(
	track: GridTrackRuntimeScript,
	origin: Dictionary,
	expected: Dictionary,
	phase: String
) -> void:
	var detached_recovery: Dictionary = origin["recovery"]
	assert_equal(_record_values(origin["route_records"]), expected["records"], "Detached origin route remains unchanged %s" % phase)
	assert_equal(_piece_values(origin["pieces"]), expected["pieces"], "Detached origin pieces remain unchanged %s" % phase)
	assert_equal(_piece_values(origin["locked_ledger"]), expected["ledger"], "Detached origin ledger remains unchanged %s" % phase)
	assert_equal(_anchor_values(origin["anchors"]), expected["anchors"], "Detached origin anchors remain unchanged %s" % phase)
	assert_equal(
		detached_recovery["recovered_cells_by_piece"],
		expected["recovery_cells"],
		"Detached origin nested recovery remains unchanged %s" % phase
	)
	assert_equal(
		detached_recovery["recovered_end_distance_cells"],
		expected["recovery_frontier"],
		"Detached origin recovery frontier remains unchanged %s" % phase
	)
	assert_equal(_record_values(origin["construction"]), expected["construction"], "Detached origin construction remains unchanged %s" % phase)
	assert_equal(origin["inventory"], expected["inventory"], "Detached origin inventory remains unchanged %s" % phase)
	assert_equal(origin["contact_observations"], expected["contacts"], "Detached origin contacts remain unchanged %s" % phase)
	var stored = track.call("get_gesture_origin_observation")
	assert_true(stored is Dictionary and not stored.is_empty(), "Stored origin remains available %s" % phase)
	if not stored is Dictionary or stored.is_empty():
		return
	var stored_values := _abort_origin_values(stored)
	assert_equal(stored_values, expected, "Stored gesture-origin copies remain byte-for-byte unchanged %s" % phase)


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


func _make_five_straight_runtime():
	var track = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(track.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(3, 0), Vector2i(4, 0),
	]), 5, "Five straight replacement fixture accepts five cells")
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
