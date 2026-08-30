extends "res://tests/support/prototype_test.gd"

const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackCellSequenceScript = preload("res://src/domain/track/track_cell_sequence.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")


func run() -> PackedStringArray:
	_test_append_charges_each_unique_orthogonal_cell_once()
	_test_append_stops_before_diagonal_duplicate_or_exhausted_cell()
	_test_cancel_unlocked_ghost_suffix_refunds_once()
	_test_tentative_append_can_roll_back_exactly_once()
	_test_departure_anchor_is_free()
	_test_records_are_detached_observations()
	_test_tentative_record_is_detached()
	_test_rollback_and_cancel_guards()
	_test_serial_and_nominal_distance_continuity()
	_test_invalid_buffer_stops_immediately()
	_test_departure_anchor_reuse_follows_recovery_boundary()
	_test_start_building_does_not_lock_geometry()
	_test_endpoint_reshape_replacement_preserves_identity()
	_test_crossing_occurrence_counts_and_identity_conserve_inventory()
	return finish()


func _test_append_charges_each_unique_orthogonal_cell_once() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 4)
	var first_cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	assert_equal(route.append_candidates(first_cells), 2, "Two cells accepted")
	assert_equal(route.get_available_track_cells(), 2, "Two cells remain")
	var turn_cells: Array[Vector2i] = [Vector2i(2, 1)]
	assert_equal(route.append_candidates(turn_cells), 1, "Turn cell accepted")
	assert_equal(route.get_available_track_cells(), 1, "One cell remains")
	assert_true(route.is_conservation_valid(), "Integer conservation")


func _test_append_stops_before_diagonal_duplicate_or_exhausted_cell() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 2)
	var diagonal: Array[Vector2i] = [Vector2i(1, 1)]
	assert_equal(route.append_candidates(diagonal), 0, "Diagonal rejected")
	var over_capacity: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	]
	assert_equal(route.append_candidates(over_capacity), 2, "Inventory clips third cell")
	assert_equal(route.get_endpoint_cell(), Vector2i(2, 0), "Endpoint after clip")
	assert_equal(route.get_available_track_cells(), 0, "Inventory exhausted")


func _test_cancel_unlocked_ghost_suffix_refunds_once() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 4)
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	route.append_candidates(cells)
	assert_equal(route.cancel_ghost_suffix(Vector2i(2, 0)), 2, "Two ghost cells canceled")
	assert_equal(route.get_available_track_cells(), 3, "Canceled cells refunded")
	assert_equal(route.cancel_ghost_suffix(Vector2i(2, 0)), 0, "Repeated cancel is inert")


func _test_tentative_append_can_roll_back_exactly_once() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 2)
	var record = route.try_append_candidate(Vector2i(1, 0))
	assert_not_null(record, "Tentative cell accepted")
	if record == null:
		return
	route.rollback_last_unlocked_ghost(record.route_serial)
	assert_equal(route.get_available_track_cells(), 2, "Rollback refunds tentative cell")
	route.rollback_last_unlocked_ghost(record.route_serial)
	assert_equal(route.get_available_track_cells(), 2, "Repeated rollback is inert")


func _test_departure_anchor_is_free() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(7, 3), 5)
	assert_equal(route.get_departure_cell(), Vector2i(7, 3), "Departure anchor is retained")
	assert_equal(route.get_endpoint_cell(), Vector2i(7, 3), "Empty endpoint is departure")
	assert_equal(route.get_available_track_cells(), 5, "Departure anchor costs no inventory")
	assert_equal(route.get_records().size(), 0, "Departure anchor is not a route record")
	assert_true(route.is_conservation_valid(), "Empty route conserves integer inventory")


func _test_records_are_detached_observations() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 2)
	var cells: Array[Vector2i] = [Vector2i(1, 0)]
	route.append_candidates(cells)
	var observed = route.get_records()
	observed[0].cell = Vector2i(99, 99)
	observed[0].state = TrackCellRecordScript.State.BUILT
	observed[0].build_progress = 1.0
	observed[0].geometry_group_id = 42
	observed[0].geometry_locked = true
	var fresh = route.get_records()
	assert_equal(fresh[0].cell, Vector2i(1, 0), "Observed cell mutation is detached")
	assert_equal(fresh[0].state, TrackCellRecordScript.State.RESERVED_GHOST, "Observed state mutation is detached")
	assert_equal(fresh[0].build_progress, 0.0, "Observed progress mutation is detached")
	assert_equal(fresh[0].geometry_group_id, -1, "Observed group mutation is detached")
	assert_equal(fresh[0].geometry_locked, false, "Observed lock mutation is detached")


