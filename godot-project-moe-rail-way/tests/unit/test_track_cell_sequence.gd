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
	_test_departure_anchor_cannot_be_reserved_again()
	_test_start_building_does_not_lock_geometry()
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


func _test_departure_anchor_cannot_be_reserved_again() -> void:
	var route = TrackCellSequenceScript.new(Vector2i(0, 0), 10)
	var buffered: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1),
		Vector2i(0, 0), Vector2i(0, -1),
	]
	assert_equal(route.append_candidates(buffered), 3, "Departure anchor stops the buffer")
	assert_equal(route.get_endpoint_cell(), Vector2i(0, 1), "Cells after departure re-entry are ignored")
	assert_equal(route.get_available_track_cells(), 7, "Only three route cells are charged")
	assert_equal(route.get_records().size(), 3, "Departure anchor is never a route record")
	assert_true(route.is_conservation_valid(), "Rejected departure re-entry keeps conservation")


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
