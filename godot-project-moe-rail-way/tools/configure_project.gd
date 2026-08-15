extends SceneTree


func _initialize() -> void:
    ProjectSettings.set_setting(
        "application/config/name",
        "Moe Rail Way Prototype"
    )
    ProjectSettings.set_setting(
        "application/run/main_scene",
        "res://src/app/prototype_app.tscn"
    )
    ProjectSettings.set_setting(
        "display/window/size/viewport_width",
        1280
    )
    ProjectSettings.set_setting(
        "display/window/size/viewport_height",
        720
    )
    ProjectSettings.set_setting(
        "display/window/stretch/mode",
        "canvas_items"
    )
    ProjectSettings.set_setting(
        "display/window/stretch/aspect",
        "expand"
    )

    var left_click := InputEventMouseButton.new()
    left_click.button_index = MOUSE_BUTTON_LEFT
    ProjectSettings.set_setting(
        "input/track_draw",
        {
            "deadzone": 0.5,
            "events": [left_click],
        }
    )

    var save_result := ProjectSettings.save()
    if save_result != OK:
        push_error(
            "Failed to save project settings: %s" %
            error_string(save_result)
        )
        quit(1)
        return

    print("Project settings configured")
    quit(0)
