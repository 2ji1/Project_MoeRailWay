class_name TrackGeometryResolver
extends RefCounted

const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackGeometryResolutionScript = preload("res://src/domain/track/track_geometry_resolution.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const DISTANCE_EPSILON := 0.0001
const TANGENT_DOT_EPSILON := 0.0001
const CENTERLINE_SEGMENTS_PER_NOMINAL_CELL := 16
const EXACT_KNOT_OFFSET_SAMPLES := CENTERLINE_SEGMENTS_PER_NOMINAL_CELL / 2
const LOCAL_CORNER_HALF_WINDOW_SAMPLES := CENTERLINE_SEGMENTS_PER_NOMINAL_CELL / 4
const LOCAL_CORNER_HANDLE_RATIO := 1.0 / 3.0


func resolve(
    departure_cell: Vector2i,
    records: Array,
    locked_pieces: Array,
    anchors: Array,
    grid_origin_units: Vector2,
    grid_size: Vector2i,
    cell_size_units: float
) -> RefCounted:
    if records.is_empty():
        return TrackGeometryResolutionScript.accepted([])
    var newest_serial: int = records[-1].route_serial
    if grid_size.x <= 0 or grid_size.y <= 0 or cell_size_units <= 0.0:
        return TrackGeometryResolutionScript.rejected(newest_serial, &"invalid_grid")
    for record in records:
        if not _cell_in_grid(record.cell, grid_size):
            return TrackGeometryResolutionScript.rejected(newest_serial, &"grid_bounds")

    var covered := {}
    var pieces: Array[TrackGeometryPieceScript] = []
    var blocking_locked: Array = []
    for source in locked_pieces:
        var first_active := -1
        var last_active := -1
        for index in range(records.size()):
            if source.contains_serial(records[index].route_serial):
                if first_active < 0:
                    first_active = index
                last_active = index
                covered[index] = true
        if first_active < 0:
            blocking_locked.append(source)
            continue
        var local_start: float = records[first_active].route_distance_start_cells - source.absolute_start_distance_cells
        var local_end: float = records[last_active].route_distance_start_cells + 1.0 - source.absolute_start_distance_cells
        pieces.append(source.duplicate_active_slice(local_start, local_end))
        blocking_locked.append(source)

    var candidates := _turn_candidates(departure_cell, records, covered)
    var changed := true
    while changed:
        changed = false
        for first_index in range(candidates.size()):
            for second_index in range(first_index + 1, candidates.size()):
                var overlap := _intersection_count(
                    _candidate_footprint(candidates[first_index], records),
                    _candidate_footprint(candidates[second_index], records)
                )
                if overlap <= 0:
                    continue
                if candidates[first_index].radius <= 1 and candidates[second_index].radius <= 1:
                    return TrackGeometryResolutionScript.rejected(newest_serial, &"final_overlap")
                if candidates[first_index].radius > 1:
                    candidates[first_index].radius -= 1
                if candidates[second_index].radius > 1:
                    candidates[second_index].radius -= 1
                changed = true

    for candidate in candidates:
        while candidate.radius > 0:
            var span := _candidate_span(candidate, records.size())
            var footprint := _candidate_footprint(candidate, records)
            var valid := span.x >= 0 and span.y < records.size()
            if valid:
                for cell in footprint:
                    valid = valid and _cell_in_grid(cell, grid_size)
            if valid:
                for index in range(span.x, span.y + 1):
                    if covered.has(index):
                        valid = false
            if valid and _footprint_contains_non_owned_record(candidate, records):
                valid = false
            if valid and _conflicts_with_locked(footprint, blocking_locked):
                valid = false
            if valid:
                var preview = _curve_piece(
                    -1, candidate, span.x, span.y,
                    departure_cell, records, grid_origin_units, cell_size_units, anchors
                )
                for anchor in anchors:
                    if anchor.contact_mode == RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER:
                        if _span_owns_cell(span, records, anchor.cell) and not _piece_contains_exact_center(
                            preview, anchor.cell, grid_origin_units, cell_size_units
                        ):
                            valid = false
                    elif footprint.has(anchor.cell) and not preview.contacts_cell(
                        anchor.cell, grid_origin_units, cell_size_units
                    ):
                        valid = false
                if valid and not _curve_samples_fit_footprint(
                    preview, span, records, departure_cell,
                    grid_origin_units, cell_size_units
                ):
                    valid = false
            if valid:
                break
            candidate.radius -= 1
        if candidate.radius <= 0:
            return TrackGeometryResolutionScript.rejected(newest_serial, &"curve_unresolved")

    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return a.turn_index < b.turn_index
    )
    var last_assigned := -1
    var group_id := pieces.size()
    for candidate in candidates:
        var desired := _candidate_span(candidate, records.size())
        var start_index: int = desired.x
        var end_index: int = desired.y
        if start_index <= last_assigned or start_index < 0:
            return TrackGeometryResolutionScript.rejected(newest_serial, &"serial_overlap")
        for index in range(last_assigned + 1, start_index):
            if not covered.has(index):
                pieces.append(_straight_piece(group_id, index, departure_cell, records, grid_origin_units, cell_size_units))
                group_id += 1
        var curve = _curve_piece(
            group_id, candidate, start_index, end_index,
            departure_cell, records, grid_origin_units, cell_size_units, anchors
        )
        if _conflicts_with_locked(curve.footprint_cells, blocking_locked):
            return TrackGeometryResolutionScript.rejected(newest_serial, &"locked_overlap")
        for anchor in anchors:
            if anchor.contact_mode == RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER:
                if _span_owns_cell(desired, records, anchor.cell) and not _piece_contains_exact_center(
                    curve, anchor.cell, grid_origin_units, cell_size_units
                ):
                    return TrackGeometryResolutionScript.rejected(newest_serial, &"anchor_contact")
            elif curve.footprint_cells.has(anchor.cell) and not curve.contacts_cell(
                anchor.cell, grid_origin_units, cell_size_units
            ):
                return TrackGeometryResolutionScript.rejected(newest_serial, &"anchor_contact")
        pieces.append(curve)
        group_id += 1
        last_assigned = end_index
    for index in range(last_assigned + 1, records.size()):
        if covered.has(index):
            continue
        var straight = _straight_piece(group_id, index, departure_cell, records, grid_origin_units, cell_size_units)
        if _conflicts_with_locked(straight.footprint_cells, blocking_locked):
            return TrackGeometryResolutionScript.rejected(newest_serial, &"locked_overlap")
        pieces.append(straight)
        group_id += 1
    pieces.sort_custom(func(a, b) -> bool:
        return a.absolute_start_distance_cells < b.absolute_start_distance_cells
    )
    _stitch_unlocked_successors_to_locked_pieces(pieces)
    return TrackGeometryResolutionScript.accepted(pieces)


