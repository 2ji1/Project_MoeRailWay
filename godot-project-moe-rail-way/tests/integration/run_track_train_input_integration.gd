extends SceneTree

const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
    call_deferred("_run")


func _config() -> SessionStartConfigScript:
    return SessionStartConfigScript.new(
        123, 120.0, 60, 90.0, 1000.0, 30.0, 3.0, 120.0,
        24.0, 16.0, 8.0, 4.0, 32.0, Vector2(800.0, 400.0),
        &"departure_01", Vector2(100.0, 100.0)
    )


func _logical_to_viewport(view, logical_position: Vector2) -> Vector2:
    var content: Rect2 = view.get_logical_content_rect()
    var local_position := (
        content.position + logical_position / Vector2(800.0, 400.0) * content.size
    )
    return view.get_global_transform_with_canvas() * local_position


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


func _motion(
    position: Vector2,
    button_mask: int = 0
) -> InputEventMouseMotion:
    var event := InputEventMouseMotion.new()
    event.position = position
    event.global_position = position
    event.button_mask = button_mask
    return event


func _deliver(event: InputEvent) -> void:
    root.push_input(event, true)
    await process_frame


func _consume_frame(shell):
    await physics_frame
    return shell.consume_track_input_frame()


func _consume(shell, track):
    var frame = await _consume_frame(shell)
    var right_won: bool = track.apply_right_input(frame)
    if not right_won:
        track.apply_left_input(frame)
    return frame


