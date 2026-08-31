class_name RunState
extends RefCounted

const COMPANY_COUNT := 6
const MAX_ABSOLUTE_CASH := 1000000000000
const MAX_TRUST_MILLI := 1000000000000
const MAX_INT := 9223372036854775807

var _cash: int
var _completed_cycle_count: int
var _company_ids: Array[StringName] = []
var _company_trust_milli: Dictionary = {}
var _company_rate_basis_points: Dictionary = {}
var _active_loans: Array = []
var _next_loan_id: int
var _credit_revision: int


func _init(
	cash_value: int,
	company_ids_value: Array,
	company_trust_milli_value: Dictionary = {},
	completed_cycle_count_value: int = 0,
	company_rate_basis_points_value: Dictionary = {},
	active_loans_value: Array = [],
	next_loan_id_value: int = 1,
	credit_revision_value: int = 0
) -> void:
	assert(cash_value >= -MAX_ABSOLUTE_CASH and cash_value <= MAX_ABSOLUTE_CASH, "Run cash exceeds the prototype bound")
	assert(company_ids_value.size() == COMPANY_COUNT, "RunState requires exactly six companies")
	assert(completed_cycle_count_value >= 0, "Completed cycle count cannot be negative")
	assert(not company_rate_basis_points_value.is_empty(), "RunState rate table must cover every company")
	assert(next_loan_id_value >= 1 and next_loan_id_value <= MAX_INT, "Next loan ID must be positive and bounded")
	assert(credit_revision_value >= 0 and credit_revision_value <= MAX_INT, "Credit revision must be nonnegative and bounded")
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
		assert(company_rate_basis_points_value.has(company_id), "RunState rate table must cover every company")
		var rate_value := int(company_rate_basis_points_value[company_id])
		assert(rate_value >= 0 and rate_value <= 10000, "RunState rate exceeds the prototype bound")
		_company_rate_basis_points[company_id] = rate_value
	_next_loan_id = next_loan_id_value
	_credit_revision = credit_revision_value
	var observed_loan_ids := {}
	for loan in active_loans_value:
		assert(loan != null and has_company(loan.get_company_id()), "RunState loan company must exist")
		assert(loan.get_rate_basis_points() == get_company_rate_basis_points(loan.get_company_id()), "RunState loan rate must match the fixed company rate")
		assert(loan.get_loan_id() < _next_loan_id, "RunState loan ID must precede next loan ID")
		assert(not observed_loan_ids.has(loan.get_loan_id()), "RunState loan IDs must be unique")
		observed_loan_ids[loan.get_loan_id()] = true
		_active_loans.append(loan.duplicate_record())
	_active_loans.sort_custom(_is_loan_before)


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


func get_company_rate_basis_points(company_id: StringName) -> int:
	assert(_company_rate_basis_points.has(company_id), "Unknown company ID")
	return _company_rate_basis_points[company_id]


func get_active_loans() -> Array:
	var detached: Array = []
	for loan in _active_loans: detached.append(loan.duplicate_record())
	return detached


func get_next_loan_id() -> int: return _next_loan_id
func get_credit_revision() -> int: return _credit_revision


func append_loan(loan: RefCounted) -> void:
	assert(loan != null, "Loan is required")
	assert(_next_loan_id < MAX_INT, "Next loan ID exhausted")
	assert(_credit_revision < MAX_INT, "Credit revision exhausted")
	assert(loan.get_loan_id() == _next_loan_id, "Loan ID must match the next loan ID")
	assert(has_company(loan.get_company_id()), "Loan company must exist")
	assert(loan.get_rate_basis_points() == get_company_rate_basis_points(loan.get_company_id()), "Loan rate must match the fixed company rate")
	_active_loans.append(loan.duplicate_record())
	_active_loans.sort_custom(_is_loan_before)
	_next_loan_id += 1
	_credit_revision += 1


func apply_debt_service_quote(quote: RefCounted) -> void:
	assert(quote != null and quote.get_credit_revision() == _credit_revision, "Debt quote revision must match RunState")
	var next_revision := _credit_revision
	if quote.has_payments():
		assert(_credit_revision < MAX_INT, "Credit revision exhausted")
		next_revision += 1
	var validated: Variant = get_script().new(_cash, _company_ids, _company_trust_milli, _completed_cycle_count, _company_rate_basis_points, quote.get_post_loans(), _next_loan_id, next_revision)
	_active_loans = validated.get_active_loans()
	_credit_revision = next_revision


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
	var loan_observation: Array = []
	for company_id in _company_ids:
		trust_observation[String(company_id)] = _company_trust_milli[company_id]
	for loan in _active_loans: loan_observation.append(loan.get_observation())
	return {
		"cash": _cash,
		"completed_cycle_count": _completed_cycle_count,
		"company_ids": _company_ids.duplicate(),
		"company_trust_milli": trust_observation,
		"company_rate_basis_points": _company_rate_basis_points.duplicate(true),
		"active_loans": loan_observation,
		"next_loan_id": _next_loan_id,
		"credit_revision": _credit_revision,
	}


func duplicate_state() -> RunState:
	return get_script().new(
		_cash,
		_company_ids.duplicate(),
		_company_trust_milli.duplicate(true),
		_completed_cycle_count,
		_company_rate_basis_points.duplicate(true), get_active_loans(), _next_loan_id, _credit_revision
	)


func replace_with(source: RunState) -> void:
	assert(source != null, "Source RunState is required")
	assert(source._company_ids == _company_ids, "Source RunState company IDs must match in stable order")
	assert(source._company_rate_basis_points == _company_rate_basis_points, "Source RunState company rates must match")
	_cash = source._cash
	_completed_cycle_count = source._completed_cycle_count
	_company_trust_milli = source._company_trust_milli.duplicate(true)
	_active_loans = source.get_active_loans()
	_next_loan_id = source._next_loan_id
	_credit_revision = source._credit_revision


func _is_loan_before(left, right) -> bool:
	var left_company := _company_ids.find(left.get_company_id())
	var right_company := _company_ids.find(right.get_company_id())
	if left_company != right_company: return left_company < right_company
	return left.get_loan_id() < right.get_loan_id()
