extends "res://tests/support/prototype_test.gd"

const APP_SCENE_PATH := "res://src/app/prototype_app.tscn"
const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")
const LogicalTrackFieldScript = preload("res://src/presentation/track/logical_track_field.gd")
const TrackFieldViewScript = preload("res://src/presentation/track/track_field_view.gd")


func run() -> PackedStringArray:
	_test_composition_snaps_only_the_runtime_candidate()
	_test_standard_curve_intervals_and_integer_hud()
	_test_render_observations_are_recursively_detached()
	_test_result_surface_remains_single_shot()
	_test_operations_mode_starts_selected_session()
	return finish()


func _test_operations_mode_starts_selected_session() -> void:
	var app = _new_app()
	if app == null:
		return
	app.start_in_operations = true
	Engine.get_main_loop().root.add_child(app)
	var operations = app.get_node("OperationsScreen")
	assert_true(operations.visible, "Operations mode presents the selection screen")
	assert_true(app.session_controller == null, "Operations mode creates no hidden running session")
	var initial_operations: Dictionary = operations.get_presentation_observation()
	assert_equal(initial_operations.rows.size(), 6, "Operations mode shows all six companies")
	assert_true(initial_operations.start_disabled, "Operations requires an explicit company selection")
	operations.get_node("Center/Panel/Margin/Rows/StartButton").emit_signal("pressed")
	assert_true(app.session_controller == null, "Disabled start creates no session before selection")
	var company_rows = operations.get_node("Center/Panel/Margin/Rows/CompanyRows")
	company_rows.get_child(2).emit_signal("pressed")
	assert_true(operations.get_presentation_observation().rows[2].selected, "Mouse selection updates the explicit selected row")
	operations.get_node("Center/Panel/Margin/Rows/StartButton").emit_signal("pressed")
	assert_true(app.session_controller != null, "Start command composes the selected session")
	if app.session_controller != null:
		assert_equal(app.session_controller.get_state(), SessionControllerScript.State.PREPARING_DEPARTURE, "Start command enters departure preparation")
	assert_false(operations.visible, "Starting hides operations")
	assert_true(app.get_node("SessionShell").visible, "Starting reveals the map-dominant session shell")
	assert_true(
		app.get_node("SessionShell").get_layout_observation().contract_text.begins_with("C3 0/"),
		"Operations-selected company is readable in the session contract HUD"
	)
	app.session_controller.call("_complete", SessionResultScript.Reason.REGULAR_TIME_EXPIRED)
	var results = app.get_node("ContractResultPanel")
	assert_true(results.visible, "Session completion presents ordered contract results")
	results.get_node("Center/Panel/Margin/Rows/ContinueButton").emit_signal("pressed")
	assert_true(operations.visible, "Continue returns once to operations")
	assert_equal(app.run_state.get_completed_cycle_count(), 1, "Presented cycle persists one completed settlement")
	app.free()


func _new_app():
	var packed = load(APP_SCENE_PATH) as PackedScene
	assert_not_null(packed, "Prototype app scene loads")
	if packed == null:
		return null
	var app = packed.instantiate()
	app.balance = app.balance.duplicate(true)
	app.balance.session_balance = app.balance.session_balance.duplicate(true)
	app.balance.train_balance = app.balance.train_balance.duplicate(true)
	app.balance.track_inventory_balance = app.balance.track_inventory_balance.duplicate(true)
	app.balance.track_construction_balance = app.balance.track_construction_balance.duplicate(true)
	app.balance.departure_balance = app.balance.departure_balance.duplicate(true)
	app.layout_profile = app.layout_profile.duplicate(true)
	return app


func _new_shell():
	var packed = load(SHELL_SCENE_PATH) as PackedScene
	assert_not_null(packed, "Session shell scene loads")
	if packed == null:
		return null
	var shell = packed.instantiate()
	shell.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	shell.size = Vector2(1280.0, 720.0)
	Engine.get_main_loop().root.add_child(shell)
	return shell


