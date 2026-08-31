extends SceneTree

const APP_SCENE_PATH := "res://tests/integration/contract_economy_app.tscn"
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const PrototypeRunControllerScript = preload("res://src/domain/run/prototype_run_controller.gd")
const TerminalRunResultScript = preload("res://src/domain/run/terminal_run_result.gd")

const INTEGRATION_SEED := 73013
const SELECTED_COMPANY := &"company_02"
const OTHER_COMPANY := &"company_05"
const ROUTE_CELLS: Array[Vector2i] = [
	Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
	Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2),
	Vector2i(9, 2), Vector2i(10, 2), Vector2i(11, 2), Vector2i(11, 3),
	Vector2i(11, 4), Vector2i(11, 5), Vector2i(11, 6), Vector2i(10, 6),
	Vector2i(9, 6), Vector2i(8, 6), Vector2i(7, 6), Vector2i(6, 6),
	Vector2i(5, 6), Vector2i(4, 6), Vector2i(3, 6), Vector2i(2, 6),
	Vector2i(1, 6), Vector2i(1, 5), Vector2i(1, 4), Vector2i(2, 4),
	Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4),
	Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4), Vector2i(10, 4),
	Vector2i(10, 3), Vector2i(9, 3), Vector2i(8, 3), Vector2i(7, 3),
	Vector2i(6, 3), Vector2i(5, 3), Vector2i(4, 3), Vector2i(3, 3),
	Vector2i(2, 3), Vector2i(1, 3), Vector2i(0, 3), Vector2i(0, 4),
	Vector2i(0, 5), Vector2i(0, 6), Vector2i(0, 7), Vector2i(1, 7),
	Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7),
	Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7), Vector2i(9, 7),
	Vector2i(10, 7), Vector2i(11, 7),
	Vector2i(11, 8), Vector2i(11, 9), Vector2i(10, 9), Vector2i(9, 9),
	Vector2i(8, 9), Vector2i(7, 9), Vector2i(6, 9), Vector2i(5, 9),
	Vector2i(4, 9), Vector2i(3, 9), Vector2i(2, 9), Vector2i(1, 9),
	Vector2i(0, 9), Vector2i(0, 8), Vector2i(1, 8), Vector2i(2, 8),
]

var _failures := PackedStringArray()
var _app_scene: PackedScene
var _canonical_traces: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app_scene = load(APP_SCENE_PATH) as PackedScene
	if _app_scene == null:
		push_error("Missing Contract Economy integration scene: %s" % APP_SCENE_PATH)
		quit(1)
		return
	await _verify_complete_cycle()
	await _verify_complete_cycle()
	_assert_equal(_canonical_traces.size(), 2, "Repeated runs publish two canonical traces")
	if _canonical_traces.size() == 2:
		_assert_equal(
			_canonical_traces[1],
			_canonical_traces[0],
			"Repeated fixed-seed Contract Economy traces are byte-identical"
		)
	await _verify_negative_cash_boundary()
	_finish()


