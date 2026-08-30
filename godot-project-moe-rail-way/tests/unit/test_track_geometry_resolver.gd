extends "res://tests/support/prototype_test.gd"

const TrackCellSequenceScript = preload("res://src/domain/track/track_cell_sequence.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackGeometryResolutionScript = preload("res://src/domain/track/track_geometry_resolution.gd")
const TrackGeometryResolverScript = preload("res://src/domain/track/track_geometry_resolver.gd")

const STRAIGHT := 0
const CURVE_1X1 := 1
const CURVE_2X2 := 2
const CURVE_3X3 := 3
const DEPARTURE := Vector2i(-1, 0)
const MAX_LOCAL_CORNER_NONLINEAR_RUN := 9
const MAX_LOCAL_REVERSE_SEGMENT_RUN := 8
const MIN_STRAIGHT_SEGMENT_RUN := 4
const CENTERLINE_SEGMENTS_PER_NOMINAL_CELL := 16
const EXACT_KNOT_OFFSET_SAMPLES := CENTERLINE_SEGMENTS_PER_NOMINAL_CELL / 2
const LOCAL_CORNER_HALF_WINDOW_SAMPLES := 4
const TEST_CELL_SIZE := 40.0

var _resolver = TrackGeometryResolverScript.new()


func run() -> PackedStringArray:
	_test_track_geometry_piece_owns_centerline_queries()
	_test_route_zero_starts_at_departure_center()
	_test_curve_growth_reclassifies_without_changing_cell_count()
	_test_overlapping_curves_downgrade_both()
	_test_adjacent_turn_overlap_downgrades_only_larger_candidate()
	_test_irreducible_duplicate_turn_footprints_still_reject()
	_test_anchor_forces_centerline_contact()
	_test_unanchored_curve_orientations_use_local_corners()
	_test_right_edge_owned_turn_center_is_visible()
	_test_exact_anchor_knots_preserve_template_contracts()
	_test_terminal_exact_anchor_preserves_nonzero_exit_travel()
	_test_multiple_exact_knots_remain_literal_and_deterministic()
	_test_nonzero_grid_origin_translates_every_centerline()
	_test_nominal_lengths_sampling_and_grid_bounds()
	_test_non_final_curve_continuity_and_one_cell_tangents()
	_test_non_owned_route_cell_in_curve_footprint()
	_test_locked_piece_identity_and_determinism()
	_test_locked_aabb_empty_corner_uses_geometric_collision_occupancy()
	_test_locked_predecessor_stitches_anchored_turn_by_declared_heading()
	_test_empty_acceptance_and_final_conflict_rejection()
	_test_detached_duplicates()
	_test_exit_support_metadata_copies_with_active_slices()
	_test_grade_separated_crossing_exception_is_exact_and_perpendicular()
	return finish()


func _test_track_geometry_piece_owns_centerline_queries() -> void:
	var piece = TrackGeometryPieceScript.new()
	piece.nominal_length_cells = 2
	piece.centerline = PackedVector2Array([
		Vector2(20.0, 20.0),
		Vector2(60.0, 20.0),
		Vector2(60.0, 20.0),
		Vector2(100.0, 20.0),
	])
	var has_projection_query := piece.has_method("find_nominal_distance_at_position")
	var has_nominal_cell_query := piece.has_method("contacts_cell_in_nominal_range")
	assert_true(
		has_projection_query,
		"TrackGeometryPiece owns continuous point-to-nominal projection"
	)
	assert_true(
		has_nominal_cell_query,
		"TrackGeometryPiece owns nominal-range cell coverage"
	)
	if not has_projection_query or not has_nominal_cell_query:
		return
	assert_true(
		absf(piece.find_nominal_distance_at_position(Vector2(40.0, 20.0), 0.0001) - 1.0 / 3.0)
			<= 0.0001,
		"Interior segment projection uses uniform stored-index nominal distance"
	)
	assert_true(
		absf(piece.find_nominal_distance_at_position(Vector2(60.0, 20.0), 0.0001) - 2.0 / 3.0)
			<= 0.0001,
		"Repeated points preserve the earliest matching projection"
	)
	assert_equal(
		piece.find_nominal_distance_at_position(Vector2(40.0, 21.0), 0.0001),
		-1.0,
		"A target outside the logical-unit epsilon has no nominal projection"
	)
	assert_false(
		piece.contacts_cell_in_nominal_range(
			Vector2i(2, 0), Vector2.ZERO, 40.0, 0.0, 0.75, 8
		),
		"An inactive nominal prefix cannot report a later cell"
	)
	assert_true(
		piece.contacts_cell_in_nominal_range(
			Vector2i(2, 0), Vector2.ZERO, 40.0, 1.0, 2.0, 8
		),
		"The active nominal suffix reports its sampled cell"
	)


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


func _test_terminal_exact_anchor_preserves_nonzero_exit_travel() -> void:
	var records := _records_for([Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)])
	var anchor = RouteContactAnchorScript.new(
		&"terminal_exact",
		records[-1].cell,
		RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER
	)
	var result = _resolver.resolve(
		DEPARTURE, records, [], [anchor], Vector2.ZERO, Vector2i(8, 8), TEST_CELL_SIZE
	)
	assert_true(result.is_valid, "Terminal exact anchored curve resolves")
	if not result.is_valid:
		return
	var piece = _piece_covering_serial(result.pieces, records[-1].route_serial)
	assert_not_null(piece, "Terminal exact anchor keeps one curve owner")
	if piece == null:
		return
	var exact_index := (
		(records.size() - 1) * CENTERLINE_SEGMENTS_PER_NOMINAL_CELL
		+ EXACT_KNOT_OFFSET_SAMPLES
	)
	var expected_center := (Vector2(records[-1].cell) + Vector2(0.5, 0.5)) * TEST_CELL_SIZE
	assert_true(
		piece.centerline[exact_index].distance_to(expected_center) <= 0.0001,
		"Terminal exact anchor remains at its fixed midpoint sample"
	)
	assert_true(
		piece.centerline[-1].distance_to(piece.centerline[-2]) > 0.0001,
		"Terminal exact anchor preserves nonzero stored exit travel"
	)
	assert_true(
		(piece.centerline[-1] - piece.centerline[-2]).normalized().is_equal_approx(Vector2.DOWN),
		"Terminal exact support preserves the route exit heading"
	)
	for sample_index in range(exact_index + 1, piece.centerline.size()):
		var point: Vector2 = piece.centerline[sample_index]
		var cell := Vector2i(
			int(floor(point.x / TEST_CELL_SIZE)),
			int(floor(point.y / TEST_CELL_SIZE))
		)
		assert_equal(cell, records[-1].cell, "Terminal exact support stays in its owned cell")
	var replay = _resolver.resolve(
		DEPARTURE, records, [], [anchor], Vector2.ZERO, Vector2i(8, 8), TEST_CELL_SIZE
	)
	var replay_piece = _piece_covering_serial(replay.pieces, records[-1].route_serial)
	assert_equal(
		replay_piece.centerline,
		piece.centerline,
		"Terminal exact support replays deterministically"
	)


