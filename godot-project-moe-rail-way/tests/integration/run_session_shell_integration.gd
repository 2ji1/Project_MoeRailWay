extends SceneTree

const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
const SHORT_APP_SCENE_PATH := "res://tests/integration/short_session_app.tscn"
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")
const UILayoutValidatorScript = preload("res://src/presentation/layout/ui_layout_validator.gd")

const PROFILE_FIELDS := [
    "outer_padding_x",
    "outer_padding_y",
    "panel_padding",
    "item_gap",
    "row_gap",
    "hud_height",
    "icon_size",
]

var _failures := PackedStringArray()
var _shell_scene: PackedScene


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    _shell_scene = load(SHELL_SCENE_PATH) as PackedScene
    if _shell_scene == null:
        push_error("Missing session shell scene: %s" % SHELL_SCENE_PATH)
        quit(1)
        return

    var out_of_tree_shell = _shell_scene.instantiate()
    var out_of_tree_view = out_of_tree_shell.get_track_field_view()
    _assert_true(out_of_tree_view != null, "Out-of-tree shell must resolve its direct TrackFieldView")
    if out_of_tree_view != null:
        _assert_true(
            out_of_tree_view.get_logical_track_field() != null,
            "Out-of-tree TrackFieldView must resolve its direct LogicalTrackField"
        )
    out_of_tree_shell.free()

    await _verify_supported_layouts()
    await _verify_profile_metric_consumers()
    await _verify_app_lifecycle()
    await _verify_track_end_urgent_presentation()

    if _failures.is_empty():
        print("PASS: session shell layout integration")
        print("PASS: session shell lifecycle integration")
        quit(0)
        return

    for failure in _failures:
        push_error(failure)
    print("FAIL: %d session shell integration assertion(s)" % _failures.size())
    quit(1)


