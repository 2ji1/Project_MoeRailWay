extends "res://tests/support/prototype_test.gd"

const FIELD_SCENE_PATH := "res://src/presentation/track/logical_track_field.tscn"
const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackFieldViewScript = preload("res://src/presentation/track/track_field_view.gd")


func run() -> PackedStringArray:
	_test_horizontal_and_l_shaped_physical_events()
	_test_corner_order_and_consume_once()
	_test_outside_and_right_cell_mapping()
	_test_resize_and_nonzero_canvas_offset_preserve_cells()
	_test_grid_observation_matches_authoritative_field()
	_test_valid_start_observation_tracks_endpoint_and_completion()
	return finish()


func _config() -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		1, 20.0, 60,
		1.0, 10, 2, 2.0, 1.0, 1,
		Vector2(1200.0, 560.0), Vector2i(30, 14), 40.0, Vector2.ZERO,
		&"view_departure", Vector2(20.0, 20.0), Vector2i(0, 0)
	)


func _fixture(offset: Vector2 = Vector2.ZERO, view_size: Vector2 = Vector2(1000.0, 700.0)) -> Dictionary:
	var parent := Control.new()
	parent.position = offset
	Engine.get_main_loop().root.add_child(parent)
	var view = TrackFieldViewScript.new()
	view.size = view_size
	parent.add_child(view)
	var packed = load(FIELD_SCENE_PATH) as PackedScene
	view.add_child(packed.instantiate())
	view.configure_session(_config())
	view.get_logical_content_rect()
	return {"parent": parent, "view": view}


func _button(position: Vector2, button_index: int, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = button_index
	event.pressed = pressed
	return event


func _motion(position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	return event


func _local_for_logical(view, logical: Vector2) -> Vector2:
	var content: Rect2 = view.get_logical_content_rect()
	return content.position + logical / Vector2(1200.0, 560.0) * content.size


func _deliver(view, event: InputEvent) -> void:
	view.call("_gui_input", event)


func _test_horizontal_and_l_shaped_physical_events() -> void:
	var fixture := _fixture()
	var view = fixture.view
	var start := _local_for_logical(view, Vector2(20.0, 20.0))
	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(140.0, 20.0))))
	var horizontal = view.consume_input_frame()
	assert_equal(
		horizontal.crossed_cells,
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
		"One fast event preserves all three horizontal cells"
	)
	_deliver(view, _button(_local_for_logical(view, Vector2(140.0, 20.0)), MOUSE_BUTTON_LEFT, false))
	view.consume_input_frame()

	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 20.0))))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 100.0))))
	var l_shape = view.consume_input_frame()
	assert_equal(
		l_shape.crossed_cells,
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)],
		"Two real events preserve an L without a diagonal shortcut"
	)
	fixture.parent.free()


func _test_corner_order_and_consume_once() -> void:
	var fixture := _fixture()
	var view = fixture.view
	var start := _local_for_logical(view, Vector2(20.0, 20.0))
	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(140.0, 60.0))))
	var dominant = view.consume_input_frame()
	assert_equal(
		dominant.crossed_cells,
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(3, 1)],
		"Horizontal-dominant exact corner is ordered"
	)
	var consumed = view.consume_input_frame()
	assert_equal(consumed.crossed_cells, [], "Cell buffer clears exactly once per consume")
	assert_true(consumed.left_held, "Held state persists after the buffer clears")
	_deliver(view, _button(_local_for_logical(view, Vector2(140.0, 60.0)), MOUSE_BUTTON_LEFT, false))
	view.consume_input_frame()
	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 100.0))))
	assert_equal(
		view.consume_input_frame().crossed_cells,
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		"Equal-axis corner is horizontal first"
	)
	fixture.parent.free()


func _test_outside_and_right_cell_mapping() -> void:
	var fixture := _fixture()
	var view = fixture.view
	var content: Rect2 = view.get_logical_content_rect()
	var letterbox := Vector2(content.get_center().x, content.position.y * 0.5)
	_deliver(view, _button(letterbox, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(letterbox + Vector2(50.0, 0.0)))
	var outside = view.consume_input_frame()
	assert_false(outside.left_press_inside_grid, "Letterbox press is outside the grid")
	assert_equal(outside.crossed_cells, [], "Letterbox events emit no cells")
	_deliver(view, _button(letterbox, MOUSE_BUTTON_LEFT, false))
	view.consume_input_frame()
	var right_position := _local_for_logical(view, Vector2(100.0, 60.0))
	_deliver(view, _button(right_position, MOUSE_BUTTON_RIGHT, true))
	var right = view.consume_input_frame()
	assert_true(right.right_pressed, "Right edge appears once")
	assert_true(right.right_press_inside_grid, "Right center is inside the grid")
	assert_equal(right.right_press_cell, Vector2i(2, 1), "Right press resolves one exact cell")
	assert_false(view.consume_input_frame().right_pressed, "Right edge clears after consume")
	fixture.parent.free()


func _test_resize_and_nonzero_canvas_offset_preserve_cells() -> void:
	var fixture := _fixture(Vector2(137.0, 83.0))
	var view = fixture.view
	var start := _local_for_logical(view, Vector2(20.0, 20.0))
	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 20.0))))
	var before: Array[Vector2i] = view.consume_input_frame().crossed_cells
	_deliver(view, _button(_local_for_logical(view, Vector2(100.0, 20.0)), MOUSE_BUTTON_LEFT, false))
	view.consume_input_frame()
	view.size = Vector2(1400.0, 700.0)
	start = _local_for_logical(view, Vector2(20.0, 20.0))
	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 20.0))))
	assert_equal(view.consume_input_frame().crossed_cells, before, "Resize changes scale, not grid cells")
	assert_equal(fixture.parent.position, Vector2(137.0, 83.0), "Nonzero canvas offset is preserved")
	fixture.parent.free()


func _test_grid_observation_matches_authoritative_field() -> void:
	var fixture := _fixture()
	var observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(
		observation.grid_rect,
		Rect2(Vector2.ZERO, Vector2(1200.0, 560.0)),
		"Grid observation preserves the configured authoritative field rectangle"
	)
	assert_equal(
		fixture.view.grid_line_color,
		Color(0.5, 0.5, 0.5, 1.0),
		"Grid lines default to opaque fifty-percent gray"
	)
	fixture.view.grid_line_color = Color(0.25, 0.75, 1.0, 0.2)
	assert_equal(
		fixture.view.grid_line_color,
		Color(0.25, 0.75, 1.0, 1.0),
		"Grid lines remain opaque after programmatic color assignment"
	)
	fixture.parent.free()


func _test_valid_start_observation_tracks_endpoint_and_completion() -> void:
	var fixture := _fixture()
	var first_record := TrackCellRecordScript.new(0, Vector2i(1, 0))
	var last_record := TrackCellRecordScript.new(1, Vector2i(1, 1))
	fixture.view.present(SessionSnapshotScript.new(
		1, 0, 1, 60, true, SessionControllerScript.State.PREPARING_DEPARTURE,
		[first_record, last_record]
	))
	assert_equal(
		fixture.view.call("_get_valid_start_cell"),
		Vector2i(1, 1),
		"Valid-start highlight follows the last ordered active route cell"
	)
	fixture.view.present(SessionSnapshotScript.new(
		1, 1, 0, 60, true, SessionControllerScript.State.COMPLETED,
		[first_record, last_record]
	))
	assert_equal(
		fixture.view.call("_get_valid_start_cell"),
		Vector2i(-1, -1),
		"Completed sessions hide the valid-start highlight"
	)
	fixture.parent.free()
