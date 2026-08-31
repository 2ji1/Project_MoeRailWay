extends "res://tests/support/prototype_test.gd"

const CreditQuoteScript = preload("res://src/domain/credit/credit_quote.gd")
const CreditSystemScript = preload("res://src/domain/credit/credit_system.gd")
const LoanRecordScript = preload("res://src/domain/credit/loan_record.gd")
const CreditBalanceScript = preload("res://src/config/credit_survival_balance.gd")
const RunStateScript = preload("res://src/domain/run/run_state.gd")
const RunControllerScript = preload("res://src/domain/run/prototype_run_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")

const COMPANY_IDS := [&"company_01", &"company_02", &"company_03", &"company_04", &"company_05", &"company_06"]
const COMPANY_RATES := {&"company_01": 400, &"company_02": 500, &"company_03": 600, &"company_04": 700, &"company_05": 800, &"company_06": 900}


func run() -> PackedStringArray:
	assert_not_null(CreditQuoteScript, "CreditQuote facts exist")
	assert_equal(CreditSystemScript.calculate_interest(1, 1), 1, "One unit at one basis point rounds up")
	assert_equal(CreditSystemScript.calculate_interest(100, 0), 0, "Zero rate has zero interest")
	_test_quote_purity_order_and_zero_principal_advancement()
	_test_atomic_settlement_and_retirement()
	_test_quote_binding_retry_and_preinstall_failure()
	return finish()


func _test_quote_purity_order_and_zero_principal_advancement() -> void:
	var loans := [
		LoanRecordScript.new(1, &"company_02", 10, 10, 500, 4, 0, 1),
		LoanRecordScript.new(2, &"company_01", 1, 1, 400, 5, 0, 1),
	]
	var state := RunStateScript.new(300, COMPANY_IDS, {}, 0, COMPANY_RATES, loans, 3, 0)
	var before := JSON.stringify(state.get_observation())
	var quote = CreditSystemScript.create_debt_service_quote(state, 7, 1)
	assert_not_null(quote, "Pure quote is created")
	assert_equal(JSON.stringify(state.get_observation()), before, "Quote creation does not mutate RunState")
	assert_equal([quote.get_items()[0]["company_id"], quote.get_items()[0]["loan_id"], quote.get_items()[1]["company_id"], quote.get_items()[1]["loan_id"]], [&"company_01", 2, &"company_02", 1], "Quote order is company then loan ID")
	assert_equal(quote.get_items()[0]["principal"], 0, "P less than N begins with zero principal")
	assert_equal(quote.get_items()[0]["post_installments_paid"], 1, "Zero-principal installment still advances")
	var detached: Dictionary = quote.get_observation()
	detached["items"][0]["principal"] = 999
	assert_equal(quote.get_observation()["items"][0]["principal"], 0, "Quote observation is detached")
	var sequence_state := RunStateScript.new(0, COMPANY_IDS, {}, 0, COMPANY_RATES, [LoanRecordScript.new(1, &"company_01", 1, 1, 400, 5, 0, 1)], 2, 0)
	var sequence: Array[int] = []
	for cycle in range(1, 6):
		var cycle_quote = CreditSystemScript.create_debt_service_quote(sequence_state, cycle, cycle)
		sequence.append(cycle_quote.get_principal_total())
		sequence_state.apply_debt_service_quote(cycle_quote)
	assert_equal(sequence, [0, 0, 0, 0, 1], "Equal-principal sequence retains final remainder")
	assert_equal(sequence_state.get_active_loans().size(), 0, "Final payment retires the loan")