func _verify_supported_layouts() -> void:
    var cases := [
        [Vector2i(960, 540), _profile_at_bounds(0), "minimum profile at 960x540"],
        [Vector2i(960, 540), _profile_at_bounds(1), "maximum profile at 960x540"],
        [Vector2i(1280, 720), UILayoutProfileScript.new(), "default profile at 1280x720"],
        [Vector2i(1920, 1080), UILayoutProfileScript.new(), "default profile at 1920x1080"],
    ]

    for case in cases:
        var viewport_size: Vector2i = case[0]
        var profile = case[1]
        var description: String = case[2]
        var fixture: Dictionary = await _create_fixture(viewport_size, profile)
        var shell = fixture.shell
        var track_field_view = shell.get_track_field_view()
        var observation: Dictionary = shell.get_layout_observation()
        var top_rect: Rect2 = observation.top_hud_rect
        var field_rect: Rect2 = observation.field_rect
        var bottom_rect: Rect2 = observation.bottom_hud_rect

        _assert_close(top_rect.end.y, field_rect.position.y, "%s top HUD must touch the field" % description)
        _assert_close(field_rect.end.y, bottom_rect.position.y, "%s field must touch the bottom HUD" % description)
        _assert_true(not top_rect.intersects(field_rect), "%s top HUD must not overlap the field" % description)
        _assert_true(not field_rect.intersects(bottom_rect), "%s field must not overlap the bottom HUD" % description)
        _assert_true(field_rect.size.x >= 640.0, "%s field width must remain playable" % description)
        _assert_true(field_rect.size.y >= 300.0, "%s field height must remain playable" % description)
        _assert_true(field_rect.size.y > top_rect.size.y, "%s field must dominate the top HUD" % description)
        _assert_true(field_rect.size.y > bottom_rect.size.y, "%s field must dominate the bottom HUD" % description)
        _assert_close(top_rect.size.y, profile.hud_height, "%s top HUD must reserve exact height" % description)
        _assert_close(bottom_rect.size.y, profile.hud_height, "%s bottom HUD must reserve exact height" % description)
        _assert_equal(
            field_rect.size,
            UILayoutValidatorScript.calculate_field_size(profile, viewport_size),
            "%s field allocation must match the validated formula" % description
        )
        _assert_close(observation.root_separation, 0.0, "%s root separation must be zero" % description)
        _assert_equal(shell.is_showing_result(), false, "%s must begin in the running view" % description)
        _assert_equal(observation.time_text, "3:00", "%s must show the initial countdown" % description)
        _assert_equal(
            observation.hud_texts,
            PackedStringArray([
                "TIME", "3:00", "TRACK", "—", "CASH", "—", "DURABILITY", "—",
                "CONTRACT", "—", "CARGO", "—", "TRACK END", "—",
            ]),
            "%s must expose approved live and inactive placeholders" % description
        )

        var field_center := field_rect.get_center()
        var mapped_center = shell.try_viewport_to_field(field_center)
        _assert_true(mapped_center != null, "%s field center must map" % description)
        _assert_true(
            shell.is_viewport_point_in_field(field_center),
            "%s public field containment must accept the center" % description
        )
        if mapped_center != null:
            _assert_vector_close(
                mapped_center,
                field_rect.size * 0.5,
                "%s field center must map to half the field size" % description
            )
        _assert_equal(
            shell.try_viewport_to_field(Vector2(field_rect.position.x - 0.5, field_center.y)),
            null,
            "%s must reject a point left of the field" % description
        )
        _assert_equal(
            shell.is_viewport_point_in_field(
                Vector2(field_rect.position.x - 0.5, field_center.y)
            ),
            false,
            "%s public field containment must reject an outside point" % description
        )
        _assert_equal(
            shell.try_viewport_to_field(Vector2(field_rect.end.x + 0.5, field_center.y)),
            null,
            "%s must reject a point right of the field" % description
        )
        _assert_equal(
            shell.try_viewport_to_field(Vector2(field_center.x, field_rect.position.y - 0.5)),
            null,
            "%s must reject a point above the field" % description
        )
        _assert_equal(
            shell.try_viewport_to_field(Vector2(field_center.x, field_rect.end.y + 0.5)),
            null,
            "%s must reject a point below the field" % description
        )
        _assert_true(track_field_view != null, "%s shell must own one TrackFieldView" % description)
        if track_field_view != null:
            _assert_equal(
                _count_named_children(shell.get_node("OuterMargin/MainColumn/Field"), "TrackFieldView"),
                1,
                "%s field must own exactly one TrackFieldView" % description
            )
            var content_rect: Rect2 = track_field_view.get_logical_content_rect()
            var logical_center = shell.try_viewport_to_logical_field(
                track_field_view.get_global_transform_with_canvas() * content_rect.get_center()
            )
            _assert_vector_close(
                logical_center,
                Vector2(600.0, 280.0),
                "%s logical delegate must map a content point" % description
            )
            var letterbox_point := Vector2(content_rect.get_center().x, 0.5)
            if content_rect.position.x > 0.5:
                letterbox_point = Vector2(0.5, content_rect.get_center().y)
            _assert_equal(
                shell.try_viewport_to_logical_field(
                    track_field_view.get_global_transform_with_canvas() * letterbox_point
                ),
                null,
                "%s logical delegate must reject its internal letterbox" % description
            )

        fixture.host.queue_free()
        await process_frame


