class_name TrainSystem
extends RefCounted

const TrackSystemScript = preload("res://src/domain/track/track_system.gd")

var _speed_units_per_second := 0.0
var _route_distance := 0.0
var _active := false


func _init(speed_units_per_second: float) -> void:
    assert(speed_units_per_second > 0.0, "Train speed must be positive")
    _speed_units_per_second = speed_units_per_second


func depart(route_distance := 0.0) -> void:
    assert(route_distance >= 0.0, "Departure distance must be non-negative")
    if _active:
        return
    _route_distance = route_distance
    _active = true


func advance_tick(
    track_system: TrackSystemScript,
    seconds_per_tick: float
) -> bool:
    assert(track_system != null, "Track system is required")
    assert(seconds_per_tick > 0.0, "Tick duration must be positive")
    _assert_route_access(track_system)
    if not _active:
        return false
    var requested_distance := (
        _route_distance + _speed_units_per_second * seconds_per_tick
    )
    var built_end := track_system.get_built_end_distance()
    if requested_distance + TrackSystemScript.GEOMETRY_EPSILON >= built_end:
        _route_distance = built_end
        return true
    _route_distance = requested_distance
    return false


func is_active() -> bool:
    return _active


func get_route_distance() -> float:
    return _route_distance


func get_position(track_system: TrackSystemScript) -> Vector2:
    assert(track_system != null, "Track system is required")
    _assert_route_access(track_system)
    return track_system.get_position_at_distance(_route_distance)


func get_heading(track_system: TrackSystemScript) -> Vector2:
    assert(track_system != null, "Track system is required")
    _assert_route_access(track_system)
    return track_system.get_heading_at_distance(_route_distance)


func _assert_route_access(track_system: TrackSystemScript) -> void:
    assert(
        _route_distance + TrackSystemScript.GEOMETRY_EPSILON
            >= track_system.get_active_start_distance(),
        "Train route distance cannot be behind active track"
    )