func _stitch_unlocked_successors_to_locked_pieces(
    pieces: Array[TrackGeometryPieceScript]
) -> void:
    for index in range(1, pieces.size()):
        var predecessor: TrackGeometryPieceScript = pieces[index - 1]
        var successor: TrackGeometryPieceScript = pieces[index]
        if (
            not predecessor.locked
            or successor.locked
            or absf(
                successor.absolute_start_distance_cells
                - predecessor.absolute_start_distance_cells
                - float(predecessor.nominal_length_cells)
            ) > DISTANCE_EPSILON
            or predecessor.centerline.is_empty()
            or successor.centerline.is_empty()
            or not _centerline_gap_is_forward(predecessor, successor)
        ):
            continue
        var stitched_centerline := successor.centerline.duplicate()
        stitched_centerline[0] = predecessor.centerline[-1]
        successor.centerline = stitched_centerline


func _centerline_gap_is_forward(
    predecessor: TrackGeometryPieceScript,
    successor: TrackGeometryPieceScript
) -> bool:
    var gap: Vector2 = successor.centerline[0] - predecessor.centerline[-1]
    if gap.is_zero_approx():
        return true
    if predecessor.centerline.size() < 2 or successor.centerline.size() < 2:
        return false
    var predecessor_heading: Vector2 = predecessor.sample_nominal(
        float(predecessor.nominal_length_cells)
    ).heading
    var successor_heading: Vector2 = successor.sample_nominal(0.0).heading
    var gap_heading := gap.normalized()
    return (
        gap_heading.dot(predecessor_heading) >= 1.0 - TANGENT_DOT_EPSILON
        and gap_heading.dot(successor_heading) >= 1.0 - TANGENT_DOT_EPSILON
    )


