class_name RunState
extends RefCounted

const COMPANY_COUNT := 6
const MAX_ABSOLUTE_CASH := 1000000000000
const MAX_TRUST_MILLI := 1000000000000

var _cash: int
var _completed_cycle_count: int
var _company_ids: Array[StringName] = []
var _company_trust_milli: Dictionary = {}


func _init(
	cash_value: int,
	company_ids_value: Array,
	company_trust_milli_value: Dictionary = {},
	completed_cycle_count_value: int = 0
) -> void:
	assert(cash_value >= -MAX_ABSOLUTE_CASH and cash_value <= MAX_ABSOLUTE_CASH, "Run cash exceeds the prototype bound")
	assert(company_ids_value.size() == COMPANY_COUNT, "RunState requires exactly six companies")
	assert(completed_cycle_count_value >= 0, "Completed cycle count cannot be negative")
	_cash = cash_value
	_completed_cycle_count = completed_cycle_count_value
	for raw_company_id in company_ids_value:
		var company_id := StringName(raw_company_id)
		assert(not company_id.is_empty(), "RunState company ID cannot be empty")
		assert(not _company_trust_milli.has(company_id), "RunState company IDs must be unique")
		var trust_value := int(company_trust_milli_value.get(company_id, 0))
		assert(trust_value >= 0 and trust_value <= MAX_TRUST_MILLI, "RunState trust exceeds the prototype bound")
		_company_ids.append(company_id)
		_company_trust_milli[company_id] = trust_value


func get_cash() -> int:
	return _cash


func can_set_cash(value: int) -> bool:
	return value >= -MAX_ABSOLUTE_CASH and value <= MAX_ABSOLUTE_CASH


func set_cash(value: int) -> void:
	assert(value >= -MAX_ABSOLUTE_CASH and value <= MAX_ABSOLUTE_CASH, "Run cash exceeds the prototype bound")
	_cash = value


func get_completed_cycle_count() -> int:
	return _completed_cycle_count


func increment_completed_cycle() -> void:
	assert(_completed_cycle_count < 9223372036854775807, "Completed cycle count overflow")
	_completed_cycle_count += 1


func get_company_ids() -> Array[StringName]:
	return _company_ids.duplicate()


func has_company(company_id: StringName) -> bool:
	return _company_trust_milli.has(company_id)


func get_company_trust_milli(company_id: StringName) -> int:
	assert(_company_trust_milli.has(company_id), "Unknown company ID")
	return _company_trust_milli[company_id]


func add_company_trust_milli(company_id: StringName, amount: int) -> void:
	assert(_company_trust_milli.has(company_id), "Unknown company ID")
	assert(amount >= 0, "Trust increment cannot be negative")
	var current: int = _company_trust_milli[company_id]
	assert(amount <= MAX_TRUST_MILLI - current, "RunState trust overflow")
	_company_trust_milli[company_id] = current + amount


func can_add_company_trust_milli(company_id: StringName, amount: int) -> bool:
	if not _company_trust_milli.has(company_id) or amount < 0:
		return false
	return amount <= MAX_TRUST_MILLI - int(_company_trust_milli[company_id])


func can_increment_completed_cycle() -> bool:
	return _completed_cycle_count < 9223372036854775807


func get_observation() -> Dictionary:
	var trust_observation := {}
	for company_id in _company_ids:
		trust_observation[String(company_id)] = _company_trust_milli[company_id]
	return {
		"cash": _cash,
		"completed_cycle_count": _completed_cycle_count,
		"company_ids": _company_ids.duplicate(),
		"company_trust_milli": trust_observation,
	}


func duplicate_state() -> RunState:
	return get_script().new(
		_cash,
		_company_ids.duplicate(),
		_company_trust_milli.duplicate(true),
		_completed_cycle_count
	)


func replace_with(source: RunState) -> void:
	assert(source != null, "Source RunState is required")
	assert(source._company_ids == _company_ids, "Source RunState company IDs must match in stable order")
	_cash = source._cash
	_completed_cycle_count = source._completed_cycle_count
	_company_trust_milli = source._company_trust_milli.duplicate(true)
