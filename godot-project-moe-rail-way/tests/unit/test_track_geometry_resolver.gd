extends "res://tests/support/prototype_test.gd"

const TrackCellSequenceScript = preload("res://src/domain/track/track_cell_sequence.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackGeometryResolutionScript = preload("res://src/domain/track/track_geometry_resolution.gd")
const TrackGeometryResolverScript = preload("res://src/domain/track/track_geometry_resolver.gd")

const STRAIGHT := 0
const CURVE_1X1 := 1
const CURVE_2X2 := 2
const CURVE_3X3 := 3
const DEPARTURE := Vector2i(-1, 0)

var _resolver = TrackGeometryResolverScript.new()


func run() -> PackedStringArray:
	_test_route_zero_starts_at_departure_center()
	_test_curve_growth_reclassifies_without_changing_cell_count()
	_test_overlapping_curves_downgrade_both()
	_test_anchor_forces_centerline_contact()
	_test_exact_anchor_knots_preserve_template_contracts()
	_test_nonzero_grid_origin_translates_every_centerline()
	_test_nominal_lengths_sampling_and_grid_bounds()
	_test_non_final_curve_continuity_and_one_cell_tangents()
	_test_non_owned_route_cell_in_curve_footprint()
	_test_locked_piece_identity_and_determinism()
	_test_empty_acceptance_and_final_conflict_rejection()
	_test_detached_duplicates()
	_test_exit_support_metadata_copies_with_active_slices()
	return finish()


func _test_exact_anchor_knots_preserve_template_contracts() -> void:
	var exact_anchor = RouteContactAnchorScript.new(&"warp_exact", Vector2i(0, 0))
	var has_mode := _object_has_property(exact_anchor, &"contact_mode")
	assert_true(has_mode, "Route anchors expose a concrete contact mode")
	if not has_mode:
		return
	exact_anchor.set(&"contact_mode", 1)
	var straight_records := _records_for([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	exact_anchor.cell = Vector2i(1, 0)
	var straight_result = _resolver.resolve(
		DEPARTURE, straight_records, [], [exact_anchor],
		Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_true(straight_result.is_valid, "Exact anchored straight resolves")
	if straight_result.is_valid:
		var straight = _piece_covering_serial(straight_result.pieces, straight_records[1].route_serial)
		assert_equal(straight.centerline.size(), 2, "Exact anchored straight preserves two-point geometry")
		assert_true(
			straight.sample_nominal(0.5).position.distance_to(Vector2(60.0, 20.0)) <= 0.0001,
			"Exact anchored straight passes its literal cell center at nominal midpoint"
		)

	_assert_exact_curve_orientations(
		[Vector2i(0, 0), Vector2i(0, 1)], 0, CURVE_1X1, "1x1"
	)
	_assert_exact_curve_orientations(
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)], 1, CURVE_2X2, "2x2"
	)
	_assert_exact_curve_orientations(
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)],
		2, CURVE_3X3, "3x3"
	)


func _assert_exact_curve_orientations(
	base_cells: Array,
	anchor_offset: int,
	expected_kind: int,
	label: String
) -> void:
	var bases := [
		[Vector2i(1, 0), Vector2i(0, 1)],
		[Vector2i(0, 1), Vector2i(-1, 0)],
		[Vector2i(-1, 0), Vector2i(0, -1)],
		[Vector2i(0, -1), Vector2i(1, 0)],
		[Vector2i(-1, 0), Vector2i(0, 1)],
		[Vector2i(0, 1), Vector2i(1, 0)],
		[Vector2i(1, 0), Vector2i(0, -1)],
		[Vector2i(0, -1), Vector2i(-1, 0)],
	]
	for orientation in range(bases.size()):
		var basis_x: Vector2i = bases[orientation][0]
		var basis_y: Vector2i = bases[orientation][1]
		var offset := Vector2i(5, 5)
		var departure := _transform_cell(DEPARTURE, basis_x, basis_y) + offset
		var cells: Array[Vector2i] = []
		for base_cell in base_cells:
			cells.append(_transform_cell(base_cell, basis_x, basis_y) + offset)
		_assert_exact_curve_fixture(
			cells, anchor_offset, expected_kind,
			"%s orientation %d" % [label, orientation], departure
		)