func _verify_complete_cycle() -> void:
	var app = await _spawn_operations_app()
	if app == null:
		return
	var operations = app.get_node("OperationsScreen")
	var initial_operations: Dictionary = operations.get_presentation_observation()
	_assert_equal(initial_operations.rows.size(), 6, "Operations presents all six companies")
	_assert_true(initial_operations.start_disabled, "Start remains disabled before contract selection")
	await _verify_operations_layout_at_resolutions(app)
	_select_company_and_start(app, 1)
	if app.session_controller == null:
		_free_app(app)
		await process_frame
		return

	var event_trace: Array[Dictionary] = []
	var delivered: Array[Dictionary] = []
	var pair_identity := {}
	var purchase_pending := false
	var purchase_submitted := false
	var marker_verified := false
	var input_tick := 0
	while (
		app.session_controller.get_state() != SessionControllerScript.State.COMPLETED
		and input_tick < 200
	):
		input_tick += 1
		var frame = TrackInputFrameScript.empty()
		if input_tick == 1:
			frame = _held_frame(app.track_system.get_endpoint_cell(), ROUTE_CELLS)
		elif input_tick == 2:
			frame = _release_frame(ROUTE_CELLS)
		var investment_input = null
		if purchase_pending and not purchase_submitted:
			investment_input = _take_purchase_input(app, "CargoPurchaseButton")
			_assert_true(investment_input != null, "First delivered fee enables the real cargo purchase button")
			purchase_submitted = investment_input != null
		app.session_controller.advance_tick(frame, investment_input)
		var snapshot = app.session_controller.get_snapshot()
		for pair in snapshot.get_warp_pair_records():
			var identity := {
				"company_id": pair.company_id,
				"base_delivery_fee": pair.base_delivery_fee,
				"origin": pair.origin_cell,
				"destination": pair.destination_cell,
			}
			if pair_identity.has(String(pair.pair_id)):
				_assert_equal(identity, pair_identity[String(pair.pair_id)], "Generated pair identity remains immutable")
			else:
				pair_identity[String(pair.pair_id)] = identity
		for event in snapshot.get_warp_cargo_events():
			var event_observation := _event_observation(event)
			event_trace.append(event_observation)
			if StringName(event.get("type", StringName())) == &"DELIVERED":
				delivered.append(event_observation)
				if delivered.size() == 1:
					purchase_pending = true
		if not marker_verified and not snapshot.get_warp_pair_records().is_empty():
			marker_verified = _verify_generated_company_markers(app)

	_assert_true(input_tick > 0, "Real session advances at least one tick")
	_assert_equal(app.session_controller.get_state(), SessionControllerScript.State.COMPLETED, "Route reaches a natural terminal condition")
	_assert_true(app.session_controller.get_snapshot().get_elapsed_ticks() > 0, "Natural completion records elapsed simulation ticks")
	_assert_true(marker_verified, "Generated Warp pairs expose company markers without replacing pair style")
	_assert_true(purchase_submitted, "Immediate fee funds one real in-session purchase")
	_assert_equal(delivered.size(), 3, "Actual train contact delivers three generated pairs")
	if delivered.size() == 3:
		_assert_equal(
			delivered.map(func(event): return event.pair_id),
			[&"warp_pair_1", &"warp_pair_2", &"warp_pair_3"],
			"Actual route produces the approved delivery order"
		)
		_assert_equal(
			delivered.map(func(event): return event.company_id),
			[SELECTED_COMPANY, OTHER_COMPANY, SELECTED_COMPANY],
			"Fixed seed produces contracted and uncontracted deliveries"
		)
		_assert_equal(
			delivered.map(func(event): return event.base_delivery_fee),
			[40, 80, 40],
			"Actual delivery events retain company-specific fees"
		)

	var terminal_snapshot = app.session_controller.get_snapshot()
	_assert_equal(terminal_snapshot.get_delivery_fee_total(), 160, "All actual delivery fees credit immediately")
	_assert_equal(terminal_snapshot.get_total_session_cash_spent(), 40, "Fee-funded purchase spends the configured cost")
	_assert_equal(terminal_snapshot.get_contracted_delivery_count(), 2, "Only selected-company deliveries attain quota")
	_assert_equal(terminal_snapshot.get_contract_attainment_basis_points(), 20000, "Two of quota one yields 200 percent attainment")
	_assert_equal(terminal_snapshot.get_contract_trust_gain_milli(), 125, "Only one excess contracted delivery grants trust")
	_assert_equal(terminal_snapshot.get_temporary_cargo_purchase_count(), 1, "Purchase is committed exactly once")

	var settlement = app.settlement_result
	_assert_true(settlement != null, "Real app settles natural completion once")
	if settlement == null:
		_free_app(app)
		await process_frame
		return
	_assert_equal(settlement.get_completion_reason(), 1, "Actual route ends at track end")
	_assert_equal(settlement.get_session_starting_cash(), 0, "Settlement retains session starting cash")
	_assert_equal(settlement.get_delivery_fee_total(), 160, "Settlement reconciles actual mixed-company fees")
	_assert_equal(settlement.get_session_spending(), 40, "Settlement reconciles funded purchase spending")
	_assert_equal(settlement.get_settlement_opening_cash(), 120, "Settlement opens from post-spend session cash")
	_assert_equal(settlement.get_contract_adjustment(), 60, "Quota completion grants the configured bonus")
	_assert_equal(settlement.get_trust_gain_milli(), 125, "Settlement carries over-attainment trust once")
	_assert_equal(settlement.get_repair_cost(), 0, "Hazard-free fixture has no repair cost")
	_assert_equal(settlement.get_operating_cost(), 50, "Settlement charges operating cost after repair")
	_assert_equal(settlement.get_closing_cash(), 130, "Ordered settlement produces exact closing cash")

	var result_panel = app.get_node("ContractResultPanel")
	var result_observation: Dictionary = result_panel.get_presentation_observation()
	_assert_true(result_observation.visible, "Contract result panel becomes visible")
	_assert_true(not operations.visible, "Hidden Operations does not retain result clicks")
	_assert_equal(
		result_observation.rows.map(func(row): return row.id),
		[&"session_starting_cash", &"delivery_fee_total", &"session_spending", &"settlement_opening_cash", &"contract_adjustment", &"trust_gain_milli", &"repair_cost", &"operating_cost", &"closing_cash"],
		"Result panel preserves exact settlement line order"
	)
	_assert_true(result_observation.contract_text.contains("2 / 1"), "Result panel presents selected-company attainment")
	_assert_true(not JSON.stringify(result_observation).contains("BANKRUPT"), "Contract Economy never presents bankruptcy")

	var trace := {
		"seed": app.session_start_config.seed,
		"input_ticks": input_tick,
		"route": _cell_observations(ROUTE_CELLS),
		"pair_identity": pair_identity,
		"events": event_trace,
		"terminal_snapshot": _snapshot_observation(terminal_snapshot),
		"settlement": settlement.get_observation(),
		"result": _result_text_observation(result_observation),
	}
	var continue_button = result_panel.get_node("Center/Panel/Margin/Rows/ContinueButton")
	continue_button.emit_signal("pressed")
	continue_button.emit_signal("pressed")
	await process_frame
	var returned_operations: Dictionary = operations.get_presentation_observation()
	_assert_true(returned_operations.visible, "Continue returns to Operations")
	_assert_equal(returned_operations.status_text, "CASH 130 | CYCLE 2", "Operations presents persistent closing cash and pending cycle")
	_assert_true(returned_operations.start_disabled, "Continue clears the prior contract selection")
	var run_observation: Dictionary = app.run_controller.get_run_state_observation()
	_assert_equal(run_observation.company_trust_milli[String(SELECTED_COMPANY)], 125, "Only selected company receives persisted trust")
	_assert_equal(run_observation.company_trust_milli[String(OTHER_COMPANY)], 0, "Uncontracted delivery grants no trust")
	_canonical_traces.append(JSON.stringify({
		"cycle": trace,
		"returned_operations": _operations_text_observation(returned_operations),
		"run": run_observation,
	}))
	_free_app(app)
	await process_frame


