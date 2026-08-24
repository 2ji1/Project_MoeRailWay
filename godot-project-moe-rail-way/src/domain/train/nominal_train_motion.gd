class_name NominalTrainMotion
extends RefCounted

const ENDPOINT_EPSILON := 0.000001

var _speed_cells_per_second: float
var _route_distance_cells := 0.0
var _active := false


func _init(speed_cells_per_second: float) -> void:
    assert(speed_cells_per_second > 0.0, "Train speed must be positive")
    _speed_cells_per_second = speed_cells_per_second


func depart(route_distance_cells: float = 0.0) -> void:
    assert(route_distance_cells >= 0.0, "Departure distance must be non-negative")
    if _active:
        return
    _route_distance_cells = route_distance_cells
    _active = true


func advance(built_end_distance_cells: float, seconds_per_tick: float) -> bool:
    assert(built_end_distance_cells >= 0.0, "Built endpoint must be non-negative")
    assert(seconds_per_tick > 0.0, "Tick duration must be positive")
    if not _active:
        return false
    var endpoint := maxf(built_end_distance_cells, _route_distance_cells)
    var requested := _route_distance_cells + _speed_cells_per_second * seconds_per_tick
    if requested + ENDPOINT_EPSILON >= endpoint:
        _route_distance_cells = endpoint
        return true
    _route_distance_cells = requested
    return false


func is_active() -> bool:
    return _active


func get_route_distance_cells() -> float:
    return _route_distance_cells
