extends SceneTree

const APP_SCENE_PATH := "res://tests/integration/risk_investment_app.tscn"
const SessionInvestmentInputScript = preload("res://src/domain/session/session_investment_input.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")

const ACTION_DEMOLITION := &"paid_demolition"
const ACTION_TRACK := &"temporary_track_purchase"
const ACTION_CARGO := &"temporary_cargo_purchase"
const CROSSING_BASE_ROUTE: Array[Vector2i] = [
	Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
	Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2),
]
const CROSSING_PATH: Array[Vector2i] = [
	Vector2i(8, 2), Vector2i(9, 2), Vector2i(9, 3), Vector2i(9, 4),
	Vector2i(9, 5), Vector2i(9, 6), Vector2i(9, 7), Vector2i(8, 7),
	Vector2i(7, 7), Vector2i(6, 7), Vector2i(5, 7), Vector2i(4, 7),
	Vector2i(3, 7), Vector2i(2, 7), Vector2i(2, 6), Vector2i(2, 5),
	Vector2i(2, 4), Vector2i(2, 3), Vector2i(2, 2), Vector2i(2, 1),
]

var _failures := PackedStringArray()
var _app_scene: PackedScene
var _deterministic_terminal_traces: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_app_scene = load(APP_SCENE_PATH) as PackedScene
	if _app_scene == null:
		push_error("Missing Risk integration scene: %s" % APP_SCENE_PATH)
		quit(1)
		return

	await _verify_fixed_seed_scene_and_resize_mapping()
	await _verify_actions_and_regular_cleanup()
	await _verify_crossing_hazard_warp_and_track_end()
	await _verify_crossing_hazard_warp_and_track_end()
	_assert_equal(_deterministic_terminal_traces.size(), 2, "Repeated complete traces publish two observations")
	if _deterministic_terminal_traces.size() == 2:
		_assert_equal(
			_deterministic_terminal_traces[1],
			_deterministic_terminal_traces[0],
			"Repeated fixed-seed complete traces are byte-identical"
		)
	await _verify_same_sweep_warp_before_durability_end()

	if _failures.is_empty():
		print("PASS: risk investment integration")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("FAIL: %d risk investment integration assertion(s)" % _failures.size())
	quit(1)


func _verify_fixed_seed_scene_and_resize_mapping() -> void:
	var first = await _spawn_app()
	var second = await _spawn_app()
	if first == null or second == null:
		_free_app(first)
		_free_app(second)
		await process_frame
		return
	_assert_equal(
		_scene_observation(first),
		_scene_observation(second),
		"Repeated fixed-seed scene composition is byte-identical"
	)
	_assert_equal(first.startup_seed, 73013, "Risk fixture uses the approved fixed seed")
	_assert_equal(first.session_start_config.departure_cell, Vector2i(0, 2), "Risk fixture selects the authored deterministic departure")
	_assert_equal(first.hazard_system.get_hazard_cells().size(), 12, "Risk fixture composes twelve unique hazard cells")
	_assert_true(not first.hazard_system.get_hazard_cells().has(Vector2i(0, 2)), "Hazard layout excludes departure")

	var shell = first.get_node("SessionShell")
	var view = shell.get_track_field_view()
	var presentation_ready := _require_presentation_surface(shell, view)
	if presentation_ready:
		var render: Dictionary = view.get_render_observation()
		_assert_equal(render.hazard_terrain.size(), 12, "Real field presents every fixed-seed hazard")
		for viewport_size in [
			Vector2(960.0, 540.0),
			Vector2(1280.0, 720.0),
			Vector2(1600.0, 900.0),
			Vector2(1920.0, 1080.0),
		]:
			shell.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			shell.size = viewport_size
			await process_frame
			var field_rect: Rect2 = shell.get_field_global_rect()
			var mapped = shell.try_viewport_to_logical_field(field_rect.get_center())
			_assert_true(mapped != null, "Real shell maps the resized field center at %s" % viewport_size)
			if mapped != null:
				_assert_true(Vector2(mapped).is_equal_approx(Vector2(320.0, 160.0)), "Resize preserves logical center at %s" % viewport_size)
	_free_app(first)
	_free_app(second)
	await process_frame