func _turn_candidates(
    departure_cell: Vector2i,
    records: Array,
    covered: Dictionary
) -> Array:
    var result := []
    for index in range(records.size() - 1):
        if covered.has(index):
            continue
        var previous: Vector2i = departure_cell if index == 0 else records[index - 1].cell
        var incoming: Vector2i = records[index].cell - previous
        var outgoing: Vector2i = records[index + 1].cell - records[index].cell
        if incoming == outgoing:
            continue
        var radius := 3
        radius = mini(radius, index + 1)
        radius = mini(radius, records.size() - index)
        result.append({"turn_index": index, "radius": radius})
    return result


func _candidate_span(candidate: Dictionary, record_count: int) -> Vector2i:
    var offset: int = candidate.radius - 1
    return Vector2i(
        candidate.turn_index - offset,
        mini(candidate.turn_index + offset, record_count - 1)
    )


func _candidate_footprint(candidate: Dictionary, records: Array) -> Array[Vector2i]:
    var span := _candidate_span(candidate, records.size())
    if span.x < 0 or span.y >= records.size():
        return []
    var minimum: Vector2i = records[span.x].cell
    var maximum := minimum
    for index in range(span.x, span.y + 1):
        minimum.x = mini(minimum.x, records[index].cell.x)
        minimum.y = mini(minimum.y, records[index].cell.y)
        maximum.x = maxi(maximum.x, records[index].cell.x)
        maximum.y = maxi(maximum.y, records[index].cell.y)
    var result: Array[Vector2i] = []
    for y in range(minimum.y, maximum.y + 1):
        for x in range(minimum.x, maximum.x + 1):
            result.append(Vector2i(x, y))
    return result


func _footprint_contains_non_owned_record(candidate: Dictionary, records: Array) -> bool:
    var span := _candidate_span(candidate, records.size())
    var footprint := _candidate_footprint(candidate, records)
    for index in range(records.size()):
        if index < span.x or index > span.y:
            if footprint.has(records[index].cell):
                return true
    return false


func _curve_piece(
    group_id: int,
    candidate: Dictionary,
    start_index: int,
    end_index: int,
    departure_cell: Vector2i,
    records: Array,
    origin: Vector2,
    cell_size: float,
    anchors: Array = []
) -> RefCounted:
    var piece = TrackGeometryPieceScript.new()
    piece.group_id = group_id
    piece.kind = candidate.radius
    piece.first_route_serial = records[start_index].route_serial
    piece.last_route_serial = records[end_index].route_serial
    piece.nominal_length_cells = end_index - start_index + 1
    piece.absolute_start_distance_cells = records[start_index].route_distance_start_cells
    piece.footprint_cells = _candidate_footprint(candidate, records)
    piece.centerline = _curve_centerline(
        start_index, end_index,
        departure_cell, records, origin, cell_size, anchors
    )
    var exact_knots := _exact_knots_for_span(
        anchors, records, start_index, end_index, origin, cell_size
    )
    if not exact_knots.is_empty():
        var turn_index: int = candidate.turn_index
        var previous: Vector2i = departure_cell if turn_index == 0 else records[turn_index - 1].cell
        piece.entry_heading_override = Vector2(records[turn_index].cell - previous).normalized()
        piece.exit_heading_override = Vector2(records[turn_index + 1].cell - records[turn_index].cell).normalized()
    piece.active_local_end_cells = float(piece.nominal_length_cells)
    return piece


func _straight_piece(
    group_id: int,
    index: int,
    departure_cell: Vector2i,
    records: Array,
    origin: Vector2,
    cell_size: float
) -> RefCounted:
    var piece = TrackGeometryPieceScript.new()
    piece.group_id = group_id
    piece.first_route_serial = records[index].route_serial
    piece.last_route_serial = records[index].route_serial
    piece.nominal_length_cells = 1
    piece.absolute_start_distance_cells = records[index].route_distance_start_cells
    var footprint: Array[Vector2i] = [records[index].cell]
    piece.footprint_cells = footprint
    piece.centerline = PackedVector2Array([
        _boundary_before(index, departure_cell, records, origin, cell_size),
        _boundary_after(index, records, origin, cell_size),
    ])
    piece.active_local_end_cells = 1.0
    return piece


