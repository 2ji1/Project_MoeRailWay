extends "res://tests/support/prototype_test.gd"

const CargoSlotRecordScript = preload("res://src/domain/cargo/cargo_slot_record.gd")
const SessionInvestmentInputScript = preload("res://src/domain/session/session_investment_input.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const SessionEconomyScript = preload("res://src/domain/economy/session_economy.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")
const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")
const TrackFieldViewScript = preload("res://src/presentation/track/track_field_view.gd")
const LogicalTrackFieldScene = preload("res://src/presentation/track/logical_track_field.tscn")
const RiskBalance = preload("res://tests/fixtures/risk_investment_balance.tres")

const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
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


func run() -> PackedStringArray:
	_test_shell_hud_buttons_and_ordered_input()
	_test_same_tick_field_purchase_chronology()
	_test_hazard_primitives_and_resize_mapping()
	_test_free_paid_and_crossing_occurrence_feedback()
	_test_demolition_feedback_matches_strict_train_boundaries()
	_test_durability_result_surface()
	return finish()


func _test_shell_hud_buttons_and_ordered_input() -> void:
	var shell = _new_shell()
	if shell == null:
		return
	var required_methods := [
		&"consume_investment_input",
		&"get_layout_observation",
	]
	var ready := true
	for method_name in required_methods:
		if not shell.has_method(method_name):
			assert_true(false, "Session shell exposes %s" % method_name)
			ready = false
	var track_button = shell.get_node_or_null(
		"OuterMargin/MainColumn/BottomHud/BottomContent/BottomItems/TrackPurchaseButton"
	)
	var cargo_button = shell.get_node_or_null(
		"OuterMargin/MainColumn/BottomHud/BottomContent/BottomItems/CargoPurchaseButton"
	)
	var base_reward_title = shell.get_node_or_null(
		"OuterMargin/MainColumn/TopHud/TopContent/TopItems/BaseRewardItem/BaseRewardText/BaseRewardTitle"
	)
	if track_button == null:
		assert_true(false, "Session shell owns the ordinary track purchase Button")
		ready = false
	if cargo_button == null:
		assert_true(false, "Session shell owns the ordinary cargo purchase Button")
		ready = false
	if base_reward_title == null:
		assert_true(false, "Session shell retains BASE REWARD separately from CASH")
		ready = false
	if not ready:
		shell.free()
		return

	var config = _config()
	var hazards: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 2)]
	shell.configure(
		UILayoutProfileScript.new(),
		_snapshot(config, [], [], hazards, 120, 64.0, 36, 37, 1, 1, 65, 3),
		config
	)
	var observation: Dictionary = shell.get_layout_observation()
	assert_equal(observation.get("cash_text"), "120", "CASH reads provisional session cash")
	assert_equal(observation.get("base_reward_text"), "37", "BASE REWARD remains a separate score")
	assert_equal(observation.get("durability_text"), "64 / 100", "Durability shows current and maximum")
	assert_equal(observation.get("repair_basis_text"), "REPAIR 36", "HUD shows repair-cost basis")
	assert_equal(track_button.text, "BUY TRACK +5 / 40 [1/6]", "Track button shows exact increment, cost, and count")
	assert_equal(cargo_button.text, "BUY CARGO +1 / 80 [1/4]", "Cargo button shows exact increment, cost, and count")
	assert_false(track_button.disabled, "Affordable available track purchase is enabled")
	assert_false(cargo_button.disabled, "Affordable available cargo purchase is enabled")
	assert_equal(track_button.mouse_filter, Control.MOUSE_FILTER_STOP, "Track button is an ordinary explicit input owner")
	assert_equal(cargo_button.mouse_filter, Control.MOUSE_FILTER_STOP, "Cargo button is an ordinary explicit input owner")

	track_button.emit_signal("pressed")
	cargo_button.emit_signal("pressed")
	var ordered_input = shell.call("consume_investment_input")
	assert_true(ordered_input is SessionInvestmentInputScript, "Shell returns the concrete investment input")
	if ordered_input is SessionInvestmentInputScript:
		assert_equal(
			ordered_input.get_ordered_priced_actions(),
			[ACTION_TRACK],
			"The first button edge suppresses later same-tick presses"
		)
	var consumed_again = shell.call("consume_investment_input")
	if consumed_again is SessionInvestmentInputScript:
		assert_equal(consumed_again.get_ordered_priced_actions(), [], "Consumed button edges never queue across ticks")

	var view = shell.get_track_field_view()
	assert_true(view != null and view.has_signal("field_press_edge_captured"), "Every field press shares shell arbitration")
	if view != null and view.has_signal("field_press_edge_captured"):
		view.emit_signal("field_press_edge_captured", ACTION_DEMOLITION)
		track_button.emit_signal("pressed")
		var right_first = shell.call("consume_investment_input")
		if right_first is SessionInvestmentInputScript:
			assert_equal(
				right_first.get_ordered_priced_actions(),
				[ACTION_DEMOLITION],
				"The first paid field edge suppresses a later purchase"
			)

	shell.present(_snapshot(config, [], [], hazards, 39, 64.0, 36, 37, 1, 1, 65, 3, false, false))
	assert_true(track_button.disabled, "Unaffordable track purchase is disabled")
	assert_true(cargo_button.disabled, "Unaffordable cargo purchase is disabled")
	shell.free()