func _test_tentative_record_is_detached() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 2)
	var tentative = route.try_append_candidate(Vector2i(1, 0))
	assert_not_null(tentative, "Tentative append returns an observation")
	if tentative == null:
		return
	tentative.cell = Vector2i(99, 99)
	tentative.state = TrackCellRecordScript.State.BUILT
	tentative.geometry_locked = true
	var fresh = route.get_records()
	assert_equal(fresh[0].cell, Vector2i(1, 0), "Tentative cell mutation is detached")
	assert_equal(fresh[0].state, TrackCellRecordScript.State.RESERVED_GHOST, "Tentative state mutation is detached")
	assert_equal(fresh[0].geometry_locked, false, "Tentative lock mutation is detached")
	assert_equal(route.get_available_track_cells(), 1, "Tentative observation cannot alter inventory")


func _test_rollback_and_cancel_guards() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 4)
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	route.append_candidates(cells)
	var observed = route.get_records()
	route.rollback_last_unlocked_ghost(observed[0].route_serial)
	assert_equal(route.get_records().size(), 3, "Rollback requires the exact tail serial")
	route._records[-1].geometry_locked = true
	route.rollback_last_unlocked_ghost(observed[-1].route_serial)
	assert_equal(route.get_records().size(), 3, "Rollback rejects a locked tail")
	assert_equal(route.cancel_ghost_suffix(Vector2i(2, 0)), 0, "Cancellation rejects a later locked cell")
	route._records[-1].geometry_locked = false
	route._records[-1].state = TrackCellRecordScript.State.BUILDING
	route.rollback_last_unlocked_ghost(observed[-1].route_serial)
	assert_equal(route.get_records().size(), 3, "Rollback rejects a building tail")
	assert_equal(route.cancel_ghost_suffix(Vector2i(2, 0)), 0, "Cancellation rejects a later building cell")
	route._records[-1].state = TrackCellRecordScript.State.RESERVED_GHOST
	route._records[1].state = TrackCellRecordScript.State.BUILT
	assert_equal(route.cancel_ghost_suffix(Vector2i(2, 0)), 0, "Cancellation rejects a built target")
	assert_equal(route.get_available_track_cells(), 1, "Rejected mutations never refund inventory")
	assert_true(route.is_conservation_valid(), "Rejected mutations keep exact conservation")


func _test_serial_and_nominal_distance_continuity() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 5)
	var initial: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	route.append_candidates(initial)
	var before = route.get_records()
	for index in range(before.size()):
		assert_equal(before[index].route_serial, index + 1, "Route serial is monotonic")
		assert_equal(before[index].route_distance_start_cells, float(index), "Nominal start is absolute")
	assert_equal(route.cancel_ghost_suffix(Vector2i(2, 0)), 2, "Canceled branch removed")
	var replacement: Array[Vector2i] = [Vector2i(1, 1)]
	assert_equal(route.append_candidates(replacement), 1, "Replacement branch accepted")
	var after = route.get_records()
	assert_equal(after[1].route_serial, 4, "Canceled serials are never reused")
	assert_equal(after[1].route_distance_start_cells, 1.0, "Distance continues from retained endpoint")


func _test_invalid_buffer_stops_immediately() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 4)
	var initial: Array[Vector2i] = [Vector2i(1, 0)]
	route.append_candidates(initial)
	var buffered: Array[Vector2i] = [Vector2i(2, 0), Vector2i(1, 0), Vector2i(2, 1)]
	assert_equal(route.append_candidates(buffered), 1, "Only cells before the duplicate are accepted")
	assert_equal(route.get_endpoint_cell(), Vector2i(2, 0), "Candidates after invalid duplicate are ignored")
	assert_equal(route.get_available_track_cells(), 2, "Only two active cells are charged")
	assert_true(route.is_conservation_valid(), "Stopped buffer keeps exact conservation")