func _test_atomic_settlement_and_retirement() -> void:
	var loan := LoanRecordScript.new(1, &"company_01", 40, 40, 400, 4, 0, 1)
	var state := RunStateScript.new(300, COMPANY_IDS, {&"company_01": 100}, 0, COMPANY_RATES, [loan], 2, 0)
	var credit := CreditBalanceScript.new()
	var remaining_before := CreditSystemScript.get_remaining_credit(state, credit, &"company_01")
	var controller := RunControllerScript.new(state, 50, credit)
	assert_true(controller.try_select_contract(_contract()), "Settlement contract is selected")
	assert_not_null(controller.try_start_session(), "Settlement session starts")
	var quote = controller.create_debt_service_quote()
	assert_equal(quote.get_principal_total(), 10, "First principal installment is quoted")
	assert_equal(quote.get_interest_total(), 2, "Interest uses ceiling basis points on pre-payment principal")
	var settlement = controller.try_settle_session(_session_result(), quote)
	assert_not_null(settlement, "Bound quote settles once")
	assert_equal(state.get_cash(), 398, "Debt service follows contract, repair, and operating costs")
	assert_equal(state.get_active_loans()[0].get_remaining_principal(), 30, "Principal is reduced once")
	assert_equal(state.get_active_loans()[0].get_installments_paid(), 1, "Installment count advances once")
	assert_equal(state.get_credit_revision(), 1, "Debt payment advances Credit revision")
	assert_equal(CreditSystemScript.get_remaining_credit(state, credit, &"company_01"), remaining_before + 10, "Paid principal immediately frees company credit")
	assert_equal(settlement.get_debt_principal_paid(), 10, "Settlement exposes principal paid")
	assert_equal(settlement.get_debt_interest_paid(), 2, "Settlement exposes interest paid")
	var lines := settlement.get_ordered_line_items()
	assert_equal([lines[-3]["id"], lines[-2]["id"], lines[-1]["id"]], [&"debt_principal", &"debt_interest", &"closing_cash"], "Debt rows precede closing cash")
	assert_true(settlement.does_next_session_start_at_full_durability(), "Durability restoration remains committed")
	assert_true(settlement.are_session_only_increases_cleared(), "Temporary investment cleanup remains committed")
	assert_equal(controller.get_active_settlement_identity(), 0, "Successful settlement consumes its identity")
	var after := JSON.stringify(state.get_observation())
	assert_true(controller.try_settle_session(_session_result(), quote) == null, "Duplicate settlement rejects")
	assert_equal(JSON.stringify(state.get_observation()), after, "Duplicate settlement changes nothing")


func _test_quote_binding_retry_and_preinstall_failure() -> void:
	var loan := LoanRecordScript.new(1, &"company_01", 40, 40, 400, 4, 0, 1)
	var state := RunStateScript.new(300, COMPANY_IDS, {}, 0, COMPANY_RATES, [loan], 2, 0)
	var controller := RunControllerScript.new(state, 50, CreditBalanceScript.new())
	controller.try_select_contract(_contract())
	controller.try_start_session()
	var valid = controller.create_debt_service_quote()
	var before := JSON.stringify(state.get_observation())
	var identity_before := controller.get_active_settlement_identity()
	var wrong_cycle := CreditQuoteScript.new(valid.get_settlement_identity(), valid.get_cycle() + 1, valid.get_credit_revision(), valid.get_items(), valid.get_post_loans(), valid.get_principal_total(), valid.get_interest_total())
	assert_true(controller.try_settle_session(_session_result(), wrong_cycle) == null, "Wrong-cycle quote rejects")
	var wrong_revision := CreditQuoteScript.new(valid.get_settlement_identity(), valid.get_cycle(), valid.get_credit_revision() + 1, valid.get_items(), valid.get_post_loans(), valid.get_principal_total(), valid.get_interest_total())
	assert_true(controller.try_settle_session(_session_result(), wrong_revision) == null, "Stale revision quote rejects")
	var wrong_identity := CreditQuoteScript.new(valid.get_settlement_identity() + 1, valid.get_cycle(), valid.get_credit_revision(), valid.get_items(), valid.get_post_loans(), valid.get_principal_total(), valid.get_interest_total())
	assert_true(controller.try_settle_session(_session_result(), wrong_identity) == null, "Wrong identity quote rejects")
	assert_true(controller.try_settle_session(_session_result(), valid, true) == null, "Injected final pre-install failure rejects")
	assert_equal(JSON.stringify(state.get_observation()), before, "All rejected quotes preserve persistent state")
	assert_equal(controller.get_active_settlement_identity(), identity_before, "Rejected quotes retain settlement identity")
	assert_not_null(controller.try_settle_session(_session_result(), valid), "Valid retry commits after rejection")


func _contract() -> Dictionary:
	return {"company_id": &"company_01", "quota": 4, "maximum_shortfall_penalty": 100, "completion_bonus_at_quota": 60, "trust_per_excess_delivery_milli": 0}


func _session_result():
	return SessionResultScript.new(SessionResultScript.Reason.REGULAR_TIME_EXPIRED, 10, 10, 0, 5, 200, 100.0, 75.0, 25, 425, 75, 2, 1, 18, 3, 1, 40, 1, 40, 40, 80, &"company_01", 4, 4, 10000, 60, 0, [])
