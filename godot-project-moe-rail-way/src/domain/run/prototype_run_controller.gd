class_name PrototypeRunController
extends RefCounted

const RunStateScript = preload("res://src/domain/run/run_state.gd")
const SessionEconomyScript = preload("res://src/domain/economy/session_economy.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SettlementResultScript = preload("res://src/domain/run/settlement_result.gd")
const ContractSystemScript = preload("res://src/domain/contract/contract_system.gd")
const MAX_INT := 9223372036854775807

enum Phase {
	OPERATIONS,
	SESSION,
	RESULTS,
}

var _run_state: RunStateScript
var _base_operating_cost: int
var _phase := Phase.OPERATIONS
var _selected_contract: Dictionary = {}
var _session_starting_cash := 0
var _settlement_result: SettlementResultScript


func _init(run_state: RunStateScript, base_operating_cost: int) -> void:
	assert(run_state != null, "Prototype run state is required")
	assert(base_operating_cost >= 0 and base_operating_cost <= 1000000, "Base operating cost must be between 0 and 1000000")
	_run_state = run_state
	_base_operating_cost = base_operating_cost


func try_select_contract(contract: Dictionary) -> bool:
	if _phase != Phase.OPERATIONS or not _is_valid_contract(contract):
		return false
	_selected_contract = contract.duplicate(true)
	return true


func can_start_session() -> bool:
	return (
		_phase == Phase.OPERATIONS
		and not _selected_contract.is_empty()
		and _run_state.get_cash() >= 0
	)


func try_start_session() -> SessionEconomyScript:
	if not can_start_session():
		return null
	var session_economy := SessionEconomyScript.new(_run_state.get_cash())
	_session_starting_cash = _run_state.get_cash()
	_settlement_result = null
	_phase = Phase.SESSION
	return session_economy


func try_settle_session(session_result: SessionResultScript) -> SettlementResultScript:
	if (
		_phase != Phase.SESSION
		or _settlement_result != null
		or not _is_valid_session_result(session_result)
	):
		return null
	var opening_cash := session_result.get_final_session_cash()
	var contract_adjustment := session_result.get_cash_contract_adjustment()
	var repair_cost := session_result.get_repair_cost_basis()
	var trust_gain := session_result.get_contract_trust_gain_milli()
	if not _run_state.can_set_cash(opening_cash):
		return null
	var after_contract: Variant = _cash_after_delta(opening_cash, contract_adjustment)
	if after_contract == null:
		return null
	var after_repair: Variant = _cash_after_delta(int(after_contract), -repair_cost)
	if after_repair == null:
		return null
	var closing_cash: Variant = _cash_after_delta(int(after_repair), -_base_operating_cost)
	if closing_cash == null:
		return null
	var company_id := session_result.get_selected_contract_company_id()
	if (
		not _run_state.can_add_company_trust_milli(company_id, trust_gain)
		or not _run_state.can_increment_completed_cycle()
	):
		return null

	var candidate := _run_state.duplicate_state()
	candidate.set_cash(int(closing_cash))
	candidate.add_company_trust_milli(company_id, trust_gain)
	candidate.increment_completed_cycle()
	var credit_observation := candidate.get_observation()
	credit_observation["session_starting_cash"] = _session_starting_cash
	credit_observation["delivery_fee_total"] = session_result.get_delivery_fee_total()
	credit_observation["session_spending"] = session_result.get_total_session_cash_spent()
	credit_observation["settlement_opening_cash"] = opening_cash
	credit_observation["selected_company_id"] = company_id
	credit_observation["contracted_delivery_count"] = session_result.get_contracted_delivery_count()
	credit_observation["contract_quota"] = session_result.get_contract_quota()
	credit_observation["contract_attainment_basis_points"] = session_result.get_contract_attainment_basis_points()
	credit_observation["contract_adjustment"] = contract_adjustment
	credit_observation["trust_gain_milli"] = trust_gain
	credit_observation["repair_cost"] = repair_cost
	credit_observation["operating_cost"] = _base_operating_cost
	credit_observation["closing_cash"] = int(closing_cash)
	credit_observation["session_start_blocked"] = int(closing_cash) < 0
	var settlement := SettlementResultScript.new(
		session_result.get_reason(),
		company_id,
		_session_starting_cash,
		session_result.get_delivery_fee_total(),
		session_result.get_total_session_cash_spent(),
		opening_cash,
		session_result.get_contracted_delivery_count(),
		session_result.get_contract_quota(),
		session_result.get_contract_attainment_basis_points(),
		contract_adjustment,
		trust_gain,
		repair_cost,
		_base_operating_cost,
		int(closing_cash),
		candidate.get_completed_cycle_count(),
		true,
		true,
		credit_observation
	)
	_run_state.replace_with(candidate)
	_settlement_result = settlement
	_phase = Phase.RESULTS
	return _settlement_result


func try_continue_to_operations() -> bool:
	if _phase != Phase.RESULTS:
		return false
	_phase = Phase.OPERATIONS
	_selected_contract = {}
	return true


func get_phase() -> Phase:
	return _phase


func get_run_state_observation() -> Dictionary:
	return _run_state.get_observation()


func get_selected_contract() -> Dictionary:
	return _selected_contract.duplicate(true)


func get_settlement_result() -> SettlementResultScript:
	return _settlement_result


func _is_valid_contract(contract: Dictionary) -> bool:
	var company_id := StringName(contract.get("company_id", StringName()))
	var quota := int(contract.get("quota", 0))
	var maximum_shortfall_penalty := int(contract.get("maximum_shortfall_penalty", -1))
	var completion_bonus_at_quota := int(contract.get("completion_bonus_at_quota", -1))
	var trust_per_excess_delivery_milli := int(contract.get("trust_per_excess_delivery_milli", -1))
	return (
		not company_id.is_empty()
		and _run_state.has_company(company_id)
		and quota >= 1
		and quota <= 1000000
		and maximum_shortfall_penalty >= 0
		and maximum_shortfall_penalty <= 1000000
		and completion_bonus_at_quota >= 0
		and completion_bonus_at_quota <= 1000000
		and trust_per_excess_delivery_milli >= 0
		and trust_per_excess_delivery_milli <= 1000000
	)


func _is_valid_session_result(result: SessionResultScript) -> bool:
	if result == null:
		return false
	if result.get_reason() not in [
		SessionResultScript.Reason.REGULAR_TIME_EXPIRED,
		SessionResultScript.Reason.TRACK_END_REACHED,
		SessionResultScript.Reason.DURABILITY_DEPLETED,
	]:
		return false
	if (
		result.get_selected_contract_company_id()
			!= StringName(_selected_contract.get("company_id", StringName()))
		or result.get_contract_quota() != int(_selected_contract.get("quota", 0))
		or result.get_delivery_fee_total() < 0
		or result.get_total_session_cash_spent() < 0
		or result.get_repair_cost_basis() < 0
		or result.get_contract_trust_gain_milli() < 0
	):
		return false
	var delivery_count := result.get_contracted_delivery_count()
	var quota := int(_selected_contract["quota"])
	var trust_rate := int(_selected_contract["trust_per_excess_delivery_milli"])
	if delivery_count < 0 or delivery_count > MAX_INT / 10000:
		return false
	var excess_delivery_count := maxi(delivery_count - quota, 0)
	if trust_rate > 0 and excess_delivery_count > MAX_INT / trust_rate:
		return false
	if (
		result.get_contract_attainment_basis_points()
			!= ContractSystemScript.calculate_attainment_basis_points(delivery_count, quota)
		or result.get_cash_contract_adjustment()
			!= ContractSystemScript.calculate_cash_contract_adjustment(
				delivery_count,
				quota,
				int(_selected_contract["maximum_shortfall_penalty"]),
				int(_selected_contract["completion_bonus_at_quota"])
			)
		or result.get_contract_trust_gain_milli()
			!= ContractSystemScript.calculate_trust_gain_milli(
				delivery_count,
				quota,
				trust_rate
			)
	):
		return false
	var fee_total := result.get_delivery_fee_total()
	if fee_total > MAX_INT - _session_starting_cash:
		return false
	var cash_before_spending := _session_starting_cash + fee_total
	var spending := result.get_total_session_cash_spent()
	return spending <= cash_before_spending and cash_before_spending - spending == result.get_final_session_cash()


func _cash_after_delta(cash: int, delta: int) -> Variant:
	if delta > 0 and cash > RunStateScript.MAX_ABSOLUTE_CASH - delta:
		return null
	if delta < 0 and cash < -RunStateScript.MAX_ABSOLUTE_CASH - delta:
		return null
	var value := cash + delta
	return value if _run_state.can_set_cash(value) else null