func _boundary_before(index: int, departure: Vector2i, records: Array, origin: Vector2, size: float) -> Vector2:
    if index == 0 and is_zero_approx(records[index].route_distance_start_cells):
        return _cell_center(departure, origin, size)
    var previous: Vector2i
    if index == 0:
        previous = departure
    else:
        previous = records[index - 1].cell
    var current_center := _cell_center(records[index].cell, origin, size)
    var previous_center := _cell_center(previous, origin, size)
    return (current_center + previous_center) * 0.5


func _boundary_after(index: int, records: Array, origin: Vector2, size: float) -> Vector2:
    var current := _cell_center(records[index].cell, origin, size)
    if index + 1 >= records.size():
        return current
    return (current + _cell_center(records[index + 1].cell, origin, size)) * 0.5


func _curve_centerline(
    start_index: int,
    end_index: int,
    departure_cell: Vector2i,
    records: Array,
    origin: Vector2,
    cell_size: float,
    anchors: Array = []
) -> PackedVector2Array:
    var start := _boundary_before(start_index, departure_cell, records, origin, cell_size)
    var finish := _boundary_after(end_index, records, origin, cell_size)
    var route_knots := _ordered_route_center_knots(
        records, start_index, end_index, origin, cell_size,
        anchors, start, finish
    )
    var previous_exit_cell: Vector2i = (
        departure_cell if end_index == 0 else records[end_index - 1].cell
    )
    var exit_heading := Vector2(records[end_index].cell - previous_exit_cell).normalized()
    return _ordered_route_curve_centerline(
        start,
        finish,
        route_knots,
        end_index - start_index + 1,
        exit_heading,
        cell_size
    )


func _cell_center(cell: Vector2i, origin: Vector2, size: float) -> Vector2:
    return origin + (Vector2(cell) + Vector2(0.5, 0.5)) * size


func _exact_knots_for_span(
    anchors: Array,
    records: Array,
    start_index: int,
    end_index: int,
    origin: Vector2,
    cell_size: float
) -> Array[Dictionary]:
    var knots: Array[Dictionary] = []
    var seen_cells: Dictionary = {}
    var ordered_anchors := anchors.duplicate()
    ordered_anchors.sort_custom(func(first, second) -> bool:
        return String(first.anchor_id) < String(second.anchor_id)
    )
    for record_index in range(start_index, end_index + 1):
        for anchor in ordered_anchors:
            if (
                anchor.contact_mode != RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER
                or anchor.cell != records[record_index].cell
                or seen_cells.has(anchor.cell)
            ):
                continue
            seen_cells[anchor.cell] = true
            knots.append({
                "sample_index": (
                    (record_index - start_index)
                    * CENTERLINE_SEGMENTS_PER_NOMINAL_CELL
                    + EXACT_KNOT_OFFSET_SAMPLES
                ),
                "position": _cell_center(anchor.cell, origin, cell_size),
            })
    return knots


func _ordered_route_center_knots(
    records: Array,
    start_index: int,
    end_index: int,
    origin: Vector2,
    cell_size: float,
    anchors: Array,
    start: Vector2,
    finish: Vector2
) -> Array[Dictionary]:
    var knots: Array[Dictionary] = []
    for record_index in range(start_index, end_index + 1):
        var position := _cell_center(records[record_index].cell, origin, cell_size)
        var is_exact := false
        for anchor in anchors:
            if (
                anchor.contact_mode == RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER
                and anchor.cell == records[record_index].cell
            ):
                is_exact = true
                break
        if not is_exact and (position.is_equal_approx(start) or position.is_equal_approx(finish)):
            continue
        knots.append({
            "sample_index": (
                (record_index - start_index)
                * CENTERLINE_SEGMENTS_PER_NOMINAL_CELL
                + EXACT_KNOT_OFFSET_SAMPLES
            ),
            "position": position,
            "exact": is_exact,
        })
    return knots


