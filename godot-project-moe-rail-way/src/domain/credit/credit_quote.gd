class_name CreditQuote
extends RefCounted

var _settlement_identity: int
var _cycle: int
var _credit_revision: int
var _items: Array[Dictionary]
var _post_loans: Array
var _principal_total: int
var _interest_total: int


func _init(settlement_identity_value: int, cycle_value: int, credit_revision_value: int, items_value: Array, post_loans_value: Array, principal_total_value: int, interest_total_value: int) -> void:
	assert(settlement_identity_value >= 1, "Settlement identity must be positive")
	assert(cycle_value >= 1, "Settlement cycle must be positive")
	assert(credit_revision_value >= 0, "Credit revision must be nonnegative")
	assert(principal_total_value >= 0 and interest_total_value >= 0, "Debt totals must be nonnegative")
	_settlement_identity = settlement_identity_value
	_cycle = cycle_value
	_credit_revision = credit_revision_value
	_items = items_value.duplicate(true)
	_post_loans = []
	for loan in post_loans_value: _post_loans.append(loan.duplicate_record())
	_principal_total = principal_total_value
	_interest_total = interest_total_value


func get_settlement_identity() -> int: return _settlement_identity
func get_cycle() -> int: return _cycle
func get_credit_revision() -> int: return _credit_revision
func get_principal_total() -> int: return _principal_total
func get_interest_total() -> int: return _interest_total
func has_payments() -> bool: return not _items.is_empty()
func get_items() -> Array[Dictionary]: return _items.duplicate(true)


func get_post_loans() -> Array:
	var detached: Array = []
	for loan in _post_loans: detached.append(loan.duplicate_record())
	return detached


func get_observation() -> Dictionary:
	var post_loan_observations: Array = []
	for loan in _post_loans: post_loan_observations.append(loan.get_observation())
	return {
		"settlement_identity": _settlement_identity,
		"cycle": _cycle,
		"credit_revision": _credit_revision,
		"items": get_items(),
		"post_loans": post_loan_observations,
		"principal_total": _principal_total,
		"interest_total": _interest_total,
	}.duplicate(true)