func _run() -> void:
    var packed = load(SHELL_SCENE_PATH) as PackedScene
    _assert_true(packed != null, "Session shell scene must load")
    if packed == null:
        await _finish(null)
        return
    var shell = packed.instantiate()
    root.add_child(shell)
    await process_frame
    if not shell.has_method("consume_track_input_frame"):
        print("RED: SessionShell must expose consume_track_input_frame")
        shell.queue_free()
        quit(1)
        return

    var view = shell.get_track_field_view()
    var logical_field = view.get_logical_track_field()
    logical_field.custom_width = 800.0
    logical_field.custom_height = 400.0
    logical_field.size_preset = logical_field.SizePreset.CUSTOM
    var config := _config()
    shell.configure(
        UILayoutProfileScript.new(),
        SessionSnapshotScript.new(10800, 0, 10800, 60),
        config
    )
    await process_frame
    await process_frame
    var track = TrackSystemScript.new(config)

    var off_endpoint := _logical_to_viewport(view, Vector2(300.0, 200.0))
    await _deliver(_button(off_endpoint, MOUSE_BUTTON_LEFT, true))
    var off_frame = await _consume(shell, track)
    _assert_true(off_frame.left_press_inside_field, "Inside off-endpoint press is mapped")
    _assert_equal(track.get_reserved_end_distance(), 0.0, "Off-endpoint press changes no route")
    await _deliver(_button(off_endpoint, MOUSE_BUTTON_LEFT, false))
    await _consume(shell, track)

    var departure := _logical_to_viewport(view, Vector2(100.0, 100.0))
    var far_motion := _logical_to_viewport(view, Vector2(200.0, 100.0))
    await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
    await _deliver(_motion(far_motion, MOUSE_BUTTON_MASK_LEFT))
    var draw_frame = await _consume(shell, track)
    _assert_vector_close(draw_frame.left_press_position, Vector2(100.0, 100.0), "Motion preserves left press")
    _assert_vector_close(draw_frame.cursor_position, Vector2(200.0, 100.0), "Latest motion sample")
    _assert_close(track.get_reserved_end_distance(), 100.0, "Draw begins at original press")
    await _deliver(_button(far_motion, MOUSE_BUTTON_LEFT, false))
    await _consume(shell, track)

    var cancel_point := _logical_to_viewport(view, Vector2(150.0, 100.0))
    var cancel_motion := _logical_to_viewport(view, Vector2(400.0, 300.0))
    await _deliver(_button(cancel_point, MOUSE_BUTTON_RIGHT, true))
    await _deliver(_motion(cancel_motion, MOUSE_BUTTON_MASK_RIGHT))
    var cancel_frame = await _consume(shell, track)
    _assert_vector_close(cancel_frame.right_press_position, Vector2(150.0, 100.0), "Motion preserves right press")
    _assert_close(track.get_reserved_end_distance(), 50.0, "Right projection cancels once")
    await _deliver(_button(cancel_motion, MOUSE_BUTTON_RIGHT, false))

    var endpoint := _logical_to_viewport(view, Vector2(150.0, 100.0))
    await _deliver(_button(endpoint, MOUSE_BUTTON_LEFT, true))
    await _deliver(_motion(_logical_to_viewport(view, Vector2(200.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
    await _deliver(_motion(_logical_to_viewport(view, Vector2(200.0, 200.0)), MOUSE_BUTTON_MASK_LEFT))
    var drag_frame = await _consume(shell, track)
    _assert_vector_close(drag_frame.cursor_position, Vector2(200.0, 200.0), "Only latest motion is sampled")
    var before_exit := track.get_reserved_end_distance()
    await _deliver(_motion(_logical_to_viewport(view, Vector2(900.0, 200.0)), MOUSE_BUTTON_MASK_LEFT))
    var exit_frame = await _consume(shell, track)
    _assert_true(not exit_frame.cursor_inside_field, "Captured exit reports outside")
    _assert_true(exit_frame.cursor_position.x > 800.0, "Captured exit remains unclamped")
    _assert_true(track.get_reserved_end_distance() > before_exit, "Field exit extends route")
    _assert_close(track.get_reserved_endpoint().x, 800.0, "Domain clips at field edge")
    await _deliver(_button(_logical_to_viewport(view, Vector2(800.0, 200.0)), MOUSE_BUTTON_LEFT, false))
    var release_frame = await _consume(shell, track)
    _assert_true(release_frame.left_released, "Release edge reaches consume")
    _assert_true(not track.is_stroke_active(), "Release stops stroke")

    var suppression_start := track.get_reserved_endpoint()
    var suppression_press_logical := suppression_start + Vector2(-1.0, 0.0)
    await _deliver(_button(_logical_to_viewport(view, suppression_press_logical), MOUSE_BUTTON_LEFT, true))
    await _deliver(_motion(_logical_to_viewport(view, suppression_start + Vector2(-40.0, 40.0)), MOUSE_BUTTON_MASK_LEFT))
    await _consume(shell, track)
    await _deliver(_button(_logical_to_viewport(view, suppression_start + Vector2(-20.0, 20.0)), MOUSE_BUTTON_RIGHT, true))
    var suppression_frame = await _consume(shell, track)
    _assert_true(suppression_frame.left_held, "Right tick observes held left")
    var suppressed_end := track.get_reserved_end_distance()
    await _deliver(_motion(_logical_to_viewport(view, suppression_start + Vector2(-80.0, 80.0)), MOUSE_BUTTON_MASK_LEFT))
    await _consume(shell, track)
    _assert_close(track.get_reserved_end_distance(), suppressed_end, "Held left stays suppressed")
    await _deliver(_button(_logical_to_viewport(view, suppression_press_logical), MOUSE_BUTTON_LEFT, false))
    await _consume(shell, track)
    await _deliver(_motion(_logical_to_viewport(view, suppression_start + Vector2(-100.0, 100.0))))
    await _consume(shell, track)
    _assert_close(track.get_reserved_end_distance(), suppressed_end, "Motion needs fresh press")

    var current_endpoint := track.get_reserved_endpoint()
    await _deliver(_button(_logical_to_viewport(view, current_endpoint), MOUSE_BUTTON_LEFT, true))
    await _deliver(_motion(_logical_to_viewport(view, current_endpoint + Vector2(0.0, 40.0)), MOUSE_BUTTON_MASK_LEFT))
    await _consume(shell, track)
    _assert_true(track.get_reserved_end_distance() > suppressed_end, "Fresh press resumes drawing")
    await _deliver(_button(_logical_to_viewport(view, current_endpoint), MOUSE_BUTTON_LEFT, false))
    await _consume(shell, track)

    var before_invalid := track.get_reserved_end_distance()
    var hud = shell.get_node("OuterMargin/MainColumn/TopHud") as Control
    await _deliver(_button(hud.get_global_rect().get_center(), MOUSE_BUTTON_LEFT, true))
    await _consume(shell, track)
    _assert_close(track.get_reserved_end_distance(), before_invalid, "HUD click cannot draw")
    await _deliver(_button(hud.get_global_rect().get_center(), MOUSE_BUTTON_LEFT, false))

    var content: Rect2 = view.get_logical_content_rect()
    var letterbox_local := Vector2(content.get_center().x, content.position.y * 0.5)
    if content.position.y <= 0.0:
        letterbox_local = Vector2(content.position.x * 0.5, content.get_center().y)
    var letterbox_viewport: Vector2 = (
        view.get_global_transform_with_canvas() * letterbox_local
    )
    await _deliver(_button(letterbox_viewport, MOUSE_BUTTON_LEFT, true))
    var letterbox_frame = await _consume(shell, track)
    _assert_true(not letterbox_frame.left_press_inside_field, "Letterbox cannot start capture")
    _assert_close(track.get_reserved_end_distance(), before_invalid, "Letterbox cannot draw")
    await _deliver(_button(letterbox_viewport, MOUSE_BUTTON_LEFT, false))
    await _consume(shell, track)

    var normalized_logical := Vector2(400.0, 200.0)
    await _deliver(_motion(_logical_to_viewport(view, normalized_logical)))
    var before_resize = await _consume_frame(shell)
    shell.size = Vector2(1100.0, 650.0)
    await process_frame
    await process_frame
    await _deliver(_motion(_logical_to_viewport(view, normalized_logical)))
    var after_resize = await _consume_frame(shell)
    _assert_vector_close(before_resize.cursor_position, normalized_logical, "Mapping before resize")
    _assert_vector_close(after_resize.cursor_position, normalized_logical, "Resize changes only scale")
    _assert_true(track.is_conservation_valid(), "Input sequence conserves inventory")
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


func _assert_close(actual: float, expected: float, message: String) -> void:
    _assert_true(absf(actual - expected) <= TrackSystemScript.GEOMETRY_EPSILON, message)


func _assert_vector_close(actual: Vector2, expected: Vector2, message: String) -> void:
    _assert_true(
        actual.is_equal_approx(expected),
        "%s | expected=%s actual=%s" % [message, expected, actual]
    )
