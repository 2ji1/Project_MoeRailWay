extends SceneTree

const APP_SCENE_PATH := "res://src/app/prototype_app.tscn"
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
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
	call_deferred("_run")


func compose_preset_fixture(preset: int, departure_cell: Vector2i):
	var packed = load(APP_SCENE_PATH) as PackedScene
	_assert_true(packed != null, "Prototype app scene loads")
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
	root.add_child(app)
	await process_frame
	app.set_physics_process(false)
	var fixture := PresetFixture.new()
	fixture.app = app
	fixture.field = field
	fixture.view = view
	fixture.controller = app.session_controller
	fixture.latest_snapshot = app.session_controller.get_snapshot()
	fixture.authored_candidate = selected_candidate
	fixture.authored_position = authored_position
	return fixture


func assert_centered_preset_end_to_end(preset: int, expected_origin: Vector2) -> void:
	var fixture = await compose_preset_fixture(preset, Vector2i(0, 0))
	if fixture == null:
		return
	var field = fixture.field
	var target_cell := Vector2i(1, 0)
	var target_center: Vector2 = field.grid_cell_center(target_cell)
	_assert_equal(fixture.app.session_start_config.grid_origin_units, expected_origin, "Config origin")
	_assert_equal(fixture.app.session_start_config.departure_cell, Vector2i(0, 0), "Departure cell")
	_assert_equal(fixture.authored_candidate.position, fixture.authored_position, "Composition does not mutate source node")
	var centers: Array[Vector2] = [target_center]
	fixture.drag_through_logical_centers(centers)
	var input_frame = fixture.view.consume_input_frame()
	_assert_equal(input_frame.crossed_cells, [target_cell], "Rasterized cell")
	fixture.advance_with_input_until_train_distance(input_frame, 1.0)
	var snapshot = fixture.latest_snapshot
	var observation: Dictionary = fixture.view.get_render_observation()
	_assert_equal(snapshot.get_grid_origin_units(), expected_origin, "Snapshot origin")
	_assert_equal(
		snapshot.get_geometry_pieces()[0].sample_nominal(1.0).position,
		target_center,
		"Runtime centerline"
	)
	_assert_equal(
		observation.pieces[0].sample_nominal(1.0).position,
		target_center,
		"Rendered centerline"
	)
	_assert_equal(snapshot.get_train_position(), target_center, "Train position")
	fixture.app.queue_free()
	await process_frame


func _run() -> void:
	await assert_centered_preset_end_to_end(
		LogicalTrackFieldScript.SizePreset.COMPACT,
		Vector2(10.0, 10.0)
	)
	await assert_centered_preset_end_to_end(
		LogicalTrackFieldScript.SizePreset.EXPANSIVE,
		Vector2(30.0, 30.0)
	)
	if _failures.is_empty():
		print("PASS: logical track field integration")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("FAIL: %d logical track field integration assertion(s)" % _failures.size())
	quit(1)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, expected, actual])
