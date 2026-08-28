class_name RouteContactAnchor
extends RefCounted

enum ContactMode { CELL_ENTRY, EXACT_CELL_CENTER }

var anchor_id: StringName
var cell: Vector2i
var contact_mode: ContactMode


func _init(
    id: StringName = StringName(),
    grid_cell: Vector2i = Vector2i.ZERO,
    mode: ContactMode = ContactMode.CELL_ENTRY
) -> void:
    anchor_id = id
    cell = grid_cell
    contact_mode = mode


func duplicate_anchor() -> RefCounted:
    return get_script().new(anchor_id, cell, contact_mode)