func _ordered_route_curve_centerline(
    start: Vector2,
    finish: Vector2,
    route_knots: Array[Dictionary],
    nominal_length_cells: int,
    exit_heading: Vector2,
    cell_size: float
) -> PackedVector2Array:
    var skeleton: Array[Dictionary] = [{
        "sample_index": 0,
        "position": start,
        "exact": false,
    }]
    for knot in route_knots:
        skeleton.append({
            "sample_index": knot["sample_index"],
            "position": knot["position"],
            "exact": knot["exact"],
        })
    var finish_index := nominal_length_cells * CENTERLINE_SEGMENTS_PER_NOMINAL_CELL
    _insert_terminal_exact_exit_support(
        skeleton, finish, finish_index, exit_heading, cell_size
    )
    skeleton.append({
        "sample_index": finish_index,
        "position": finish,
        "exact": false,
    })
    var points := _linear_centerline_from_knots(
        skeleton,
        nominal_length_cells * CENTERLINE_SEGMENTS_PER_NOMINAL_CELL + 1
    )
    _round_local_skeleton_corners(points, skeleton)
    return points


func _insert_terminal_exact_exit_support(
    skeleton: Array[Dictionary],
    finish: Vector2,
    finish_index: int,
    exit_heading: Vector2,
    cell_size: float
) -> void:
    if skeleton.size() < 2 or exit_heading.is_zero_approx() or cell_size <= 0.0:
        return
    var terminal: Dictionary = skeleton[-1]
    if not terminal["exact"] or not Vector2(terminal["position"]).is_equal_approx(finish):
        return
    var terminal_index: int = terminal["sample_index"]
    var support_sample_offset := (finish_index - terminal_index) / 2
    if support_sample_offset <= 0:
        return
    skeleton.append({
        "sample_index": terminal_index + support_sample_offset,
        "position": (
            finish
            - exit_heading
            * cell_size
            * float(support_sample_offset)
            / float(CENTERLINE_SEGMENTS_PER_NOMINAL_CELL)
        ),
        "exact": false,
    })


func _linear_centerline_from_knots(
    skeleton: Array[Dictionary],
    sample_count: int
) -> PackedVector2Array:
    var points := PackedVector2Array()
    points.resize(sample_count)
    for segment_index in range(skeleton.size() - 1):
        var knot_a: Dictionary = skeleton[segment_index]
        var knot_b: Dictionary = skeleton[segment_index + 1]
        var index_a: int = knot_a["sample_index"]
        var index_b: int = knot_b["sample_index"]
        if index_b <= index_a:
            continue
        for sample_index in range(index_a, index_b + 1):
            var weight := float(sample_index - index_a) / float(index_b - index_a)
            points[sample_index] = Vector2(knot_a["position"]).lerp(
                Vector2(knot_b["position"]), weight
            )
    return points


func _round_local_skeleton_corners(
    points: PackedVector2Array,
    skeleton: Array[Dictionary]
) -> void:
    for knot_index in range(1, skeleton.size() - 1):
        var previous: Dictionary = skeleton[knot_index - 1]
        var current: Dictionary = skeleton[knot_index]
        var following: Dictionary = skeleton[knot_index + 1]
        var incoming_delta: Vector2 = current["position"] - previous["position"]
        var outgoing_delta: Vector2 = following["position"] - current["position"]
        if incoming_delta.is_zero_approx() or outgoing_delta.is_zero_approx():
            continue
        var incoming_heading := incoming_delta.normalized()
        var outgoing_heading := outgoing_delta.normalized()
        if incoming_heading.dot(outgoing_heading) >= 1.0 - TANGENT_DOT_EPSILON:
            continue
        var current_index: int = current["sample_index"]
        var half_window := mini(
            LOCAL_CORNER_HALF_WINDOW_SAMPLES,
            mini(
                (current_index - int(previous["sample_index"])) / 2,
                (int(following["sample_index"]) - current_index) / 2
            )
        )
        if half_window <= 0:
            continue
        if current["exact"]:
            _round_exact_corner(
                points,
                current_index,
                half_window,
                Vector2(current["position"]),
                incoming_heading,
                outgoing_heading
            )
        else:
            _round_support_corner(
                points,
                current_index,
                half_window,
                Vector2(current["position"])
            )


