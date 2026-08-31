class_name ContractSystem
extends RefCounted

const MAX_INT := 9223372036854775807
const MAX_BALANCE_VALUE := 1000000

var _selected_company_id: StringName
var _quota: int
var _maximum_shortfall_penalty: int
var _completion_bonus_at_quota: int
var _trust_per_excess_delivery_milli: int
var _contracted_delivery_count := 0
var _seen_pair_ids := {}
var _delivery_facts: Array[Dictionary] = []


func _init(selected_contract: Dictionary) -> void:
	_selected_company_id = StringName(
		selected_contract.get("company_id", StringName())
	)
	_quota = int(selected_contract.get("quota", 0))
	_maximum_shortfall_penalty = int(
		selected_contract.get("maximum_shortfall_penalty", -1)
	)
	_completion_bonus_at_quota = int(
		selected_contract.get("completion_bonus_at_quota", -1)
	)
	_trust_per_excess_delivery_milli = int(
		selected_contract.get("trust_per_excess_delivery_milli", -1)
	)
	assert(not _selected_company_id.is_empty(), "Selected contract company ID is required")
	assert(_quota > 0 and _quota <= MAX_BALANCE_VALUE, "Contract quota must be between 1 and 1000000")
	assert(_is_balance_value(_maximum_shortfall_penalty), "Contract shortfall penalty must be between 0 and 1000000")
	assert(_is_balance_value(_completion_bonus_at_quota), "Contract completion bonus must be between 0 and 1000000")
	assert(_is_balance_value(_trust_per_excess_delivery_milli), "Contract trust gain must be between 0 and 1000000")


func try_record_delivery(fact: Dictionary) -> bool:
	if not _is_valid_delivery_fact(fact):
		return false
	var pair_id := StringName(fact["pair_id"])
	if _seen_pair_ids.has(pair_id):
		return false
	var company_id := StringName(fact["company_id"])
	var is_selected_contract := company_id == _selected_company_id
	if is_selected_contract:
		if _contracted_delivery_count >= MAX_INT / 10000:
			return false
		var prospective_excess := maxi(_contracted_delivery_count + 1 - _quota, 0)
		if (
			_trust_per_excess_delivery_milli > 0
			and prospective_excess
				> MAX_INT / _trust_per_excess_delivery_milli
		):
			return false
	_seen_pair_ids[pair_id] = true
	if is_selected_contract:
		_contracted_delivery_count += 1
	_delivery_facts.append({
		"pair_id": pair_id,
		"company_id": company_id,
		"base_delivery_fee": int(fact["base_delivery_fee"]),
		"is_selected_contract": is_selected_contract,
		"contracted_delivery_count_after_event": _contracted_delivery_count,
	})
	return true


func has_delivery(pair_id: StringName) -> bool:
	return not pair_id.is_empty() and _seen_pair_ids.has(pair_id)


func can_record_additional_deliveries(maximum_additional_count: int) -> bool:
	if (
		maximum_additional_count < 0
		or _contracted_delivery_count
			> MAX_INT / 10000 - maximum_additional_count
	):
		return false
	var maximum_count := _contracted_delivery_count + maximum_additional_count
	var maximum_excess := maxi(maximum_count - _quota, 0)
	return (
		_trust_per_excess_delivery_milli == 0
		or maximum_excess <= MAX_INT / _trust_per_excess_delivery_milli
	)


func get_selected_company_id() -> StringName:
	return _selected_company_id


func get_quota() -> int:
	return _quota


func get_contracted_delivery_count() -> int:
	return _contracted_delivery_count


func get_attainment_basis_points() -> int:
	return calculate_attainment_basis_points(_contracted_delivery_count, _quota)


func get_cash_contract_adjustment() -> int:
	return calculate_cash_contract_adjustment(
		_contracted_delivery_count,
		_quota,
		_maximum_shortfall_penalty,
		_completion_bonus_at_quota
	)


