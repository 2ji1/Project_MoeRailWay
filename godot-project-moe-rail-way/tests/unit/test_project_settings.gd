extends "res://tests/support/prototype_test.gd"


func run() -> PackedStringArray:
    assert_equal(
        ProjectSettings.get_setting("application/config/name"),
        "Moe Rail Way Prototype",
        "Application name must identify the prototype"
    )
    assert_equal(
        ProjectSettings.get_setting("application/run/main_scene"),
        "res://src/app/prototype_app.tscn",
        "PrototypeApp must be the main scene"
    )
    assert_equal(
        ProjectSettings.get_setting("display/window/size/viewport_width"),
        1280,
        "Logical viewport width must be 1280"
    )
    assert_equal(
        ProjectSettings.get_setting("display/window/size/viewport_height"),
        720,
        "Logical viewport height must be 720"
    )
    assert_equal(
        ProjectSettings.get_setting("display/window/stretch/mode"),
        "canvas_items",
        "2D stretch mode must remain canvas_items"
    )
    assert_equal(
        ProjectSettings.get_setting("display/window/stretch/aspect"),
        "expand",
        "Aspect mode must remain expand"
    )

    assert_true(InputMap.has_action("track_draw"), "track_draw action must exist")
    var has_left_mouse := false
    for event in InputMap.action_get_events("track_draw"):
        if event is InputEventMouseButton:
            has_left_mouse = (
                event.button_index == MOUSE_BUTTON_LEFT
                or has_left_mouse
            )
    assert_true(has_left_mouse, "track_draw must bind the left mouse button")

    return finish()
