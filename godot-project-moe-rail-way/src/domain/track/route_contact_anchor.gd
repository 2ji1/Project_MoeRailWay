class_name RouteContactAnchor
extends RefCounted

var anchor_id: StringName
var cell: Vector2i


func _init(id: StringName = StringName(), grid_cell: Vector2i = Vector2i.ZERO) -> void:
    anchor_id = id
    cell = grid_cell


func duplicate_anchor() -> RefCounted:
    return get_script().new(anchor_id, cell)
