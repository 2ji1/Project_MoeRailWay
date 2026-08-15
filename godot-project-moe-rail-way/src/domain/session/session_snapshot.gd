class_name SessionSnapshot
extends RefCounted

var _total_ticks: int
var _elapsed_ticks: int
var _remaining_ticks: int
var _ticks_per_second: int


func _init(
    total_ticks_value: int,
    elapsed_ticks_value: int,
    remaining_ticks_value: int,
    ticks_per_second_value: int
) -> void:
    _total_ticks = total_ticks_value
    _elapsed_ticks = elapsed_ticks_value
    _remaining_ticks = remaining_ticks_value
    _ticks_per_second = ticks_per_second_value


func get_total_ticks() -> int:
    return _total_ticks


func get_elapsed_ticks() -> int:
    return _elapsed_ticks


func get_remaining_ticks() -> int:
    return _remaining_ticks


func get_ticks_per_second() -> int:
    return _ticks_per_second


func get_display_seconds() -> int:
    if _remaining_ticks <= 0:
        return 0
    return int(ceil(float(_remaining_ticks) / float(_ticks_per_second)))