func _verify_profile_metric_consumers() -> void:
    var viewport_size := Vector2i(1280, 720)
    var snapshot = _initial_snapshot()
    var default_profile = UILayoutProfileScript.new()
    var fixture: Dictionary = await _create_fixture(viewport_size, default_profile)
    var shell = fixture.shell
    var baseline: Dictionary = shell.get_layout_observation()

    fixture.host.size = Vector2(1600, 900)
    shell.configure(default_profile, snapshot)
    await _wait_for_layout()
    var resized_observation: Dictionary = shell.get_layout_observation()
    _assert_equal(
        resized_observation.field_rect.size,
        UILayoutValidatorScript.calculate_field_size(default_profile, Vector2i(1600, 900)),
        "Reapplying the profile after resize must preserve derived field geometry"
    )
    var resized_center: Vector2 = resized_observation.field_rect.get_center()
    _assert_vector_close(
        shell.try_viewport_to_field(resized_center),
        resized_observation.field_rect.size * 0.5,
        "Reapplying the profile after resize must preserve coordinate mapping"
    )
    fixture.host.size = Vector2(viewport_size)
    shell.configure(default_profile, snapshot)
    await _wait_for_layout()
    baseline = shell.get_layout_observation()

    var horizontal = _copy_profile(default_profile)
    horizontal.outer_padding_x = 24.0
    shell.configure(horizontal, snapshot)
    await _wait_for_layout()
    var horizontal_observation: Dictionary = shell.get_layout_observation()
    _assert_close(
        horizontal_observation.field_rect.position.x,
        baseline.field_rect.position.x + 8.0,
        "outer_padding_x must move only the horizontal field edge"
    )
    _assert_close(
        horizontal_observation.field_rect.size.x,
        baseline.field_rect.size.x - 16.0,
        "outer_padding_x must reduce field width twice"
    )
    _assert_close(
        horizontal_observation.field_rect.position.y,
        baseline.field_rect.position.y,
        "outer_padding_x must not move the vertical field edge"
    )
    _assert_close(
        horizontal_observation.field_rect.size.y,
        baseline.field_rect.size.y,
        "outer_padding_x must not change field height"
    )

    var vertical = _copy_profile(default_profile)
    vertical.outer_padding_y = 20.0
    shell.configure(vertical, snapshot)
    await _wait_for_layout()
    var vertical_observation: Dictionary = shell.get_layout_observation()
    _assert_close(
        vertical_observation.field_rect.position.x,
        baseline.field_rect.position.x,
        "outer_padding_y must not move the horizontal field edge"
    )
    _assert_close(
        vertical_observation.field_rect.size.x,
        baseline.field_rect.size.x,
        "outer_padding_y must not change field width"
    )
    _assert_close(
        vertical_observation.field_rect.position.y,
        baseline.field_rect.position.y + 8.0,
        "outer_padding_y must move the vertical field edge"
    )
    _assert_close(
        vertical_observation.field_rect.size.y,
        baseline.field_rect.size.y - 16.0,
        "outer_padding_y must reduce field height twice"
    )

    shell.show_result(
        SessionResultScript.new(SessionResultScript.Reason.REGULAR_TIME_EXPIRED, 10800, 10800, 0)
    )
    await _wait_for_layout()
    _assert_equal(shell.is_showing_result(), true, "show_result must reveal the result overlay once")
    _assert_equal(
        shell.get_layout_observation().result_texts,
        PackedStringArray([
            "SESSION COMPLETE",
            "REGULAR TIME EXPIRED",
            "Settlement is not available in this milestone.",
        ]),
        "The result overlay must contain only approved text"
    )

    var panel_profile = _copy_profile(default_profile)
    panel_profile.panel_padding = 14.0
    shell.configure(panel_profile, snapshot)
    await _wait_for_layout()
    var panel_observation: Dictionary = shell.get_layout_observation()
    _assert_equal(
        panel_observation.top_content_insets,
        Vector4(14.0, 14.0, 14.0, 14.0),
        "panel_padding must inset the top HUD content"
    )
    _assert_equal(
        panel_observation.bottom_content_insets,
        Vector4(14.0, 14.0, 14.0, 14.0),
        "panel_padding must inset the bottom HUD content"
    )
    _assert_equal(
        panel_observation.result_content_insets,
        Vector4(14.0, 14.0, 14.0, 14.0),
        "panel_padding must inset the result content"
    )

    var item_profile = _copy_profile(default_profile)
    item_profile.item_gap = 18.0
    shell.configure(item_profile, snapshot)
    await _wait_for_layout()
    var item_observation: Dictionary = shell.get_layout_observation()
    _assert_all_close(item_observation.top_item_gaps, 18.0, "item_gap must separate top HUD items")
    _assert_all_close(item_observation.bottom_item_gaps, 18.0, "item_gap must separate bottom HUD items")

    var row_profile = _copy_profile(default_profile)
    row_profile.row_gap = 10.0
    shell.configure(row_profile, snapshot)
    await _wait_for_layout()
    _assert_all_close(
        shell.get_layout_observation().result_row_gaps,
        10.0,
        "row_gap must separate result text rows"
    )

    var hud_profile = _copy_profile(default_profile)
    hud_profile.hud_height = 64.0
    shell.configure(hud_profile, snapshot)
    await _wait_for_layout()
    var hud_observation: Dictionary = shell.get_layout_observation()
    _assert_close(hud_observation.top_hud_rect.size.y, 64.0, "hud_height must size the top HUD")
    _assert_close(hud_observation.bottom_hud_rect.size.y, 64.0, "hud_height must size the bottom HUD")

    var icon_profile = _copy_profile(default_profile)
    icon_profile.icon_size = 28.0
    shell.configure(icon_profile, snapshot)
    await _wait_for_layout()
    var icon_observation: Dictionary = shell.get_layout_observation()
    for icon_rect in icon_observation.icon_rects:
        _assert_vector_close(icon_rect.size, Vector2(28.0, 28.0), "icon_size must size every square icon")

    fixture.host.queue_free()
    await process_frame


