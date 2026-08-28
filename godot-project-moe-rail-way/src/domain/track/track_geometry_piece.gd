class_name TrackGeometryPiece
extends RefCounted

enum Kind { STRAIGHT, CURVE_1X1, CURVE_2X2, CURVE_3X3 }

var group_id: int = -1
var kind: Kind = Kind.STRAIGHT
var first_route_serial: int = -1
var last_route_serial: int = -1
var nominal_length_cells: int = 0
var absolute_start_distance_cells: float = 0.0
var footprint_cells: Array[Vector2i] = []
var centerline := PackedVector2Array()
var locked := false
var exit_support_route_serial: int = -1
var active_local_start_cells := 0.0
var active_local_end_cells := 0.0
var entry_heading_override := Vector2.ZERO
var exit_heading_override := Vector2.ZERO


func contains_serial(route_serial: int) -> bool:
    return route_serial >= first_route_serial and route_serial <= last_route_serial


func contacts_cell(
    cell: Vector2i,
    grid_origin_units: Vector2,
    cell_size_units: float
) -> bool:
    if cell_size_units <= 0.0 or centerline.is_empty():
        return false
    for index in range(maxi(centerline.size() - 1, 1)):
        var start: Vector2 = centerline[index]
        var finish: Vector2 = centerline[mini(index + 1, centerline.size() - 1)]
        var steps := maxi(1, int(ceil(start.distance_to(finish) / (cell_size_units / 8.0))))
        for step in range(steps + 1):
            var sample := start.lerp(finish, float(step) / float(steps))
            var mapped := Vector2i(
                int(floor((sample.x - grid_origin_units.x) / cell_size_units)),
                int(floor((sample.y - grid_origin_units.y) / cell_size_units))
            )
            if mapped == cell:
                return true
    return false


func find_nominal_distance_at_position(
    target_position: Vector2,
    position_epsilon_units: float
) -> float:
    if (
        centerline.size() < 2
        or nominal_length_cells < 0
        or not is_finite(position_epsilon_units)
        or position_epsilon_units < 0.0
    ):
        return -1.0
    var segment_count := centerline.size() - 1
    for segment_index in range(segment_count):
        var start: Vector2 = centerline[segment_index]
        var finish: Vector2 = centerline[segment_index + 1]
        var delta := finish - start
        var length_squared := delta.length_squared()
        var weight := 0.0
        if length_squared > 0.0:
            weight = clampf(
                (target_position - start).dot(delta) / length_squared,
                0.0,
                1.0
            )
        var projection := start + delta * weight
        if projection.distance_to(target_position) <= position_epsilon_units:
            return (
                (float(segment_index) + weight)
                / float(segment_count)
                * float(nominal_length_cells)
            )
    return -1.0


func contacts_cell_in_nominal_range(
    cell: Vector2i,
    grid_origin_units: Vector2,
    cell_size_units: float,
    local_start_cells: float,
    local_end_cells: float,
    subdivisions_per_nominal_cell: int
) -> bool:
    if (
        cell_size_units <= 0.0
        or centerline.is_empty()
        or nominal_length_cells < 0
        or subdivisions_per_nominal_cell <= 0
        or not is_finite(local_start_cells)
        or not is_finite(local_end_cells)
        or local_end_cells < local_start_cells
    ):
        return false
    var bounded_start := clampf(
        local_start_cells, 0.0, float(nominal_length_cells)
    )
    var bounded_end := clampf(
        local_end_cells, 0.0, float(nominal_length_cells)
    )
    if bounded_end < bounded_start:
        return false
    var steps := maxi(
        1,
        int(ceil(
            (bounded_end - bounded_start)
            * float(subdivisions_per_nominal_cell)
        ))
    )
    for step in range(steps + 1):
        var weight := float(step) / float(steps)
        var local_distance := lerpf(bounded_start, bounded_end, weight)
        var position: Vector2 = sample_nominal(local_distance).position
        var mapped := Vector2i(
            int(floor((position.x - grid_origin_units.x) / cell_size_units)),
            int(floor((position.y - grid_origin_units.y) / cell_size_units))
        )
        if mapped == cell:
            return true
    return false


func sample_nominal(local_distance_cells: float) -> Dictionary:
    if centerline.is_empty():
        return {"position": Vector2.ZERO, "heading": Vector2.RIGHT}
    if centerline.size() == 1:
        return {"position": Vector2(centerline[0]), "heading": Vector2.RIGHT}
    var fraction := 0.0
    var bounded_distance := 0.0
    if nominal_length_cells > 0:
        bounded_distance = clampf(local_distance_cells, 0.0, float(nominal_length_cells))
        fraction = bounded_distance / float(nominal_length_cells)
    var scaled := fraction * float(centerline.size() - 1)
    var segment := mini(int(floor(scaled)), centerline.size() - 2)
    var weight := scaled - float(segment)
    var position: Vector2 = centerline[segment].lerp(centerline[segment + 1], weight)
    var heading: Vector2 = (centerline[segment + 1] - centerline[segment]).normalized()
    if is_zero_approx(bounded_distance) and not entry_heading_override.is_zero_approx():
        heading = entry_heading_override.normalized()
    elif is_equal_approx(bounded_distance, float(nominal_length_cells)) and not exit_heading_override.is_zero_approx():
        heading = exit_heading_override.normalized()
    if heading.is_zero_approx():
        for offset in range(1, centerline.size()):
            var fallback_index := mini(segment + offset, centerline.size() - 2)
            heading = (centerline[fallback_index + 1] - centerline[fallback_index]).normalized()
            if not heading.is_zero_approx():
                break
    if heading.is_zero_approx():
        heading = Vector2.RIGHT
    return {"position": position, "heading": heading}


func duplicate_active_slice(
    local_start_cells: float,
    local_end_cells: float
) -> RefCounted:
    var copy = duplicate_piece()
    copy.active_local_start_cells = clampf(local_start_cells, 0.0, float(nominal_length_cells))
    copy.active_local_end_cells = clampf(local_end_cells, copy.active_local_start_cells, float(nominal_length_cells))
    return copy


func duplicate_piece() -> RefCounted:
    var copy = get_script().new()
    copy.group_id = group_id
    copy.kind = kind
    copy.first_route_serial = first_route_serial
    copy.last_route_serial = last_route_serial
    copy.nominal_length_cells = nominal_length_cells
    copy.absolute_start_distance_cells = absolute_start_distance_cells
    copy.footprint_cells = footprint_cells.duplicate()
    copy.centerline = centerline.duplicate()
    copy.locked = locked
    copy.exit_support_route_serial = exit_support_route_serial
    copy.active_local_start_cells = active_local_start_cells
    copy.active_local_end_cells = active_local_end_cells
    copy.entry_heading_override = Vector2(entry_heading_override)
    copy.exit_heading_override = Vector2(exit_heading_override)
    return copy