func _verify_actions_and_regular_cleanup() -> void:
	var app = await _spawn_app()
	if app == null:
		return
	var shell = app.get_node("SessionShell")
	var view = shell.get_track_field_view()
	if not _require_presentation_surface(shell, view):
		_free_app(app)
		await process_frame
		return
	app.session_start_config.departure_required_built_cells = 99
	var track = app.track_system
	var free_suffix: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2)]
	_append_and_release(track, free_suffix)
	_assert_equal(track.get_endpoint_cell(), Vector2i(2, 2), "Free-cancel fixture commits a valid ghost suffix")
	app.session_controller.call("_publish_snapshot")
	var cash_before_free: int = app.session_economy.get_cash()
	_assert_true(_move_pointer(app, Vector2i(2, 2)), "Real field hovers the free ghost suffix")
	await process_frame
	_assert_true(_send_right_click(app, Vector2i(2, 2)), "Real field captures free ghost right-click")
	_assert_equal(app.session_economy.get_cash(), cash_before_free, "Free ghost cancellation never changes cash")
	_assert_equal(track.get_endpoint_cell(), Vector2i(1, 2), "Free cancellation removes the selected suffix")

	var built_suffix: Array[Vector2i] = [Vector2i(2, 2)]
	_append_and_release(track, built_suffix)
	_assert_equal(track.get_endpoint_cell(), Vector2i(2, 2), "Paid-demolition fixture recommits the valid suffix")
	track.advance_construction(100.0)
	app.session_controller.call("_publish_snapshot")
	_assert_true(_move_pointer(app, Vector2i(2, 2)), "Real field hovers the paid built occurrence")
	await process_frame
	var paid_feedback: Dictionary = view.call(
		"_build_right_click_feedback",
		_cell_center(app.session_start_config, Vector2i(2, 2))
	)
	_assert_equal(
		paid_feedback.get("mode"),
		ACTION_DEMOLITION,
		"Built route occurrence exposes paid demolition before click"
	)
	_assert_true(_send_right_click(app, Vector2i(2, 2)), "Real field captures paid built right-click")
	_assert_equal(app.session_economy.get_cash(), 250, "Paid demolition charges the shared cost once")
	_assert_equal(app.session_controller.get_snapshot().get_paid_demolition_count(), 1, "Paid demolition count reaches presentation snapshot")

	var crossing_base_extension: Array[Vector2i] = [
		Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
		Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2),
	]
	_append_and_release(track, crossing_base_extension)
	track.advance_construction(100.0)
	_assert_true(track.prepare_for_train_sampling(0.0, float(CROSSING_BASE_ROUTE.size())), "Action fixture locks the crossing base")
	app.session_controller.advance_tick(_held_frame(track.get_endpoint_cell(), CROSSING_PATH))
	await process_frame
	var preview: Dictionary = view.get_render_observation().crossing_preview
	_assert_equal(preview.count, 1, "Real scene publishes one pending crossing")
	_assert_equal(preview.cost, 50, "Real scene publishes the shared crossing cost")
	app.session_controller.advance_tick(_release_frame(CROSSING_PATH))
	_assert_equal(app.session_economy.get_cash(), 200, "Crossing charges exactly once")
	_assert_equal(app.session_controller.get_snapshot().get_grade_separated_crossing_count(), 1, "Crossing action count reaches presentation snapshot")

	_assert_true(_press_purchase(app, "TrackPurchaseButton"), "Real track button emits an investment edge")
	_assert_true(_press_purchase(app, "CargoPurchaseButton"), "Real cargo button emits an investment edge")
	_assert_equal(app.session_economy.get_cash(), 80, "Both capacity buttons charge exact costs")
	_assert_equal(track.get_total_track_cells(), 85, "Track button adds five cells")
	_assert_equal(app.cargo_system.get_total_slot_count(), 3, "Cargo button adds one slot")
	_assert_true(_press_purchase(app, "TrackPurchaseButton"), "Second real track purchase is accepted")
	_assert_equal(app.session_economy.get_cash(), 40, "Second track purchase leaves forty cash")

	var canonical_before := _capacity_observation(app)
	app.session_controller.advance_tick(
		TrackInputFrameScript.empty(),
		SessionInvestmentInputScript.new([ACTION_CARGO])
	)
	_assert_equal(_capacity_observation(app), canonical_before, "Insufficient cargo purchase leaves canonical capacity and cash unchanged")
	var cargo_button = _button(shell, "CargoPurchaseButton")
	_assert_true(cargo_button != null and cargo_button.disabled, "Real cargo button disables at insufficient cash")

	var results: Array = []
	app.session_result_presented.connect(func(result): results.append(result))
	app.session_controller.call("_complete", SessionResultScript.Reason.REGULAR_TIME_EXPIRED)
	_assert_equal(results.size(), 1, "Regular completion presents one result")
	if results.size() == 1:
		_assert_equal(results[0].get_final_session_cash(), 40, "Regular completion refunds no action cost")
	_assert_true(_button(shell, "TrackPurchaseButton").disabled, "Regular completion revokes track purchase UI")
	_assert_true(_button(shell, "CargoPurchaseButton").disabled, "Regular completion revokes cargo purchase UI")

	var fresh = await _spawn_app()
	if fresh != null:
		_assert_equal(fresh.session_economy.get_cash(), 300, "Fresh real scene restores starting cash")
		_assert_equal(fresh.track_system.get_total_track_cells(), 80, "Fresh real scene restores base track capacity")
		_assert_equal(fresh.cargo_system.get_total_slot_count(), 2, "Fresh real scene restores base cargo capacity")
	_free_app(fresh)
	_free_app(app)
	await process_frame