func _verify_app_lifecycle() -> void:
    var previous_physics_ticks := Engine.physics_ticks_per_second
    var packed_app = load(SHORT_APP_SCENE_PATH) as PackedScene
    _assert_true(packed_app != null, "The short-session wrapper must load the real app scene")
    if packed_app == null:
        return

    var app = packed_app.instantiate()
    app.balance = app.balance.duplicate(true)
    app.balance.session_balance = app.balance.session_balance.duplicate(true)
    app.balance.train_balance = app.balance.train_balance.duplicate(true)
    app.balance.track_inventory_balance = app.balance.track_inventory_balance.duplicate(true)
    app.balance.track_construction_balance = app.balance.track_construction_balance.duplicate(true)
    app.balance.departure_balance = app.balance.departure_balance.duplicate(true)
    app.balance.train_balance.speed_cells_per_second = 0.1
    app.balance.track_inventory_balance.total_track_cells = 12
    app.balance.track_construction_balance.build_cells_per_second = 60.0
    app.balance.departure_balance.required_built_cells = 1
    var presented_results := []
    var connect_error := app.connect(
        "session_result_presented",
        func(result) -> void: presented_results.append(result)
    )
    _assert_equal(connect_error, OK, "PrototypeApp must expose session_result_presented")
    root.add_child(app)
    await process_frame

    var controller = app.get("session_controller")
    var shell = _find_session_shell(app)
    _assert_true(controller != null, "Automatic startup must compose a session controller")
    _assert_true(shell != null, "The real app scene must contain the public SessionShell")
    if controller == null or shell == null:
        app.queue_free()
        await process_frame
        Engine.physics_ticks_per_second = previous_physics_ticks
        return

    _assert_equal(
        controller.get_state(),
        SessionControllerScript.State.PREPARING_DEPARTURE,
        "Adding the app to the tree must start departure preparation"
    )
    _assert_equal(
        shell.get_layout_observation().time_text,
        "0:02",
        "The short fixture must auto-start with a two-second HUD"
    )

    app.set_physics_process(false)
    var start_config = app.get("session_start_config")
    var preparation_observation: Dictionary = shell.get_layout_observation()
    _assert_equal(
        preparation_observation.hud_texts[3],
        "12 / 12",
        "The real preparation HUD must show available and total track"
    )
    _assert_equal(
        preparation_observation.hud_texts[13],
        "0 / 1",
        "The real preparation HUD must show built and required track"
    )
    _assert_equal(
        preparation_observation.track_end_urgent,
        false,
        "The real preparation HUD must use normal warning style"
    )
    var departure_cell: Vector2i = start_config.departure_cell
    var target_cell := departure_cell + Vector2i.RIGHT
    if target_cell.x >= start_config.grid_size.x:
        target_cell = departure_cell + Vector2i.LEFT
    var crossed: Array[Vector2i] = [target_cell]
    var draw_frame = TrackInputFrameScript.new(
        crossed,
        departure_cell,
        true,
        Vector2i(-1, -1),
        false,
        true,
        true,
        false,
        false
    )
    controller.advance_tick(draw_frame)
    var preparation_safety: int = start_config.simulation_ticks_per_second + 2
    while (
        controller.get_state() == SessionControllerScript.State.PREPARING_DEPARTURE
        and preparation_safety > 0
    ):
        controller.advance_tick(TrackInputFrameScript.empty())
        preparation_safety -= 1
    _assert_equal(
        controller.get_state(),
        SessionControllerScript.State.RUNNING,
        "The exact construction threshold tick must start the train"
    )
    _assert_equal(
        controller.get_snapshot().get_elapsed_ticks(),
        1,
        "The departure threshold tick must start the timer"
    )
    _assert_true(
        controller.get_snapshot().is_train_active(),
        "The departure threshold tick must publish an active train"
    )
    _assert_equal(
        shell.get_layout_observation().hud_texts[13],
        "10.0 s",
        "The real running HUD must show built-end seconds with one decimal"
    )

    var safety_ticks: int = controller.get_snapshot().get_total_ticks() + 1
    while controller.get_state() == SessionControllerScript.State.RUNNING and safety_ticks > 0:
        controller.advance_tick(TrackInputFrameScript.empty())
        safety_ticks -= 1

    _assert_equal(
        controller.get_state(),
        SessionControllerScript.State.COMPLETED,
        "Explicit ticks must drive the short session to completion"
    )
    _assert_equal(presented_results.size(), 1, "The app must present exactly one result")
    if not presented_results.is_empty():
        var result = presented_results[0]
        _assert_equal(
            result.get_reason(),
            SessionResultScript.Reason.REGULAR_TIME_EXPIRED,
            "The automatic result must use regular time expiry"
        )
        _assert_equal(
            shell.get_layout_observation().time_text,
            "0:00",
            "The HUD must publish zero before result presentation"
        )
        _assert_equal(app.call("is_showing_result"), true, "The app must expose the result view")

        for index in range(10):
            controller.advance_tick()
        app.call("present_session_result", result)
        _assert_equal(
            presented_results.size(),
            1,
            "Controller and app guards must prevent duplicate result transitions"
        )

    var final_observation: Dictionary = shell.get_layout_observation()
    _assert_equal(final_observation.hud_texts[5], "—", "CASH must remain an inactive em dash")
    _assert_equal(final_observation.hud_texts[9], "—", "CONTRACT must remain an inactive em dash")
    _assert_equal(
        final_observation.result_texts,
        PackedStringArray([
            "SESSION COMPLETE",
            "REGULAR TIME EXPIRED",
            "Settlement is not available in this milestone.",
        ]),
        "Lifecycle completion must not add settlement or action text"
    )

    app.queue_free()
    await process_frame
    Engine.physics_ticks_per_second = previous_physics_ticks


