extends SceneTree

const APP_SCENE := "res://tests/integration/credit_survival_app.tscn"
const CreditBalanceScript = preload("res://src/config/credit_survival_balance.gd")
const CycleProgressionScript = preload("res://src/domain/run/cycle_progression.gd")
const LoanRecordScript = preload("res://src/domain/credit/loan_record.gd")
const RunControllerScript = preload("res://src/domain/run/prototype_run_controller.gd")
const RunStateScript = preload("res://src/domain/run/run_state.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const TerminalResultScript = preload("res://src/domain/run/terminal_run_result.gd")

const COMPANY_IDS: Array[StringName] = [
	&"company_01", &"company_02", &"company_03",
	&"company_04", &"company_05", &"company_06",
]

var _failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_real_app_surface()
	var first := _scenario_a()
	var second := _scenario_a()
	_assert_equal(first, _scenario_a_expected(), "Independent two-cycle debt oracle matches exact values")
	_assert_equal(JSON.stringify(second), JSON.stringify(first), "Repeated Credit traces are byte-identical")
	_verify_gameplay_trust_unlock()
	_verify_negative_recovery_and_decline()
	_verify_credit_exhaustion()
	_verify_difficulty_growth()
	_finish()


func _verify_real_app_surface() -> void:
	var scene = load(APP_SCENE) as PackedScene
	_assert_true(scene != null, "Credit integration scene exists")
	if scene == null: return
	var original_size := root.size
	var app = scene.instantiate()
	root.add_child(app)
	await process_frame
	for size in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = size
		await process_frame
		await process_frame
		var observation: Dictionary = app.get_playtest_observation()
		_assert_equal(observation.operations.company_credit.size(), 6, "Real app exposes six Credit companies at %s" % size)
		var operations = app.get_node("OperationsScreen")
		var panel: Rect2 = operations.get_presentation_observation().panel_rect
		_assert_true(root.get_visible_rect().encloses(panel), "Operations panel fits %s" % size)
		_assert_true(operations.get_node("Center/Panel/Margin/Rows/CompanyScroll") is ScrollContainer, "Company list scrolls at %s" % size)
	root.size = original_size
	app.free()
	await process_frame


func _scenario_a() -> Dictionary:
	var balance := CreditBalanceScript.new()
	var trust := {&"company_01": 100, &"company_06": 100}
	var state := RunStateScript.new(300, COMPANY_IDS, trust, 0, balance.get_rate_table(COMPANY_IDS))
	var controller := RunControllerScript.new(state, 50, balance, CycleProgressionScript.new())
	_assert_true(controller.try_borrow(&"company_06", 60), "Scenario A borrows company 06 first")
	_assert_true(controller.try_borrow(&"company_01", 40), "Scenario A borrows company 01 second")
	var post_borrow := state.get_cash()
	var cycle_1 = _settle(controller, 100, 50, 50)
	_assert_true(controller.try_continue_to_operations(), "Scenario A continues after cycle 1")
	var cycle_2 = _settle(controller, 62, 40, 50)
	var loans := {}
	for loan in state.get_active_loans(): loans[String(loan.get_company_id())] = loan.get_remaining_principal()
	return {
		"post_borrow_cash": post_borrow,
		"cycle_1": _settlement_trace(cycle_1),
		"cycle_2": _settlement_trace(cycle_2),
		"remaining_principal": loans,
		"completed_cycles": state.get_completed_cycle_count(),
	}


func _scenario_a_expected() -> Dictionary:
	return {
		"post_borrow_cash": 400,
		"cycle_1": {
			"closing_cash": 222,
			"payments": [
				{"company_id": &"company_01", "loan_id": 2, "principal": 10, "interest": 2, "post_principal": 30},
				{"company_id": &"company_06", "loan_id": 1, "principal": 10, "interest": 6, "post_principal": 50},
			],
			"share": {"numerator": 28, "denominator": 50},
		},
		"cycle_2": {
			"closing_cash": 73,
			"payments": [
				{"company_id": &"company_01", "loan_id": 2, "principal": 10, "interest": 2, "post_principal": 20},
				{"company_id": &"company_06", "loan_id": 1, "principal": 10, "interest": 5, "post_principal": 40},
			],
			"share": {"numerator": 27, "denominator": 40},
		},
		"remaining_principal": {"company_01": 20, "company_06": 40},
		"completed_cycles": 2,
	}


func _settle(controller, spending: int, bonus: int, repair: int):
	var contract := {
		"company_id": &"company_01", "quota": 1,
		"maximum_shortfall_penalty": 0, "completion_bonus_at_quota": bonus,
		"trust_per_excess_delivery_milli": 0,
	}
	_assert_true(controller.try_select_contract(contract), "Scenario selects the next cycle")
	var starting_cash: int = controller.get_run_state_observation().cash
	_assert_true(controller.try_start_session() != null, "Scenario starts from nonnegative shared cash")
	var result: Variant = _session_result(&"company_01", starting_cash - spending, spending, repair, bonus, 0, 1, 1)
	var settlement = controller.try_settle_session(result)
	_assert_true(settlement != null, "Scenario settles one complete cycle")
	return settlement


func _settlement_trace(settlement) -> Dictionary:
	var payments: Array[Dictionary] = []
	for item in settlement.get_credit_survival_observation().debt_service.items:
		payments.append({
			"company_id": item.company_id, "loan_id": item.loan_id,
			"principal": item.principal, "interest": item.interest,
			"post_principal": item.post_principal,
		})
	return {
		"closing_cash": settlement.get_closing_cash(),
		"payments": payments,
		"share": settlement.get_debt_service_share_observation(),
	}


func _verify_gameplay_trust_unlock() -> void:
	var balance := CreditBalanceScript.new()
	var state := RunStateScript.new(300, COMPANY_IDS, {}, 0, balance.get_rate_table(COMPANY_IDS))
	var controller := RunControllerScript.new(state, 50, balance, CycleProgressionScript.new())
	var contract := {"company_id": &"company_01", "quota": 1, "maximum_shortfall_penalty": 0, "completion_bonus_at_quota": 0, "trust_per_excess_delivery_milli": 100}
	_assert_true(controller.try_select_contract(contract), "Trust loop selects company 01")
	_assert_true(controller.try_start_session() != null, "Trust loop starts")
	var settlement = controller.try_settle_session(_session_result(&"company_01", 300, 0, 0, 0, 100, 2, 1))
	_assert_true(settlement != null, "Trust loop settles")
	_assert_true(controller.try_continue_to_operations(), "Trust loop returns to operations")
	var credit: Dictionary = controller.get_operations_observation().company_credit[0]
	_assert_equal(credit.trust_milli, 100, "Gameplay earns company trust")
	_assert_equal(credit.credit_limit, 100, "Gameplay trust unlocks Credit immediately")
	_assert_true(controller.try_borrow(&"company_01", 40), "Positive-cash voluntary borrowing succeeds after unlock")
	_assert_equal(state.get_cash(), 290, "Borrowed proceeds enter shared post-settlement cash")


func _verify_negative_recovery_and_decline() -> void:
	var balance := CreditBalanceScript.new()
	var state := RunStateScript.new(-30, COMPANY_IDS, {&"company_02": 100}, 2, balance.get_rate_table(COMPANY_IDS))
	var controller := RunControllerScript.new(state, 50, balance)
	controller._recovery_mode = true
	_assert_true(controller.get_recovery_observation().recovery_possible, "Scenario B deficit is recoverable")
	_assert_true(controller.try_borrow(&"company_02", 30), "Scenario B borrows the exact deficit")
	_assert_equal(state.get_cash(), 0, "Scenario B restores shared cash to zero")
	var loan = state.get_active_loans()[0]
	_assert_equal(loan.get_remaining_principal(), 30, "Scenario B records principal 30")
	_assert_equal(loan.get_first_due_cycle(), 3, "Scenario B first payment is cycle 3")
	var decline_state := RunStateScript.new(-30, COMPANY_IDS, {&"company_02": 100}, 2, balance.get_rate_table(COMPANY_IDS))
	var decline := RunControllerScript.new(decline_state, 50, balance)
	decline._recovery_mode = true
	_assert_true(decline.try_decline_recovery(), "Explicit recovery decline ends the run")
	_assert_equal(decline.get_terminal_result().get_reason(), TerminalResultScript.Reason.RECOVERY_DECLINED, "Decline has its distinct terminal reason")


func _verify_credit_exhaustion() -> void:
	var balance := CreditBalanceScript.new()
	var trust := {}
	var limits := [100, 100, 125, 125, 150, 150]
	var loans: Array = []
	for index in range(COMPANY_IDS.size()):
		trust[COMPANY_IDS[index]] = 100
		var company = balance.get_company(COMPANY_IDS[index])
		loans.append(LoanRecordScript.new(index + 1, COMPANY_IDS[index], limits[index], limits[index], company.rate_basis_points, company.term_cycles, 0, 3))
	var state := RunStateScript.new(-11, COMPANY_IDS, trust, 2, balance.get_rate_table(COMPANY_IDS), loans, 7, 0)
	var controller := RunControllerScript.new(state, 50, balance)
	controller._phase = RunControllerScript.Phase.RESULTS
	_assert_true(controller.try_continue_to_operations(), "Scenario C commits terminal continuation once")
	_assert_equal(controller.get_terminal_result().get_reason(), TerminalResultScript.Reason.CREDIT_EXHAUSTED, "Scenario C has Credit exhausted reason")
	var recovery: Dictionary = controller.get_terminal_result().get_observation().recovery
	_assert_equal(recovery.comparison_capacity, 0, "Scenario C comparison capacity is zero")
	_assert_equal(recovery.aggregate_remaining_credit_saturated, 0, "Scenario C aggregate remaining Credit is zero")
	_assert_false(controller.try_continue_to_operations(), "Scenario C bankruptcy is one-shot")


func _verify_difficulty_growth() -> void:
	var balance := CreditBalanceScript.new()
	var state := RunStateScript.new(300, COMPANY_IDS, {}, 2, balance.get_rate_table(COMPANY_IDS))
	var controller := RunControllerScript.new(state, 50, balance, CycleProgressionScript.new(2, 1, 1.0, 10.0))
	var difficulty: Dictionary = controller.get_cycle_difficulty(1, 100, 2.0)
	_assert_equal(difficulty, {"cycle": 3, "hazard_cell_count": 2, "damage_per_traveled_cell": 4.0}, "Cycle 3 difficulty grows once from the hard-coded base")


func _session_result(company_id: StringName, final_cash: int, spending: int, repair: int, adjustment: int, trust_gain: int, deliveries: int, quota: int):
	return SessionResultScript.new(
		SessionResultScript.Reason.REGULAR_TIME_EXPIRED, 10, 10, 0,
		deliveries, 0, 100.0, 100.0 - float(repair), repair,
		final_cash, spending, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0,
		company_id, quota, deliveries, deliveries * 10000 / quota,
		adjustment, trust_gain, []
	)


func _assert_true(value: bool, message: String) -> void:
	if not value: _failures.append(message)


func _assert_false(value: bool, message: String) -> void:
	if value: _failures.append(message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected: _failures.append("%s | expected=%s actual=%s" % [message, expected, actual])


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: credit survival integration")
		quit(0)
		return
	for failure in _failures: push_error(failure)
	print("FAIL: %d credit survival integration assertion(s)" % _failures.size())
	quit(1)