func _verify_crossing_hazard_warp_and_track_end() -> void:
	var app = await _spawn_app()
	if app == null:
		return
	var shell = app.get_node("SessionShell")
	var view = shell.get_track_field_view()
	if not _require_presentation_surface(shell, view):
		_free_app(app)
		await process_frame
		return
	app.session_start_config.departure_required_built_cells = 99
	var track = app.track_system
	_append_and_release(track, CROSSING_BASE_ROUTE)
	track.advance_construction(100.0)
	_assert_true(track.prepare_for_train_sampling(0.0, float(CROSSING_BASE_ROUTE.size())), "Movement fixture locks the crossing base")
	app.session_controller.advance_tick(_held_frame(track.get_endpoint_cell(), CROSSING_PATH))
	app.session_controller.advance_tick(_release_frame(CROSSING_PATH))
	track.advance_construction(100.0)
	app.session_start_config.departure_required_built_cells = 1
	app.session_start_config.train_speed_cells_per_second = 5.0
	app.train_system._motion._speed_cells_per_second = 5.0
	var hazard_cells: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2)]
	app.hazard_system._hazard_cells = hazard_cells
	_install_active_warp(app, Vector2i(2, 2), Vector2i(2, 6))
	var built_end: float = track.get_built_end_distance_cells()
	_assert_true(
		track.prepare_for_train_sampling(0.0, built_end),
		"Movement fixture validates the complete crossing route"
	)
	var route_trace := _route_observation(track)
	var expected_hazard_distance: float = track.get_traveled_hazard_distance_cells(
		hazard_cells, 0.0, built_end
	)
	var crossing_hazard_cells: Array[Vector2i] = [Vector2i(2, 2)]
	var crossing_occurrence_distances: Array[float] = []
	for record in track.get_cell_records():
		if record.cell != Vector2i(2, 2):
			continue
		crossing_occurrence_distances.append(
			track.get_traveled_hazard_distance_cells(
				crossing_hazard_cells,
				record.route_distance_start_cells,
				record.route_distance_start_cells + 1.0
			)
		)
	_assert_equal(crossing_occurrence_distances.size(), 2, "Crossing cell has two route occurrences")
	for occurrence_distance in crossing_occurrence_distances:
		_assert_true(occurrence_distance > 0.0, "Each crossing occurrence contributes actual hazard distance")
	_assert_true(_press_purchase(app, "TrackPurchaseButton"), "Track-end fixture buys temporary track capacity")
	_assert_true(_press_purchase(app, "CargoPurchaseButton"), "Track-end fixture buys temporary cargo capacity")

	var results: Array = []
	app.session_result_presented.connect(func(result): results.append(result))
	var saw_partial_damage := false
	for _tick in range(100):
		if app.session_controller.get_state() == 3:
			break
		app.session_controller.advance_tick(TrackInputFrameScript.empty())
		var durability: float = app.train_system.get_current_durability()
		if durability < 100.0 and durability > 70.0:
			saw_partial_damage = true
	_assert_true(saw_partial_damage, "Real movement exposes partial actual-distance hazard damage")
	_assert_equal(results.size(), 1, "Track end presents exactly one result")
	if results.size() == 1:
		_assert_equal(results[0].get_reason(), SessionResultScript.Reason.TRACK_END_REACHED, "Long crossing route ends at track end")
		_assert_equal(results[0].get_final_session_cash(), 167, "Track end retains one delivery fee and refunds neither crossing nor purchases")
		_assert_equal(results[0].get_final_total_track_cells(), 85, "Track-end evidence retains final temporary track capacity")
		_assert_equal(results[0].get_final_total_cargo_slots(), 3, "Track-end evidence retains final temporary cargo capacity")
	var expected_durability := maxf(
		0.0,
		100.0 - expected_hazard_distance * app.session_start_config.damage_per_traveled_cell
	)
	_assert_true(
		is_equal_approx(app.train_system.get_current_durability(), expected_durability),
		"Whole-route durability matches deterministic actual-distance hazard damage"
	)
	_assert_equal(app.cargo_system.get_delivered_pair_count(), 1, "Warp origin and destination contacts survive crossing traversal")
	_assert_equal(app.cargo_system.get_base_delivery_reward_total(), 37, "Warp delivery retains base reward boundary")
	_assert_true(_button(shell, "TrackPurchaseButton").disabled, "Track end revokes purchase UI")
	var result = results[0] if results.size() == 1 else null
	_deterministic_terminal_traces.append(
		_complete_trace_observation(
			app,
			route_trace,
			hazard_cells,
			crossing_occurrence_distances,
			result
		)
	)
	_free_app(app)
	await process_frame


