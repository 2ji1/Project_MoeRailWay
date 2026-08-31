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
	_verify_invalid_probe()
	_test_amount_bounds_and_shared_cash()
	_test_independent_loans_and_canonical_order()
	_test_schedule_and_fixed_rate()
	_test_candidate_isolation_and_aggregate_install()
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
	var overflow_before := JSON.stringify(overflow_state.get_observation())
	assert_false(RunControllerScript.new(overflow_state, 0, credit).try_borrow(&"company_01", 1), "Cash overflow rejects")
	assert_equal(JSON.stringify(overflow_state.get_observation()), overflow_before, "Cash overflow rejection is value-identical")


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
	loans[0]["remaining_principal"] = 999
	assert_equal(state.get_observation()["active_loans"][0]["remaining_principal"], 20, "Loan observations are detached")


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
	var later_state := RunStateScript.new(0, COMPANY_IDS, {&"company_01": 100}, 3, COMPANY_RATES)
	assert_true(RunControllerScript.new(later_state, 0, credit).try_borrow(&"company_01", 1), "Borrowing after completed cycles succeeds")
	assert_equal(later_state.get_active_loans()[0].get_first_due_cycle(), 4, "First due cycle follows the completed-cycle authority")


func _test_candidate_isolation_and_aggregate_install() -> void:
	var credit := CreditBalanceScript.new()
	var state: Variant = _state(10, {&"company_01": 100})
	var before := JSON.stringify(state.get_observation())
	var proposal = CreditSystemScript.create_borrow_proposal(state, credit, &"company_01", 25)
	assert_not_null(proposal, "Pure borrow proposal is created")
	assert_equal(JSON.stringify(state.get_observation()), before, "Proposal creation leaves live state unchanged")
	assert_equal(proposal.get_original_principal(), 25, "Proposal contains validated loan facts")
	var controller := RunControllerScript.new(state, 0, credit)
	assert_true(controller.try_borrow(&"company_01", 25), "Controller accepts the proposal")
	assert_equal(state.get_cash(), 35, "Aggregate install replaces cash")
	assert_equal(state.get_active_loans().size(), 1, "Aggregate install replaces Credit facts")
	assert_equal(state.get_credit_revision(), 1, "Aggregate install replaces identity revision")
	var result := controller.get_last_borrow_result()
	assert_equal(result["cash_before"], 10, "Borrow result reports pre-install cash")
	assert_equal(result["cash_after"], 35, "Borrow result reports installed cash")
	assert_equal(result["loan"]["loan_id"], 1, "Borrow result reports the accepted loan")
	result["loan"]["remaining_principal"] = 999
	assert_equal(controller.get_last_borrow_result()["loan"]["remaining_principal"], 25, "Borrow result is detached")
	var detached: Array = state.get_active_loans()
	detached.clear()
	assert_equal(state.get_active_loans().size(), 1, "Loan list copies cannot mutate RunState")


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
	var exhausted_before := JSON.stringify(exhausted.get_observation())
	assert_false(RunControllerScript.new(exhausted, 0, credit).try_borrow(&"company_01", 1), "Loan ID exhaustion rejects")
	assert_equal(JSON.stringify(exhausted.get_observation()), exhausted_before, "Loan ID exhaustion is value-identical")
	var revision_exhausted := RunStateScript.new(0, COMPANY_IDS, {&"company_01": 100}, 0, COMPANY_RATES, [], 1, MAX_INT)
	var revision_before := JSON.stringify(revision_exhausted.get_observation())
	assert_false(RunControllerScript.new(revision_exhausted, 0, credit).try_borrow(&"company_01", 1), "Credit revision exhaustion rejects")
	assert_equal(JSON.stringify(revision_exhausted.get_observation()), revision_before, "Credit revision exhaustion is value-identical")


