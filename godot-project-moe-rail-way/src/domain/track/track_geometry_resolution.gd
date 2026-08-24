class_name TrackGeometryResolution
extends RefCounted

const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")

var is_valid := false
var pieces: Array[TrackGeometryPieceScript] = []
var rejected_route_serial := -1
var reason := StringName()


static func accepted(value: Array) -> RefCounted:
    var result = load("res://src/domain/track/track_geometry_resolution.gd").new()
    result.is_valid = true
    for piece in value:
        result.pieces.append(piece.duplicate_piece())
    return result


static func rejected(route_serial: int, reason_value: StringName) -> RefCounted:
    var result = load("res://src/domain/track/track_geometry_resolution.gd").new()
    result.rejected_route_serial = route_serial
    result.reason = reason_value
    return result


func duplicate_resolution() -> RefCounted:
    if is_valid:
        return get_script().accepted(pieces)
    return get_script().rejected(rejected_route_serial, reason)
