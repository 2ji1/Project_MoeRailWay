class_name SessionResult
extends RefCounted

enum Reason {
	REGULAR_TIME_EXPIRED,
	TRACK_END_REACHED,
	DURABILITY_DEPLETED,
}

var _reason: Reason
var _total_ticks: int
var _elapsed_ticks: int
var _remaining_ticks: int
var _delivered_pair_count: int
var _base_delivery_reward_total: int
var _maximum_durability: float
var _current_durability: float
var _repair_cost_basis: int


func _init(
	reason_value: Reason,
	total_ticks_value: int,
	elapsed_ticks_value: int,
	remaining_ticks_value: int,
	delivered_pair_count_value: int = 0,
	base_delivery_reward_total_value: int = 0,
	maximum_durability_value: float = 0.0,
	current_durability_value: float = 0.0,
	repair_cost_basis_value: int = 0
) -> void:
	_reason = reason_value
	_total_ticks = total_ticks_value
	_elapsed_ticks = elapsed_ticks_value
	_remaining_ticks = remaining_ticks_value
	_delivered_pair_count = delivered_pair_count_value
	_base_delivery_reward_total = base_delivery_reward_total_value
	_maximum_durability = maximum_durability_value
	_current_durability = current_durability_value
	_repair_cost_basis = repair_cost_basis_value


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


func get_maximum_durability() -> float:
	return _maximum_durability


func get_current_durability() -> float:
	return _current_durability


func get_durability_loss() -> float:
	return maxf(0.0, _maximum_durability - _current_durability)


func get_repair_cost_basis() -> int:
	return _repair_cost_basis