func _verify_invalid_probe() -> void:
	var cases := {
		"loan_id": "Loan ID must be positive",
		"company_id": "Loan company ID is required",
		"original_principal": "Original principal must be positive",
		"remaining_principal": "Remaining principal must be positive and bounded",
		"rate": "Loan rate must be between 0 and 10000",
		"term": "Loan term must be between 1 and 1000",
		"installments": "Paid installments must be inside the term",
		"first_due_cycle": "First due cycle must be positive",
		"run_loan_company": "RunState loan company must exist",
		"run_loan_rate": "RunState loan rate must match the fixed company rate",
		"run_loan_id_order": "RunState loan ID must precede next loan ID",
		"run_loan_id_duplicate": "RunState loan IDs must be unique",
	}
	var case_names := PackedStringArray(["loan_id", "company_id", "original_principal", "remaining_principal", "rate", "term", "installments", "first_due_cycle", "run_loan_company", "run_loan_rate", "run_loan_id_order", "run_loan_id_duplicate"])
	for case_name in case_names:
		var output: Array = []
		var arguments := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/run_all.gd", "--", "--credit-system-invalid-probe=" + case_name])
		var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true)
		var captured := "\n".join(PackedStringArray(output))
		assert_true(captured.contains("CREDIT_SYSTEM_INVALID_PROBE_BEGIN:" + case_name), "Loan invariant probe starts: " + case_name)
		assert_true(captured.contains(cases[case_name]), "Loan invariant probe reports: " + case_name)
		assert_true(exit_code != 0, "Loan invariant probe exits unsuccessfully: " + case_name)


func run_invalid_probe(case_name: String) -> void:
	match case_name:
		"loan_id": LoanRecordScript.new(0, &"company_01", 10, 10, 400, 4, 0, 1)
		"company_id": LoanRecordScript.new(1, StringName(), 10, 10, 400, 4, 0, 1)
		"original_principal": LoanRecordScript.new(1, &"company_01", 0, 0, 400, 4, 0, 1)
		"remaining_principal": LoanRecordScript.new(1, &"company_01", 10, 11, 400, 4, 0, 1)
		"rate": LoanRecordScript.new(1, &"company_01", 10, 10, 10001, 4, 0, 1)
		"term": LoanRecordScript.new(1, &"company_01", 10, 10, 400, 0, 0, 1)
		"installments": LoanRecordScript.new(1, &"company_01", 10, 10, 400, 4, 4, 1)
		"first_due_cycle": LoanRecordScript.new(1, &"company_01", 10, 10, 400, 4, 0, 0)
		"run_loan_company":
			var loan := LoanRecordScript.new(1, &"unknown_company", 10, 10, 400, 4, 0, 1)
			RunStateScript.new(0, COMPANY_IDS, {}, 0, COMPANY_RATES, [loan], 2, 0)
		"run_loan_rate":
			var loan := LoanRecordScript.new(1, &"company_01", 10, 10, 1, 4, 0, 1)
			RunStateScript.new(0, COMPANY_IDS, {}, 0, COMPANY_RATES, [loan], 2, 0)
		"run_loan_id_order":
			var loan := LoanRecordScript.new(2, &"company_01", 10, 10, 400, 4, 0, 1)
			RunStateScript.new(0, COMPANY_IDS, {}, 0, COMPANY_RATES, [loan], 2, 0)
		"run_loan_id_duplicate":
			var first := LoanRecordScript.new(1, &"company_01", 10, 10, 400, 4, 0, 1)
			var second := LoanRecordScript.new(1, &"company_02", 10, 10, 500, 4, 0, 1)
			RunStateScript.new(0, COMPANY_IDS, {}, 0, COMPANY_RATES, [first, second], 2, 0)


func _state(cash: int, trust: Dictionary) -> Variant:
	return RunStateScript.new(cash, COMPANY_IDS, trust, 0, COMPANY_RATES)


func _contract() -> Dictionary:
	return {"company_id": &"company_01", "quota": 1, "maximum_shortfall_penalty": 0, "completion_bonus_at_quota": 0, "trust_per_excess_delivery_milli": 0}
