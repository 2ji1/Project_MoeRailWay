class_name TrackInputFrame
extends RefCounted

var cursor_position: Vector2
var cursor_inside_field: bool
var left_press_position: Vector2
var left_press_inside_field: bool
var right_press_position: Vector2
var right_press_inside_field: bool
var left_pressed: bool
var left_held: bool
var left_released: bool
var right_pressed: bool


func _init(
    cursor_position_value := Vector2.ZERO,
    cursor_inside_field_value := false,
    left_pressed_value := false,
    left_held_value := false,
    left_released_value := false,
    right_pressed_value := false,
    left_press_position_value := Vector2.ZERO,
    left_press_inside_field_value := false,
    right_press_position_value := Vector2.ZERO,
    right_press_inside_field_value := false
) -> void:
    cursor_position = cursor_position_value
    cursor_inside_field = cursor_inside_field_value
    left_press_position = left_press_position_value
    left_press_inside_field = left_press_inside_field_value
    right_press_position = right_press_position_value
    right_press_inside_field = right_press_inside_field_value
    left_pressed = left_pressed_value
    left_held = left_held_value
    left_released = left_released_value
    right_pressed = right_pressed_value


static func empty():
    return new()