func _transform_cell(cell: Vector2i, basis_x: Vector2i, basis_y: Vector2i) -> Vector2i:
	return basis_x * cell.x + basis_y * cell.y


func _assert_exact_curve_fixture(
	cells: Array,
	anchor_offset: int,
	expected_kind: int,
	label: String,
	departure: Vector2i = DEPARTURE
) -> void:
	var records := _records_for(cells, departure)
	var anchor_cell: Vector2i = records[anchor_offset].cell
	var baseline = _resolver.resolve(
		departure, records, [], [], Vector2.ZERO, Vector2i(12, 12), 40.0
	)
	var baseline_piece = _piece_covering_serial(
		baseline.pieces, records[anchor_offset].route_serial
	) if baseline.is_valid else null
	var anchor = RouteContactAnchorScript.new(&"warp_exact", anchor_cell)
	anchor.set(&"contact_mode", 1)
	var result = _resolver.resolve(
		departure, records, [], [anchor], Vector2.ZERO, Vector2i(12, 12), 40.0
	)
	assert_true(result.is_valid, "%s exact anchored curve resolves" % label)
	if not result.is_valid:
		return
	var piece = _piece_covering_serial(result.pieces, records[anchor_offset].route_serial)
	assert_not_null(piece, "%s exact anchor has one owning piece" % label)
	if piece == null:
		return
	assert_equal(piece.kind, expected_kind, "%s retains its accepted template kind" % label)
	assert_not_null(baseline_piece, "%s has a pre-anchor accepted owner" % label)
	if baseline_piece != null:
		assert_equal(
			piece.footprint_cells, baseline_piece.footprint_cells,
			"%s exact anchor preserves the accepted footprint byte-for-byte" % label
		)
	assert_false(
		piece.footprint_cells.has(departure),
		"%s departure lead-in never becomes route footprint ownership" % label
	)
	assert_equal(
		piece.centerline.size(), piece.nominal_length_cells * 16 + 1,
		"%s anchored curve uses fixed nominal sampling" % label
	)
	var expected_center := (Vector2(anchor_cell) + Vector2(0.5, 0.5)) * 40.0
	var local_offset: float = float(records[anchor_offset].route_distance_start_cells) \
		- piece.absolute_start_distance_cells + 0.5
	assert_true(
		piece.sample_nominal(local_offset).position.distance_to(expected_center) <= 0.0001,
		"%s passes the literal cell center at its nominal knot" % label
	)
	var turn_index := _first_turn_index(departure, records)
	var previous: Vector2i = departure if turn_index == 0 else records[turn_index - 1].cell
	var incoming := Vector2(records[turn_index].cell - previous).normalized()
	var outgoing := Vector2(records[turn_index + 1].cell - records[turn_index].cell).normalized()
	assert_true(piece.sample_nominal(0.0).heading.is_equal_approx(incoming), "%s preserves operational entry heading" % label)
	assert_true(piece.sample_nominal(float(piece.nominal_length_cells)).heading.is_equal_approx(outgoing), "%s preserves operational exit heading" % label)
	var first_chord_heading: Vector2 = (piece.centerline[1] - piece.centerline[0]).normalized()
	var last_chord_heading: Vector2 = (piece.centerline[-1] - piece.centerline[-2]).normalized()
	assert_true(
		piece.sample_nominal(1.0 / 32.0).heading.is_equal_approx(first_chord_heading),
		"%s entry heading override applies only at the exact boundary" % label
	)
	assert_true(
		piece.sample_nominal(float(piece.nominal_length_cells) - 1.0 / 32.0).heading.is_equal_approx(last_chord_heading),
		"%s exit heading override applies only at the exact boundary" % label
	)
	for sample_index in range(1, piece.centerline.size() - 1):
		var point: Vector2 = piece.centerline[sample_index]
		var cell := Vector2i(int(floor(point.x / 40.0)), int(floor(point.y / 40.0)))
		assert_true(
			piece.footprint_cells.has(cell) or cell == departure,
			"%s interior sample %d remains inside footprint or the departure lead-in" % [label, sample_index]
		)
	var replay = _resolver.resolve(
		departure, records, [], [anchor], Vector2.ZERO, Vector2i(12, 12), 40.0
	)
	var replay_piece = _piece_covering_serial(replay.pieces, records[anchor_offset].route_serial)
	assert_equal(replay_piece.centerline, piece.centerline, "%s exact geometry replays deterministically" % label)


