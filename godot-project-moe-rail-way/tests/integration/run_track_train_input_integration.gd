extends SceneTree

const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")
const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _config() -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		123, 120.0, 60,
		1.0, 10, 2, 3.0, 60.0, 1,
		Vector2(800.0, 400.0), Vector2i(20, 10), 40.0, Vector2.ZERO,
		&"departure_01", Vector2(100.0, 100.0), Vector2i(2, 2)
	)


func _logical_to_viewport(view, logical: Vector2) -> Vector2:
	var content: Rect2 = view.get_logical_content_rect()
	var local := content.position + logical / Vector2(800.0, 400.0) * content.size
	return view.get_global_transform_with_canvas() * local


func _button(position: Vector2, button: int, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = button
	event.pressed = pressed
	if pressed and button == MOUSE_BUTTON_LEFT:
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
	elif pressed and button == MOUSE_BUTTON_RIGHT:
		event.button_mask = MOUSE_BUTTON_MASK_RIGHT
	return event


func _motion(position: Vector2, button_mask: int = 0) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.button_mask = button_mask
	return event


func _deliver(event: InputEvent) -> void:
	root.push_input(event, true)
	await process_frame


func _consume(shell, track):
	await physics_frame
	var frame = shell.consume_track_input_frame()
	var right_won: bool = track.apply_right_input(frame)
	if not right_won:
		track.apply_left_input(frame)
	return frame


func _consume_view(shell, track = null):
	await physics_frame
	var frame = shell.consume_track_input_frame()
	if track != null:
		var right_won: bool = track.apply_right_input(frame)
		if not right_won:
			track.apply_left_input(frame)
	return frame


func _release_view(shell, position: Vector2) -> void:
	await _deliver(_button(position, MOUSE_BUTTON_LEFT, false))


func _release(shell, track, position: Vector2) -> void:
	await _deliver(_button(position, MOUSE_BUTTON_LEFT, false))
	await _consume(shell, track)


func _track_snapshot(track, state: int = SessionControllerScript.State.PREPARING_DEPARTURE) -> SessionSnapshotScript:
	return SessionSnapshotScript.new(
		1, 0, 1, 60, true, state, track.get_cell_records(), track.get_geometry_pieces(),
		track.get_contact_observations(), track.get_built_end_distance_cells(),
		track.get_available_track_cells(), track.get_total_track_cells(), track.get_grid_origin_units(),
		0, 2, 0.0, false, 0.0, Vector2.ZERO, Vector2.RIGHT, 0.0, false,
		&"integration", Vector2i(2, 2), track.is_endpoint_gesture_eligible(),
		track.is_runtime_gesture_active()
	)


func _run() -> void:
	var packed = load(SHELL_SCENE_PATH) as PackedScene
	_assert_true(packed != null, "Session shell scene loads")
	if packed == null:
		await _finish(null)
		return
	var shell = packed.instantiate()
	root.add_child(shell)
	await process_frame
	var config := _config()
	shell.get_track_field_view().get_logical_track_field().size_preset = 3
	shell.get_track_field_view().get_logical_track_field().custom_width = 800.0
	shell.get_track_field_view().get_logical_track_field().custom_height = 400.0
	shell.get_track_field_view().get_logical_track_field().custom_grid_columns = 20
	shell.get_track_field_view().get_logical_track_field().custom_grid_rows = 10
	shell.configure(UILayoutProfileScript.new(), SessionSnapshotScript.new(10800, 0, 10800, 60), config)
	await process_frame
	await process_frame
	var view = shell.get_track_field_view()
	var departure := _logical_to_viewport(view, Vector2(100.0, 100.0))

	var running_track := TrackSystemScript.new(config)
	var running_train := TrainSystemScript.new(config.train_speed_cells_per_second)
	var running_controller := SessionControllerScript.new(config, running_track, running_train)
	running_controller.start()
	view.present(running_controller.get_snapshot())
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var running_frame = await _consume_view(shell)
	running_controller.advance_tick(running_frame)
	await _release_view(shell, _logical_to_viewport(view, Vector2(220.0, 100.0)))
	var running_release = await _consume_view(shell)
	running_controller.advance_tick(running_release)
	for _tick in range(100):
		running_controller.advance_tick()
	var running_snapshot: SessionSnapshotScript = running_controller.get_snapshot()
	view.present(running_snapshot)
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0))))
	var endpoint_observation: Dictionary = view.get_render_observation()
	var running_green: bool = running_snapshot.get_state() == SessionControllerScript.State.RUNNING \
		and running_snapshot.is_train_active() \
		and endpoint_observation.get("hover_extend_cell", Vector2i(-1, -1)) == Vector2i(5, 2)
	_assert_true(running_green, "Endpoint reshape integration assertion failed endpoint green")
	if running_green:
		print("PASS: Endpoint reshape integration running endpoint green")

	var overlap_track := TrackSystemScript.new(config)
	var overlap_frame := TrackInputFrameScript.new(
		[Vector2i(3, 2)], Vector2i(2, 2), true, Vector2i(-1, -1), false,
		true, false, true, false, Vector2i(3, 2), true
	)
	overlap_track.apply_left_input(overlap_frame)
	var overlap_snapshot: SessionSnapshotScript = _track_snapshot(overlap_track)
	view.present(overlap_snapshot)
	await _deliver(_motion(_logical_to_viewport(view, Vector2(140.0, 100.0))))
	var overlap_observation: Dictionary = view.get_render_observation()
	var overlap_green: bool = overlap_observation.get("hover_extend_cell", Vector2i(-1, -1)) == Vector2i(3, 2) \
		and overlap_observation.get("hover_cancel_cell", Vector2i(-1, -1)) == Vector2i(3, 2)
	_assert_true(overlap_green, "Endpoint reshape integration assertion failed overlap endpoint green")
	if overlap_green:
		print("PASS: Endpoint reshape integration overlap endpoint green")
	await _deliver(_button(_logical_to_viewport(view, Vector2(140.0, 100.0)), MOUSE_BUTTON_RIGHT, true))
	var overlap_right: TrackInputFrameScript = await _consume_view(shell, overlap_track)
	var overlap_cancelled: bool = overlap_right.right_pressed and overlap_track.get_cell_records().is_empty()
	_assert_true(overlap_cancelled, "Overlap endpoint retains real right-click cancellation")

	var abort_track := TrackSystemScript.new(config)
	var abort_controller := SessionControllerScript.new(config, abort_track, TrainSystemScript.new(config.train_speed_cells_per_second))
	abort_controller.start()
	view.present(abort_controller.get_snapshot())
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var abort_seed = await _consume_view(shell)
	abort_controller.advance_tick(abort_seed)
	await _release_view(shell, _logical_to_viewport(view, Vector2(220.0, 100.0)))
	var abort_seed_release = await _consume_view(shell)
	abort_controller.advance_tick(abort_seed_release)
	for _tick in range(20):
		abort_controller.advance_tick()
	view.present(abort_controller.get_snapshot())
	await _deliver(_button(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(260.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var abort_origin_endpoint := abort_track.get_endpoint_cell()
	var abort_frame = await _consume_view(shell)
	abort_track.apply_left_input(abort_frame)
	var abort_active_before: bool = abort_track.is_runtime_gesture_active()
	view.present(_track_snapshot(abort_track, abort_controller.get_state()))
	await _deliver(_button(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_RIGHT, true))
	var abort_right: TrackInputFrameScript = await _consume_view(shell)
	abort_track.apply_right_input(abort_right)
	var abort_snapshot: SessionSnapshotScript = abort_controller.get_snapshot()
	view.present(_track_snapshot(abort_track, abort_controller.get_state()))
	var abort_cleared: bool = abort_active_before and not abort_track.is_runtime_gesture_active() \
		and abort_track.get_endpoint_cell() == abort_origin_endpoint and not view._left_capture_active \
		and view._crossed_cells.is_empty()
	_assert_true(abort_cleared, "Endpoint reshape integration assertion failed abort clears capture")
	if abort_cleared:
		print("PASS: Endpoint reshape integration abort clears capture")
	await _release_view(shell, departure)
	await _consume_view(shell)

	var prep_track := TrackSystemScript.new(config)
	var prep_controller := SessionControllerScript.new(config, prep_track, TrainSystemScript.new(config.train_speed_cells_per_second))
	prep_controller.start()
	view.present(prep_controller.get_snapshot())
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var prep_seed = await _consume_view(shell)
	prep_controller.advance_tick(prep_seed)
	await _release_view(shell, _logical_to_viewport(view, Vector2(220.0, 100.0)))
	var prep_seed_release = await _consume_view(shell)
	prep_controller.advance_tick(prep_seed_release)
	for _tick in range(20):
		prep_controller.advance_tick()
	view.present(prep_controller.get_snapshot())
	await _deliver(_button(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(260.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var prep_frame = await _consume_view(shell)
	prep_track.apply_left_input(prep_frame)
	view.present(_track_snapshot(prep_track, prep_controller.get_state()))
	var prep_active_before: bool = prep_track.is_runtime_gesture_active()
	var prep_endpoint_before := prep_track.get_endpoint_cell()
	var prep_result: bool = prep_track.prepare_for_train_sampling(2.0, 4.0)
	var prep_inactive: bool = prep_active_before and prep_result and not prep_track.is_runtime_gesture_active()
	view.present(_track_snapshot(prep_track))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(180.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var frozen_frame: TrackInputFrameScript = await _consume_view(shell, prep_track)
	var train_frozen: bool = prep_inactive and prep_track.get_endpoint_cell() == prep_endpoint_before \
		and frozen_frame.crossed_cells.is_empty() and not view._left_capture_active
	_assert_true(train_frozen, "Endpoint reshape integration assertion failed train preparation freezes overlap")
	if train_frozen:
		print("PASS: Endpoint reshape integration train preparation freezes overlap")
	await _release_view(shell, _logical_to_viewport(view, Vector2(180.0, 100.0)))
	await _consume_view(shell)

	var horizontal_track = TrackSystemScript.new(config)
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var horizontal = await _consume(shell, horizontal_track)
	_assert_equal(horizontal.crossed_cells, [Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)], "Three horizontal cells")
	_assert_equal(horizontal_track.get_endpoint_cell(), Vector2i(5, 2), "Facade consumes horizontal order")
	await _release(shell, horizontal_track, _logical_to_viewport(view, Vector2(220.0, 100.0)))

	var l_track = TrackSystemScript.new(config)
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(180.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(180.0, 180.0)), MOUSE_BUTTON_MASK_LEFT))
	var l_frame = await _consume(shell, l_track)
	_assert_equal(
		l_frame.crossed_cells,
		[Vector2i(3, 2), Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4)],
		"Physical L events never shortcut diagonally"
	)
	await _release(shell, l_track, _logical_to_viewport(view, Vector2(180.0, 180.0)))

	var corner_track = TrackSystemScript.new(config)
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 140.0)), MOUSE_BUTTON_MASK_LEFT))
	var corner = await _consume(shell, corner_track)
	_assert_equal(
		corner.crossed_cells,
		[Vector2i(3, 2), Vector2i(4, 2), Vector2i(4, 3), Vector2i(5, 3)],
		"Fast corner uses dominant-axis ordering"
	)
	await _release(shell, corner_track, _logical_to_viewport(view, Vector2(220.0, 140.0)))

	var reflow_track = TrackSystemScript.new(config)
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	await _consume(shell, reflow_track)
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 180.0)), MOUSE_BUTTON_MASK_LEFT))
	var reflow_frame = await _consume(shell, reflow_track)
	_assert_equal(reflow_frame.crossed_cells, [Vector2i(5, 3), Vector2i(5, 4)], "Second frame emits only cells not consumed by the first frame")
	await _release(shell, reflow_track, _logical_to_viewport(view, Vector2(220.0, 180.0)))
	_assert_equal(reflow_track.advance_construction(5.0), 5.0, "Head completes without geometry locking")
	_assert_equal(reflow_track.get_geometry_pieces()[0].kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Completed head reflows as curve")
	var support_endpoint := reflow_track.get_endpoint_cell()
	reflow_track.apply_left_input(TrackInputFrameScript.new(
		[], support_endpoint, true, Vector2i(-1, -1), false,
		true, true, false, false, support_endpoint, true
	))
	var support_frame := TrackInputFrameScript.new(
		[support_endpoint, Vector2i(5, 5)], support_endpoint, true, Vector2i(-1, -1), false,
		false, true, false, false, Vector2i(5, 5), true
	)
	reflow_track.apply_left_input(support_frame)
	reflow_track.apply_left_input(TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, false, true, false, Vector2i(5, 5), true
	))
	_assert_equal(support_frame.crossed_cells, [support_endpoint, Vector2i(5, 5)], "Third frame appends G as exit support along F's direction")
	var g_viewport_position := _logical_to_viewport(view, Vector2(220.0, 220.0))
	_assert_true(not reflow_track._left_capture_active, "Releasing G clears left capture before the support right-click")
	var support_count := reflow_track.get_cell_records().size()
	_assert_equal(support_count, 6, "G support was actually appended")
	var support_record = reflow_track.get_cell_records()[-1]
	_assert_equal(support_record.cell, Vector2i(5, 5), "G support record is the active endpoint")
	var support_metadata_present := false
	for piece in reflow_track.get_geometry_pieces():
		if piece.exit_support_route_serial == support_record.route_serial:
			support_metadata_present = true
	_assert_true(support_metadata_present, "G is the active exit-support route serial")
	await _deliver(_button(g_viewport_position, MOUSE_BUTTON_RIGHT, true))
	await _consume(shell, reflow_track)
	_assert_equal(reflow_track.get_cell_records().size(), support_count, "Right-clicking exit support is a no-op")
	_assert_equal(reflow_track.get_endpoint_cell(), Vector2i(5, 5), "Exit support remains endpoint")

	await _deliver(_button(_logical_to_viewport(view, Vector2(180.0, 100.0)), MOUSE_BUTTON_RIGHT, true))
	var canceled = await _consume(shell, horizontal_track)
	_assert_equal(canceled.right_press_cell, Vector2i(4, 2), "Right press resolves one cell")
	_assert_equal(horizontal_track.get_endpoint_cell(), Vector2i(3, 2), "Right click cancels its ghost suffix")

	var before_invalid = horizontal_track.get_cell_records()
	var hud = shell.get_node("OuterMargin/MainColumn/TopHud") as Control
	await _deliver(_button(hud.get_global_rect().get_center(), MOUSE_BUTTON_LEFT, true))
	var hud_frame = await _consume(shell, horizontal_track)
	_assert_equal(hud_frame.crossed_cells, [], "HUD events emit no cells")
	_assert_equal(horizontal_track.get_cell_records().size(), before_invalid.size(), "HUD cannot change domain cells")
	await _deliver(_button(hud.get_global_rect().get_center(), MOUSE_BUTTON_LEFT, false))

	var content: Rect2 = view.get_logical_content_rect()
	var letterbox_local := Vector2(content.get_center().x, content.position.y * 0.5)
	var letterbox: Vector2 = view.get_global_transform_with_canvas() * letterbox_local
	await _deliver(_button(letterbox, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(letterbox + Vector2(40.0, 0.0), MOUSE_BUTTON_MASK_LEFT))
	var outside = await _consume(shell, horizontal_track)
	_assert_true(not outside.left_press_inside_grid, "Letterbox press is outside grid")
	_assert_equal(outside.crossed_cells, [], "Letterbox motion emits no cells")
	await _deliver(_button(letterbox, MOUSE_BUTTON_LEFT, false))
	await _consume(shell, horizontal_track)

	var domain_before_resize = horizontal_track.get_cell_records()
	shell.size = Vector2(1100.0, 650.0)
	await process_frame
	await process_frame
	_assert_equal(horizontal_track.get_cell_records().size(), domain_before_resize.size(), "Resize does not change domain cells")
	await _finish(shell)


func _finish(shell) -> void:
	if shell != null:
		shell.queue_free()
		await process_frame
	if _failures.is_empty():
		print("PASS: track train input integration")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("FAIL: %d track train input assertion(s)" % _failures.size())
	quit(1)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, expected, actual])