func _test_departure_anchor_reuse_follows_recovery_boundary() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 10)
	var buffered: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1),
		Vector2i(0, 0), Vector2i(0, -1),
	]
	assert_equal(route.append_candidates(buffered), 3, "Departure anchor stops the buffer before recovery")
	assert_equal(route.get_endpoint_cell(), Vector2i(0, 1), "Cells after pre-recovery departure re-entry are ignored")
	assert_equal(route.get_available_track_cells(), 7, "Only three pre-recovery route cells are charged")
	var replacement_through_departure: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
	assert_false(
		route.replace_span_in_place(2, 3, replacement_through_departure),
		"Span replacement cannot reuse departure before recovery"
	)

	route._records[0].state = TrackCellRecordScript.State.BUILT
	route._records[0].build_progress = 1.0
	assert_equal(route.recover_eligible_cells(1.0).size(), 1, "Recovery advances beyond the free origin")
	assert_equal(route.get_active_predecessor_cell(), Vector2i(1, 0), "Recovered cell becomes the active predecessor")
	var replacement_succeeded := route.replace_span_in_place(2, 3, replacement_through_departure)
	assert_true(
		replacement_succeeded,
		"Span replacement may reuse departure after recovery advances beyond it"
	)
	if replacement_succeeded:
		assert_equal(route.get_records()[0].cell, Vector2i(0, 0), "Replacement publishes the reused departure coordinate")
	assert_true(route.is_conservation_valid(), "Replacement keeps exact conservation")

	var reuse_route = TrackCellSequenceScript.new(Vector2i(0, 0), 12)
	assert_equal(reuse_route.append_candidates([
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1),
	]), 3, "Reuse fixture appends its initial route")
	reuse_route._records[0].state = TrackCellRecordScript.State.BUILT
	reuse_route._records[0].build_progress = 1.0
	assert_equal(reuse_route.recover_eligible_cells(1.0).size(), 1, "Reuse fixture recovers its first cell")
	var inventory_before_reuse: int = reuse_route.get_available_track_cells()
	var reused_count := reuse_route.append_candidates([
		Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(-1, 0),
	])
	assert_equal(reused_count, 4, "Recovered departure accepts an ordinary route through the historical coordinate")
	if reused_count != 4:
		return
	var reused_records = reuse_route.get_records()
	assert_equal(reused_records[2].cell, Vector2i(0, 0), "Reused departure is an active route record")
	assert_equal(reused_records[2].route_serial, 4, "Reused departure receives a fresh monotonic serial")
	assert_equal(reused_records[2].route_distance_start_cells, 3.0, "Reused departure receives a fresh absolute distance")
	assert_equal(reuse_route.get_available_track_cells(), inventory_before_reuse - 4, "Reused route charges every ordinary cell")
	assert_true(reuse_route.try_append_candidate(Vector2i(0, 0)) == null, "Active departure occurrence remains unique")

	for record in reuse_route._records:
		record.state = TrackCellRecordScript.State.BUILT
		record.build_progress = 1.0
	assert_equal(reuse_route.recover_eligible_cells(4.0).size(), 3, "Recovery advances through the reused departure record")
	assert_equal(reuse_route.get_active_predecessor_cell(), Vector2i(0, 0), "Reused departure becomes the active predecessor boundary")
	assert_true(reuse_route.try_append_candidate(Vector2i(0, 0)) == null, "Immediate predecessor departure cannot be reserved again")
	assert_equal(reuse_route.recover_eligible_cells(5.0).size(), 1, "Recovery advances beyond the reused departure boundary")
	assert_equal(reuse_route.get_active_predecessor_cell(), Vector2i(0, -1), "Later recovery clears the departure boundary")
	var second_reuse = reuse_route.try_append_candidate(Vector2i(0, 0))
	assert_not_null(second_reuse, "Departure becomes eligible again after recovery advances")
	if second_reuse != null:
		assert_equal(second_reuse.route_serial, 8, "Second reuse keeps the serial watermark monotonic")
		assert_equal(second_reuse.route_distance_start_cells, 7.0, "Second reuse keeps absolute distance monotonic")
	assert_true(reuse_route.is_conservation_valid(), "Recovered departure reuse keeps exact conservation")