func _verify_same_sweep_warp_before_durability_end() -> void:
	var app = await _spawn_app()
	if app == null:
		return
	var shell = app.get_node("SessionShell")
	var view = shell.get_track_field_view()
	if not _require_presentation_surface(shell, view):
		_free_app(app)
		await process_frame
		return
	var route: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]
	_append_and_release(app.track_system, route)
	app.track_system.advance_construction(100.0)
	app.session_start_config.train_speed_cells_per_second = 5.0
	app.train_system._motion._speed_cells_per_second = 5.0
	app.train_system._maximum_durability = 5.0
	app.train_system._current_durability = 5.0
	var hazard_cells: Array[Vector2i] = [Vector2i(1, 2)]
	app.hazard_system._hazard_cells = hazard_cells
	_install_active_warp(app, Vector2i(1, 2), Vector2i(3, 2))
	_assert_true(_press_purchase(app, "TrackPurchaseButton"), "Durability fixture buys temporary track capacity")
	var results: Array = []
	app.session_result_presented.connect(func(result): results.append(result))
	for _tick in range(4):
		if app.session_controller.get_state() == 3:
			break
		app.session_controller.advance_tick(TrackInputFrameScript.empty())
	_assert_equal(results.size(), 1, "Zero durability presents exactly one result")
	if results.size() == 1:
		_assert_equal(results[0].get_reason(), SessionResultScript.Reason.DURABILITY_DEPLETED, "Durability end wins before time or track end")
		_assert_equal(results[0].get_final_session_cash(), 260, "Durability end refunds no purchase")
	var event_types: Array[StringName] = []
	for event in app.session_controller.get_snapshot().get_warp_cargo_events():
		event_types.append(StringName(event.type))
	_assert_true(event_types.has(&"LOADED"), "Same-sweep Warp contact resolves before zero durability")
	_assert_true(event_types.has(&"VOIDED"), "Durability completion voids the in-transit pair")
	_assert_equal(app.cargo_system.get_occupied_slot_count(), 0, "Durability completion clears temporary cargo authority")
	_assert_equal(shell.get_layout_observation().result_texts[1], "DURABILITY DEPLETED", "Real result overlay names durability depletion")
	_assert_true(_button(shell, "TrackPurchaseButton").disabled, "Durability completion revokes purchase UI")
	_free_app(app)
	await process_frame


