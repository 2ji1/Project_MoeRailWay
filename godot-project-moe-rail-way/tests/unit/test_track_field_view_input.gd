extends "res://tests/support/prototype_test.gd"

const FIELD_SCENE_PATH := "res://src/presentation/track/logical_track_field.tscn"
const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
const TrackFieldViewScript = preload("res://src/presentation/track/track_field_view.gd")


func _fixture(offset := Vector2.ZERO, view_size := Vector2(1000.0, 700.0)) -> Dictionary:
    var parent := Control.new()
    parent.position = offset
    Engine.get_main_loop().root.add_child(parent)
    var view = TrackFieldViewScript.new()
    view.size = view_size
    parent.add_child(view)
    var packed = load(FIELD_SCENE_PATH) as PackedScene
    view.add_child(packed.instantiate())
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


func _deliver(view, event: InputEvent) -> void:
    view.call("_gui_input", event)


func _consume(view):
    return view.call("consume_input_frame")


func _assert_vector_close(actual: Vector2, expected: Vector2, message: String) -> void:
    assert_true(
        actual.is_equal_approx(expected),
        "%s | expected=%s actual=%s" % [message, expected, actual]
    )


func _test_left_edges_and_latest_motion() -> void:
    var fixture := _fixture()
    var view = fixture["view"]
    var content: Rect2 = view.get_logical_content_rect()
    var press_local := content.get_center()
    var motion_one := content.position + content.size * Vector2(0.75, 0.25)
    var motion_two := Vector2(-100.0, content.get_center().y)

    _deliver(view, _button(press_local, MOUSE_BUTTON_LEFT, true))
    _deliver(view, _motion(motion_one))
    _deliver(view, _motion(motion_two))
    var first = _consume(view)
    assert_true(first.left_pressed, "Left press edge must appear once")
    assert_true(first.left_held, "Left press must establish held state")
    assert_false(first.left_released, "Press tick must not report release")
    assert_true(first.left_press_inside_field, "Content press must be inside")
    _assert_vector_close(
        first.left_press_position,
        Vector2(600.0, 280.0),
        "Later motion must not overwrite the left press position"
    )
    assert_false(first.cursor_inside_field, "Latest outside motion must be outside")
    assert_true(first.cursor_position.x < 0.0, "Captured motion must remain unclamped")

    var held = _consume(view)
    assert_false(held.left_pressed, "Consumed left edge must disappear")
    assert_true(held.left_held, "Held state must appear once per later physics tick")
    assert_false(held.left_released, "Held tick must not invent release")
    _assert_vector_close(
        held.cursor_position,
        first.cursor_position,
        "A consume without motion must retain only the latest cursor sample"
    )

    _deliver(view, _button(motion_two, MOUSE_BUTTON_LEFT, false))
    var released = _consume(view)
    assert_true(released.left_released, "Release edge must appear once")
    assert_false(released.left_held, "Release must clear held state")
    var after_release = _consume(view)
    assert_false(after_release.left_released, "Consumed release edge must disappear")
    assert_false(after_release.left_held, "Released state must remain clear")
    fixture["parent"].free()


func _test_right_edge_and_invalid_capture() -> void:
    var fixture := _fixture()
    var view = fixture["view"]
    var content: Rect2 = view.get_logical_content_rect()
    var right_local := content.position + content.size * Vector2(0.25, 0.75)
    var outside_local := Vector2(content.get_center().x, 50.0)

    _deliver(view, _button(right_local, MOUSE_BUTTON_RIGHT, true))
    _deliver(view, _motion(outside_local))
    var right = _consume(view)
    assert_true(right.right_pressed, "Right press edge must appear once")
    assert_false(right.left_pressed, "Right press must never alias left draw")
    assert_true(right.right_press_inside_field, "Right content press must be inside")
    _assert_vector_close(
        right.right_press_position,
        Vector2(300.0, 420.0),
        "Later motion must not overwrite the right press position"
    )
    assert_false(right.cursor_inside_field, "Latest letterbox motion must be outside")
    _assert_vector_close(
        right.cursor_position,
        Vector2.ZERO,
        "Uncaptured outside cursor must not use unclamped logical conversion"
    )
    assert_false(_consume(view).right_pressed, "Consumed right edge must disappear")

    _deliver(view, _button(outside_local, MOUSE_BUTTON_LEFT, true))
    var invalid_press = _consume(view)
    assert_true(invalid_press.left_pressed, "Letterbox press edge remains explicit")
    assert_false(
        invalid_press.left_press_inside_field,
        "Letterbox press must not begin logical capture"
    )
    _assert_vector_close(
        invalid_press.left_press_position,
        Vector2.ZERO,
        "Invalid outside press must not expose unclamped logical coordinates"
    )
    _deliver(view, _motion(content.get_center()))
    var later_inside = _consume(view)
    assert_true(later_inside.cursor_inside_field, "Latest cursor may later enter content")
    assert_false(later_inside.left_pressed, "Later motion must not recreate the invalid press")
    _deliver(view, _button(content.get_center(), MOUSE_BUTTON_LEFT, false))
    _consume(view)
    fixture["parent"].free()


func _test_resize_preserves_logical_value() -> void:
    var fixture := _fixture()
    var view = fixture["view"]
    var normalized := Vector2(0.25, 0.75)
    var content: Rect2 = view.get_logical_content_rect()
    _deliver(view, _motion(content.position + content.size * normalized))
    var before = _consume(view)

    view.size = Vector2(1400.0, 700.0)
    var resized: Rect2 = view.get_logical_content_rect()
    _deliver(view, _motion(resized.position + resized.size * normalized))
    var after = _consume(view)
    _assert_vector_close(before.cursor_position, Vector2(300.0, 420.0), "Pre-resize mapping")
    _assert_vector_close(after.cursor_position, before.cursor_position, "Resize changes only scale")
    fixture["parent"].free()


func _test_nonzero_viewport_offset_uses_local_event_position() -> void:
    var packed = load(SHELL_SCENE_PATH) as PackedScene
    var shell = packed.instantiate()
    shell.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    shell.size = Vector2(1000.0, 700.0)
    shell.position = Vector2(137.0, 83.0)
    Engine.get_main_loop().root.add_child(shell)
    var view = shell.get_track_field_view()
    view.size = Vector2(1000.0, 700.0)
    var local_center: Vector2 = view.get_logical_content_rect().get_center()
    _deliver(view, _button(local_center, MOUSE_BUTTON_LEFT, true))
    var frame = shell.consume_track_input_frame()
    _assert_vector_close(
        shell.global_position,
        Vector2(137.0, 83.0),
        "SessionShell must retain its nonzero viewport offset"
    )
    _assert_vector_close(
        frame.left_press_position,
        Vector2(600.0, 280.0),
        "Control-local event position must pass through the canvas/global transform"
    )
    assert_true(frame.left_press_inside_field, "Offset content press must remain inside")
    shell.free()


func run() -> PackedStringArray:
    var guard_fixture := _fixture()
    var guard_view = guard_fixture["view"]
    if not guard_view.has_method("consume_input_frame"):
        assert_true(false, "TrackFieldView must expose consume_input_frame")
        guard_fixture["parent"].free()
        return finish()
    guard_fixture["parent"].free()

    _test_left_edges_and_latest_motion()
    _test_right_edge_and_invalid_capture()
    _test_resize_preserves_logical_value()
    _test_nonzero_viewport_offset_uses_local_event_position()
    return finish()
