extends SceneTree

const APP_SCENE_PATH := "res://src/app/prototype_app.tscn"
const NONDEFAULT_SCENE_PATH := "res://tests/integration/nondefault_track_train_app.tscn"
const INVALID_SCENE_PATH := "res://tests/integration/invalid_track_train_app.tscn"
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const LogicalTrackFieldScript = preload("res://src/presentation/track/logical_track_field.gd")

var _failures := PackedStringArray()


class PresetFixture extends RefCounted:
	var app
	var field
	var view
	var controller
	var latest_snapshot
	var authored_candidate
	var authored_position := Vector2.ZERO
	var results: Array = []
	var event_order: Array[String] = []
	var result_observer: Callable
	var snapshot_observer: Callable
	var event_result_observer: Callable

	func _logical_to_local(logical: Vector2) -> Vector2:
		var content: Rect2 = view.get_logical_content_rect()
		return content.position + logical / field.get_logical_size() * content.size

	func drag_through_logical_centers(centers: Array[Vector2]) -> void:
		var press := InputEventMouseButton.new()
		press.position = _logical_to_local(app.session_start_config.departure_position)
		press.button_index = MOUSE_BUTTON_LEFT
		press.button_mask = MOUSE_BUTTON_MASK_LEFT
		press.pressed = true
		view.call("_gui_input", press)
		for center in centers:
			var motion := InputEventMouseMotion.new()
			motion.position = _logical_to_local(center)
			motion.button_mask = MOUSE_BUTTON_MASK_LEFT
			view.call("_gui_input", motion)
		var release := InputEventMouseButton.new()
		release.position = _logical_to_local(centers[-1])
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		view.call("_gui_input", release)

	func advance_with_input_until_train_distance(input_frame, target_distance: float) -> void:
		controller.advance_tick(input_frame)
		for _tick in range(360):
			latest_snapshot = controller.get_snapshot()
			if latest_snapshot.get_train_route_distance_cells() + 0.0001 >= target_distance:
				return
			if controller.get_state() == SessionControllerScript.State.COMPLETED:
				return
			controller.advance_tick(TrackInputFrameScript.empty())


func _initialize() -> void:
	if OS.get_cmdline_user_args().has("--track-field-reconfiguration-probe"):
		call_deferred("_run_reconfiguration_probe")
		return
	call_deferred("_run")


func _duplicate_runtime_resources(app) -> void:
	app.balance = app.balance.duplicate(true)
	app.balance.session_balance = app.balance.session_balance.duplicate(true)
	app.balance.train_balance = app.balance.train_balance.duplicate(true)
	app.balance.track_inventory_balance = app.balance.track_inventory_balance.duplicate(true)
	app.balance.track_construction_balance = app.balance.track_construction_balance.duplicate(true)
	app.balance.departure_balance = app.balance.departure_balance.duplicate(true)
	app.layout_profile = app.layout_profile.duplicate(true)


func compose_preset_fixture(preset: int, departure_cell: Vector2i):
	var packed = load(APP_SCENE_PATH) as PackedScene
	_assert_true(packed != null, "Prototype app scene loads")
	if packed == null:
		return null
	var app = packed.instantiate()
	_duplicate_runtime_resources(app)
	app.balance.train_balance.speed_cells_per_second = 1.0
	app.balance.track_construction_balance.build_cells_per_second = 60.0
	app.balance.departure_balance.required_built_cells = 1
	app.balance.track_inventory_balance.total_track_cells = 12
	var view = app.get_node("SessionShell").get_track_field_view()
	var field = view.get_logical_track_field()
	field.size_preset = preset
	var records: Array[Dictionary] = field.get_sorted_candidate_records()
	var selected_index := SessionRngScript.new(app.startup_seed).peek_index(records.size())
	var selected_id: StringName = records[selected_index].candidate_id
	var selected_candidate = null
	for child in field.get_node("DepartureCandidates").get_children():
		if StringName(child.candidate_id) == selected_id:
			selected_candidate = child
			break
	_assert_true(selected_candidate != null, "Deterministic authored candidate exists")
	if selected_candidate == null:
		app.free()
		return null
	selected_candidate.position = field.grid_cell_center(departure_cell)
	var authored_position: Vector2 = selected_candidate.position
	var results: Array = []
	var event_order: Array[String] = []
	var result_observer := func(result): results.append(result)
	var snapshot_observer := func(_snapshot): event_order.append("snapshot")
	var event_result_observer := func(_result): event_order.append("result")
	app.session_result_presented.connect(result_observer)
	root.add_child(app)
	await process_frame
	app.set_physics_process(false)
	var fixture := PresetFixture.new()
	fixture.app = app
	fixture.field = field
	fixture.view = view
	fixture.controller = app.session_controller
	fixture.controller.snapshot_published.connect(snapshot_observer)
	app.session_result_presented.connect(event_result_observer)
	fixture.latest_snapshot = app.session_controller.get_snapshot()
	fixture.authored_candidate = selected_candidate
	fixture.authored_position = authored_position
	fixture.results = results
	fixture.event_order = event_order
	fixture.result_observer = result_observer
	fixture.snapshot_observer = snapshot_observer
	fixture.event_result_observer = event_result_observer
	return fixture