func _spawn_app():
	var app = _app_scene.instantiate()
	root.add_child(app)
	app.set_physics_process(false)
	await process_frame
	if app.session_controller == null:
		_failures.append("Risk app must compose a session controller")
		app.queue_free()
		await process_frame
		return null
	return app


func _require_presentation_surface(shell, view) -> bool:
	var ready := true
	if not shell.has_method("consume_investment_input"):
		_failures.append("Session shell must expose consume_investment_input")
		ready = false
	if view == null or not view.has_signal("paid_demolition_edge_captured"):
		_failures.append("Track field must expose paid_demolition_edge_captured")
		ready = false
	if view != null:
		var render: Dictionary = view.get_render_observation()
		if not render.has("hazard_terrain"):
			_failures.append("Track field must expose hazard_terrain")
			ready = false
		if not render.has("crossing_preview"):
			_failures.append("Track field must expose crossing_preview")
			ready = false
	if _button(shell, "TrackPurchaseButton") == null:
		_failures.append("Session shell must own TrackPurchaseButton")
		ready = false
	if _button(shell, "CargoPurchaseButton") == null:
		_failures.append("Session shell must own CargoPurchaseButton")
		ready = false
	return ready


func _press_purchase(app, button_name: String) -> bool:
	var shell = app.get_node("SessionShell")
	var button = _button(shell, button_name)
	if button == null or button.disabled or not shell.has_method("consume_investment_input"):
		return false
	button.emit_signal("pressed")
	var investment_input = shell.call("consume_investment_input")
	app.session_controller.advance_tick(TrackInputFrameScript.empty(), investment_input)
	return true


func _send_right_click(app, cell: Vector2i) -> bool:
	var shell = app.get_node("SessionShell")
	var view = shell.get_track_field_view()
	if view == null or not shell.has_method("consume_investment_input"):
		return false
	if not _move_pointer(app, cell):
		return false
	var logical := _cell_center(app.session_start_config, cell)
	var content: Rect2 = view.get_logical_content_rect()
	var local: Vector2 = content.position + logical * (content.size / app.session_start_config.logical_field_size)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	click.position = local
	view.call("_gui_input", click)
	var frame = shell.consume_track_input_frame()
	var investment_input = shell.call("consume_investment_input")
	app.session_controller.advance_tick(frame, investment_input)
	return true


func _move_pointer(app, cell: Vector2i) -> bool:
	var shell = app.get_node("SessionShell")
	var view = shell.get_track_field_view()
	if view == null:
		return false
	var logical := _cell_center(app.session_start_config, cell)
	var content: Rect2 = view.get_logical_content_rect()
	var local: Vector2 = content.position + logical * (
		content.size / app.session_start_config.logical_field_size
	)
	var motion := InputEventMouseMotion.new()
	motion.position = local
	view.call("_gui_input", motion)
	return true


