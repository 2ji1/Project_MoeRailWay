class_name CreditSystem
extends RefCounted

const LoanRecordScript = preload("res://src/domain/credit/loan_record.gd")
const CreditQuoteScript = preload("res://src/domain/credit/credit_quote.gd")
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


static func create_borrow_proposal(run_state: RefCounted, credit_balance: Resource, company_id: StringName, amount: int):
	if run_state == null or credit_balance == null or amount < 1: return null
	var remaining_credit := get_remaining_credit(run_state, credit_balance, company_id)
	if remaining_credit < 0 or amount > remaining_credit: return null
	if run_state.get_next_loan_id() >= MAX_INT or run_state.get_credit_revision() >= MAX_INT or run_state.get_completed_cycle_count() >= MAX_INT: return null
	var company = credit_balance.get_company(company_id)
	if company == null or company.term_cycles < 1 or company.term_cycles > 1000: return null
	return LoanRecordScript.new(run_state.get_next_loan_id(), company_id, amount, amount, run_state.get_company_rate_basis_points(company_id), company.term_cycles, 0, run_state.get_completed_cycle_count() + 1)


static func calculate_interest(principal: int, rate_basis_points: int) -> int:
	assert(principal >= 0, "Interest principal must be nonnegative")
	assert(rate_basis_points >= 0 and rate_basis_points <= 10000, "Interest rate must be between 0 and 10000")
	var whole := principal / 10000 * rate_basis_points
	var remainder_product := (principal % 10000) * rate_basis_points
	return whole + remainder_product / 10000 + (1 if remainder_product % 10000 > 0 else 0)


static func create_debt_service_quote(run_state: RefCounted, settlement_identity: int, cycle: int):
	if run_state == null or settlement_identity < 1 or cycle < 1: return null
	var items: Array[Dictionary] = []
	var post_loans: Array = []
	var principal_total := 0
	var interest_total := 0
	for loan in run_state.get_active_loans():
		if cycle < loan.get_first_due_cycle():
			post_loans.append(loan)
			continue
		var pre_principal: int = loan.get_remaining_principal()
		var principal_due: int = mini(loan.get_next_principal_due(), pre_principal)
		var interest_due := calculate_interest(pre_principal, loan.get_rate_basis_points())
		if principal_due > MAX_INT - principal_total or interest_due > MAX_INT - interest_total: return null
		principal_total += principal_due
		interest_total += interest_due
		var post_principal := pre_principal - principal_due
		var post_installments: int = loan.get_installments_paid() + 1
		items.append({
			"company_id": loan.get_company_id(),
			"loan_id": loan.get_loan_id(),
			"pre_principal": pre_principal,
			"principal": principal_due,
			"interest": interest_due,
			"post_principal": post_principal,
			"post_installments_paid": post_installments,
		})
		if post_principal > 0:
			post_loans.append(LoanRecordScript.new(loan.get_loan_id(), loan.get_company_id(), loan.get_original_principal(), post_principal, loan.get_rate_basis_points(), loan.get_term_cycles(), post_installments, loan.get_first_due_cycle()))
	return CreditQuoteScript.new(settlement_identity, cycle, run_state.get_credit_revision(), items, post_loans, principal_total, interest_total)


static func is_debt_service_quote_valid(run_state: RefCounted, quote: RefCounted, settlement_identity: int, cycle: int) -> bool:
	if run_state == null or quote == null: return false
	if quote.get_settlement_identity() != settlement_identity or quote.get_cycle() != cycle or quote.get_credit_revision() != run_state.get_credit_revision(): return false
	var expected = create_debt_service_quote(run_state, settlement_identity, cycle)
	return expected != null and JSON.stringify(expected.get_observation()) == JSON.stringify(quote.get_observation())
