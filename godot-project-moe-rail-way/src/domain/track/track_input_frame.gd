class_name TrackInputFrame
extends RefCounted

var crossed_cells: Array[Vector2i]
var live_gesture_path: Array[Vector2i]
var left_press_cell: Vector2i
var left_press_inside_grid: bool
var right_press_cell: Vector2i
var right_press_inside_grid: bool
var left_pressed: bool
var left_held: bool
var left_released: bool
var right_pressed: bool
var current_pointer_cell: Vector2i
var current_pointer_inside_grid: bool
var release_live_gesture_path: Array[Vector2i]
var left_release_pointer_cell: Vector2i
var left_release_pointer_inside_grid: bool
var has_explicit_release_snapshot: bool
var allows_bounded_reentry_connection: bool


func _init(
	crossed_cells_value: Array[Vector2i] = [],
	left_press_cell_value: Vector2i = Vector2i(-1, -1),
	left_press_inside_grid_value: bool = false,
	right_press_cell_value: Vector2i = Vector2i(-1, -1),
	right_press_inside_grid_value: bool = false,
	left_pressed_value: bool = false,
	left_held_value: bool = false,
	left_released_value: bool = false,
	right_pressed_value: bool = false,
	current_pointer_cell_value: Vector2i = Vector2i(-1, -1),
	current_pointer_inside_grid_value: bool = false,
	live_gesture_path_value: Variant = null,
	release_live_gesture_path_value: Variant = null,
	left_release_pointer_cell_value: Vector2i = Vector2i(-1, -1),
	left_release_pointer_inside_grid_value: bool = false,
	allows_bounded_reentry_connection_value: bool = false
) -> void:
	crossed_cells = crossed_cells_value.duplicate()
	live_gesture_path = []
	var source_path: Array = crossed_cells_value if live_gesture_path_value == null else live_gesture_path_value
	for cell in source_path:
		live_gesture_path.append(Vector2i(cell))
	left_press_cell = left_press_cell_value
	left_press_inside_grid = left_press_inside_grid_value
	right_press_cell = right_press_cell_value
	right_press_inside_grid = right_press_inside_grid_value
	left_pressed = left_pressed_value
	left_held = left_held_value
	left_released = left_released_value
	right_pressed = right_pressed_value
	current_pointer_cell = current_pointer_cell_value
	current_pointer_inside_grid = current_pointer_inside_grid_value
	release_live_gesture_path = []
	if release_live_gesture_path_value != null:
		for cell in release_live_gesture_path_value:
			release_live_gesture_path.append(Vector2i(cell))
	left_release_pointer_cell = left_release_pointer_cell_value
	left_release_pointer_inside_grid = left_release_pointer_inside_grid_value
	has_explicit_release_snapshot = release_live_gesture_path_value != null
	allows_bounded_reentry_connection = allows_bounded_reentry_connection_value


static func empty() -> TrackInputFrame:
	return load("res://src/domain/track/track_input_frame.gd").new()