func _install_active_warp(app, origin: Vector2i, destination: Vector2i) -> void:
	var record := WarpPairRecordScript.new()
	record.ordinal = 1
	record.pair_id = &"warp_pair_1"
	record.origin_cell = origin
	record.destination_cell = destination
	record.state = WarpPairRecordScript.State.ACTIVE_UNLOADED
	record.forecast_remaining_ticks = 0
	record.lifetime_total_ticks = 200
	record.lifetime_remaining_ticks = 200
	record.style_index = 0
	record.company_id = &"legacy_risk_fixture"
	record.base_delivery_fee = 37
	var records: Array[WarpPairRecordScript] = [record]
	app.warp_pair_system._records = records
	app.warp_pair_system._next_ordinal = 2
	app.warp_pair_system._max_live_pairs = 1
	app.session_controller.call("_install_warp_anchors")


func _append_and_release(track, cells: Array[Vector2i]) -> void:
	track.apply_left_input(_held_frame(track.get_endpoint_cell(), cells))
	track.apply_left_input(_release_frame(cells))


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


func _scene_observation(app) -> String:
	var render: Dictionary = app.get_node("SessionShell").get_track_field_view().get_render_observation()
	return JSON.stringify({
		"seed": app.session_start_config.seed,
		"departure": app.session_start_config.departure_cell,
		"hazards": app.hazard_system.get_hazard_cells(),
		"cash": app.session_economy.get_observation(),
		"track_total": app.track_system.get_total_track_cells(),
		"cargo_total": app.cargo_system.get_total_slot_count(),
		"hazard_render": render.get("hazard_terrain", []),
	})


func _complete_trace_observation(
	app,
	route_trace: Dictionary,
	hazard_cells: Array[Vector2i],
	crossing_occurrence_distances: Array[float],
	result
) -> String:
	var snapshot = app.session_controller.get_snapshot()
	return JSON.stringify({
		"seed": app.session_start_config.seed,
		"hazards": _cell_observations(hazard_cells),
		"hazard_distance_by_crossing_occurrence": crossing_occurrence_distances.duplicate(),
		"route_and_crossing": route_trace,
		"cash": app.session_economy.get_observation(),
		"durability": {
			"maximum": app.train_system.get_maximum_durability(),
			"current": app.train_system.get_current_durability(),
		},
		"capacity": {
			"track_total": app.track_system.get_total_track_cells(),
			"cargo_total": app.cargo_system.get_total_slot_count(),
			"track_purchase_count": snapshot.get_temporary_track_purchase_count(),
			"cargo_purchase_count": snapshot.get_temporary_cargo_purchase_count(),
		},
		"terminal_snapshot": {
			"state": snapshot.get_state(),
			"elapsed_ticks": snapshot.get_elapsed_ticks(),
			"remaining_ticks": snapshot.get_remaining_ticks(),
			"cash": snapshot.get_current_session_cash(),
			"spent": snapshot.get_total_session_cash_spent(),
			"durability": snapshot.get_current_durability(),
			"repair_basis": snapshot.get_repair_cost_basis(),
			"available_track": snapshot.get_available_track_cells(),
			"total_track": snapshot.get_total_track_cells(),
			"total_cargo": snapshot.get_total_cargo_slots(),
			"delivered": snapshot.get_delivered_pair_count(),
			"base_reward": snapshot.get_base_delivery_reward_total(),
			"demolition_count": snapshot.get_paid_demolition_count(),
			"crossing_count": snapshot.get_grade_separated_crossing_count(),
			"track_purchase_count": snapshot.get_temporary_track_purchase_count(),
			"cargo_purchase_count": snapshot.get_temporary_cargo_purchase_count(),
		},
		"result": _result_observation(result),
	})