func _test_hazard_primitives_and_resize_mapping() -> void:
	var view := _new_view()
	var config = _config()
	view.configure_session(config)
	var child_count := view.get_child_count()
	var hazards: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 2)]
	view.present(_snapshot(config, [], [], hazards))
	var observation: Dictionary = view.get_render_observation()
	assert_true(observation.has("hazard_terrain"), "Field exposes detached hazard terrain primitives")
	if observation.has("hazard_terrain"):
		assert_equal(observation.hazard_terrain.size(), 2, "Every hazard cell has one terrain observation")
		for terrain in observation.hazard_terrain:
			assert_equal(terrain.draw_layer, &"below_grid", "Hazard terrain declares its below-grid layer")
			assert_true(terrain.has("fill_color"), "Hazard terrain has a fill")
			assert_true(terrain.has("border_color"), "Hazard terrain has a border")
			assert_equal(terrain.mark_segments.size(), 2, "Hazard terrain repeats a primitive X mark")
	assert_equal(view.get_child_count(), child_count, "Hazard primitives add no input-intercepting Control")

	for view_size in [Vector2(960.0, 400.0), Vector2(640.0, 500.0)]:
		view.size = view_size
		var content := view.get_logical_content_rect()
		var viewport_center := view.get_global_transform_with_canvas() * content.get_center()
		var mapped = view.try_viewport_to_logical(viewport_center)
		assert_true(mapped != null, "Resized field center remains mappable at %s" % view_size)
		if mapped != null:
			assert_true(Vector2(mapped).is_equal_approx(config.logical_field_size * 0.5), "Resize preserves logical field center at %s" % view_size)
	view.free()


func _test_same_tick_field_purchase_chronology() -> void:
	var config = _config()
	var free_track := TrackSystemScript.new(config)
	var free_cells: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]
	_append_and_release(free_track, free_cells)

	var purchase_first_shell = _new_shell()
	if purchase_first_shell == null:
		return
	purchase_first_shell.configure(
		UILayoutProfileScript.new(),
		_snapshot(config, free_track.get_cell_records(), free_track.get_geometry_pieces()),
		config
	)
	var purchase_first_view = purchase_first_shell.get_track_field_view()
	var purchase_first_button = purchase_first_shell.get_node(
		"OuterMargin/MainColumn/BottomHud/BottomContent/BottomItems/TrackPurchaseButton"
	)
	purchase_first_button.emit_signal("pressed")
	_send_right_click(purchase_first_view, config, Vector2i(2, 2))
	var purchase_first_frame = purchase_first_shell.consume_track_input_frame()
	var purchase_first_input = purchase_first_shell.consume_investment_input()
	assert_false(
		purchase_first_frame.right_pressed,
		"A purchase edge suppresses a later free field press in the same tick"
	)
	assert_equal(
		purchase_first_input.get_ordered_priced_actions(),
		[ACTION_TRACK],
		"The chronologically first purchase remains the only same-tick action"
	)
	purchase_first_shell.free()

	var field_first_shell = _new_shell()
	if field_first_shell == null:
		return
	field_first_shell.configure(
		UILayoutProfileScript.new(),
		_snapshot(config, free_track.get_cell_records(), free_track.get_geometry_pieces()),
		config
	)
	var field_first_view = field_first_shell.get_track_field_view()
	var field_first_button = field_first_shell.get_node(
		"OuterMargin/MainColumn/BottomHud/BottomContent/BottomItems/TrackPurchaseButton"
	)
	_send_right_click(field_first_view, config, Vector2i(2, 2))
	field_first_button.emit_signal("pressed")
	var field_first_frame = field_first_shell.consume_track_input_frame()
	var field_first_input = field_first_shell.consume_investment_input()
	assert_true(
		field_first_frame.right_pressed,
		"A chronologically first free field press retains the same-tick frame"
	)
	assert_true(
		field_first_frame.right_press_inside_grid,
		"The chronology fixture presses a valid grid cell"
	)
	assert_equal(
		field_first_input.get_ordered_priced_actions(),
		[],
		"A chronologically first free field press suppresses a later purchase"
	)
	field_first_shell.free()