func _first_turn_index(departure: Vector2i, records: Array) -> int:
	for index in range(records.size() - 1):
		var previous: Vector2i = departure if index == 0 else records[index - 1].cell
		if records[index].cell - previous != records[index + 1].cell - records[index].cell:
			return index
	return -1


func _object_has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if property.get("name", StringName()) == property_name:
			return true
	return false


func _test_route_zero_starts_at_departure_center() -> void:
	var departure := Vector2i(0, 0)
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	var sequence = TrackCellSequenceScript.new(departure, 4)
	assert_equal(sequence.append_candidates(cells), cells.size(), "Fixture cells accepted")
	var result = _resolver.resolve(
		departure,
		sequence.get_records(),
		[],
		[],
		Vector2(10.0, 10.0),
		Vector2i(8, 8),
		40.0
	)
	assert_true(result.is_valid, "Departure route resolves")
	if result.is_valid and not result.pieces.is_empty():
		assert_equal(
			result.pieces[0].sample_nominal(0.0).position,
			Vector2(30.0, 30.0),
			"Route distance zero starts at the snapped departure center"
		)


func _test_curve_growth_reclassifies_without_changing_cell_count() -> void:
	var four = _records_for([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)])
	var result = _resolve(four)
	assert_true(result.is_valid, "Four-cell route resolves")
	_assert_piece_kinds(result.pieces, [STRAIGHT, CURVE_2X2])
	assert_equal(_total_nominal_cells(result.pieces), 4, "Four nominal cells")
	var five = _abcde_records()
	result = _resolve(five)
	assert_true(result.is_valid, "Five-cell route resolves")
	_assert_piece_kinds(result.pieces, [CURVE_3X3])
	assert_equal(_total_nominal_cells(result.pieces), 5, "Five nominal cells")


func _test_overlapping_curves_downgrade_both() -> void:
	var result = _resolve(_close_double_turn_records(), Vector2i(12, 12))
	assert_true(result.is_valid, "Double turn resolves")
	assert_equal(_curve_sizes(result.pieces), [1, 1], "Both curves downgrade until ownership is disjoint")
	assert_equal(_total_nominal_cells(result.pieces), 7, "Double turn covers seven nominal cells")
	_assert_each_serial_owned_once(result.pieces, _close_double_turn_records())


