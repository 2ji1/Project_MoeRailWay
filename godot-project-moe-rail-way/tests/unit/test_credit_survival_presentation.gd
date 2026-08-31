extends "res://tests/support/prototype_test.gd"

const OPERATIONS_SCENE := "res://src/presentation/operations/operations_screen.tscn"
const RESULT_SCENE := "res://src/presentation/results/contract_result_panel.tscn"
const CompanyBalanceScript = preload("res://src/config/company_contract_balance.gd")
const CreditBalanceScript = preload("res://src/config/credit_survival_balance.gd")
const RunStateScript = preload("res://src/domain/run/run_state.gd")
const RunControllerScript = preload("res://src/domain/run/prototype_run_controller.gd")
const TerminalRunResultScript = preload("res://src/domain/run/terminal_run_result.gd")


func run() -> PackedStringArray:
	_test_detached_credit_observation()
	_test_mouse_only_operations()
	_test_recovery_and_terminal_presentation()
	return finish()


func _test_detached_credit_observation() -> void:
	var fixture := _controller_fixture(300)
	var controller = fixture.controller
	assert_true(controller.try_borrow(&"company_01", 40), "Positive-cash operations allow explicit borrowing")
	assert_true(controller.try_borrow(&"company_02", 20), "Shared cash accepts a second company loan")
	var observation: Dictionary = controller.get_operations_observation()
	assert_equal(observation.company_credit.size(), 6, "Credit observation preserves six companies")
	assert_equal(observation.cash, 360, "Credit observation exposes shared post-borrow cash")
	assert_equal(observation.pending_cycle, 1, "Credit observation exposes the next cycle")
	assert_equal(observation.projected_operating_cost, 50, "Credit observation exposes projected operating cost")
	assert_equal(observation.projected_repair_cost, 0, "Credit observation exposes the currently knowable repair cost")
	assert_equal(observation.projected_debt_principal, 15, "Credit observation aggregates next principal")
	assert_equal(observation.projected_debt_interest, 3, "Credit observation aggregates next interest")
	var first: Dictionary = observation.company_credit[0]
	assert_equal(first.company_id, &"company_01", "Credit rows retain canonical company order")
	assert_equal(first.trust_milli, 100, "Credit row exposes trust")
	assert_equal(first.credit_limit, 100, "Credit row exposes current limit")
	assert_equal(first.outstanding_principal, 40, "Credit row exposes outstanding principal")
	assert_equal(first.remaining_credit, 60, "Credit row exposes remaining credit")
	assert_equal(first.borrow_capacity, 60, "Credit row exposes the bounded borrow capacity")
	assert_equal(first.rate_basis_points, 400, "Credit row exposes fixed rate")
	assert_equal(first.next_principal, 10, "Credit row exposes next principal")
	assert_equal(first.next_interest, 2, "Credit row exposes next interest")
	assert_true(first.next_limit_trust_milli > first.trust_milli, "Credit row exposes the next limit threshold")
	assert_equal(first.schedule.size(), 1, "Selected-company schedule is available as detached data")
	observation.company_credit[0].remaining_credit = 999
	assert_equal(controller.get_operations_observation().company_credit[0].remaining_credit, 60, "Presentation observation cannot mutate domain state")
	var max_fixture := _controller_fixture(RunStateScript.MAX_ABSOLUTE_CASH)
	assert_equal(max_fixture.controller.get_operations_observation().company_credit[0].borrow_capacity, 0, "Run cash maximum disables otherwise available Credit")


