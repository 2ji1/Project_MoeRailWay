class_name TrackInputFrame
extends RefCounted

var crossed_cells: Array[Vector2i]
var left_press_cell: Vector2i
var left_press_inside_grid: bool
var right_press_cell: Vector2i
var right_press_inside_grid: bool
var left_pressed: bool
var left_held: bool
var left_released: bool
var right_pressed: bool


func _init(
	crossed_cells_value: Array[Vector2i] = [],
	left_press_cell_value: Vector2i = Vector2i(-1, -1),
	left_press_inside_grid_value: bool = false,
	right_press_cell_value: Vector2i = Vector2i(-1, -1),
	right_press_inside_grid_value: bool = false,
	left_pressed_value: bool = false,
	left_held_value: bool = false,
	left_released_value: bool = false,
	right_pressed_value: bool = false
) -> void:
	crossed_cells = crossed_cells_value.duplicate()
	left_press_cell = left_press_cell_value
	left_press_inside_grid = left_press_inside_grid_value
	right_press_cell = right_press_cell_value
	right_press_inside_grid = right_press_inside_grid_value
	left_pressed = left_pressed_value
	left_held = left_held_value
	left_released = left_released_value
	right_pressed = right_pressed_value


static func empty() -> TrackInputFrame:
	return load("res://src/domain/track/track_input_frame.gd").new()