func _round_support_corner(
    points: PackedVector2Array,
    corner_index: int,
    half_window: int,
    corner_position: Vector2
) -> void:
    var start_index := corner_index - half_window
    var finish_index := corner_index + half_window
    var start: Vector2 = points[start_index]
    var finish: Vector2 = points[finish_index]
    for sample_index in range(start_index, finish_index + 1):
        var weight := float(sample_index - start_index) / float(finish_index - start_index)
        var inverse := 1.0 - weight
        points[sample_index] = (
            start * inverse * inverse
            + corner_position * 2.0 * inverse * weight
            + finish * weight * weight
        )


func _round_exact_corner(
    points: PackedVector2Array,
    corner_index: int,
    half_window: int,
    corner_position: Vector2,
    incoming_heading: Vector2,
    outgoing_heading: Vector2
) -> void:
    var shared_tangent := (incoming_heading + outgoing_heading).normalized()
    if shared_tangent.is_zero_approx():
        return
    var start_index := corner_index - half_window
    var finish_index := corner_index + half_window
    var start: Vector2 = points[start_index]
    var finish: Vector2 = points[finish_index]
    var incoming_handle := start.distance_to(corner_position) * LOCAL_CORNER_HANDLE_RATIO
    var outgoing_handle := corner_position.distance_to(finish) * LOCAL_CORNER_HANDLE_RATIO
    _write_cubic_samples(
        points,
        start_index,
        corner_index,
        start,
        start + incoming_heading * incoming_handle,
        corner_position - shared_tangent * incoming_handle,
        corner_position
    )
    _write_cubic_samples(
        points,
        corner_index,
        finish_index,
        corner_position,
        corner_position + shared_tangent * outgoing_handle,
        finish - outgoing_heading * outgoing_handle,
        finish
    )


func _write_cubic_samples(
    points: PackedVector2Array,
    start_index: int,
    finish_index: int,
    start: Vector2,
    control_a: Vector2,
    control_b: Vector2,
    finish: Vector2
) -> void:
    for sample_index in range(start_index, finish_index + 1):
        var weight := float(sample_index - start_index) / float(finish_index - start_index)
        var inverse := 1.0 - weight
        points[sample_index] = (
            start * inverse * inverse * inverse
            + control_a * 3.0 * inverse * inverse * weight
            + control_b * 3.0 * inverse * weight * weight
            + finish * weight * weight * weight
        )


func _span_owns_cell(span: Vector2i, records: Array, cell: Vector2i) -> bool:
    for index in range(span.x, span.y + 1):
        if index >= 0 and index < records.size() and records[index].cell == cell:
            return true
    return false


func _piece_contains_exact_center(
    piece,
    cell: Vector2i,
    origin: Vector2,
    cell_size: float
) -> bool:
    var target := _cell_center(cell, origin, cell_size)
    return piece.find_nominal_distance_at_position(target, DISTANCE_EPSILON) >= 0.0


func _curve_samples_fit_footprint(
    piece,
    span: Vector2i,
    records: Array,
    departure_cell: Vector2i,
    origin: Vector2,
    cell_size: float
) -> bool:
    for index in range(1, piece.centerline.size() - 1):
        var point: Vector2 = piece.centerline[index]
        var cell := Vector2i(
            int(floor((point.x - origin.x) / cell_size)),
            int(floor((point.y - origin.y) / cell_size))
        )
        if span.x == 0 and cell == departure_cell:
            continue
        if not piece.footprint_cells.has(cell):
            return false
    return true


func _cell_in_grid(cell: Vector2i, grid_size: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func _intersection_count(first: Array, second: Array) -> int:
    var count := 0
    for cell in first:
        if second.has(cell):
            count += 1
    return count


func _conflicts_with_locked(footprint: Array, locked_pieces: Array) -> bool:
    for locked in locked_pieces:
        if _intersection_count(footprint, locked.footprint_cells) > 0:
            return true
    return false
