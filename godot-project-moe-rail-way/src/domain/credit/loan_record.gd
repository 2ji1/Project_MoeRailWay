class_name LoanRecord
extends RefCounted

var _loan_id: int
var _company_id: StringName
var _original_principal: int
var _remaining_principal: int
var _rate_basis_points: int
var _term_cycles: int
var _installments_paid: int
var _first_due_cycle: int


func _init(loan_id_value: int, company_id_value: StringName, original_principal_value: int, remaining_principal_value: int, rate_basis_points_value: int, term_cycles_value: int, installments_paid_value: int, first_due_cycle_value: int) -> void:
	assert(loan_id_value >= 1, "Loan ID must be positive")
	assert(not company_id_value.is_empty(), "Loan company ID is required")
	assert(original_principal_value >= 1, "Original principal must be positive")
	assert(remaining_principal_value >= 1 and remaining_principal_value <= original_principal_value, "Remaining principal must be positive and bounded")
	assert(rate_basis_points_value >= 0 and rate_basis_points_value <= 10000, "Loan rate must be between 0 and 10000")
	assert(term_cycles_value >= 1 and term_cycles_value <= 1000, "Loan term must be between 1 and 1000")
	assert(installments_paid_value >= 0 and installments_paid_value < term_cycles_value, "Paid installments must be inside the term")
	assert(first_due_cycle_value >= 1, "First due cycle must be positive")
	_loan_id = loan_id_value
	_company_id = company_id_value
	_original_principal = original_principal_value
	_remaining_principal = remaining_principal_value
	_rate_basis_points = rate_basis_points_value
	_term_cycles = term_cycles_value
	_installments_paid = installments_paid_value
	_first_due_cycle = first_due_cycle_value


func get_loan_id() -> int: return _loan_id
func get_company_id() -> StringName: return _company_id
func get_original_principal() -> int: return _original_principal
func get_remaining_principal() -> int: return _remaining_principal
func get_rate_basis_points() -> int: return _rate_basis_points
func get_term_cycles() -> int: return _term_cycles
func get_installments_paid() -> int: return _installments_paid
func get_first_due_cycle() -> int: return _first_due_cycle


func get_scheduled_principal(installment_number: int) -> int:
	assert(installment_number >= 1 and installment_number <= _term_cycles, "Installment number must be inside the term")
	var regular_principal := _original_principal / _term_cycles
	if installment_number < _term_cycles:
		return regular_principal
	return _original_principal - regular_principal * (_term_cycles - 1)


func get_next_principal_due() -> int:
	return get_scheduled_principal(_installments_paid + 1)


func duplicate_record():
	return get_script().new(_loan_id, _company_id, _original_principal, _remaining_principal, _rate_basis_points, _term_cycles, _installments_paid, _first_due_cycle)


func get_observation() -> Dictionary:
	return {"loan_id": _loan_id, "company_id": _company_id, "original_principal": _original_principal, "remaining_principal": _remaining_principal, "rate_basis_points": _rate_basis_points, "term_cycles": _term_cycles, "installments_paid": _installments_paid, "first_due_cycle": _first_due_cycle, "next_principal_due": get_next_principal_due()}