func _test_unanchored_curve_orientations_use_local_corners() -> void:
	_assert_unanchored_curve_orientations(
		[Vector2i(0, 0), Vector2i(0, 1)], CURVE_1X1, "unanchored 1x1"
	)
	_assert_unanchored_curve_orientations(
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
		CURVE_2X2,
		"unanchored 2x2"
	)
	_assert_unanchored_curve_orientations(
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)],
		CURVE_3X3,
		"unanchored 3x3"
	)


func _assert_unanchored_curve_orientations(
	base_cells: Array,
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
		_assert_unanchored_curve_fixture(
			cells,
			expected_kind,
			"%s orientation %d" % [label, orientation],
			departure
		)


func _assert_unanchored_curve_fixture(
	cells: Array,
	expected_kind: int,
	label: String,
	departure: Vector2i
) -> void:
	var origin := Vector2(17.0, 23.0)
	var records := _records_for(cells, departure)
	var result = _resolver.resolve(
		departure, records, [], [], origin, Vector2i(12, 12), 40.0
	)
	assert_true(result.is_valid, "%s resolves without a Warp" % label)
	if not result.is_valid:
		return
	var turn_index := _first_turn_index(departure, records)
	var piece = _piece_covering_serial(result.pieces, records[turn_index].route_serial)
	assert_not_null(piece, "%s has one curve owner" % label)
	if piece == null:
		return
	var span_offset := expected_kind - 1
	var expected_start := turn_index - span_offset
	var expected_end := mini(turn_index + span_offset, records.size() - 1)
	assert_equal(piece.kind, expected_kind, "%s retains its selected ownership kind" % label)
	assert_equal(
		piece.first_route_serial,
		records[expected_start].route_serial,
		"%s retains the selected owner span start" % label
	)
	assert_equal(
		piece.last_route_serial,
		records[expected_end].route_serial,
		"%s retains the selected owner span end" % label
	)
	assert_equal(
		piece.nominal_length_cells,
		expected_end - expected_start + 1,
		"%s retains nominal ownership length" % label
	)
	assert_equal(
		piece.centerline.size(),
		piece.nominal_length_cells * 16 + 1,
		"%s uses fixed-count local-corner samples" % label
	)
	assert_false(
		piece.footprint_cells.has(departure),
		"%s departure lead-in never becomes footprint ownership" % label
	)
	_assert_each_serial_owned_once(result.pieces, records)
	var previous: Vector2i = departure if turn_index == 0 else records[turn_index - 1].cell
	var incoming := Vector2(records[turn_index].cell - previous).normalized()
	var outgoing := Vector2(records[turn_index + 1].cell - records[turn_index].cell).normalized()
	assert_true(
		piece.sample_nominal(0.0).heading.is_equal_approx(incoming),
		"%s preserves the operational entry heading" % label
	)
	assert_true(
		piece.sample_nominal(float(piece.nominal_length_cells)).heading.is_equal_approx(outgoing),
		"%s preserves the operational exit heading" % label
	)
	assert_true(
		_longest_straight_segment_run(piece.centerline) >= MIN_STRAIGHT_SEGMENT_RUN,
		"%s keeps a visible straight run outside local bends" % label
	)
	var nonlinear_run := _longest_nonlinear_vertex_run(piece.centerline)
	assert_true(
		nonlinear_run <= MAX_LOCAL_CORNER_NONLINEAR_RUN,
		"%s confines nonlinear samples to local windows (run=%d)" % [label, nonlinear_run]
	)
	_assert_owned_record_intervals_enter_cells(piece, records, origin, label)
	_assert_centerline_never_reverses(piece.centerline, incoming, outgoing)
	for sample_index in range(1, piece.centerline.size() - 1):
		var point: Vector2 = piece.centerline[sample_index]
		var cell := Vector2i(
			int(floor((point.x - origin.x) / 40.0)),
			int(floor((point.y - origin.y) / 40.0))
		)
		assert_true(
			piece.footprint_cells.has(cell) or cell == departure,
			"%s interior sample %d stays inside its footprint or departure lead-in"
				% [label, sample_index]
		)
	var replay = _resolver.resolve(
		departure, records, [], [], origin, Vector2i(12, 12), 40.0
	)
	assert_true(replay.is_valid, "%s deterministic replay resolves" % label)
	if replay.is_valid:
		assert_equal(
			_resolution_signature(replay),
			_resolution_signature(result),
			"%s deterministic replay is byte-identical" % label
		)


func _test_right_edge_owned_turn_center_is_visible() -> void:
	var departure := Vector2i(11, 8)
	var records := _records_for([
		Vector2i(11, 7), Vector2i(11, 6), Vector2i(11, 5),
		Vector2i(11, 4), Vector2i(11, 3), Vector2i(10, 3),
		Vector2i(9, 3), Vector2i(8, 3), Vector2i(7, 3),
	], departure)
	var result = _resolver.resolve(
		departure, records, [], [], Vector2.ZERO, Vector2i(12, 12), 40.0
	)
	assert_true(result.is_valid, "Reported right-edge ownership fixture resolves")
	if not result.is_valid:
		return
	var turn_record = records[4]
	var owner = _piece_covering_serial(result.pieces, turn_record.route_serial)
	assert_not_null(owner, "Reported hidden cell has one geometry owner")
	if owner == null:
		return
	assert_equal(owner.kind, CURVE_3X3, "Reported hidden cell retains 3x3 ownership")
	var local_start: float = (
		turn_record.route_distance_start_cells
		- owner.absolute_start_distance_cells
	)
	assert_true(
		owner.contacts_cell_in_nominal_range(
			Vector2i(11, 3), Vector2.ZERO, 40.0,
			local_start, local_start + 1.0, 8
		),
		"The visible spine enters the logically owned (11, 3) route cell"
	)


func _test_multiple_exact_knots_remain_literal_and_deterministic() -> void:
	var records := _records_for([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	])
	var first = RouteContactAnchorScript.new(&"warp_first", records[1].cell)
	var duplicate = RouteContactAnchorScript.new(&"warp_duplicate", records[1].cell)
	var second = RouteContactAnchorScript.new(&"warp_second", records[2].cell)
	for anchor in [first, duplicate, second]:
		anchor.set(&"contact_mode", 1)
	var result = _resolver.resolve(
		DEPARTURE, records, [], [second, duplicate, first],
		Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_true(result.is_valid, "Distinct and duplicate exact anchors resolve together")
	if not result.is_valid:
		return
	var piece = _piece_covering_serial(result.pieces, records[1].route_serial)
	assert_not_null(piece, "Multiple exact anchors share the accepted curve owner")
	if piece == null:
		return
	assert_equal(piece.kind, CURVE_3X3, "Multiple exact anchors retain 3x3 ownership")
	for record_offset in [1, 2]:
		var local_offset: float = (
			records[record_offset].route_distance_start_cells
			- piece.absolute_start_distance_cells
			+ 0.5
		)
		var exact_index := int(round(local_offset * 16.0))
		var expected_center := (Vector2(records[record_offset].cell) + Vector2(0.5, 0.5)) * 40.0
		assert_true(
			piece.centerline[exact_index].distance_to(expected_center) <= 0.0001,
			"Exact anchor at offset %d remains at its fixed sample" % record_offset
		)
	_assert_each_serial_owned_once(result.pieces, records)
	var replay = _resolver.resolve(
		DEPARTURE, records, [], [first, second],
		Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	var replay_piece = _piece_covering_serial(replay.pieces, records[1].route_serial)
	assert_equal(
		replay_piece.centerline,
		piece.centerline,
		"Anchor ordering and same-cell duplicates do not change generated geometry"
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
		assert_equal(baseline_piece.kind, expected_kind, "%s baseline template kind" % label)
		assert_equal(
			piece.first_route_serial, baseline_piece.first_route_serial,
			"%s exact anchor preserves the owner span start" % label
		)
		assert_equal(
			piece.last_route_serial, baseline_piece.last_route_serial,
			"%s exact anchor preserves the owner span end" % label
		)
		assert_equal(
			piece.nominal_length_cells, baseline_piece.nominal_length_cells,
			"%s exact anchor preserves nominal ownership length" % label
		)
		assert_equal(
			piece.footprint_cells, baseline_piece.footprint_cells,
			"%s exact anchor preserves the accepted footprint byte-for-byte" % label
		)
	assert_false(
		piece.footprint_cells.has(departure),
		"%s departure lead-in never becomes route footprint ownership" % label
	)
	_assert_each_serial_owned_once(result.pieces, records)
	assert_equal(
		piece.centerline.size(), piece.nominal_length_cells * 16 + 1,
		"%s anchored curve uses fixed nominal sampling" % label
	)
	var expected_center := (Vector2(anchor_cell) + Vector2(0.5, 0.5)) * 40.0
	var local_offset: float = float(records[anchor_offset].route_distance_start_cells) \
		- piece.absolute_start_distance_cells + 0.5
	var exact_sample_index := int(round(local_offset * 16.0))
	assert_true(
		piece.centerline[exact_sample_index].distance_to(expected_center) <= 0.0001,
		"%s stores the exact center at its literal fixed sample index" % label
	)
	assert_true(
		piece.sample_nominal(local_offset).position.distance_to(expected_center) <= 0.0001,
		"%s passes the literal cell center at its nominal knot" % label
	)
	_assert_owned_record_intervals_enter_cells(
		piece, records, Vector2.ZERO, label
	)
	var turn_index := _first_turn_index(departure, records)
	var previous: Vector2i = departure if turn_index == 0 else records[turn_index - 1].cell
	var incoming := Vector2(records[turn_index].cell - previous).normalized()
	var outgoing := Vector2(records[turn_index + 1].cell - records[turn_index].cell).normalized()
	assert_true(piece.sample_nominal(0.0).heading.is_equal_approx(incoming), "%s preserves operational entry heading" % label)
	assert_true(piece.sample_nominal(float(piece.nominal_length_cells)).heading.is_equal_approx(outgoing), "%s preserves operational exit heading" % label)
	assert_true(
		_longest_straight_segment_run(piece.centerline) >= MIN_STRAIGHT_SEGMENT_RUN,
		"%s retains a visible straight run outside local corner blends" % label
	)
	var nonlinear_run := _longest_nonlinear_vertex_run(piece.centerline)
	assert_true(
		nonlinear_run <= MAX_LOCAL_CORNER_NONLINEAR_RUN,
		"%s confines each nonlinear run to one local half-cell window (run=%d)"
			% [label, nonlinear_run]
	)
	assert_true(
		_longest_reverse_segment_run(piece.centerline, incoming, outgoing)
			<= MAX_LOCAL_REVERSE_SEGMENT_RUN,
		"%s confines any exact-knot reverse travel to one local window" % label
	)
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


func _test_adjacent_turn_overlap_downgrades_only_larger_candidate() -> void:
	var cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(3, 1),
	]
	var records := _records_for(cells)
	var unanchored = _resolve(records)
	assert_true(
		unanchored.is_valid,
		"Adjacent turns try the remaining 2x2-to-1x1 downgrade without an anchor"
	)
	if unanchored.is_valid:
		_assert_adjacent_one_by_one_turns(unanchored.pieces, records, "Unanchored")

	var anchor = RouteContactAnchorScript.new(
		&"adjacent_exact",
		cells[-1],
		RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER
	)
	var anchored = _resolver.resolve(
		DEPARTURE, records, [], [anchor],
		Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_true(
		anchored.is_valid,
		"Adjacent turns try the same remaining downgrade with an exact outgoing anchor"
	)
	if anchored.is_valid:
		_assert_adjacent_one_by_one_turns(anchored.pieces, records, "Exact anchored")
		var target := (Vector2(cells[-1]) + Vector2(0.5, 0.5)) * 40.0
		var owner = _piece_covering_serial(anchored.pieces, records[-1].route_serial)
		assert_not_null(owner, "Exact outgoing cell retains one owner")
		if owner != null:
			assert_true(
				owner.find_nominal_distance_at_position(target, 0.0001) >= 0.0,
				"Exact outgoing anchor remains on the accepted centerline"
			)
	var replay = _resolve(records)
	if unanchored.is_valid and replay.is_valid:
		assert_equal(
			_resolution_signature(replay),
			_resolution_signature(unanchored),
			"Adjacent asymmetric downgrade replays deterministically"
		)


func _assert_adjacent_one_by_one_turns(
	pieces: Array,
	records: Array,
	label: String
) -> void:
	var curves: Array = []
	for piece in pieces:
		if piece.kind != STRAIGHT:
			curves.append(piece)
	assert_equal(curves.size(), 2, "%s adjacent route retains both turns" % label)
	if curves.size() != 2:
		return
	assert_equal(curves[0].kind, CURVE_1X1, "%s first turn reaches 1x1" % label)
	assert_equal(curves[1].kind, CURVE_1X1, "%s second turn remains 1x1" % label)
	assert_equal(
		curves[0].footprint_cells,
		[Vector2i(2, 0)],
		"%s first turn owns only its turn cell" % label
	)
	assert_equal(
		curves[1].footprint_cells,
		[Vector2i(2, 1)],
		"%s second turn owns only its distinct turn cell" % label
	)
	for cell in curves[0].footprint_cells:
		assert_false(
			curves[1].footprint_cells.has(cell),
			"%s final curve footprints do not overlap" % label
		)
	_assert_each_serial_owned_once(pieces, records)


func _test_irreducible_duplicate_turn_footprints_still_reject() -> void:
	var cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1),
		Vector2i(0, 1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1),
	]
	var records: Array = []
	for index in range(cells.size()):
		records.append(TrackCellRecordScript.new(index + 1, cells[index], float(index)))
	var result = _resolver.resolve(
		DEPARTURE, records, [], [], Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_false(result.is_valid, "Duplicate turn cells remain an irreducible overlap")
	assert_equal(result.reason, &"final_overlap", "Irreducible 1x1 overlap keeps final_overlap")


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
		assert_equal(
			piece.kind,
			CURVE_3X3,
			"Common local-corner centerline retains the largest curve that contacts the anchor"
		)
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
	var empty_corner := Vector2i(1, 1)
	assert_true(locked.footprint_cells.has(empty_corner), "Locked curve AABB contains the reentry corner")
	assert_false(
		locked.contacts_cell(empty_corner, Vector2.ZERO, TEST_CELL_SIZE),
		"Locked curve centerline leaves the reentry corner geometrically empty"
	)
	var reentered = _resolver.resolve(DEPARTURE, reentry_records, locked_pieces, [], Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_true(reentered.is_valid, "Unlocked suffix may enter a geometrically empty locked AABB corner")


func _test_locked_aabb_empty_corner_uses_geometric_collision_occupancy() -> void:
	var departure := Vector2i(2, 3)
	var locked_records := _records_for([
		Vector2i(2, 2), Vector2i(2, 1), Vector2i(3, 1),
	], departure)
	var locked_resolution = _resolver.resolve(
		departure, locked_records, [], [], Vector2.ZERO, Vector2i(8, 8), TEST_CELL_SIZE
	)
	assert_true(locked_resolution.is_valid, "Locked empty-corner fixture resolves its initial route")
	if not locked_resolution.is_valid:
		return
	var locked = _first_curve(locked_resolution.pieces)
	assert_not_null(locked, "Locked empty-corner fixture owns a curve")
	if locked == null:
		return
	locked = locked.duplicate_piece()
	locked.locked = true
	var empty_corner := Vector2i(3, 2)
	assert_equal(locked.kind, CURVE_2X2, "Locked empty-corner fixture retains its 2x2 AABB")
	assert_true(locked.footprint_cells.has(empty_corner), "Locked AABB contains the later route cell")
	assert_false(
		locked.contacts_cell(empty_corner, Vector2.ZERO, TEST_CELL_SIZE),
		"Locked centerline does not geometrically occupy the AABB empty corner"
	)
	var locked_before := _piece_signature(locked)
	var route_cells := [
		Vector2i(2, 2), Vector2i(2, 1), Vector2i(3, 1),
		Vector2i(4, 1), Vector2i(5, 1), Vector2i(5, 2),
		Vector2i(4, 2), empty_corner,
	]
	var records := _records_for(route_cells, departure)
	var no_anchor = _resolver.resolve(
		departure, records, [locked], [], Vector2.ZERO, Vector2i(8, 8), TEST_CELL_SIZE
	)
	assert_true(
		no_anchor.is_valid,
		"Unlocked route may enter a locked AABB cell that neither centerline occupies"
	)
	if not no_anchor.is_valid:
		assert_equal(no_anchor.reason, &"locked_overlap", "RED identifies the AABB false positive")
	var anchor = RouteContactAnchorScript.new(
		&"empty_corner_exact", empty_corner,
		RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER
	)
	var anchored = _resolver.resolve(
		departure, records, [locked], [anchor], Vector2.ZERO, Vector2i(8, 8), TEST_CELL_SIZE
	)
	assert_true(
		anchored.is_valid,
		"An accepted empty-corner route may add an exact-center hard knot"
	)
	if not anchored.is_valid:
		assert_equal(anchored.reason, &"locked_overlap", "Exact anchoring occurs only after collision acceptance")
	else:
		var owner = _piece_covering_serial(anchored.pieces, records[-1].route_serial)
		assert_not_null(owner, "Exact empty-corner route retains a concrete geometry owner")
		if owner != null:
			assert_true(
				_resolver._piece_contains_exact_center(owner, empty_corner, Vector2.ZERO, TEST_CELL_SIZE),
				"Exact empty-corner contact remains a literal center knot"
			)
	var repeated = _resolver.resolve(
		departure, records, [locked], [anchor], Vector2.ZERO, Vector2i(8, 8), TEST_CELL_SIZE
	)
	assert_equal(
		_resolution_signature(repeated), _resolution_signature(anchored),
		"Geometric locked occupancy resolves deterministically"
	)
	assert_equal(_piece_signature(locked), locked_before, "Collision queries keep locked bytes unchanged")


func _test_locked_predecessor_stitches_anchored_turn_by_declared_heading() -> void:
	var departure := Vector2i(7, 4)
	var records := _records_for([
		Vector2i(7, 3), Vector2i(7, 2), Vector2i(6, 2),
	], departure)
	var locked = TrackGeometryPieceScript.new()
	locked.group_id = 90
	locked.kind = STRAIGHT
	locked.first_route_serial = records[0].route_serial
	locked.last_route_serial = records[0].route_serial
	locked.nominal_length_cells = 1
	locked.absolute_start_distance_cells = 0.0
	var locked_footprint: Array[Vector2i] = [Vector2i(7, 3)]
	locked.footprint_cells = locked_footprint
	locked.centerline = PackedVector2Array([Vector2(300.0, 180.0), Vector2(300.0, 140.0)])
	locked.locked = true
	locked.active_local_end_cells = 1.0
	var locked_before := _piece_signature(locked)
	var anchor = RouteContactAnchorScript.new(
		&"warp_exact", Vector2i(7, 2), RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER
	)
	var result = _resolver.resolve(
		departure, records, [locked], [anchor], Vector2.ZERO, Vector2i(16, 10), 40.0
	)
	assert_true(result.is_valid, "Locked endpoint anchored-turn fixture resolves")
	if not result.is_valid:
		return
	assert_equal(_piece_signature(locked), locked_before, "Resolver never mutates the source locked predecessor")
	assert_equal(result.pieces.size(), 3, "Locked endpoint fixture retains one predecessor, one curve, and one suffix")
	if result.pieces.size() != 3:
		return
	var predecessor = result.pieces[0]
	var curve = result.pieces[1]
	assert_equal(curve.kind, CURVE_1X1, "First unlocked successor remains an anchored 1x1 curve")
	assert_equal(curve.first_route_serial, records[1].route_serial, "Anchored curve owns only the Warp route record")
	assert_equal(curve.footprint_cells, [Vector2i(7, 2)], "Anchored turn preserves its one-cell footprint")
	assert_true(
		predecessor.centerline[-1].is_equal_approx(curve.centerline[0]),
		"Declared entry heading stitches the anchored curve to the immutable predecessor"
	)
	assert_true(
		curve.sample_nominal(0.5).position.is_equal_approx(Vector2(300.0, 100.0)),
		"Stitched successor retains the exact Warp center knot"
	)
	var sideways = curve.duplicate_piece()
	sideways.centerline[0] = Vector2(300.0, 120.0)
	sideways.entry_heading_override = Vector2.LEFT
	assert_false(
		_resolver._centerline_gap_is_forward(predecessor, sideways),
		"A sideways declared entry remains ineligible for locked-boundary stitching"
	)
	var nonforward_locked = locked.duplicate_piece()
	nonforward_locked.centerline[-1] = Vector2(340.0, 140.0)
	var nonforward_before: PackedVector2Array = nonforward_locked.centerline.duplicate()
	var nonforward_result = _resolver.resolve(
		departure, records, [nonforward_locked], [anchor],
		Vector2.ZERO, Vector2i(16, 10), 40.0
	)
	assert_true(nonforward_result.is_valid, "Resolver leaves final continuity ownership to the runtime")
	if nonforward_result.is_valid and nonforward_result.pieces.size() >= 2:
		assert_false(
			nonforward_result.pieces[0].centerline[-1].is_equal_approx(
				nonforward_result.pieces[1].centerline[0]
			),
			"Non-forward locked boundary remains unstitched"
		)
	assert_equal(
		nonforward_locked.centerline,
		nonforward_before,
		"Rejected stitch attempt never mutates its locked source"
	)


func _test_empty_acceptance_and_final_conflict_rejection() -> void:
	var empty = _resolver.resolve(DEPARTURE, [], [], [], Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_true(empty.is_valid, "Empty route is accepted")
	assert_equal(empty.pieces.size(), 0, "Empty route has no pieces")
	assert_equal(empty.rejected_route_serial, -1, "Accepted empty route rejects no serial")
	var records = _records_for([Vector2i(0, 0), Vector2i(1, 0)])
	var blocker = TrackGeometryPieceScript.new()
	blocker.group_id = 99
	blocker.kind = CURVE_1X1
	blocker.first_route_serial = 99
	blocker.last_route_serial = 99
	blocker.nominal_length_cells = 1
	var blocker_footprint: Array[Vector2i] = [Vector2i(1, 0)]
	blocker.footprint_cells = blocker_footprint
	blocker.centerline = PackedVector2Array([Vector2(60, 20), Vector2(60, 30)])
	blocker.locked = true
	var locked: Array = [blocker]
	var rejected = _resolver.resolve(DEPARTURE, records, locked, [], Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_true(not rejected.is_valid, "Unresolved final 1x1 conflict rejects")
	assert_equal(rejected.reason, &"locked_overlap", "Real shared centerline contact remains a locked collision")
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


func _test_grade_separated_crossing_exception_is_exact_and_perpendicular() -> void:
	var sequence = TrackCellSequenceScript.new(Vector2i(0, 2), 16)
	assert_equal(sequence.append_candidates([
		Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
		Vector2i(3, 3), Vector2i(3, 4), Vector2i(2, 4), Vector2i(2, 3),
	]), 7, "Geometry crossing fixture appends its unique approach")
	sequence._records[1].geometry_locked = true
	assert_not_null(sequence.try_append_candidate(Vector2i(2, 2), true, 2), "Geometry fixture appends the authorized crossing occurrence")
	assert_not_null(sequence.try_append_candidate(Vector2i(2, 1)), "Geometry fixture appends the opposite-side exit")
	var locked = TrackGeometryPieceScript.new()
	locked.group_id = 90
	locked.kind = STRAIGHT
	locked.first_route_serial = 2
	locked.last_route_serial = 2
	locked.nominal_length_cells = 1
	locked.absolute_start_distance_cells = 1.0
	var locked_footprint: Array[Vector2i] = [Vector2i(2, 2)]
	locked.footprint_cells = locked_footprint
	locked.centerline = PackedVector2Array([Vector2(80.0, 100.0), Vector2(120.0, 100.0)])
	locked.active_local_end_cells = 1.0
	locked.locked = true
	var result = _resolver.resolve(
		Vector2i(0, 2), sequence.get_records(), [locked], [],
		Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_true(result.is_valid, "Exact perpendicular center crossing is the only locked-overlap exception")
	if result.is_valid:
		var later = _piece_covering_serial(result.pieces, 8)
		assert_not_null(later, "Later crossing occurrence owns one geometry piece")
		if later != null:
			var center := Vector2(100.0, 100.0)
			var later_distance: float = later.find_nominal_distance_at_position(center, 0.001)
			var locked_distance: float = locked.find_nominal_distance_at_position(center, 0.001)
			assert_true(later_distance >= 0.0 and locked_distance >= 0.0, "Both centerlines pass through the literal crossing center")
			if later_distance >= 0.0 and locked_distance >= 0.0:
				assert_true(absf(later.sample_nominal(later_distance).heading.dot(locked.sample_nominal(locked_distance).heading)) <= 0.0001, "Resolved crossing headings are perpendicular")
	var wrong_partner_records := sequence.get_records()
	wrong_partner_records[-2].crossing_partner_route_serial = 1
	var rejected = _resolver.resolve(
		Vector2i(0, 2), wrong_partner_records, [locked], [],
		Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_false(rejected.is_valid, "A mismatched partner serial cannot bypass locked collision ownership")
	assert_equal(rejected.reason, &"locked_overlap", "Mismatched crossing identity rejects as a real overlap")


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


func _assert_owned_record_intervals_enter_cells(
	piece,
	records: Array,
	origin: Vector2,
	label: String
) -> void:
	for record in records:
		if not piece.contains_serial(record.route_serial):
			continue
		var local_start: float = (
			record.route_distance_start_cells
			- piece.absolute_start_distance_cells
		)
		assert_true(
			piece.contacts_cell_in_nominal_range(
				record.cell, origin, TEST_CELL_SIZE,
				local_start, local_start + 1.0, 8
			),
			"%s visibly enters owned route cell %s in its nominal interval"
				% [label, record.cell]
		)


func _longest_straight_segment_run(centerline: PackedVector2Array) -> int:
	var longest := 0
	var current := 0
	var previous_heading := Vector2.ZERO
	for index in range(centerline.size() - 1):
		var delta: Vector2 = centerline[index + 1] - centerline[index]
		if delta.is_zero_approx():
			current = 0
			previous_heading = Vector2.ZERO
			continue
		var heading := delta.normalized()
		if (
			not previous_heading.is_zero_approx()
			and absf(previous_heading.cross(heading)) <= 0.000001
			and previous_heading.dot(heading) > 0.0
		):
			current += 1
		else:
			current = 1
		previous_heading = heading
		longest = maxi(longest, current)
	return longest


func _longest_nonlinear_vertex_run(centerline: PackedVector2Array) -> int:
	var longest := 0
	var current := 0
	for index in range(1, centerline.size() - 1):
		var second_difference: Vector2 = (
			centerline[index + 1]
			- centerline[index] * 2.0
			+ centerline[index - 1]
		)
		if second_difference.length() > 0.0001:
			current += 1
			longest = maxi(longest, current)
		else:
			current = 0
	return longest


func _longest_reverse_segment_run(
	centerline: PackedVector2Array,
	incoming: Vector2,
	outgoing: Vector2
) -> int:
	var longest := 0
	var current := 0
	for index in range(centerline.size() - 1):
		var delta: Vector2 = centerline[index + 1] - centerline[index]
		if delta.dot(incoming) < -0.0001 or delta.dot(outgoing) < -0.0001:
			current += 1
			longest = maxi(longest, current)
		else:
			current = 0
	return longest


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
