class_name CreditSystem
extends RefCounted

const LoanRecordScript = preload("res://src/domain/credit/loan_record.gd")
const MAX_INT := 9223372036854775807


static func get_outstanding_principal(run_state: RefCounted, company_id: StringName) -> int:
	if run_state == null or not run_state.has_company(company_id): return -1
	var total := 0
	for loan in run_state.get_active_loans():
		if loan.get_company_id() != company_id: continue
		var principal: int = loan.get_remaining_principal()
		if principal > MAX_INT - total: return MAX_INT
		total += principal
	return total


static func get_remaining_credit(run_state: RefCounted, credit_balance: Resource, company_id: StringName) -> int:
	if run_state == null or credit_balance == null or not run_state.has_company(company_id): return -1
	var limit: int = credit_balance.get_credit_limit(company_id, run_state.get_company_trust_milli(company_id))
	if limit < 0: return -1
	var principal := get_outstanding_principal(run_state, company_id)
	if principal < 0 or principal >= limit: return 0
	return limit - principal


static func create_borrow_candidate(run_state: RefCounted, credit_balance: Resource, company_id: StringName, amount: int):
	if run_state == null or credit_balance == null or amount < 1: return null
	var remaining_credit := get_remaining_credit(run_state, credit_balance, company_id)
	if remaining_credit < 0 or amount > remaining_credit: return null
	if amount > run_state.MAX_ABSOLUTE_CASH - run_state.get_cash(): return null
	if run_state.get_next_loan_id() >= MAX_INT or run_state.get_credit_revision() >= MAX_INT or run_state.get_completed_cycle_count() >= MAX_INT: return null
	var company = credit_balance.get_company(company_id)
	if company == null or company.term_cycles < 1 or company.term_cycles > 1000: return null
	var loan := LoanRecordScript.new(run_state.get_next_loan_id(), company_id, amount, amount, run_state.get_company_rate_basis_points(company_id), company.term_cycles, 0, run_state.get_completed_cycle_count() + 1)
	var candidate = run_state.duplicate_state()
	candidate.set_cash(run_state.get_cash() + amount)
	candidate.append_loan(loan)
	return candidate