func _verify_track_end_urgent_presentation() -> void:
    var fixture: Dictionary = await _create_fixture(
        Vector2i(1280, 720),
        UILayoutProfileScript.new()
    )
    var shell = fixture.shell
    var urgent_snapshot = SessionSnapshotScript.new(
        40,
        10,
        30,
        10,
        true,
        SessionControllerScript.State.RUNNING,
        [],
        [],
        [],
        3.0,
        10,
        20,
        Vector2.ZERO,
        1,
        1,
        3.0,
        true,
        2.0,
        Vector2(100.0, 100.0),
        Vector2.RIGHT,
        1.5,
        true,
        &"departure_01",
        Vector2i(0, 0)
    )
    shell.present(urgent_snapshot)
    await _wait_for_layout()
    var urgent_observation: Dictionary = shell.get_layout_observation()
    _assert_equal(urgent_observation.hud_texts[3], "10 / 20", "Urgent probe inventory text")
    _assert_equal(urgent_observation.hud_texts[13], "1.5 s", "Urgent probe seconds text")
    _assert_true(urgent_observation.track_end_urgent, "Urgent snapshot must expose urgent style")

    shell.show_result(SessionResultScript.new(
        SessionResultScript.Reason.TRACK_END_REACHED,
        40,
        10,
        30
    ))
    await _wait_for_layout()
    _assert_equal(
        shell.get_layout_observation().result_texts,
        PackedStringArray([
            "SESSION COMPLETE",
            "TRACK END REACHED",
            "Settlement is not available in this milestone.",
        ]),
        "Track-end result overlay must contain only approved text"
    )
    fixture.host.queue_free()
    await process_frame