func _test_start_building_does_not_lock_geometry() -> void:
	var sequence = TrackCellSequenceScript.new(Vector2i.ZERO, 3)
	assert_not_null(sequence.try_append_candidate(Vector2i(1, 0)), "Fixture record")
	var piece = TrackGeometryPieceScript.new()
	piece.group_id = 0
	piece.first_route_serial = 1
	piece.last_route_serial = 1
	piece.nominal_length_cells = 1
	var footprint_cells: Array[Vector2i] = [Vector2i(1, 0)]
	piece.footprint_cells = footprint_cells
	piece.centerline = PackedVector2Array([Vector2(20.0, 20.0), Vector2(60.0, 20.0)])
	sequence.apply_resolved_geometry([piece])
	sequence.start_building(1)
	var record = sequence.get_records()[0]
	assert_equal(record.state, TrackCellRecordScript.State.BUILDING, "Construction starts")
	assert_false(record.geometry_locked, "Construction state does not lock geometry")


func _test_endpoint_reshape_replacement_preserves_identity() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(-1, 0), 5)
	route.append_candidates([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	])
	route._records[1].state = TrackCellRecordScript.State.BUILDING
	route._records[1].build_progress = 0.25
	route._records[1].geometry_group_id = 9
	var before = route.get_records()
	var inventory_before: int = route.get_available_track_cells()
	print("Endpoint reshape: replacement preserves identity")
	assert_true(route.has_method("replace_span_in_place"), "Span replacement contract exists")
	if not route.has_method("replace_span_in_place"):
		return
	var replacement_cells: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1),
	]
	var replaced = route.call(
		"replace_span_in_place",
		2,
		4,
		replacement_cells
	)
	assert_true(replaced, "Equal-length span replacement succeeds")
	if not replaced:
		return
	var after = route.get_records()
	assert_equal(after.size(), before.size(), "Replacement preserves record count")
	assert_equal(route.get_available_track_cells(), inventory_before, "Replacement does not charge inventory")
	for index in range(before.size()):
		assert_equal(after[index].route_serial, before[index].route_serial, "Replacement preserves route serial")
		assert_equal(after[index].route_distance_start_cells, before[index].route_distance_start_cells, "Replacement preserves nominal distance")
		assert_equal(after[index].state, before[index].state, "Replacement preserves construction state")
		assert_equal(after[index].build_progress, before[index].build_progress, "Replacement preserves build progress")
		assert_equal(after[index].geometry_group_id, before[index].geometry_group_id, "Replacement preserves geometry identity")
	assert_equal(after[0].cell, before[0].cell, "Replacement leaves prefix cell unchanged")
	assert_equal(after[1].cell, Vector2i(1, 0), "Replacement applies first span cell")
	assert_equal(after[2].cell, Vector2i(1, 1), "Replacement applies second span cell")
	assert_equal(after[3].cell, Vector2i(2, 1), "Replacement applies third span cell")
	assert_true(route.is_conservation_valid(), "Replacement preserves conservation")

	var gap_route = TrackCellSequenceScript.new(Vector2i(-1, 0), 6)
	gap_route.append_candidates([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	])
	assert_equal(gap_route.cancel_ghost_suffix(Vector2i(1, 0)), 2, "Consumed suffix creates an active serial gap")
	gap_route._records[0].state = TrackCellRecordScript.State.BUILT
	gap_route._records[0].build_progress = 1.0
	gap_route._records[0].geometry_group_id = 7
	assert_equal(gap_route.append_candidates([Vector2i(1, 0)]), 1, "Fresh later record fills the active route")
	var first_gap_record = gap_route._records[0]
	var second_gap_record = gap_route._records[1]
	second_gap_record.state = TrackCellRecordScript.State.BUILDING
	second_gap_record.build_progress = 0.25
	second_gap_record.geometry_group_id = 9
	var first_gap_ref = first_gap_record
	var second_gap_ref = second_gap_record
	var gap_inventory_before: int = gap_route.get_available_track_cells()
	var gap_replacement: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
	assert_true(gap_route.call("replace_span_in_place", 1, 4, gap_replacement), "Serial-gap span replacement locates records by identity")
	var gap_records = gap_route.get_records()
	assert_equal(gap_records.size(), 2, "Serial-gap replacement preserves active record count")
	if gap_records.size() == 2:
		assert_equal(gap_records[0].route_serial, 1, "Serial-gap replacement preserves first serial")
		assert_equal(gap_records[1].route_serial, 4, "Serial-gap replacement preserves fresh later serial")
		assert_equal(gap_route._records[0], first_gap_ref, "Serial-gap replacement preserves first record identity")
		assert_equal(gap_route._records[1], second_gap_ref, "Serial-gap replacement preserves second record identity")
		assert_equal(gap_records[0].state, TrackCellRecordScript.State.BUILT, "Serial-gap replacement preserves first build state")
		assert_equal(gap_records[0].build_progress, 1.0, "Serial-gap replacement preserves first build progress")
		assert_equal(gap_records[0].geometry_group_id, 7, "Serial-gap replacement preserves first geometry identity")
		assert_equal(gap_records[1].state, TrackCellRecordScript.State.BUILDING, "Serial-gap replacement preserves second build state")
		assert_equal(gap_records[1].build_progress, 0.25, "Serial-gap replacement preserves second build progress")
		assert_equal(gap_records[1].geometry_group_id, 9, "Serial-gap replacement preserves second geometry identity")
		assert_equal(gap_records[0].cell, Vector2i(0, 0), "Serial-gap replacement applies first cell")
		assert_equal(gap_records[1].cell, Vector2i(0, 1), "Serial-gap replacement applies second cell")
	assert_equal(gap_route.get_available_track_cells(), gap_inventory_before, "Serial-gap replacement does not charge inventory")
	assert_equal(gap_route._active_cells.size(), gap_route.get_records().size(), "Serial-gap replacement preserves uniqueness")
	assert_true(gap_route.is_conservation_valid(), "Serial-gap replacement preserves conservation")