func _test_free_paid_and_crossing_occurrence_feedback() -> void:
	var view := _new_view()
	var config = _config()
	view.configure_session(config)
	if not view.has_method("_build_right_click_feedback"):
		assert_true(false, "Field provides exact occurrence right-click feedback")
		view.free()
		return

	var free_track := TrackSystemScript.new(config)
	var free_cells: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]
	_append_and_release(free_track, free_cells)
	view.present(_snapshot(config, free_track.get_cell_records(), free_track.get_geometry_pieces()))
	var free_feedback: Dictionary = view.call("_build_right_click_feedback", _cell_center(config, Vector2i(2, 2)))
	assert_equal(free_feedback.get("mode"), &"free_cancel", "Ghost suffix advertises free cancellation")
	assert_equal(free_feedback.get("cost"), 0, "Free cancellation advertises zero cost")
	assert_true(free_feedback.get("affected_route_serials", []).size() >= 2, "Free feedback outlines the selected suffix")

	var crossing_track := TrackSystemScript.new(config)
	_append_and_release(crossing_track, CROSSING_BASE_ROUTE)
	crossing_track.advance_construction(float(CROSSING_BASE_ROUTE.size()))
	assert_true(crossing_track.prepare_for_train_sampling(0.0, float(CROSSING_BASE_ROUTE.size())), "Crossing presentation fixture locks the earlier route")
	var economy := SessionEconomyScript.new(300)
	crossing_track.apply_left_input_with_paid_crossings(_held_frame(crossing_track.get_endpoint_cell(), CROSSING_PATH), economy, 50)
	assert_equal(crossing_track.apply_left_input_with_paid_crossings(_release_frame(CROSSING_PATH), economy, 50), 1, "Crossing fixture commits one occurrence")
	crossing_track.advance_construction(100.0)
	view.present(_snapshot(
		config,
		crossing_track.get_cell_records(),
		crossing_track.get_geometry_pieces(),
		[],
		49,
		100.0,
		0,
		0,
		0,
		0,
		crossing_track.get_total_track_cells(),
		2,
		false,
		false,
		1,
		50,
		false
	))
	var center := _cell_center(config, Vector2i(2, 2))
	var horizontal: Dictionary = view.call("_build_right_click_feedback", center + Vector2(8.0, 0.0))
	var vertical: Dictionary = view.call("_build_right_click_feedback", center + Vector2(0.0, 8.0))
	var tie: Dictionary = view.call("_build_right_click_feedback", center)
	assert_equal(horizontal.get("mode"), &"paid_demolition", "Horizontal crossing occurrence advertises paid demolition")
	assert_equal(vertical.get("mode"), &"paid_demolition", "Vertical crossing occurrence advertises paid demolition")
	assert_true(horizontal.get("route_serial", -1) != vertical.get("route_serial", -1), "Pointer proximity selects distinct crossing occurrences")
	assert_equal(horizontal.get("cost"), 50, "Paid demolition uses the shared major action cost")
	assert_false(horizontal.get("affordable", true), "49 cash marks demolition unaffordable")
	assert_equal(horizontal.get("text"), "DEMOLISH 50 (NO CASH)", "Paid feedback states exact unaffordable cost")
	assert_false(tie.get("visible", true), "Exact crossing-center tie is an ambiguous no-op")

	var render := view.get_render_observation()
	assert_true(render.has("crossing_preview"), "Field exposes pending crossing bridge/cost facts")
	if render.has("crossing_preview"):
		assert_equal(render.crossing_preview.get("count"), 1, "Crossing preview reports occurrence count")
		assert_equal(render.crossing_preview.get("cost"), 50, "Crossing preview reports total cost")
		assert_false(render.crossing_preview.get("affordable", true), "Crossing preview reports affordability")
	view.free()