func _test_anchor_forces_centerline_contact() -> void:
	var anchor = RouteContactAnchorScript.new(&"warp_d", Vector2i(2, 1))
	var anchors: Array = [anchor]
	var result = _resolver.resolve(
		DEPARTURE, _abcde_records(), [], anchors,
		Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_true(result.is_valid, "Anchored route resolves")
	var piece = _piece_covering_serial(result.pieces, 3)
	assert_not_null(piece, "Turn serial has one geometry piece")
	if piece != null:
		assert_true(piece.contacts_cell(anchor.cell, Vector2.ZERO, 40.0), "Centerline contacts anchor")
		assert_equal(piece.kind, CURVE_2X2, "Anchor selects the largest contacting curve")
		_assert_centerline_never_reverses(piece.centerline, Vector2.RIGHT, Vector2.DOWN)


func _test_nonzero_grid_origin_translates_every_centerline() -> void:
	var records = _abcde_records()
	var zero = _resolver.resolve(DEPARTURE, records, [], [], Vector2.ZERO, Vector2i(8, 8), 40.0)
	var shifted = _resolver.resolve(DEPARTURE, records, [], [], Vector2(10, 10), Vector2i(8, 8), 40.0)
	assert_equal(shifted.pieces[0].centerline[0], zero.pieces[0].centerline[0] + Vector2(10, 10), "Origin translates start")
	assert_equal(shifted.pieces[-1].centerline[-1], zero.pieces[-1].centerline[-1] + Vector2(10, 10), "Origin translates end")


func _test_nominal_lengths_sampling_and_grid_bounds() -> void:
	var one = _records_for([Vector2i(0, 0), Vector2i(0, 1)])
	var one_result = _resolve(one)
	var one_curve = _first_curve(one_result.pieces)
	assert_not_null(one_curve, "One-cell curve resolves")
	if one_curve != null:
		assert_equal(one_curve.kind, CURVE_1X1, "Small route uses 1x1")
		assert_equal(one_curve.nominal_length_cells, 1, "1x1 nominal length")
	var two_curve = _first_curve(_resolve(_records_for([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)])).pieces)
	assert_equal(two_curve.nominal_length_cells, 3, "2x2 nominal length")
	var three_curve = _first_curve(_resolve(_abcde_records()).pieces)
	assert_equal(three_curve.nominal_length_cells, 5, "3x3 nominal length")
	var before = three_curve.sample_nominal(-10.0)
	var after = three_curve.sample_nominal(99.0)
	var middle = three_curve.sample_nominal(2.5)
	assert_equal(before.position, three_curve.centerline[0], "Sampling clamps before start")
	assert_equal(after.position, three_curve.centerline[-1], "Sampling clamps after end")
	assert_true(is_equal_approx(middle.heading.length(), 1.0), "Sampling returns unit heading")
	assert_true(three_curve.sample_nominal(0.0).heading.dot(Vector2.RIGHT) > 0.999, "Curve entry heading is continuous")
	assert_true(three_curve.sample_nominal(5.0).heading.dot(Vector2.DOWN) > 0.999, "Curve exit heading is continuous")
	var edge_records = _records_for([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	])
	var edge = _resolver.resolve(DEPARTURE, edge_records, [], [], Vector2.ZERO, Vector2i(3, 3), 40.0)
	assert_true(edge.is_valid, "In-bounds grid-edge turn resolves")
	assert_equal(_first_curve(edge.pieces).kind, CURVE_3X3, "Grid edge does not cause a curve downgrade")
	for piece in edge.pieces:
		for cell in piece.footprint_cells:
			assert_true(cell.x >= 0 and cell.x < 3 and cell.y >= 0 and cell.y < 3, "Footprint stays in grid")
	var outside_records = _records_for([Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)])
	var outside = _resolver.resolve(DEPARTURE, outside_records, [], [], Vector2.ZERO, Vector2i(1, 2), 40.0)
	assert_true(not outside.is_valid, "Out-of-bounds route record is rejected before curve sizing")
	assert_equal(outside.reason, &"grid_bounds", "Grid rejection names the boundary reason")


func _test_non_final_curve_continuity_and_one_cell_tangents() -> void:
	var extended = _records_for([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3),
	])
	var extended_result = _resolve(extended)
	assert_true(extended_result.is_valid, "Extended route resolves")
	_assert_piece_kinds(extended_result.pieces, [CURVE_3X3, STRAIGHT])
	var curve = extended_result.pieces[0]
	var following = extended_result.pieces[1]
	assert_equal(curve.centerline[-1], following.centerline[0], "Curve and following straight share one boundary")
	assert_true(curve.sample_nominal(5.0).heading.dot(Vector2.DOWN) > 0.999, "Curve exits along the route")
	assert_true(following.sample_nominal(0.0).heading.dot(Vector2.DOWN) > 0.999, "Following straight enters along the route")

	var one_curve = _first_curve(_resolve(_records_for([Vector2i(0, 0), Vector2i(0, 1)])).pieces)
	var first_chord: Vector2 = one_curve.centerline[1] - one_curve.centerline[0]
	var last_chord: Vector2 = one_curve.centerline[-1] - one_curve.centerline[-2]
	assert_true(is_zero_approx(first_chord.y), "1x1 entry chord is exactly horizontal")
	assert_true(first_chord.normalized().dot(Vector2.RIGHT) > 0.999, "1x1 entry heading follows the route")
	assert_true(is_zero_approx(last_chord.x), "1x1 exit chord is exactly vertical")
	assert_true(last_chord.normalized().dot(Vector2.DOWN) > 0.999, "1x1 exit heading follows the route")