func _verify_negative_cash_boundary() -> void:
	var app = await _spawn_operations_app()
	if app == null:
		return
	_select_company_and_start(app, 1)
	if app.session_controller == null:
		_free_app(app)
		await process_frame
		return
	var short_route: Array[Vector2i] = [Vector2i(1, 2)]
	for input_tick in range(1, 20):
		var frame = TrackInputFrameScript.empty()
		if input_tick == 1:
			frame = _held_frame(app.track_system.get_endpoint_cell(), short_route)
		elif input_tick == 2:
			frame = _release_frame(short_route)
		app.session_controller.advance_tick(frame)
		if app.session_controller.get_state() == SessionControllerScript.State.COMPLETED:
			break
	_assert_equal(app.session_controller.get_state(), SessionControllerScript.State.COMPLETED, "Short route ends naturally")
	_assert_true(app.session_controller.get_snapshot().get_elapsed_ticks() > 0, "Negative boundary uses elapsed real ticks")
	_assert_equal(app.settlement_result.get_closing_cash(), -170, "No-delivery settlement preserves negative cash")
	var result_panel = app.get_node("ContractResultPanel")
	var result_observation: Dictionary = result_panel.get_presentation_observation()
	_assert_equal(result_observation.blocked_text, "CREDIT SURVIVAL REQUIRED", "Negative result exposes the deferred credit boundary")
	_assert_true(not JSON.stringify(result_observation).contains("BANKRUPT"), "Negative result does not declare bankruptcy")
	result_panel.get_node("Center/Panel/Margin/Rows/ContinueButton").emit_signal("pressed")
	await process_frame
	_assert_equal(app.run_controller.get_phase(), PrototypeRunControllerScript.Phase.TERMINAL, "Unrecoverable negative cash enters terminal phase")
	_assert_equal(app.run_controller.get_terminal_result().get_reason(), TerminalRunResultScript.Reason.CREDIT_EXHAUSTED, "Terminal reason is credit exhausted")
	_assert_true(not app.get_node("OperationsScreen").visible, "Terminal transition does not expose inactive operations")
	_assert_true(result_panel.visible, "Terminal transition preserves the result surface")
	_free_app(app)
	await process_frame