func _test_mouse_only_operations() -> void:
	var fixture := _controller_fixture(300)
	var controller = fixture.controller
	assert_true(controller.try_borrow(&"company_01", 40), "Schedule fixture accepts one loan")
	var screen = load(OPERATIONS_SCENE).instantiate()
	Engine.get_main_loop().root.add_child(screen)
	assert_true(screen.has_signal("borrow_requested"), "Operations exposes an explicit borrow command")
	assert_true(screen.has_signal("decline_recovery_requested"), "Operations exposes an explicit recovery decline command")
	assert_true(screen.has_method("set_credit_observation"), "Operations accepts detached Credit observations")
	var commands: Array[Dictionary] = []
	screen.borrow_requested.connect(func(company_id, amount): commands.append({"company_id": company_id, "amount": amount}))
	screen.present(fixture.companies, controller.get_operations_observation(), &"company_01")
	var observation: Dictionary = screen.get_presentation_observation()
	assert_equal(observation.rows.size(), 6, "Operations presents six stable company rows")
	assert_true(observation.rows[0].text.contains("LIMIT 100"), "Company row presents current limit")
	assert_true(observation.rows[0].text.contains("PRINCIPAL 40"), "Company row presents principal")
	assert_true(observation.rows[0].text.contains("LEFT 60"), "Company row presents remaining credit")
	assert_true(observation.rows[0].text.contains("RATE 4.00%"), "Company row presents fixed rate")
	assert_true(observation.rows[0].text.contains("NEXT 10+2"), "Company row presents next debt service")
	assert_true(observation.schedule_text.contains("#1 P10 I2 -> 30"), "Selected company schedule is readable")
	assert_true(observation.cost_text.contains("OPERATING 50"), "Projected costs are visible before contract acceptance")
	assert_false(observation.borrow_disabled, "Positive cash does not disable borrowing")
	assert_equal(observation.borrow_amount, 1, "Borrow amount begins at the bounded minimum")
	var controls = screen.get_node("Center/Panel/Margin/Rows/BorrowControls")
	controls.get_node("MinusOne").emit_signal("pressed")
	assert_equal(screen.get_presentation_observation().borrow_amount, 1, "Minus one cannot cross the minimum")
	controls.get_node("PlusTen").emit_signal("pressed")
	controls.get_node("PlusOne").emit_signal("pressed")
	assert_equal(screen.get_presentation_observation().borrow_amount, 12, "Plus controls adjust by their exact bounded steps")
	controls.get_node("MinusTen").emit_signal("pressed")
	assert_equal(screen.get_presentation_observation().borrow_amount, 2, "Minus ten adjusts without crossing the minimum")
	controls.get_node("Maximum").emit_signal("pressed")
	assert_equal(screen.get_presentation_observation().borrow_amount, 60, "MAX selects the exact remaining credit")
	controls.get_node("BorrowButton").emit_signal("pressed")
	assert_equal(commands, [{"company_id": &"company_01", "amount": 60}], "One pressed edge emits exactly one borrow command")
	var max_fixture := _controller_fixture(RunStateScript.MAX_ABSOLUTE_CASH)
	screen.present(max_fixture.companies, max_fixture.controller.get_operations_observation(), &"company_01")
	observation = screen.get_presentation_observation()
	assert_true(observation.borrow_disabled, "Run cash bound disables borrowing")
	assert_equal(observation.borrow_disabled_reason, "RUN CASH LIMIT", "Disabled borrowing explains the run cash bound")
	assert_equal(controls.get_node("BorrowAmount").mouse_filter, Control.MOUSE_FILTER_IGNORE, "Borrow overlay does not intercept input")
	assert_equal(screen.get_node("Center/Panel/Margin/Rows/CreditSchedule").mouse_filter, Control.MOUSE_FILTER_IGNORE, "Schedule overlay does not intercept input")
	assert_equal(screen.anchor_right, 1.0, "Operations follows the full resized viewport width")
	assert_equal(screen.anchor_bottom, 1.0, "Operations follows the full resized viewport height")
	var center: Control = screen.get_node("Center")
	assert_equal(center.anchor_right, 1.0, "Centered panel recomputes horizontal mouse mapping after resize")
	assert_equal(center.anchor_bottom, 1.0, "Centered panel recomputes vertical mouse mapping after resize")
	screen.free()


func _test_recovery_and_terminal_presentation() -> void:
	var fixture := _controller_fixture(-10)
	var credit_observation: Dictionary = fixture.controller.get_operations_observation()
	credit_observation.recovery_mode = true
	var screen = load(OPERATIONS_SCENE).instantiate()
	Engine.get_main_loop().root.add_child(screen)
	var declined := [0]
	screen.decline_recovery_requested.connect(func(): declined[0] += 1)
	screen.present(fixture.companies, credit_observation, &"company_01")
	var observation: Dictionary = screen.get_presentation_observation()
	assert_true(observation.start_disabled, "Negative cash blocks continuation into a session")
	assert_equal(observation.recovery_text, "RECOVERY ACTIVE", "Operations persistently identifies recovery mode")
	assert_true(observation.decline_visible, "Recovery decline appears only during negative-cash recovery")
	screen.get_node("Center/Panel/Margin/Rows/DeclineButton").emit_signal("pressed")
	assert_equal(declined[0], 1, "Recovery decline emits one explicit command")
	screen.free()
	var panel = load(RESULT_SCENE).instantiate()
	Engine.get_main_loop().root.add_child(panel)
	assert_true(panel.has_method("present_terminal"), "Results expose the terminal bankruptcy presentation")
	var terminal := TerminalRunResultScript.new(TerminalRunResultScript.Reason.CREDIT_EXHAUSTED, fixture.controller.get_run_state_observation(), {}, fixture.controller.get_recovery_observation())
	panel.present_terminal(terminal)
	observation = panel.get_presentation_observation()
	assert_equal(observation.reason_text, "BANKRUPTCY: CREDIT EXHAUSTED", "Terminal result shows the bankruptcy reason")
	assert_true(observation.continue_disabled, "Terminal result exposes no continuation command")
	assert_equal(observation.terminal.reason, TerminalRunResultScript.Reason.CREDIT_EXHAUSTED, "Terminal observation remains detached and explicit")
	panel.free()


func _controller_fixture(cash: int) -> Dictionary:
	var credit_balance = CreditBalanceScript.new()
	var company_ids: Array[StringName] = []
	var companies: Array = []
	var trust := {}
	for index in range(6):
		var company_id := StringName("company_%02d" % (index + 1))
		company_ids.append(company_id)
		trust[company_id] = 100
		companies.append(CompanyBalanceScript.new(company_id, "Company %d" % (index + 1)))
	var state := RunStateScript.new(cash, company_ids, trust, 0, credit_balance.get_rate_table(company_ids))
	return {
		"controller": RunControllerScript.new(state, 50, credit_balance),
		"companies": companies,
	}
