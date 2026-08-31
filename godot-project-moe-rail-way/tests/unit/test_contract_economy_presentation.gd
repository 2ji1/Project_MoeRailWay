extends "res://tests/support/prototype_test.gd"

const OPERATIONS_SCENE := "res://src/presentation/operations/operations_screen.tscn"
const RESULT_SCENE := "res://src/presentation/results/contract_result_panel.tscn"
const CompanyBalanceScript = preload("res://src/config/company_contract_balance.gd")
const CargoSlotRecordScript = preload("res://src/domain/cargo/cargo_slot_record.gd")
const CargoSlotStripScript = preload("res://src/presentation/cargo/cargo_slot_strip.gd")
const SettlementResultScript = preload("res://src/domain/run/settlement_result.gd")
const TrackFieldViewScript = preload("res://src/presentation/track/track_field_view.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")


func run() -> PackedStringArray:
	assert_true(ResourceLoader.exists(OPERATIONS_SCENE), "Operations screen scene exists")
	assert_true(ResourceLoader.exists(RESULT_SCENE), "Contract result panel scene exists")
	if not ResourceLoader.exists(OPERATIONS_SCENE) or not ResourceLoader.exists(RESULT_SCENE):
		return finish()
	_test_operations_screen()
	_test_result_panel()
	_test_company_markers_do_not_own_input()
	return finish()


func _test_operations_screen() -> void:
	var screen = load(OPERATIONS_SCENE).instantiate()
	Engine.get_main_loop().root.add_child(screen)
	var companies: Array = []
	var company_ids: Array[StringName] = []
	var trust := {}
	for index in range(6):
		var company_id := StringName("company_%02d" % (index + 1))
		var company = CompanyBalanceScript.new(company_id, "Company %d" % (index + 1))
		company.base_delivery_fee = 100 + index
		company.quota = 3 + index
		companies.append(company)
		company_ids.append(company_id)
		trust[String(company_id)] = index * 125
	var selected: Array[StringName] = []
	var starts := [0]
	screen.company_selected.connect(func(company_id): selected.append(company_id))
	screen.start_requested.connect(func(): starts[0] += 1)
	screen.present(companies, {
		"cash": 300,
		"completed_cycle_count": 2,
		"company_ids": company_ids,
		"company_trust_milli": trust,
	}, &"company_02")
	var observation: Dictionary = screen.get_presentation_observation()
	assert_equal(observation.rows.size(), 6, "Operations shows six stable company rows")
	for index in range(6):
		assert_equal(observation.rows[index].company_id, company_ids[index], "Operations preserves company order %d" % index)
		assert_equal(observation.rows[index].mouse_filter, Control.MOUSE_FILTER_STOP, "Company row owns its explicit click")
	assert_true(observation.rows[1].selected, "Operations shows the selected company")
	assert_equal(observation.status_text, "CASH 300 | CYCLE 2", "Operations shows persistent cash and cycle")
	assert_false(observation.start_disabled, "Selected nonnegative run enables start")
	var row = screen.get_node("Center/Panel/Margin/Rows/CompanyScroll/CompanyRows").get_child(2)
	row.emit_signal("pressed")
	assert_equal(selected, [&"company_03"], "One company row emits one explicit selection command")
	screen.get_node("Center/Panel/Margin/Rows/StartButton").emit_signal("pressed")
	assert_equal(starts[0], 1, "Start button emits one explicit start command")
	screen.present(companies, {
		"cash": -1,
		"completed_cycle_count": 2,
		"company_ids": company_ids,
		"company_trust_milli": trust,
	}, &"company_02")
	observation = screen.get_presentation_observation()
	assert_true(observation.start_disabled, "Negative cash disables session start")
	assert_equal(observation.blocked_text, "CREDIT SURVIVAL REQUIRED", "Negative cash shows the deferred Credit boundary")
	screen.free()


func _test_result_panel() -> void:
	var panel = load(RESULT_SCENE).instantiate()
	Engine.get_main_loop().root.add_child(panel)
	var settlement := SettlementResultScript.new(
		0, &"company_01", 300, 200, 75, 425,
		5, 4, 12500, 60, 125, 25, 50, 410, 1,
		true, true, {"cash": 410, "company_trust_milli": {"company_01": 125}}
	)
	var continues := [0]
	panel.continue_requested.connect(func(): continues[0] += 1)
	panel.present(settlement)
	var observation: Dictionary = panel.get_presentation_observation()
	assert_equal(
		observation.rows.map(func(row): return row.id),
		[&"session_starting_cash", &"delivery_fee_total", &"session_spending", &"settlement_opening_cash", &"contract_adjustment", &"trust_gain_milli", &"repair_cost", &"operating_cost", &"closing_cash"],
		"Results preserve the canonical settlement line order"
	)
	assert_true(observation.rows[1].informational, "Delivery fee is a non-additive reconciliation row")
	assert_true(observation.rows[2].informational, "Session spending is a non-additive reconciliation row")
	assert_true(observation.contract_text.contains("5 / 4"), "Results distinguish contracted deliveries and quota")
	assert_true(observation.settlement.ordered_line_items != [], "Results retain a detached settlement observation")
	var button = panel.get_node("Center/Panel/Margin/Rows/ContinueButton")
	button.emit_signal("pressed")
	button.emit_signal("pressed")
	assert_equal(continues[0], 1, "Continue emits one edge only")
	assert_true(panel.get_presentation_observation().continue_disabled, "Consumed continue is disabled")
	panel.free()


func _test_company_markers_do_not_own_input() -> void:
	var slot := CargoSlotRecordScript.new()
	slot.slot_index = 0
	slot.pair_id = &"pair_1"
	slot.style_index = 0
	slot.company_id = &"company_04"
	var strip := CargoSlotStripScript.new()
	strip._slots = [slot]
	strip._occupied = 1
	strip._total = 1
	var cargo_observation: Dictionary = strip.get_render_observation()
	assert_equal(cargo_observation.slots[0].company_marker, "C4", "Cargo has a non-color company marker")
	assert_equal(strip.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Cargo marker never intercepts field input")
	strip.free()
	var view := TrackFieldViewScript.new()
	view._grid_size = Vector2i(2, 2)
	view._grid_rect = Rect2(Vector2.ZERO, Vector2(100, 100))
	var pair := WarpPairRecordScript.new()
	pair.pair_id = &"pair_1"
	pair.company_id = &"company_04"
	var endpoint: Dictionary = view._warp_endpoint(pair, &"origin", Vector2i.ZERO, true, 1.0, "", 0)
	assert_equal(endpoint.company_marker, "C4", "Warp endpoint has the same non-color company marker")
	assert_equal(view.get_child_count(), 0, "Drawn company markers add no input-owning Controls")
	view.free()