func _test_demolition_feedback_matches_strict_train_boundaries() -> void:
	var view := _new_view()
	var config = _config()
	view.configure_session(config)
	var track := TrackSystemScript.new(config)
	var cells: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]
	_append_and_release(track, cells)
	track.advance_construction(100.0)
	var records: Array[TrackCellRecordScript] = track.get_cell_records()
	var pieces: Array[TrackGeometryPieceScript] = track.get_geometry_pieces()
	var selected: TrackCellRecordScript = records[1]
	var point := _cell_center(config, selected.cell)
	var selected_start := selected.route_distance_start_cells
	var selected_end := selected_start + 1.0

	_present_train_distance(view, config, records, pieces, selected_start - 0.00005)
	var before_start: Dictionary = view.call("_build_right_click_feedback", point)
	assert_equal(
		before_start.get("mode"),
		&"paid_demolition",
		"Any train distance strictly before the selected start exposes the front suffix"
	)

	_present_train_distance(view, config, records, pieces, selected_start)
	var at_start: Dictionary = view.call("_build_right_click_feedback", point)
	assert_false(
		at_start.get("visible", true),
		"A train exactly at the selected start makes the containing span ineligible"
	)

	_present_train_distance(view, config, records, pieces, selected_end - 0.00005)
	var before_end: Dictionary = view.call("_build_right_click_feedback", point)
	assert_false(
		before_end.get("visible", true),
		"A train strictly before the selected end keeps the containing span ineligible"
	)

	_present_train_distance(view, config, records, pieces, selected_end)
	var at_end: Dictionary = view.call("_build_right_click_feedback", point)
	assert_equal(
		at_end.get("mode"),
		&"paid_demolition",
		"A train exactly at the selected end exposes the retained rear prefix"
	)
	view.free()


func _test_durability_result_surface() -> void:
	var shell = _new_shell()
	if shell == null:
		return
	var result := SessionResultScript.new(
		SessionResultScript.Reason.DURABILITY_DEPLETED,
		80, 12, 68, 1, 37,
		100.0, 0.0, 100,
		40, 260,
		2, 1, 90, 3,
		1, 50, 1, 50, 80, 80
	)
	shell.show_result(result)
	assert_true(shell.is_showing_result(), "Durability depletion opens the one-shot result overlay")
	var result_texts: PackedStringArray = shell.get_layout_observation().result_texts
	assert_equal(result_texts[1], "DURABILITY DEPLETED", "Result names the durability end reason")
	assert_equal(
		result_texts[2],
		"CASH 40 | DURABILITY 0 / 100 | REPAIR 100\nTRACK BUY 2 | CARGO BUY 1",
		"Result retains detached cash, durability, repair, and purchase evidence"
	)
	shell.free()


func _new_shell():
	var packed = load(SHELL_SCENE_PATH) as PackedScene
	assert_not_null(packed, "Session shell scene loads")
	if packed == null:
		return null
	var shell = packed.instantiate()
	var logical_field = shell.get_node(
		"OuterMargin/MainColumn/Field/TrackFieldView/LogicalTrackField"
	)
	logical_field.size_preset = 3
	logical_field.custom_width = 640.0
	logical_field.custom_height = 320.0
	logical_field.grid_cell_size_units = 26.666666
	logical_field.custom_grid_columns = 12
	logical_field.custom_grid_rows = 12
	shell.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	shell.size = Vector2(960.0, 540.0)
	Engine.get_main_loop().root.add_child(shell)
	return shell