func assert_centered_preset_end_to_end(preset: int, expected_origin: Vector2) -> void:
	var fixture = await compose_preset_fixture(preset, Vector2i(0, 0))
	if fixture == null:
		return
	var field = fixture.field
	var target_cell := Vector2i(1, 0)
	var target_center: Vector2 = field.grid_cell_center(target_cell)
	_assert_equal(fixture.app.session_start_config.grid_origin_units, expected_origin, "Config origin")
	_assert_equal(fixture.authored_candidate.position, fixture.authored_position, "Composition preserves source node")
	var centers: Array[Vector2] = [target_center]
	fixture.drag_through_logical_centers(centers)
	var input_frame = fixture.view.consume_input_frame()
	_assert_equal(input_frame.crossed_cells, [target_cell], "Rasterized cell")
	fixture.advance_with_input_until_train_distance(input_frame, 1.0)
	var snapshot = fixture.latest_snapshot
	var observation: Dictionary = fixture.view.get_render_observation()
	_assert_equal(snapshot.get_grid_origin_units(), expected_origin, "Snapshot origin")
	_assert_equal(snapshot.get_geometry_pieces()[0].sample_nominal(1.0).position, target_center, "Runtime centerline")
	_assert_equal(observation.pieces[0].sample_nominal(1.0).position, target_center, "Rendered centerline")
	_assert_equal(snapshot.get_train_position(), target_center, "Train position")
	_assert_equal(fixture.controller.get_state(), SessionControllerScript.State.COMPLETED, "Track-end lifecycle completes")
	_assert_equal(fixture.results.size(), 1, "Real app presents one result")
	if not fixture.results.is_empty():
		_assert_equal(fixture.results[0].get_reason(), SessionResultScript.Reason.TRACK_END_REACHED, "Track-end reason")
	_assert_equal(fixture.event_order.slice(-2), ["snapshot", "result"], "Terminal snapshot publishes before result")
	fixture.controller.snapshot_published.disconnect(fixture.snapshot_observer)
	fixture.app.session_result_presented.disconnect(fixture.result_observer)
	fixture.app.session_result_presented.disconnect(fixture.event_result_observer)
	fixture.app.queue_free()
	await process_frame


func assert_running_curve_endpoint_hover_survives_live_snapshots() -> void:
	print("Endpoint interaction fix: live RUNNING curve endpoint hover persists")
	var fixture = await compose_preset_fixture(
		LogicalTrackFieldScript.SizePreset.EXPANSIVE,
		Vector2i(2, 2)
	)
	if fixture == null:
		return
	var curve_cells: Array[Vector2i] = [
		Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2),
		Vector2i(5, 3), Vector2i(5, 4),
	]
	var centers: Array[Vector2] = []
	for cell in curve_cells:
		centers.append(fixture.field.grid_cell_center(cell))
	fixture.drag_through_logical_centers(centers)
	var input_frame = fixture.view.consume_input_frame()
	fixture.controller.advance_tick(input_frame)
	var running_snapshot = fixture.controller.get_snapshot()
	_assert_equal(
		running_snapshot.get_state(),
		SessionControllerScript.State.RUNNING,
		"Live curve fixture enters RUNNING"
	)
	_assert_true(running_snapshot.is_train_active(), "Live curve fixture publishes an active train")
	_assert_true(
		running_snapshot.is_endpoint_gesture_eligible(),
		"Live curve fixture keeps its locked endpoint extendable"
	)
	var endpoint := curve_cells[-1]
	var endpoint_motion := InputEventMouseMotion.new()
	endpoint_motion.position = fixture._logical_to_local(fixture.field.grid_cell_center(endpoint))
	fixture.view.call("_gui_input", endpoint_motion)
	_assert_equal(
		fixture.view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)),
		endpoint,
		"RUNNING curve endpoint is green before later snapshots"
	)
	for tick in range(8):
		fixture.controller.advance_tick(TrackInputFrameScript.empty())
		var snapshot = fixture.controller.get_snapshot()
		_assert_true(snapshot.is_train_active(), "Train remains active on hover tick %d" % tick)
		_assert_true(snapshot.is_endpoint_gesture_eligible(), "Endpoint remains eligible on hover tick %d" % tick)
		_assert_equal(
			fixture.view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)),
			endpoint,
			"Live snapshot refresh preserves endpoint hover on tick %d" % tick
		)
	fixture.controller.snapshot_published.disconnect(fixture.snapshot_observer)
	fixture.app.session_result_presented.disconnect(fixture.result_observer)
	fixture.app.session_result_presented.disconnect(fixture.event_result_observer)
	fixture.app.queue_free()
	await process_frame