func _route_observation(track) -> Dictionary:
	var records: Array[Dictionary] = []
	var crossing_count := 0
	for record in track.get_cell_records():
		if record.grade_separated_crossing:
			crossing_count += 1
		records.append({
			"serial": record.route_serial,
			"cell": [record.cell.x, record.cell.y],
			"distance": record.route_distance_start_cells,
			"state": record.state,
			"build": record.build_progress,
			"group": record.geometry_group_id,
			"locked": record.geometry_locked,
			"crossing": record.grade_separated_crossing,
			"crossing_partner": record.crossing_partner_route_serial,
		})
	var pieces: Array[Dictionary] = []
	for piece in track.get_geometry_pieces():
		pieces.append({
			"group": piece.group_id,
			"kind": piece.kind,
			"first": piece.first_route_serial,
			"last": piece.last_route_serial,
			"length": piece.nominal_length_cells,
			"absolute_start": piece.absolute_start_distance_cells,
			"footprint": _cell_observations(piece.footprint_cells),
			"centerline": _point_observations(piece.centerline),
			"locked": piece.locked,
			"exit_support": piece.exit_support_route_serial,
			"active_start": piece.active_local_start_cells,
			"active_end": piece.active_local_end_cells,
		})
	return {
		"records": records,
		"pieces": pieces,
		"crossing_count": crossing_count,
		"contacts": track.get_contact_observations(),
	}


func _result_observation(result) -> Dictionary:
	if result == null:
		return {}
	return {
		"reason": result.get_reason(),
		"total_ticks": result.get_total_ticks(),
		"elapsed_ticks": result.get_elapsed_ticks(),
		"remaining_ticks": result.get_remaining_ticks(),
		"delivered": result.get_delivered_pair_count(),
		"base_reward": result.get_base_delivery_reward_total(),
		"maximum_durability": result.get_maximum_durability(),
		"current_durability": result.get_current_durability(),
		"repair_basis": result.get_repair_cost_basis(),
		"cash": result.get_final_session_cash(),
		"spent": result.get_total_session_cash_spent(),
		"track_purchase_count": result.get_temporary_track_purchase_count(),
		"cargo_purchase_count": result.get_temporary_cargo_purchase_count(),
		"total_track": result.get_final_total_track_cells(),
		"total_cargo": result.get_final_total_cargo_slots(),
		"demolition_count": result.get_paid_demolition_count(),
		"demolition_spent": result.get_paid_demolition_spent(),
		"crossing_count": result.get_grade_separated_crossing_count(),
		"crossing_spent": result.get_grade_separated_crossing_spent(),
		"track_purchase_spent": result.get_temporary_track_purchase_spent(),
		"cargo_purchase_spent": result.get_temporary_cargo_purchase_spent(),
	}


func _cell_observations(cells: Array) -> Array:
	var observations: Array = []
	for cell in cells:
		observations.append([cell.x, cell.y])
	return observations


func _point_observations(points) -> Array:
	var observations: Array = []
	for point in points:
		observations.append([point.x, point.y])
	return observations


func _capacity_observation(app) -> String:
	var snapshot = app.session_controller.get_snapshot()
	return JSON.stringify({
		"cash": app.session_economy.get_observation(),
		"track_total": app.track_system.get_total_track_cells(),
		"track_available": app.track_system.get_available_track_cells(),
		"cargo_total": app.cargo_system.get_total_slot_count(),
		"track_count": snapshot.get_temporary_track_purchase_count(),
		"cargo_count": snapshot.get_temporary_cargo_purchase_count(),
		"demolition_count": snapshot.get_paid_demolition_count(),
		"crossing_count": snapshot.get_grade_separated_crossing_count(),
	})


func _button(shell, button_name: String):
	return shell.get_node_or_null(
		"OuterMargin/MainColumn/BottomHud/BottomContent/BottomItems/%s" % button_name
	)


func _cell_center(config, cell: Vector2i) -> Vector2:
	return config.grid_origin_units + (Vector2(cell) + Vector2(0.5, 0.5)) * config.grid_cell_size_units


func _free_app(app) -> void:
	if app != null and is_instance_valid(app):
		app.queue_free()


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
