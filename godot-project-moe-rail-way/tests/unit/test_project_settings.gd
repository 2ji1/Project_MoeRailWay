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
	var features: PackedStringArray = ProjectSettings.get_setting(
		"application/config/features",
		PackedStringArray()
	)
	assert_true(
		features.has("Forward Plus"),
        "Renderer feature must remain Forward Plus"
	)
	assert_equal(
		ProjectSettings.get_setting("rendering/rendering_device/driver.windows"),
		"d3d12",
        "Windows rendering driver must remain D3D12"
	)

	_assert_single_mouse_binding(
		&"track_draw",
		MOUSE_BUTTON_LEFT,
        "track_draw must bind exactly one left mouse button"
	)
	_assert_single_mouse_binding(
		&"track_cancel",
		MOUSE_BUTTON_RIGHT,
        "track_cancel must bind the right mouse button"
	)

	return finish()


func _assert_single_mouse_binding(
	action_name: StringName,
	expected_button: int,
	message: String
) -> void:
	assert_true(InputMap.has_action(action_name), message)
	var events := InputMap.action_get_events(action_name)
	assert_equal(events.size(), 1, message)
	if events.size() != 1:
		return
	assert_true(events[0] is InputEventMouseButton, message)
	if events[0] is InputEventMouseButton:
		assert_equal(events[0].button_index, expected_button, message)