func _verify_nondefault_copy_contract() -> void:
	var packed = load(NONDEFAULT_SCENE_PATH) as PackedScene
	_assert_true(packed != null, "Nondefault app scene loads")
	if packed == null:
		return
	var app = packed.instantiate()
	var field = app.get_node("SessionShell").get_track_field_view().get_logical_track_field()
	var errors: PackedStringArray = app.compose_session_dependencies()
	_assert_equal(errors, PackedStringArray(), "Nondefault composition succeeds")
	_assert_equal(app.session_start_config.train_speed_cells_per_second, app.balance.train_balance.speed_cells_per_second, "Cell speed copied")
	_assert_equal(app.session_start_config.total_track_cells, app.balance.track_inventory_balance.total_track_cells, "Cell inventory copied")
	_assert_equal(app.session_start_config.recovery_lag_cells, app.balance.track_inventory_balance.recovery_lag_cells, "Recovery lag copied")
	_assert_equal(app.session_start_config.build_cells_per_second, app.balance.track_construction_balance.build_cells_per_second, "Build rate copied")
	_assert_equal(app.session_start_config.departure_required_built_cells, app.balance.departure_balance.required_built_cells, "Departure cells copied")
	_assert_equal(app.session_start_config.grid_origin_units, field.get_grid_rect().position, "Centered origin copied")
	app.free()


func _verify_startup_validation() -> void:
	var packed = load(INVALID_SCENE_PATH) as PackedScene
	_assert_true(packed != null, "Invalid app scene loads")
	if packed == null:
		return
	var app = packed.instantiate()
	var errors: PackedStringArray = app.compose_session_dependencies()
	_assert_true(not errors.is_empty(), "Invalid startup reports errors")
	_assert_true(app.session_controller == null, "Invalid startup creates no domain controller")
	app.free()


func _verify_deterministic_composition() -> void:
	var packed = load(APP_SCENE_PATH) as PackedScene
	var first = packed.instantiate()
	var second = packed.instantiate()
	_duplicate_runtime_resources(first)
	_duplicate_runtime_resources(second)
	first.startup_seed = 77
	second.startup_seed = 77
	_assert_equal(first.compose_session_dependencies(), PackedStringArray(), "First replay composes")
	_assert_equal(second.compose_session_dependencies(), PackedStringArray(), "Second replay composes")
	_assert_equal(first.session_start_config.departure_candidate_id, second.session_start_config.departure_candidate_id, "Seeded candidate deterministic")
	_assert_equal(first.session_start_config.departure_cell, second.session_start_config.departure_cell, "Seeded departure cell deterministic")
	first.free()
	second.free()


func _run_reconfiguration_probe() -> void:
	var fixture = await compose_preset_fixture(LogicalTrackFieldScript.SizePreset.COMPACT, Vector2i(0, 0))
	if fixture != null:
		var before: Dictionary = fixture.view.get_render_observation()
		var rejected_config := SessionStartConfigScript.new(
			1, 20.0, 60,
			1.0, 10, 2, 2.0, 1.0, 1,
			Vector2(901.0, 420.0), Vector2i(2, 2), 40.0, Vector2(100.0, 80.0),
			&"rejected_departure", Vector2(120.0, 100.0), Vector2i(1, 1)
		)
		fixture.view.configure_session(rejected_config)
		var after: Dictionary = fixture.view.get_render_observation()
		_assert_equal(after.grid_rect, before.grid_rect, "Rejected reconfiguration preserves the active grid rectangle")
		_assert_equal(after.selected_departure_id, before.selected_departure_id, "Rejected reconfiguration preserves the active departure identity")
		_assert_equal(after.selected_departure_position, before.selected_departure_position, "Rejected reconfiguration preserves the active departure position")
		_assert_equal(after.valid_start_cell, before.valid_start_cell, "Rejected reconfiguration preserves the active valid-start cell")
		_assert_equal(after.valid_start_rect, before.valid_start_rect, "Rejected reconfiguration preserves the active valid-start rectangle")
		fixture.controller.snapshot_published.disconnect(fixture.snapshot_observer)
		fixture.app.session_result_presented.disconnect(fixture.result_observer)
		fixture.app.session_result_presented.disconnect(fixture.event_result_observer)
		fixture.app.queue_free()
		await process_frame
	if _failures.is_empty():
		print("PASS: track field reconfiguration probe")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("FAIL: %d track field reconfiguration probe assertion(s)" % _failures.size())
	quit(1)


func _run() -> void:
	await assert_centered_preset_end_to_end(LogicalTrackFieldScript.SizePreset.COMPACT, Vector2(10.0, 10.0))
	await assert_centered_preset_end_to_end(LogicalTrackFieldScript.SizePreset.EXPANSIVE, Vector2(30.0, 30.0))
	await assert_running_curve_endpoint_hover_survives_live_snapshots()
	_verify_nondefault_copy_contract()
	_verify_startup_validation()
	_verify_deterministic_composition()
	if _failures.is_empty():
		print("PASS: track train app integration")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("FAIL: %d track train app integration assertion(s)" % _failures.size())
	quit(1)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, expected, actual])
