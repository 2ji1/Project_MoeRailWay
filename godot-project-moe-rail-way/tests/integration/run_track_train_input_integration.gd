extends SceneTree

const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _config() -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		123, 120.0, 60,
		1.0, 10, 2, 3.0, 1.0, 1,
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


func _release(shell, track, position: Vector2) -> void:
	await _deliver(_button(position, MOUSE_BUTTON_LEFT, false))
	await _consume(shell, track)


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
