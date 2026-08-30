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
var _final_session_cash: int
var _total_session_cash_spent: int
var _temporary_track_purchase_count: int
var _temporary_cargo_purchase_count: int
var _final_total_track_cells: int
var _final_total_cargo_slots: int


func _init(
	reason_value: Reason,
	total_ticks_value: int,
	elapsed_ticks_value: int,
	remaining_ticks_value: int,
	delivered_pair_count_value: int = 0,
	base_delivery_reward_total_value: int = 0,
	maximum_durability_value: float = 0.0,
	current_durability_value: float = 0.0,
	repair_cost_basis_value: int = 0,
	final_session_cash_value: int = 0,
	total_session_cash_spent_value: int = 0,
	temporary_track_purchase_count_value: int = 0,
	temporary_cargo_purchase_count_value: int = 0,
	final_total_track_cells_value: int = 0,
	final_total_cargo_slots_value: int = 0
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
	_final_session_cash = final_session_cash_value
	_total_session_cash_spent = total_session_cash_spent_value
	_temporary_track_purchase_count = temporary_track_purchase_count_value
	_temporary_cargo_purchase_count = temporary_cargo_purchase_count_value
	_final_total_track_cells = final_total_track_cells_value
	_final_total_cargo_slots = final_total_cargo_slots_value


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


func get_final_session_cash() -> int:
	return _final_session_cash


func get_total_session_cash_spent() -> int:
	return _total_session_cash_spent


func get_temporary_track_purchase_count() -> int:
	return _temporary_track_purchase_count


func get_temporary_cargo_purchase_count() -> int:
	return _temporary_cargo_purchase_count


func get_final_total_track_cells() -> int:
	return _final_total_track_cells


func get_final_total_cargo_slots() -> int:
	return _final_total_cargo_slots
