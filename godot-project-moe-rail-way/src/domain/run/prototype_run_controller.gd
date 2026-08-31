class_name PrototypeRunController
extends RefCounted

const RunStateScript = preload("res://src/domain/run/run_state.gd")
const SessionEconomyScript = preload("res://src/domain/economy/session_economy.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SettlementResultScript = preload("res://src/domain/run/settlement_result.gd")
const ContractSystemScript = preload("res://src/domain/contract/contract_system.gd")
const CreditSystemScript = preload("res://src/domain/credit/credit_system.gd")
const TerminalRunResultScript = preload("res://src/domain/run/terminal_run_result.gd")
const MAX_INT := 9223372036854775807

enum Phase {
	OPERATIONS,
	SESSION,
	RESULTS,
	TERMINAL,
}

var _run_state: RunStateScript
var _base_operating_cost: int
var _phase := Phase.OPERATIONS
var _selected_contract: Dictionary = {}
var _session_starting_cash := 0
var _settlement_result: SettlementResultScript
var _credit_balance: Resource
var _last_borrow_result: Dictionary = {}
var _next_settlement_identity := 1
var _active_settlement_identity := 0
var _selected_cycle := 0
var _recovery_mode := false
var _terminal_result: TerminalRunResultScript
var _cycle_progression: RefCounted


func _init(run_state: RunStateScript, base_operating_cost: int, credit_balance: Resource = null, cycle_progression: RefCounted = null) -> void:
	assert(run_state != null, "Prototype run state is required")
	assert(base_operating_cost >= 0 and base_operating_cost <= 1000000, "Base operating cost must be between 0 and 1000000")
	_run_state = run_state
	_base_operating_cost = base_operating_cost
	_credit_balance = credit_balance
	_cycle_progression = cycle_progression


func try_borrow(company_id: StringName, amount: int) -> bool:
	if _phase != Phase.OPERATIONS or _credit_balance == null: return false
	var loan = CreditSystemScript.create_borrow_proposal(_run_state, _credit_balance, company_id, amount)
	if loan == null or amount > RunStateScript.MAX_ABSOLUTE_CASH - _run_state.get_cash(): return false
	var candidate := _run_state.duplicate_state()
	candidate.set_cash(_run_state.get_cash() + amount)
	candidate.append_loan(loan)
	var borrow_result := {
		"loan": loan.get_observation(),
		"cash_before": _run_state.get_cash(),
		"cash_after": candidate.get_cash(),
		"credit_revision": candidate.get_credit_revision(),
	}
	_run_state.replace_with(candidate)
	_last_borrow_result = borrow_result
	if _recovery_mode and _run_state.get_cash() >= 0:
		_recovery_mode = false
	return true


func get_last_borrow_result() -> Dictionary:
	return _last_borrow_result.duplicate(true)


func try_select_contract(contract: Dictionary) -> bool:
	if _phase != Phase.OPERATIONS or _recovery_mode or not _run_state.can_increment_completed_cycle() or not _is_valid_contract(contract):
		return false
	_selected_contract = contract.duplicate(true)
	_selected_cycle = _run_state.get_completed_cycle_count() + 1
	return true


func try_cancel_contract() -> bool:
	if _phase != Phase.OPERATIONS or _recovery_mode or _selected_contract.is_empty(): return false
	_selected_contract = {}
	_selected_cycle = 0
	return true


func can_start_session() -> bool:
	return (
		_phase == Phase.OPERATIONS
		and not _selected_contract.is_empty()
		and _selected_cycle == _run_state.get_completed_cycle_count() + 1
		and _run_state.get_cash() >= 0
	)


func try_start_session() -> SessionEconomyScript:
	if not can_start_session() or _next_settlement_identity >= MAX_INT:
		return null
	var session_economy := SessionEconomyScript.new(_run_state.get_cash())
	_session_starting_cash = _run_state.get_cash()
	_settlement_result = null
	_active_settlement_identity = _next_settlement_identity
	_phase = Phase.SESSION
	return session_economy


func create_debt_service_quote():
	if _phase != Phase.SESSION or _active_settlement_identity < 1: return null
	return CreditSystemScript.create_debt_service_quote(_run_state, _active_settlement_identity, _run_state.get_completed_cycle_count() + 1)


func try_settle_session(session_result: SessionResultScript, supplied_quote = null, inject_pre_install_failure: bool = false) -> SettlementResultScript:
	if (
		_phase != Phase.SESSION
		or _settlement_result != null
		or not _is_valid_session_result(session_result)
		or _selected_cycle != _run_state.get_completed_cycle_count() + 1
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
	var after_operating: Variant = _cash_after_delta(int(after_repair), -_base_operating_cost)
	if after_operating == null:
		return null
	var company_id := session_result.get_selected_contract_company_id()
	if (
		not _run_state.can_add_company_trust_milli(company_id, trust_gain)
		or not _run_state.can_increment_completed_cycle()
	):
		return null
	var settlement_cycle := _selected_cycle
	var debt_quote = supplied_quote if supplied_quote != null else create_debt_service_quote()
	if not CreditSystemScript.is_debt_service_quote_valid(_run_state, debt_quote, _active_settlement_identity, settlement_cycle):
		return null
	if debt_quote.has_payments() and _run_state.get_credit_revision() >= MAX_INT:
		return null
	var debt_total: Variant = _checked_nonnegative_sum(debt_quote.get_principal_total(), debt_quote.get_interest_total())
	if debt_total == null:
		return null
	var closing_cash: Variant = _cash_after_delta(int(after_operating), -int(debt_total))
	if closing_cash == null:
		return null

	var candidate := _run_state.duplicate_state()
	candidate.set_cash(int(closing_cash))
	candidate.add_company_trust_milli(company_id, trust_gain)
	candidate.increment_completed_cycle()
	candidate.apply_debt_service_quote(debt_quote)
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
	credit_observation["debt_service"] = debt_quote.get_observation()
	credit_observation["debt_principal_paid"] = debt_quote.get_principal_total()
	credit_observation["debt_interest_paid"] = debt_quote.get_interest_total()
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
		credit_observation,
		debt_quote.get_principal_total(),
		debt_quote.get_interest_total()
	)
	if inject_pre_install_failure:
		return null
	_run_state.replace_with(candidate)
	_settlement_result = settlement
	_phase = Phase.RESULTS
	_next_settlement_identity += 1
	_active_settlement_identity = 0
	return _settlement_result


func try_continue_to_operations(inject_terminal_failure: bool = false) -> bool:
	if _phase != Phase.RESULTS:
		return false
	if _run_state.get_cash() < 0:
		var recovery := CreditSystemScript.get_recovery_observation(_run_state, _credit_balance)
		if recovery.is_empty() or not bool(recovery.get("recovery_possible", false)):
			return _commit_terminal(TerminalRunResultScript.Reason.CREDIT_EXHAUSTED, recovery, inject_terminal_failure)
		_phase = Phase.OPERATIONS
		_recovery_mode = true
		_selected_contract = {}
		_selected_cycle = 0
		return true
	_phase = Phase.OPERATIONS
	_recovery_mode = false
	_selected_contract = {}
	_selected_cycle = 0
	return true


func try_decline_recovery(inject_terminal_failure: bool = false) -> bool:
	if _phase != Phase.OPERATIONS or not _recovery_mode or _run_state.get_cash() >= 0: return false
	var recovery := CreditSystemScript.get_recovery_observation(_run_state, _credit_balance)
	return _commit_terminal(TerminalRunResultScript.Reason.RECOVERY_DECLINED, recovery, inject_terminal_failure)


func get_phase() -> Phase:
	return _phase


func get_run_state_observation() -> Dictionary:
	return _run_state.get_observation()


func get_operations_observation() -> Dictionary:
	var observation := _run_state.get_observation()
	var cycle := _run_state.get_completed_cycle_count() + 1 if _run_state.can_increment_completed_cycle() else 0
	var debt_quote = CreditSystemScript.create_debt_service_quote(_run_state, 1, cycle) if cycle > 0 else null
	var due_by_company := {}
	var schedules_by_company := {}
	for company_id in _run_state.get_company_ids():
		due_by_company[company_id] = {"principal": 0, "interest": 0}
		schedules_by_company[company_id] = []
	if debt_quote != null:
		for item in debt_quote.get_items():
			var company_id := StringName(item.get("company_id", StringName()))
			var due: Dictionary = due_by_company.get(company_id, {"principal": 0, "interest": 0})
			due["principal"] = int(due["principal"]) + int(item.get("principal", 0))
			due["interest"] = int(due["interest"]) + int(item.get("interest", 0))
			due_by_company[company_id] = due
			schedules_by_company[company_id].append(item.duplicate(true))
	var companies: Array[Dictionary] = []
	for company_id in _run_state.get_company_ids():
		var trust := _run_state.get_company_trust_milli(company_id)
		var limit: int = _credit_balance.get_credit_limit(company_id, trust) if _credit_balance != null else 0
		var remaining: int = CreditSystemScript.get_remaining_credit(_run_state, _credit_balance, company_id) if _credit_balance != null else 0
		var borrow_disabled_reason := ""
		if remaining <= 0:
			borrow_disabled_reason = "NO REMAINING CREDIT"
		elif RunStateScript.MAX_ABSOLUTE_CASH - _run_state.get_cash() <= 0:
			borrow_disabled_reason = "RUN CASH LIMIT"
		elif _run_state.get_next_loan_id() >= MAX_INT:
			borrow_disabled_reason = "LOAN ID LIMIT"
		elif _run_state.get_credit_revision() >= MAX_INT:
			borrow_disabled_reason = "CREDIT REVISION LIMIT"
		elif not _run_state.can_increment_completed_cycle():
			borrow_disabled_reason = "CYCLE LIMIT"
		var borrow_capacity := 0 if not borrow_disabled_reason.is_empty() else mini(remaining, RunStateScript.MAX_ABSOLUTE_CASH - _run_state.get_cash())
		var due: Dictionary = due_by_company[company_id]
		companies.append({
			"company_id": company_id,
			"trust_milli": trust,
			"next_limit_trust_milli": _credit_balance.get_next_limit_trust(company_id, trust) if _credit_balance != null else -1,
			"credit_limit": limit,
			"outstanding_principal": CreditSystemScript.get_outstanding_principal(_run_state, company_id),
			"remaining_credit": remaining,
			"borrow_capacity": borrow_capacity,
			"borrow_disabled_reason": borrow_disabled_reason,
			"rate_basis_points": _run_state.get_company_rate_basis_points(company_id),
			"next_principal": int(due["principal"]),
			"next_interest": int(due["interest"]),
			"schedule": schedules_by_company[company_id],
		})
	var recovery := CreditSystemScript.get_recovery_observation(_run_state, _credit_balance)
	observation["phase"] = _phase
	observation["pending_cycle"] = get_pending_cycle()
	observation["selected_cycle"] = _selected_cycle
	observation["contract_selected"] = not _selected_contract.is_empty()
	observation["recovery_mode"] = _recovery_mode
	observation["recovery"] = recovery
	observation["company_credit"] = companies
	observation["projected_operating_cost"] = _base_operating_cost
	observation["projected_repair_known"] = false
	observation["projected_debt_principal"] = debt_quote.get_principal_total() if debt_quote != null else 0
	observation["projected_debt_interest"] = debt_quote.get_interest_total() if debt_quote != null else 0
	return observation.duplicate(true)


func get_selected_contract() -> Dictionary:
	return _selected_contract.duplicate(true)


func get_settlement_result() -> SettlementResultScript:
	return _settlement_result


func get_terminal_result(): return _terminal_result
func is_recovery_mode() -> bool: return _recovery_mode
func get_selected_cycle() -> int: return _selected_cycle
func get_pending_cycle() -> int:
	if _phase != Phase.OPERATIONS or _selected_cycle > 0 or not _run_state.can_increment_completed_cycle(): return 0
	return _run_state.get_completed_cycle_count() + 1


func get_recovery_observation() -> Dictionary:
	return CreditSystemScript.get_recovery_observation(_run_state, _credit_balance)


func get_cycle_difficulty(base_hazard_count: int, eligible_cells: int, base_damage: float) -> Dictionary:
	if _cycle_progression == null: return {}
	var cycle := _selected_cycle if _selected_cycle > 0 else get_pending_cycle()
	return _cycle_progression.compose(cycle, base_hazard_count, eligible_cells, base_damage) if cycle > 0 else {}


func get_active_settlement_identity() -> int:
	return _active_settlement_identity


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


func _checked_nonnegative_sum(left: int, right: int) -> Variant:
	if left < 0 or right < 0 or right > MAX_INT - left: return null
	return left + right


func _commit_terminal(reason: int, recovery: Dictionary, inject_failure: bool) -> bool:
	var settlement_observation := _settlement_result.get_observation() if _settlement_result != null else {}
	var terminal_result := TerminalRunResultScript.new(reason, _run_state.get_observation(), settlement_observation, recovery)
	var candidate := {"reason": reason, "result": terminal_result, "phase": Phase.TERMINAL}
	if not _is_valid_terminal_candidate(candidate): return false
	if inject_failure: return false
	_terminal_result = candidate["result"]
	_phase = candidate["phase"]
	_recovery_mode = false
	_selected_contract = {}
	_selected_cycle = 0
	return true


func _is_valid_terminal_candidate(candidate: Dictionary) -> bool:
	if candidate.get("phase", -1) != Phase.TERMINAL or candidate.get("result") == null: return false
	var reason := int(candidate.get("reason", -1))
	if reason not in [TerminalRunResultScript.Reason.CREDIT_EXHAUSTED, TerminalRunResultScript.Reason.RECOVERY_DECLINED]: return false
	var observation: Dictionary = candidate["result"].get_observation()
	return candidate["result"].get_reason() == reason and observation["run_state"] == _run_state.get_observation()