func _new_view() -> TrackFieldViewScript:
	var view := TrackFieldViewScript.new()
	var logical_field = LogicalTrackFieldScene.instantiate()
	logical_field.size_preset = 3
	logical_field.custom_width = 640.0
	logical_field.custom_height = 320.0
	logical_field.grid_cell_size_units = 26.666666
	logical_field.custom_grid_columns = 12
	logical_field.custom_grid_rows = 12
	view.add_child(logical_field)
	view.size = Vector2(640.0, 320.0)
	return view


func _config():
	var base = RiskBalance.create_session_start_config(73013)
	return RiskBalance.complete_session_start_config(
		base,
		Vector2(640.0, 320.0),
		&"departure_08",
		Vector2(173.333337, 66.666669),
		26.666666,
		Vector2i(12, 12),
		Vector2(160.000004, 0.000004),
		Vector2i(0, 2)
	)


func _snapshot(
	config,
	records: Array = [],
	pieces: Array = [],
	hazards: Array[Vector2i] = [],
	current_cash: int = 300,
	current_durability: float = 100.0,
	repair_basis: int = 0,
	base_reward: int = 0,
	track_purchase_count: int = 0,
	cargo_purchase_count: int = 0,
	total_track_cells: int = 80,
	total_cargo_slots: int = 2,
	track_affordable: bool = true,
	cargo_affordable: bool = true,
	pending_crossing_count: int = 0,
	pending_crossing_cost: int = 0,
	pending_crossing_affordable: bool = true,
	train_active: bool = false,
	train_route_distance_cells: float = 0.0
) -> SessionSnapshotScript:
	var typed_records: Array[TrackCellRecordScript] = []
	for record in records:
		typed_records.append(record)
	var typed_pieces: Array[TrackGeometryPieceScript] = []
	for piece in pieces:
		typed_pieces.append(piece)
	var warp_pairs: Array[WarpPairRecordScript] = []
	var cargo_slots: Array[CargoSlotRecordScript] = []
	return SessionSnapshotScript.new(
		80, 1, 79, 10, true, 1,
		typed_records, typed_pieces, [],
		float(typed_records.size()),
		total_track_cells - typed_records.size(),
		total_track_cells,
		config.grid_origin_units,
		1, config.departure_required_built_cells,
		float(typed_records.size()),
		train_active, train_route_distance_cells, config.departure_position, Vector2.RIGHT,
		0.0, false, config.departure_candidate_id, config.departure_cell,
		true, false,
		warp_pairs, cargo_slots, 1 if total_cargo_slots > 0 else 0, total_cargo_slots,
		1 if base_reward > 0 else 0, base_reward, [],
		false, 25, true,
		hazards, 100.0, current_durability, repair_basis,
		300, current_cash, 300 - current_cash,
		pending_crossing_count, pending_crossing_cost, pending_crossing_affordable,
		track_purchase_count, 6, 40, 5, true, track_affordable,
		cargo_purchase_count, 4, 80, 1, true, cargo_affordable
	)


func _present_train_distance(
	view: TrackFieldViewScript,
	config,
	records: Array[TrackCellRecordScript],
	pieces: Array[TrackGeometryPieceScript],
	train_distance: float
) -> void:
	view.present(_snapshot(
		config, records, pieces, [], 300, 100.0, 0, 0, 0, 0, 80, 2,
		true, true, 0, 0, true, true, train_distance
	))


func _send_right_click(
	view: TrackFieldViewScript,
	config,
	cell: Vector2i
) -> void:
	view.size = config.logical_field_size
	var logical := _cell_center(config, cell)
	var content := view.get_logical_content_rect()
	var local: Vector2 = content.position + logical * (content.size / config.logical_field_size)
	var motion := InputEventMouseMotion.new()
	motion.position = local
	view.call("_gui_input", motion)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	click.position = local
	view.call("_gui_input", click)


func _append_and_release(track: TrackSystemScript, cells: Array[Vector2i]) -> void:
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


func _cell_center(config, cell: Vector2i) -> Vector2:
	return (
		config.grid_origin_units
		+ (Vector2(cell) + Vector2(0.5, 0.5)) * config.grid_cell_size_units
	)