func _spawn_operations_app():
	var app = _app_scene.instantiate()
	root.add_child(app)
	app.set_physics_process(false)
	await process_frame
	if app.startup_seed != INTEGRATION_SEED:
		_failures.append("Contract Economy fixture must use seed %d" % INTEGRATION_SEED)
	if app.session_controller != null:
		_failures.append("Contract Economy fixture must begin in Operations")
	if not app.get_node("OperationsScreen").visible:
		_failures.append("Operations must be visible before selection")
	return app


func _select_company_and_start(app, row_index: int) -> void:
	var operations = app.get_node("OperationsScreen")
	var rows = operations.get_node("Center/Panel/Margin/Rows/CompanyScroll/CompanyRows")
	if row_index < 0 or row_index >= rows.get_child_count():
		_failures.append("Requested company row must exist")
		return
	rows.get_child(row_index).emit_signal("pressed")
	var selected: Dictionary = operations.get_presentation_observation()
	_assert_true(selected.rows[row_index].selected, "Explicit company selection updates Operations")
	_assert_true(not selected.start_disabled, "Valid selected contract enables Start")
	operations.get_node("Center/Panel/Margin/Rows/StartButton").emit_signal("pressed")
	app.set_physics_process(false)


func _verify_operations_layout_at_resolutions(app) -> void:
	var operations = app.get_node("OperationsScreen")
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		await process_frame
		await process_frame
		var observation: Dictionary = operations.get_presentation_observation()
		var viewport_rect: Rect2 = root.get_visible_rect()
		_assert_equal(root.size, resolution, "Windows fixture applies requested physical resolution")
		_assert_true(viewport_rect.encloses(observation.panel_rect), "Operations remains within logical viewport at %s" % resolution)
		_assert_equal(observation.rows.size(), 6, "All six rows remain composed at %s" % resolution)
		for row in observation.rows:
			_assert_true(viewport_rect.encloses(row.rect), "Company row remains within logical viewport at %s" % resolution)
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame


func _verify_generated_company_markers(app) -> bool:
	var render: Dictionary = app.get_node("SessionShell").get_track_field_view().get_render_observation()
	if render.warp_endpoints.is_empty():
		return false
	for endpoint in render.warp_endpoints:
		_assert_true(not String(endpoint.company_marker).is_empty(), "Generated endpoint carries a non-color company marker")
		_assert_true(int(endpoint.style_index) >= 0, "Company marker does not replace pair color and shape identity")
	return true


func _take_purchase_input(app, button_name: String):
	var shell = app.get_node("SessionShell")
	var button = shell.get_node_or_null("OuterMargin/MainColumn/BottomHud/BottomContent/BottomItems/%s" % button_name)
	if button == null or button.disabled:
		return null
	button.emit_signal("pressed")
	return shell.consume_investment_input()


func _held_frame(endpoint: Vector2i, path: Array[Vector2i]) -> TrackInputFrameScript:
	var pointer := endpoint if path.is_empty() else path[-1]
	return TrackInputFrameScript.new(
		path, endpoint, true, Vector2i(-1, -1), false,
		true, true, false, false, pointer, true, path
	)


func _release_frame(path: Array[Vector2i]) -> TrackInputFrameScript:
	var pointer := Vector2i(-1, -1) if path.is_empty() else path[-1]
	return TrackInputFrameScript.new(
		path, Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, false, true, false, pointer, not path.is_empty(), path, path,
		pointer, not path.is_empty()
	)


func _event_observation(event: Dictionary) -> Dictionary:
	return {
		"tick": int(event.get("tick", -1)),
		"type": StringName(event.get("type", StringName())),
		"pair_id": StringName(event.get("pair_id", StringName())),
		"slot_index": int(event.get("slot_index", -1)),
		"amount": int(event.get("amount", 0)),
		"company_id": StringName(event.get("company_id", StringName())),
		"base_delivery_fee": int(event.get("base_delivery_fee", 0)),
	}


func _snapshot_observation(snapshot) -> Dictionary:
	return {
		"state": snapshot.get_state(),
		"elapsed_ticks": snapshot.get_elapsed_ticks(),
		"cash": snapshot.get_current_session_cash(),
		"spent": snapshot.get_total_session_cash_spent(),
		"delivered": snapshot.get_delivered_pair_count(),
		"delivery_fee_total": snapshot.get_delivery_fee_total(),
		"selected_company": snapshot.get_selected_contract_company_id(),
		"quota": snapshot.get_contract_quota(),
		"contracted": snapshot.get_contracted_delivery_count(),
		"attainment": snapshot.get_contract_attainment_basis_points(),
		"adjustment": snapshot.get_cash_contract_adjustment(),
		"trust_gain": snapshot.get_contract_trust_gain_milli(),
		"cargo_purchase_count": snapshot.get_temporary_cargo_purchase_count(),
	}


func _result_text_observation(observation: Dictionary) -> Dictionary:
	return {
		"reason_text": observation.reason_text,
		"contract_text": observation.contract_text,
		"cycle_text": observation.cycle_text,
		"blocked_text": observation.blocked_text,
		"rows": observation.rows.map(func(row): return {"id": row.id, "text": row.text, "informational": row.informational}),
		"settlement": observation.settlement,
	}


func _operations_text_observation(observation: Dictionary) -> Dictionary:
	return {
		"status_text": observation.status_text,
		"blocked_text": observation.blocked_text,
		"start_disabled": observation.start_disabled,
		"rows": observation.rows.map(func(row): return {"company_id": row.company_id, "text": row.text, "selected": row.selected}),
	}


func _cell_observations(cells: Array[Vector2i]) -> Array:
	var observations: Array = []
	for cell in cells:
		observations.append([cell.x, cell.y])
	return observations


func _free_app(app) -> void:
	if app != null and is_instance_valid(app):
		app.queue_free()


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])


func _finish() -> void:
	if _failures.is_empty():
		print("PASS: contract economy integration")
		print("TRACE: " + _canonical_traces[0])
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("FAIL: %d contract economy integration assertion(s)" % _failures.size())
	quit(1)