func _test_non_owned_route_cell_in_curve_footprint() -> void:
	var records = _records_for([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2), Vector2i(1, 2),
	])
	assert_true(
		_resolver._footprint_contains_non_owned_record({"turn_index": 2, "radius": 3}, records),
		"Curve footprint detects a realizable non-owned route cell"
	)
	var result = _resolve(records)
	assert_true(result.is_valid, "Route with a non-owned footprint cell resolves by downgrade")
	for piece in result.pieces:
		if piece.kind == STRAIGHT:
			continue
		for record in records:
			if not piece.contains_serial(record.route_serial):
				assert_true(
					not piece.footprint_cells.has(record.cell),
					"Resolved curve footprint excludes every non-owned route cell"
				)


func _test_locked_piece_identity_and_determinism() -> void:
	var records = _abcde_records()
	var first = _resolve(records)
	var locked = first.pieces[0].duplicate_piece()
	locked.locked = true
	var locked_pieces: Array = [locked]
	var repeated = _resolver.resolve(DEPARTURE, records, locked_pieces, [], Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_true(repeated.is_valid, "Locked route resolves")
	assert_equal(_piece_signature(repeated.pieces[0]), _piece_signature(locked), "Locked piece values stay byte-stable")
	assert_true(repeated.pieces[0] != locked, "Locked observation is detached")
	var deterministic = _resolve(records)
	assert_equal(_resolution_signature(first), _resolution_signature(deterministic), "Repeated resolution is deterministic")
	first.pieces[0].centerline[0] += Vector2(999, 999)
	assert_true(first.pieces[0].centerline[0] != deterministic.pieces[0].centerline[0], "Resolution observations are detached")
	var surviving_records: Array = records.slice(2)
	var sliced = _resolver.resolve(DEPARTURE, surviving_records, locked_pieces, [], Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_true(sliced.is_valid, "Partially surviving locked piece resolves")
	assert_equal(sliced.pieces[0].active_local_start_cells, 2.0, "Locked active slice starts at surviving absolute distance")
	assert_equal(sliced.pieces[0].active_local_end_cells, 5.0, "Locked active slice keeps full surviving end")
	assert_equal(sliced.pieces[0].centerline, locked.centerline, "Partial slice preserves full locked centerline")
	var reentry_records = _records_for([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2), Vector2i(1, 2), Vector2i(1, 1),
	])
	var blocked = _resolver.resolve(DEPARTURE, reentry_records, locked_pieces, [], Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_true(not blocked.is_valid, "Unlocked suffix cannot enter active locked footprint")


func _test_empty_acceptance_and_final_conflict_rejection() -> void:
	var empty = _resolver.resolve(DEPARTURE, [], [], [], Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_true(empty.is_valid, "Empty route is accepted")
	assert_equal(empty.pieces.size(), 0, "Empty route has no pieces")
	assert_equal(empty.rejected_route_serial, -1, "Accepted empty route rejects no serial")
	var records = _records_for([Vector2i(0, 0), Vector2i(0, 1)])
	var blocker = TrackGeometryPieceScript.new()
	blocker.group_id = 99
	blocker.kind = CURVE_1X1
	blocker.first_route_serial = 99
	blocker.last_route_serial = 99
	blocker.nominal_length_cells = 1
	var blocker_footprint: Array[Vector2i] = [Vector2i(0, 0)]
	blocker.footprint_cells = blocker_footprint
	blocker.centerline = PackedVector2Array([Vector2(20, 20), Vector2(20, 60)])
	blocker.locked = true
	var locked: Array = [blocker]
	var rejected = _resolver.resolve(DEPARTURE, records, locked, [], Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_true(not rejected.is_valid, "Unresolved final 1x1 conflict rejects")
	assert_equal(rejected.rejected_route_serial, records[-1].route_serial, "Newest serial is rejected")
	assert_true(not rejected.reason.is_empty(), "Rejection names a reason")


func _test_detached_duplicates() -> void:
	var anchor = RouteContactAnchorScript.new(&"warp", Vector2i(4, 2))
	var anchor_copy = anchor.duplicate_anchor()
	anchor_copy.cell = Vector2i.ZERO
	assert_equal(anchor.cell, Vector2i(4, 2), "Anchor duplicate is detached")
	var result = _resolve(_abcde_records())
	var result_copy = result.duplicate_resolution()
	result_copy.pieces[0].footprint_cells.clear()
	assert_true(not result.pieces[0].footprint_cells.is_empty(), "Resolution duplicate is detached")
	var slice = result.pieces[0].duplicate_active_slice(1.0, 3.0)
	assert_equal(slice.active_local_start_cells, 1.0, "Active slice copies start")
	assert_equal(slice.active_local_end_cells, 3.0, "Active slice copies end")


func _test_exit_support_metadata_copies_with_active_slices() -> void:
	var result = _resolve(_abcde_records())
	var piece = result.pieces[0]
	piece.locked = true
	piece.exit_support_route_serial = 6
	var piece_copy = piece.duplicate_piece()
	var active_slice = piece.duplicate_active_slice(1.0, 4.0)
	assert_equal(piece_copy.exit_support_route_serial, 6, "Piece copy retains immutable support metadata")
	assert_equal(active_slice.exit_support_route_serial, 6, "Active slice retains immutable support metadata")
	assert_equal(active_slice.active_local_start_cells, 1.0, "Support slice stores its active start")
	assert_equal(active_slice.active_local_end_cells, 4.0, "Support slice stores its active end")
	active_slice.exit_support_route_serial = 7
	assert_equal(piece.exit_support_route_serial, 6, "Active slice support metadata is detached")


func _records_for(source_cells: Array, departure: Vector2i = DEPARTURE) -> Array:
	var cells: Array[Vector2i] = []
	for cell in source_cells:
		cells.append(cell)
	var sequence = TrackCellSequenceScript.new(departure, 32)
	assert_equal(sequence.append_candidates(cells), cells.size(), "Fixture cells accepted")
	return sequence.get_records()


func _abcde_records() -> Array:
	return _records_for([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	])


func _close_double_turn_records() -> Array:
	return _records_for([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
	])


func _resolve(records: Array, grid_size := Vector2i(8, 8)):
	return _resolver.resolve(DEPARTURE, records, [], [], Vector2.ZERO, grid_size, 40.0)


func _total_nominal_cells(pieces: Array) -> int:
	var total := 0
	for piece in pieces:
		total += piece.nominal_length_cells
	return total


func _piece_covering_serial(pieces: Array, route_serial: int):
	for piece in pieces:
		if piece.contains_serial(route_serial):
			return piece
	return null


func _first_curve(pieces: Array):
	for piece in pieces:
		if piece.kind != STRAIGHT:
			return piece
	return null


func _curve_sizes(pieces: Array) -> Array[int]:
	var sizes: Array[int] = []
	for piece in pieces:
		if piece.kind == CURVE_1X1:
			sizes.append(1)
		elif piece.kind == CURVE_2X2:
			sizes.append(2)
		elif piece.kind == CURVE_3X3:
			sizes.append(3)
	return sizes


func _assert_piece_kinds(pieces: Array, expected: Array) -> void:
	assert_equal(pieces.size(), expected.size(), "Piece count")
	for index in range(mini(pieces.size(), expected.size())):
		assert_equal(pieces[index].kind, expected[index], "Piece kind %d" % index)


func _piece_signature(piece) -> Array:
	return [
		piece.group_id, piece.kind, piece.first_route_serial, piece.last_route_serial,
		piece.nominal_length_cells, piece.absolute_start_distance_cells,
		piece.footprint_cells, piece.centerline, piece.locked,
		piece.active_local_start_cells, piece.active_local_end_cells,
	]


func _resolution_signature(result) -> Array:
	var signatures := []
	for piece in result.pieces:
		signatures.append(_piece_signature(piece))
	return signatures


func _assert_each_serial_owned_once(pieces: Array, records: Array) -> void:
	for record in records:
		var owner_count := 0
		for piece in pieces:
			if piece.contains_serial(record.route_serial):
				owner_count += 1
		assert_equal(owner_count, 1, "Every route serial has exactly one geometry owner")


func _assert_centerline_never_reverses(
	centerline: PackedVector2Array,
	incoming: Vector2,
	outgoing: Vector2
) -> void:
	for index in range(centerline.size() - 1):
		var delta: Vector2 = centerline[index + 1] - centerline[index]
		assert_true(
			delta.dot(incoming) >= -0.0001,
			"Centerline never reverses against incoming at segment %d" % index
		)
		assert_true(
			delta.dot(outgoing) >= -0.0001,
			"Centerline never reverses against outgoing at segment %d" % index
		)
