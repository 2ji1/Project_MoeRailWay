class_name SettlementResult
extends RefCounted

var _completion_reason: int
var _selected_company_id: StringName
var _session_starting_cash: int
var _delivery_fee_total: int
var _session_spending: int
var _settlement_opening_cash: int
var _contracted_delivery_count: int
var _contract_quota: int
var _contract_attainment_basis_points: int
var _contract_adjustment: int
var _trust_gain_milli: int
var _repair_cost: int
var _operating_cost: int
var _closing_cash: int
var _completed_cycle_count: int
var _next_session_starts_full_durability: bool
var _session_only_increases_cleared: bool
var _credit_survival_observation: Dictionary


func _init(
	completion_reason_value: int,
	selected_company_id_value: StringName,
	session_starting_cash_value: int,
	delivery_fee_total_value: int,
	session_spending_value: int,
	settlement_opening_cash_value: int,
	contracted_delivery_count_value: int,
	contract_quota_value: int,
	contract_attainment_basis_points_value: int,
	contract_adjustment_value: int,
	trust_gain_milli_value: int,
	repair_cost_value: int,
	operating_cost_value: int,
	closing_cash_value: int,
	completed_cycle_count_value: int,
	next_session_starts_full_durability_value: bool,
	session_only_increases_cleared_value: bool,
	credit_survival_observation_value: Dictionary
) -> void:
	_completion_reason = completion_reason_value
	_selected_company_id = selected_company_id_value
	_session_starting_cash = session_starting_cash_value
	_delivery_fee_total = delivery_fee_total_value
	_session_spending = session_spending_value
	_settlement_opening_cash = settlement_opening_cash_value
	_contracted_delivery_count = contracted_delivery_count_value
	_contract_quota = contract_quota_value
	_contract_attainment_basis_points = contract_attainment_basis_points_value
	_contract_adjustment = contract_adjustment_value
	_trust_gain_milli = trust_gain_milli_value
	_repair_cost = repair_cost_value
	_operating_cost = operating_cost_value
	_closing_cash = closing_cash_value
	_completed_cycle_count = completed_cycle_count_value
	_next_session_starts_full_durability = next_session_starts_full_durability_value
	_session_only_increases_cleared = session_only_increases_cleared_value
	_credit_survival_observation = credit_survival_observation_value.duplicate(true)


func get_completion_reason() -> int:
	return _completion_reason


func get_selected_company_id() -> StringName:
	return _selected_company_id


func get_session_starting_cash() -> int:
	return _session_starting_cash


func get_delivery_fee_total() -> int:
	return _delivery_fee_total


func get_session_spending() -> int:
	return _session_spending


func get_settlement_opening_cash() -> int:
	return _settlement_opening_cash


func get_contracted_delivery_count() -> int:
	return _contracted_delivery_count


func get_contract_quota() -> int:
	return _contract_quota


func get_contract_attainment_basis_points() -> int:
	return _contract_attainment_basis_points


func get_contract_adjustment() -> int:
	return _contract_adjustment


func get_trust_gain_milli() -> int:
	return _trust_gain_milli


func get_repair_cost() -> int:
	return _repair_cost


func get_operating_cost() -> int:
	return _operating_cost


func get_closing_cash() -> int:
	return _closing_cash


func get_completed_cycle_count() -> int:
	return _completed_cycle_count


func does_next_session_start_at_full_durability() -> bool:
	return _next_session_starts_full_durability


func are_session_only_increases_cleared() -> bool:
	return _session_only_increases_cleared


func get_ordered_line_items() -> Array[Dictionary]:
	return [
		{"id": &"session_starting_cash", "amount": _session_starting_cash, "informational": false},
		{"id": &"delivery_fee_total", "amount": _delivery_fee_total, "informational": true},
		{"id": &"session_spending", "amount": _session_spending, "informational": true},
		{"id": &"settlement_opening_cash", "amount": _settlement_opening_cash, "informational": false},
		{"id": &"contract_adjustment", "amount": _contract_adjustment, "informational": false},
		{"id": &"trust_gain_milli", "amount": _trust_gain_milli, "informational": false},
		{"id": &"repair_cost", "amount": _repair_cost, "informational": false},
		{"id": &"operating_cost", "amount": _operating_cost, "informational": false},
		{"id": &"closing_cash", "amount": _closing_cash, "informational": false},
	].duplicate(true)


func get_credit_survival_observation() -> Dictionary:
	return _credit_survival_observation.duplicate(true)


func get_observation() -> Dictionary:
	return {
		"completion_reason": _completion_reason,
		"selected_company_id": _selected_company_id,
		"contracted_delivery_count": _contracted_delivery_count,
		"contract_quota": _contract_quota,
		"contract_attainment_basis_points": _contract_attainment_basis_points,
		"ordered_line_items": get_ordered_line_items(),
		"completed_cycle_count": _completed_cycle_count,
		"next_session_starts_full_durability": _next_session_starts_full_durability,
		"session_only_increases_cleared": _session_only_increases_cleared,
		"credit_survival": get_credit_survival_observation(),
	}
