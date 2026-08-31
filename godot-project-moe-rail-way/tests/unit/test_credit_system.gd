extends "res://tests/support/prototype_test.gd"

const LoanRecordScript = preload("res://src/domain/credit/loan_record.gd")
const CreditSystemScript = preload("res://src/domain/credit/credit_system.gd")
const RunStateScript = preload("res://src/domain/run/run_state.gd")
const RunControllerScript = preload("res://src/domain/run/prototype_run_controller.gd")
const CreditBalanceScript = preload("res://src/config/credit_survival_balance.gd")
const MAX_INT := 9223372036854775807
const COMPANY_IDS := [&"company_01", &"company_02", &"company_03", &"company_04", &"company_05", &"company_06"]
const COMPANY_RATES := {&"company_01": 400, &"company_02": 500, &"company_03": 600, &"company_04": 700, &"company_05": 800, &"company_06": 900}


func run() -> PackedStringArray:
	_test_amount_bounds_and_shared_cash()
	_test_independent_loans_and_canonical_order()
	_test_schedule_and_fixed_rate()
	_test_operations_only_and_identity_exhaustion()
	return finish()


func _test_amount_bounds_and_shared_cash() -> void:
	var credit := CreditBalanceScript.new()
	var state: Variant = _state(-10, {&"company_01": 100})
	var controller := RunControllerScript.new(state, 50, credit)
	var before := JSON.stringify(state.get_observation())
	assert_false(controller.try_borrow(&"company_01", 0), "Zero borrowing rejects")
	assert_false(controller.try_borrow(&"company_01", -1), "Negative borrowing rejects")
	assert_equal(JSON.stringify(state.get_observation()), before, "Rejected amount leaves canonical state unchanged")
	assert_true(controller.try_borrow(&"company_01", 1), "One-unit borrowing succeeds with negative cash")
	assert_equal(state.get_cash(), -9, "Borrowed money enters shared signed cash")
	assert_true(controller.try_borrow(&"company_01", 99), "Exact remaining company limit succeeds")
	assert_equal(CreditSystemScript.get_remaining_credit(state, credit, &"company_01"), 0, "Accepted principal consumes company credit")
	var at_limit := JSON.stringify(state.get_observation())
	assert_false(controller.try_borrow(&"company_01", 1), "Maximum-plus-one rejects")
	assert_equal(JSON.stringify(state.get_observation()), at_limit, "Limit rejection is value-identical")
	var overflow_state: Variant = _state(RunStateScript.MAX_ABSOLUTE_CASH, {&"company_01": 100})
	assert_false(RunControllerScript.new(overflow_state, 0, credit).try_borrow(&"company_01", 1), "Cash overflow rejects")


func _test_independent_loans_and_canonical_order() -> void:
	var credit := CreditBalanceScript.new()
	var state: Variant = _state(10, {&"company_01": 100, &"company_02": 100})
	var controller := RunControllerScript.new(state, 0, credit)
	assert_true(controller.try_borrow(&"company_02", 10), "Second company borrows independently")
	assert_true(controller.try_borrow(&"company_01", 20), "First company may borrow after second")
	assert_true(controller.try_borrow(&"company_01", 5), "Repeated action creates another loan")
	var loans: Array = state.get_observation()["active_loans"]
	assert_equal(loans.size(), 3, "Every accepted action keeps one loan identity")
	assert_equal([loans[0]["company_id"], loans[0]["loan_id"], loans[1]["company_id"], loans[1]["loan_id"], loans[2]["company_id"], loans[2]["loan_id"]], [&"company_01", 2, &"company_01", 3, &"company_02", 1], "Loans observe canonical company then ID order")
	assert_equal(CreditSystemScript.get_outstanding_principal(state, &"company_01"), 25, "Company principal is derived from its loans")
	assert_equal(CreditSystemScript.get_outstanding_principal(state, &"company_02"), 10, "Other company principal remains independent")


func _test_schedule_and_fixed_rate() -> void:
	var credit := CreditBalanceScript.new()
	var state: Variant = _state(0, {&"company_03": 100})
	var controller := RunControllerScript.new(state, 0, credit)
	assert_true(controller.try_borrow(&"company_03", 1), "First loan captures the run-fixed rate")
	credit.companies[2].rate_basis_points = 1
	assert_true(controller.try_borrow(&"company_03", 1), "New loan ignores live rate edits")
	var loan = state.get_active_loans()[0]
	assert_equal(loan.get_rate_basis_points(), 600, "New loan uses run-copied fixed rate")
	assert_equal(state.get_active_loans()[1].get_rate_basis_points(), 600, "Existing and later loans retain one run-fixed rate")
	assert_equal(loan.get_first_due_cycle(), 1, "First payment is due at the next settlement")
	var schedule := []
	for installment in range(1, loan.get_term_cycles() + 1): schedule.append(loan.get_scheduled_principal(installment))
	assert_equal(schedule, [0, 0, 0, 0, 1], "Equal principal leaves the remainder in the final installment")
	var ordinary := LoanRecordScript.new(99, &"company_01", 10, 10, 400, 4, 0, 1)
	assert_equal([ordinary.get_scheduled_principal(1), ordinary.get_scheduled_principal(2), ordinary.get_scheduled_principal(3), ordinary.get_scheduled_principal(4)], [2, 2, 2, 4], "Ordinary equal-principal schedule is deterministic")


func _test_operations_only_and_identity_exhaustion() -> void:
	var credit := CreditBalanceScript.new()
	var state: Variant = _state(0, {&"company_01": 100})
	var controller := RunControllerScript.new(state, 0, credit)
	assert_true(controller.try_select_contract(_contract()), "Contract selection succeeds")
	assert_not_null(controller.try_start_session(), "Session starts")
	var before := JSON.stringify(state.get_observation())
	assert_false(controller.try_borrow(&"company_01", 1), "Borrowing outside operations rejects")
	assert_equal(JSON.stringify(state.get_observation()), before, "Phase rejection changes nothing")
	var exhausted := RunStateScript.new(0, COMPANY_IDS, {&"company_01": 100}, 0, COMPANY_RATES, [], MAX_INT, 0)
	assert_false(RunControllerScript.new(exhausted, 0, credit).try_borrow(&"company_01", 1), "Loan ID exhaustion rejects")
	var revision_exhausted := RunStateScript.new(0, COMPANY_IDS, {&"company_01": 100}, 0, COMPANY_RATES, [], 1, MAX_INT)
	assert_false(RunControllerScript.new(revision_exhausted, 0, credit).try_borrow(&"company_01", 1), "Credit revision exhaustion rejects")


func _state(cash: int, trust: Dictionary) -> Variant:
	return RunStateScript.new(cash, COMPANY_IDS, trust, 0, COMPANY_RATES)


func _contract() -> Dictionary:
	return {"company_id": &"company_01", "quota": 1, "maximum_shortfall_penalty": 0, "completion_bonus_at_quota": 0, "trust_per_excess_delivery_milli": 0}
