class_name TrackCellRecord
extends RefCounted

enum State { RESERVED_GHOST, BUILDING, BUILT }

var route_serial: int = 0
var cell: Vector2i = Vector2i.ZERO
var route_distance_start_cells: float = 0.0
var state: State = State.RESERVED_GHOST
var build_progress: float = 0.0
var geometry_group_id: int = -1
var geometry_locked: bool = false
var grade_separated_crossing: bool = false
var crossing_partner_route_serial: int = -1


func _init(
    route_serial_value: int = 0,
    cell_value: Vector2i = Vector2i.ZERO,
    route_distance_start_cells_value: float = 0.0,
    state_value: State = State.RESERVED_GHOST,
    build_progress_value: float = 0.0,
    geometry_group_id_value: int = -1,
    geometry_locked_value: bool = false,
    grade_separated_crossing_value: bool = false,
    crossing_partner_route_serial_value: int = -1
) -> void:
    route_serial = route_serial_value
    cell = cell_value
    route_distance_start_cells = route_distance_start_cells_value
    state = state_value
    build_progress = build_progress_value
    geometry_group_id = geometry_group_id_value
    geometry_locked = geometry_locked_value
    grade_separated_crossing = grade_separated_crossing_value
    crossing_partner_route_serial = crossing_partner_route_serial_value


func duplicate_record() -> RefCounted:
    return get_script().new(
        route_serial,
        cell,
        route_distance_start_cells,
        state,
        build_progress,
        geometry_group_id,
        geometry_locked,
        grade_separated_crossing,
        crossing_partner_route_serial
    )