func _find_session_shell(node):
    if node.has_method("get_layout_observation") and node.has_method("try_viewport_to_field"):
        return node
    for child in node.get_children():
        var found = _find_session_shell(child)
        if found != null:
            return found
    return null


func _count_named_children(parent: Node, child_name: StringName) -> int:
    var count := 0
    for child in parent.get_children():
        if child.name == child_name:
            count += 1
    return count


func _create_fixture(viewport_size: Vector2i, profile) -> Dictionary:
    var host := Control.new()
    host.size = Vector2(viewport_size)
    host.custom_minimum_size = Vector2(viewport_size)
    root.add_child(host)

    var shell = _shell_scene.instantiate()
    host.add_child(shell)
    shell.configure(profile, _initial_snapshot())
    await _wait_for_layout()
    return {"host": host, "shell": shell}


func _wait_for_layout() -> void:
    await process_frame
    await process_frame


func _initial_snapshot():
    return SessionSnapshotScript.new(10800, 0, 10800, 60)


func _profile_at_bounds(bound_index: int):
    var profile = UILayoutProfileScript.new()
    var bounds := {
        "outer_padding_x": Vector2(0.0, 48.0),
        "outer_padding_y": Vector2(0.0, 32.0),
        "panel_padding": Vector2(4.0, 20.0),
        "item_gap": Vector2(4.0, 24.0),
        "row_gap": Vector2(2.0, 16.0),
        "hud_height": Vector2(44.0, 80.0),
        "icon_size": Vector2(12.0, 32.0),
    }
    for field_name in PROFILE_FIELDS:
        profile.set(field_name, bounds[field_name][bound_index])
    return profile


func _copy_profile(source):
    var copy = UILayoutProfileScript.new()
    for field_name in PROFILE_FIELDS:
        copy.set(field_name, source.get(field_name))
    return copy


func _assert_true(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        _failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])


func _assert_close(actual: float, expected: float, message: String) -> void:
    if not is_equal_approx(actual, expected):
        _failures.append("%s | expected=%s actual=%s" % [message, expected, actual])


func _assert_vector_close(actual: Vector2, expected: Vector2, message: String) -> void:
    if not actual.is_equal_approx(expected):
        _failures.append("%s | expected=%s actual=%s" % [message, expected, actual])


func _assert_all_close(values: PackedFloat32Array, expected: float, message: String) -> void:
    _assert_true(not values.is_empty(), "%s | no measurements" % message)
    for value in values:
        _assert_close(value, expected, message)
