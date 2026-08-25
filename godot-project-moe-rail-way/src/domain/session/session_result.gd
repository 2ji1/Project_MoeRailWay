class_name SessionResult
extends RefCounted

enum Reason {
	REGULAR_TIME_EXPIRED,
	TRACK_END_REACHED,
}

var _reason: Reason
var _total_ticks: int
var _elapsed_ticks: int
var _remaining_ticks: int


func _init(
	reason_value: Reason,
	total_ticks_value: int,
	elapsed_ticks_value: int,
	remaining_ticks_value: int
) -> void:
	_reason = reason_value
	_total_ticks = total_ticks_value
	_elapsed_ticks = elapsed_ticks_value
	_remaining_ticks = remaining_ticks_value


func get_reason() -> Reason:
	return _reason


func get_total_ticks() -> int:
	return _total_ticks


func get_elapsed_ticks() -> int:
	return _elapsed_ticks


func get_remaining_ticks() -> int:
	return _remaining_ticks