func _test_crossing_occurrence_counts_and_identity_conserve_inventory() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 12)
	assert_equal(route.append_candidates([
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(3, 1), Vector2i(3, 2), Vector2i(2, 2), Vector2i(2, 1),
	]), 7, "Crossing sequence fixture appends its unique approach")
	route._records[1].geometry_locked = true
	assert_true(route.try_append_candidate(Vector2i(2, 0)) == null, "Duplicate cells remain rejected without explicit crossing authority")
	assert_true(route.try_append_candidate(Vector2i(2, 0), true, 1) == null, "Crossing authority requires the exact earlier serial")
	var crossing = route.try_append_candidate(Vector2i(2, 0), true, 2)
	assert_not_null(crossing, "Explicit crossing authority creates one later occurrence")
	if crossing == null:
		return
	assert_not_null(route.try_append_candidate(Vector2i(2, -1)), "A crossing remains incomplete until its opposite-side exit exists")
	assert_equal(route.get_active_occurrence_count(Vector2i(2, 0)), 2, "Crossing cell counts both ordered occurrences")
	assert_equal(route._active_cells.size(), route.get_records().size() - 1, "Only the crossing coordinate is shared")
	assert_equal(route.get_available_track_cells(), 3, "Every crossing occurrence consumes one inventory cell")
	assert_true(route.is_conservation_valid(), "Perpendicular crossing topology preserves occurrence-based conservation")
	var observed := route.get_records()
	assert_true(observed[-2].grade_separated_crossing, "Later occurrence retains crossing identity")
	assert_equal(observed[-2].crossing_partner_route_serial, 2, "Later occurrence retains exact partner identity")
	observed[-2].grade_separated_crossing = false
	assert_true(route.get_records()[-2].grade_separated_crossing, "Crossing identity observations remain detached")
	assert_false(route.replace_span_in_place(8, 9, [Vector2i(2, 0), Vector2i(2, -1)]), "Template replacement cannot mutate a paid crossing identity")
	assert_equal(route.cancel_ghost_suffix_from_serial(8), 2, "Exact crossing serial cancels its complete ghost suffix")
	assert_equal(route.get_active_occurrence_count(Vector2i(2, 0)), 1, "Crossing cancellation retains the earlier occurrence count")
	assert_equal(route.get_available_track_cells(), 5, "Crossing suffix cancellation refunds its route occurrences")
	assert_true(route.is_conservation_valid(), "Crossing cancellation restores ordinary conservation")