func get_trust_gain_milli() -> int:
	return calculate_trust_gain_milli(
		_contracted_delivery_count,
		_quota,
		_trust_per_excess_delivery_milli
	)


static func calculate_attainment_basis_points(delivery_count: int, quota: int) -> int:
	return delivery_count * 10000 / quota


static func calculate_cash_contract_adjustment(
	delivery_count: int,
	quota: int,
	maximum_shortfall_penalty: int,
	completion_bonus_at_quota: int
) -> int:
	var capped_delivery_count := mini(delivery_count, quota)
	var numerator := (
		capped_delivery_count
		* (completion_bonus_at_quota + maximum_shortfall_penalty)
		- quota * maximum_shortfall_penalty
	)
	return _round_ratio_half_away_from_zero(numerator, quota)


static func calculate_trust_gain_milli(
	delivery_count: int,
	quota: int,
	trust_per_excess_delivery_milli: int
) -> int:
	return (
		maxi(delivery_count - quota, 0)
		* trust_per_excess_delivery_milli
	)


func get_delivery_facts() -> Array[Dictionary]:
	return _delivery_facts.duplicate(true)


func get_observation() -> Dictionary:
	return {
		"selected_company_id": _selected_company_id,
		"quota": _quota,
		"contracted_delivery_count": _contracted_delivery_count,
		"attainment_basis_points": get_attainment_basis_points(),
		"cash_contract_adjustment": get_cash_contract_adjustment(),
		"trust_gain_milli": get_trust_gain_milli(),
		"delivery_facts": get_delivery_facts(),
	}


func duplicate_contract() -> ContractSystem:
	var copy: ContractSystem = get_script().new({
		"company_id": _selected_company_id,
		"quota": _quota,
		"maximum_shortfall_penalty": _maximum_shortfall_penalty,
		"completion_bonus_at_quota": _completion_bonus_at_quota,
		"trust_per_excess_delivery_milli": _trust_per_excess_delivery_milli,
	})
	copy._contracted_delivery_count = _contracted_delivery_count
	copy._seen_pair_ids = _seen_pair_ids.duplicate(true)
	copy._delivery_facts = _delivery_facts.duplicate(true)
	return copy


func replace_with(source: ContractSystem) -> void:
	assert(source != null, "Source contract is required")
	assert(
		source._selected_company_id == _selected_company_id
		and source._quota == _quota
		and source._maximum_shortfall_penalty == _maximum_shortfall_penalty
		and source._completion_bonus_at_quota == _completion_bonus_at_quota
		and source._trust_per_excess_delivery_milli
			== _trust_per_excess_delivery_milli,
		"Source contract definition must match"
	)
	_contracted_delivery_count = source._contracted_delivery_count
	_seen_pair_ids = source._seen_pair_ids.duplicate(true)
	_delivery_facts = source._delivery_facts.duplicate(true)


func _is_valid_delivery_fact(fact: Dictionary) -> bool:
	if not fact.has("pair_id") or not fact.has("company_id") or not fact.has("base_delivery_fee"):
		return false
	if typeof(fact["pair_id"]) != TYPE_STRING_NAME or typeof(fact["company_id"]) != TYPE_STRING_NAME:
		return false
	if typeof(fact["base_delivery_fee"]) != TYPE_INT:
		return false
	return (
		not StringName(fact["pair_id"]).is_empty()
		and not StringName(fact["company_id"]).is_empty()
		and _is_balance_value(int(fact["base_delivery_fee"]))
	)


static func _round_ratio_half_away_from_zero(numerator: int, denominator: int) -> int:
	if numerator == 0:
		return 0
	var magnitude := absi(numerator)
	var quotient := magnitude / denominator
	var remainder := magnitude % denominator
	if remainder * 2 >= denominator:
		quotient += 1
	return quotient if numerator > 0 else -quotient


func _is_balance_value(value: int) -> bool:
	return value >= 0 and value <= MAX_BALANCE_VALUE