func _curve_track(config) -> TrackSystemScript:
	var track = TrackSystemScript.new(config)
	var cells: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(3, 1), Vector2i(3, 2),
	]
	track.apply_left_input(TrackInputFrameScript.new(
		cells, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		true, true, false, false, Vector2i(3, 2), true
	))
	track.apply_left_input(TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, false, true, false, Vector2i(3, 2), true
	))
	return track


func _gap_curve_track(config) -> TrackSystemScript:
	var track = TrackSystemScript.new(config)
	var initial: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	track.apply_left_input(TrackInputFrameScript.new(
		initial, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		true, false, true, false, Vector2i(3, 0), true
	))
	track.apply_right_input(TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, Vector2i(3, 0), true,
		false, false, false, true, Vector2i(3, 0), true
	))
	var continuation: Array[Vector2i] = [
		Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2),
	]
	track.apply_left_input(TrackInputFrameScript.new(
		continuation, Vector2i(2, 0), true, Vector2i(-1, -1), false,
		true, false, true, false, Vector2i(3, 2), true
	))
	return track


func _snapshot(config, track, state: int, train_active: bool = false):
	var built_end: float = track.get_built_end_distance_cells()
	var train_distance := 0.0
	var train_position: Vector2 = config.departure_position
	var train_heading := Vector2.RIGHT
	if train_active:
		assert_true(track.prepare_for_train_sampling(train_distance, train_distance), "Snapshot pose owner prepares")
		var snapshot_train = TrainSystemScript.new(1.0)
		snapshot_train.depart(train_distance)
		var pose = snapshot_train.capture_pose(track)
		train_position = pose.position
		train_heading = pose.heading
	return SessionSnapshotScript.new(
		40, 0, 40, 10, true, state,
		track.get_cell_records(), track.get_geometry_pieces(), track.get_contact_observations(),
		built_end, track.get_available_track_cells(), track.get_total_track_cells(),
		config.grid_origin_units,
		mini(int(floor(built_end + 0.0001)), config.departure_required_built_cells),
		config.departure_required_built_cells,
		maxf(0.0, built_end - train_distance),
		train_active, train_distance, train_position, train_heading,
		0.0, false, config.departure_candidate_id, config.departure_cell
	)


func _test_composition_snaps_only_the_runtime_candidate() -> void:
	var app = _new_app()
	if app == null:
		return
	assert_true(app.balance is PrototypeBalanceScript, "Balance remains specifically typed")
	var shell = app.get_node("SessionShell")
	var view = shell.get_track_field_view()
	var field = view.get_logical_track_field()
	assert_true(view is TrackFieldViewScript, "App owns TrackFieldView")
	assert_true(field is LogicalTrackFieldScript, "View owns LogicalTrackField")
	var authored_before: Array[Dictionary] = field.get_sorted_candidate_records()
	var errors: PackedStringArray = app.compose_session_dependencies()
	assert_equal(errors, PackedStringArray(), "Composition succeeds")
	assert_true(app.track_system is TrackSystemScript, "Composition creates TrackSystem")
	assert_true(app.train_system is TrainSystemScript, "Composition creates TrainSystem")
	assert_equal(app.session_start_config.grid_size, Vector2i(30, 14), "STANDARD grid is active")
	assert_equal(app.session_start_config.grid_origin_units, Vector2.ZERO, "STANDARD origin is centered")
	assert_equal(
		app.session_start_config.departure_position,
		field.grid_cell_center(app.session_start_config.departure_cell),
		"Runtime departure position snaps to its logical cell center"
	)
	var authored_after: Array[Dictionary] = field.get_sorted_candidate_records()
	assert_equal(authored_after, authored_before, "Composition never mutates authored candidate nodes")
	assert_equal(
		app.session_controller.get_snapshot().get_departure_cell(),
		app.session_start_config.departure_cell,
		"Detached snapshot exposes the selected departure cell"
	)
	app.free()


