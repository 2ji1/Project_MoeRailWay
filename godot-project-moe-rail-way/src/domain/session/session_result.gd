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
var _delivered_pair_count: int
var _base_delivery_reward_total: int


func _init(
	reason_value: Reason,
	total_ticks_value: int,
	elapsed_ticks_value: int,
	remaining_ticks_value: int,
	delivered_pair_count_value: int = 0,
	base_delivery_reward_total_value: int = 0
) -> void:
	_reason = reason_value
	_total_ticks = total_ticks_value
	_elapsed_ticks = elapsed_ticks_value
	_remaining_ticks = remaining_ticks_value
	_delivered_pair_count = delivered_pair_count_value
	_base_delivery_reward_total = base_delivery_reward_total_value


func get_reason() -> Reason:
	return _reason


func get_total_ticks() -> int:
	return _total_ticks


func get_elapsed_ticks() -> int:
	return _elapsed_ticks


func get_remaining_ticks() -> int:
	return _remaining_ticks


func get_delivered_pair_count() -> int:
	return _delivered_pair_count


func get_base_delivery_reward_total() -> int:
	return _base_delivery_reward_total