func _test_standard_curve_intervals_and_integer_hud() -> void:
	var app = _new_app()
	if app == null:
		return
	assert_equal(app.compose_session_dependencies(), PackedStringArray(), "Composition succeeds")
	var config = app.session_start_config
	config.departure_cell = Vector2i(0, 0)
	config.departure_position = Vector2(20.0, 20.0)
	config.departure_required_built_cells = 1
	var track = _curve_track(config)
	assert_equal(track.get_geometry_pieces()[0].kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "3x3 curve")
	var shell = _new_shell()
	if shell == null:
		app.free()
		return
	shell.configure(app.layout_profile, _snapshot(config, track, SessionControllerScript.State.PREPARING_DEPARTURE), config)
	var ghost = shell.get_track_field_view().get_render_observation()
	assert_equal(ghost.intervals.size(), 5, "A 3x3 curve exposes five nominal intervals")
	for interval in ghost.intervals:
		assert_equal(interval.state, TrackCellRecordScript.State.RESERVED_GHOST, "Unbuilt interval is ghost")
	track.advance_construction(0.5)
	shell.present(_snapshot(config, track, SessionControllerScript.State.PREPARING_DEPARTURE))
	var building = shell.get_track_field_view().get_render_observation()
	assert_equal(building.intervals[0].state, TrackCellRecordScript.State.BUILDING, "Active interval building")
	assert_equal(building.intervals[0].build_progress, 0.5, "Active interval exposes fade")
	assert_false(building.intervals[0].locked, "Construction leaves the B through F curve provisional")
	assert_equal(track.get_built_end_distance_cells(), 0.0, "Building interval remains blocked")
	track.advance_construction(4.5)
	var available_before_support := track.get_available_track_cells()
	var endpoint := track.get_endpoint_cell()
	track.apply_left_input(TrackInputFrameScript.new(
		[], endpoint, true, Vector2i(-1, -1), false,
		true, true, false, false, endpoint, true
	))
	track.apply_left_input(TrackInputFrameScript.new(
		[endpoint, Vector2i(3, 3)], endpoint, true, Vector2i(-1, -1), false,
		false, true, false, false, Vector2i(3, 3), true
	))
	track.apply_left_input(TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, false, true, false, Vector2i(3, 3), true
	))
	var locked_piece = track.get_geometry_pieces()[0].duplicate_piece()
	assert_true(locked_piece.locked, "G locks the whole B through F curve at the horizon")
	shell.present(_snapshot(config, track, SessionControllerScript.State.PREPARING_DEPARTURE))
	var built = shell.get_track_field_view().get_render_observation()
	for interval in built.intervals.slice(0, 5):
		assert_equal(interval.state, TrackCellRecordScript.State.BUILT, "Completed interval is solid")
	assert_equal(built.intervals[5].state, TrackCellRecordScript.State.RESERVED_GHOST, "G remains a ghost support interval")
	assert_equal(track.get_geometry_pieces()[0].centerline, locked_piece.centerline, "Horizon-locked curve never reflows")
	var gap_track = _gap_curve_track(config)
	assert_equal(
		gap_track.get_geometry_pieces()[0].kind,
		TrackGeometryPieceScript.Kind.CURVE_3X3,
		"Cancellation gap still resolves one 3x3 curve"
	)
	shell.present(_snapshot(config, gap_track, SessionControllerScript.State.PREPARING_DEPARTURE))
	var gap_observation = shell.get_track_field_view().get_render_observation()
	assert_equal(gap_observation.intervals.size(), 5, "Serial gap retains one interval per active cell")
	assert_equal(gap_observation.intervals[2].route_serial, 4, "Third active cell preserves identity gap")
	assert_equal(gap_observation.intervals[2].nominal_start_cells, 2.0, "Third interval starts at cell two")
	assert_equal(gap_observation.intervals[2].nominal_end_cells, 3.0, "Third interval ends at cell three")
	for interval in gap_observation.intervals:
		assert_false(
			interval.points[0].is_equal_approx(interval.points[-1]),
			"Every active interval spans a nonzero rendered segment"
		)
	var layout: Dictionary = shell.get_layout_observation()
	assert_equal(
		layout.hud_texts[3],
		"%d / %d" % [available_before_support, track.get_total_track_cells()],
		"TRACK HUD uses exact integers"
	)
	shell.free()
	app.free()


func _test_render_observations_are_recursively_detached() -> void:
	var app = _new_app()
	if app == null:
		return
	assert_equal(app.compose_session_dependencies(), PackedStringArray(), "Composition succeeds")
	var config = app.session_start_config
	config.departure_cell = Vector2i(0, 0)
	config.departure_position = Vector2(20.0, 20.0)
	var track = _curve_track(config)
	var shell = _new_shell()
	if shell == null:
		app.free()
		return
	shell.configure(app.layout_profile, _snapshot(config, track, SessionControllerScript.State.PREPARING_DEPARTURE), config)
	var observation = shell.get_track_field_view().get_render_observation()
	var expected_keys := [
		"logical_size", "grid_rect", "grid_size", "grid_line_color", "grid_lines",
		"field_draw_order", "valid_start_cell", "valid_start_rect", "cells", "pieces", "contacts", "intervals",
		"hazard_terrain", "crossing_preview", "right_click_feedback",
		"warp_endpoints", "departure_marker", "planning_indicator",
		"selected_departure_id", "selected_departure_position", "train_active",
		"train_position", "train_heading", "hover_cancel_cell",
	]
	var actual_keys: Array = observation.keys()
	expected_keys.sort()
	actual_keys.sort()
	assert_equal(actual_keys, expected_keys, "Render observation exposes the canonical schema")
	observation.cells[0].cell = Vector2i(9, 9)
	observation.pieces[0].centerline[0] = Vector2(999.0, 999.0)
	observation.intervals[0].points[0] = Vector2(999.0, 999.0)
	observation.grid_lines[0].from = Vector2(999.0, 999.0)
	observation.field_draw_order[0] = "changed"
	var fresh = shell.get_track_field_view().get_render_observation()
	assert_equal(fresh.cells[0].cell, Vector2i(1, 0), "Rendered records detach")
	assert_false(fresh.pieces[0].centerline[0].is_equal_approx(Vector2(999.0, 999.0)), "Rendered pieces detach")
	assert_false(fresh.intervals[0].points[0].is_equal_approx(Vector2(999.0, 999.0)), "Rendered intervals detach")
	assert_false(fresh.grid_lines[0].from.is_equal_approx(Vector2(999.0, 999.0)), "Rendered grid lines detach")
	assert_equal(fresh.field_draw_order[0], "grid_lines", "Rendered field draw order detaches")
	shell.free()
	app.free()


func _test_result_surface_remains_single_shot() -> void:
	for reason in [SessionResultScript.Reason.REGULAR_TIME_EXPIRED, SessionResultScript.Reason.TRACK_END_REACHED]:
		var shell = _new_shell()
		if shell == null:
			continue
		var result = SessionResultScript.new(reason, 40, 10, 30)
		shell.show_result(result)
		assert_true(shell.is_showing_result(), "Supported result is shown")
		var expected := "REGULAR TIME EXPIRED"
		if reason == SessionResultScript.Reason.TRACK_END_REACHED:
			expected = "TRACK END REACHED"
		assert_equal(shell.get_layout_observation().result_texts[1], expected, "Exact result reason")
		shell.show_result(SessionResultScript.new(SessionResultScript.Reason.REGULAR_TIME_EXPIRED, 40, 40, 0))
		assert_equal(shell.get_layout_observation().result_texts[1], expected, "Repeated result is inert")
		shell.free()
