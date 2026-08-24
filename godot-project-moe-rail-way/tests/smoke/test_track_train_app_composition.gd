extends "res://tests/support/prototype_test.gd"

const APP_SCENE_PATH := "res://src/app/prototype_app.tscn"
const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")
const LogicalTrackFieldScript = preload("res://src/presentation/track/logical_track_field.gd")
const TrackFieldViewScript = preload("res://src/presentation/track/track_field_view.gd")
const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")


func _new_app():
    var packed = load(APP_SCENE_PATH) as PackedScene
    assert_not_null(packed, "Prototype app scene must load")
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
    return app


func _new_composed_app():
    var app = _new_app()
    if app == null:
        return null
    var errors: PackedStringArray = app.compose_session_dependencies()
    assert_equal(errors, PackedStringArray(), "Real app composition must succeed")
    return app


func _new_shell():
    var packed = load(SHELL_SCENE_PATH) as PackedScene
    assert_not_null(packed, "Session shell scene must load")
    if packed == null:
        return null
    var shell = packed.instantiate()
    shell.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    shell.size = Vector2(1280.0, 720.0)
    Engine.get_main_loop().root.add_child(shell)
    return shell


func _snapshot(
    config,
    state: int,
    built_route: PackedVector2Array,
    reserved_route: PackedVector2Array,
    construction_head: Vector2,
    train_active: bool,
    train_position: Vector2,
    train_heading: Vector2,
    available: float,
    built_for_departure: float,
    built_ahead: float,
    estimated_seconds: float,
    urgent: bool,
    elapsed_ticks := 0,
    remaining_ticks := 40
):
    return SessionSnapshotScript.new(
        40,
        elapsed_ticks,
        remaining_ticks,
        10,
        true,
        state,
        built_route,
        reserved_route,
        construction_head,
        train_active,
        train_position,
        train_heading,
        available,
        config.total_track_units,
        built_for_departure,
        config.departure_required_built_units,
        built_ahead,
        estimated_seconds,
        urgent,
        config.departure_candidate_id
    )


func _preparation_snapshot(config):
    var departure: Vector2 = config.departure_position
    return _snapshot(
        config,
        SessionControllerScript.State.PREPARING_DEPARTURE,
        PackedVector2Array([departure]),
        PackedVector2Array([departure, departure + Vector2(20.0, 0.0)]),
        departure,
        false,
        departure,
        Vector2.RIGHT,
        180.0,
        0.0,
        0.0,
        0.0,
        false
    )


func _motion(local_position: Vector2) -> InputEventMouseMotion:
    var event := InputEventMouseMotion.new()
    event.position = local_position
    event.global_position = local_position
    return event


func _button(local_position: Vector2, button_index: int) -> InputEventMouseButton:
    var event := InputEventMouseButton.new()
    event.position = local_position
    event.global_position = local_position
    event.button_index = button_index
    event.pressed = true
    return event


func _logical_to_local(view, logical_position: Vector2, logical_size: Vector2) -> Vector2:
    var content: Rect2 = view.get_logical_content_rect()
    return content.position + logical_position * (content.size / logical_size)


func _assert_vector_close(actual: Vector2, expected: Vector2, message: String) -> void:
    assert_true(
        actual.is_equal_approx(expected),
        "%s | expected=%s actual=%s" % [message, expected, actual]
    )


func _assert_export_type(app, property_name: StringName, expected_hint: String) -> void:
    var found := false
    for property in app.get_property_list():
        if property.name != property_name:
            continue
        found = true
        assert_equal(property.type, TYPE_OBJECT, "%s export must be an Object" % property_name)
        assert_true(
            String(property.hint_string).contains(expected_hint),
            "%s export must name %s" % [property_name, expected_hint]
        )
    assert_true(found, "%s must remain exported" % property_name)


func _test_composition_and_detachment() -> void:
    var app = _new_app()
    if app == null:
        return
    _assert_export_type(app, &"balance", "PrototypeBalance")
    _assert_export_type(app, &"layout_profile", "UILayoutProfile")
    assert_true(app.balance is PrototypeBalanceScript, "Balance value must stay specifically typed")
    assert_true(app.layout_profile is UILayoutProfileScript, "Layout value must stay specifically typed")

    var shell = app.get_node("SessionShell")
    var view = shell.get_track_field_view()
    var field = view.get_logical_track_field()
    assert_true(view is TrackFieldViewScript, "Shell must own one TrackFieldView")
    assert_true(field is LogicalTrackFieldScript, "TrackFieldView must own one LogicalTrackField")
    assert_equal(field.get_node("DepartureCandidates").get_child_count(), 8, "Field must keep eight authored candidates")

    var errors: PackedStringArray = app.compose_session_dependencies()
    assert_equal(errors, PackedStringArray(), "Valid composition must succeed")
    assert_not_null(app.session_start_config, "Composition must copy a start config")
    assert_not_null(app.session_rng, "Composition must expose the public RNG")
    assert_true(app.track_system is TrackSystemScript, "Composition must create TrackSystem")
    assert_true(app.train_system is TrainSystemScript, "Composition must create TrainSystem")
    assert_equal(app.session_controller.get_state(), SessionControllerScript.State.READY, "Controller must compose READY")
    var expected_rng = SessionRngScript.new(app.session_start_config.seed)
    assert_equal(app.session_rng.next_u32(), expected_rng.next_u32(), "Composition must not consume public RNG")

    var records: Array[Dictionary] = field.get_sorted_candidate_records()
    var selected_found := false
    for record in records:
        if (
            record.candidate_id == app.session_start_config.departure_candidate_id
            and record.position.is_equal_approx(app.session_start_config.departure_position)
        ):
            selected_found = true
    assert_true(selected_found, "Selected departure must match one sorted scene record")

    var selected_candidate = null
    for candidate in field.get_node("DepartureCandidates").get_children():
        if candidate.candidate_id == app.session_start_config.departure_candidate_id:
            selected_candidate = candidate
            break
    assert_not_null(selected_candidate, "Selected authoring candidate must be found by copied ID")
    if selected_candidate == null:
        app.free()
        return

    view.size = Vector2(1200.0, 560.0)
    view.configure_session(app.session_start_config)
    view.present(app.session_controller.get_snapshot())
    var config = app.session_start_config
    var snapshot = app.session_controller.get_snapshot()
    var original_logical_size := Vector2(config.logical_field_size)
    var original_departure := Vector2(config.departure_position)
    var original_candidate_id := StringName(config.departure_candidate_id)
    var original_total := float(config.total_track_units)
    var mapped_before: Vector2 = view.viewport_to_logical_unclamped(Vector2(600.0, 280.0))

    app.balance.session_balance.session_duration_seconds = 99.0
    app.balance.train_balance.speed_units_per_second = 999.0
    app.balance.track_inventory_balance.total_units = 999.0
    app.balance.track_construction_balance.speed_units_per_second = 999.0
    app.balance.departure_balance.required_built_units = 999.0
    selected_candidate.candidate_id = &"mutated_selected_departure"
    selected_candidate.position = Vector2(1.0, 1.0)
    field.size_preset = LogicalTrackFieldScript.SizePreset.COMPACT
    field.size_preset = LogicalTrackFieldScript.SizePreset.CUSTOM
    field.custom_width = 2000.0
    field.custom_height = 1000.0

    assert_equal(config.logical_field_size, original_logical_size, "Config must detach authored logical size")
    assert_equal(config.departure_candidate_id, original_candidate_id, "Config must detach candidate ID")
    assert_equal(config.departure_position, original_departure, "Config must detach candidate position")
    assert_equal(config.total_track_units, original_total, "Config must detach balance Resources")
    assert_equal(app.session_controller.get_snapshot(), snapshot, "Controller snapshot must ignore source mutation")
    assert_equal(snapshot.get_total_track_units(), original_total, "Snapshot values must ignore Resource mutation")
    _assert_vector_close(
        view.viewport_to_logical_unclamped(Vector2(600.0, 280.0)),
        mapped_before,
        "Configured input mapping must ignore authored size mutation"
    )
    assert_equal(
        view.get_render_observation().logical_size,
        original_logical_size,
        "Primitive drawing size must use copied session size"
    )
    assert_equal(
        view.get_render_observation().selected_departure_id,
        original_candidate_id,
        "Rendered departure ID must ignore selected authoring candidate mutation"
    )
    _assert_vector_close(
        view.get_render_observation().selected_departure_position,
        original_departure,
        "Rendered departure position must ignore selected authoring candidate mutation"
    )
    assert_equal(
        app.session_controller.get_snapshot().get_selected_departure_candidate_id(),
        original_candidate_id,
        "Controller snapshot selected ID must ignore authoring candidate mutation"
    )
    _assert_vector_close(
        app.track_system.get_built_points()[0],
        original_departure,
        "Domain route must ignore candidate mutation"
    )
    app.free()


func _test_runtime_candidate_and_snapshot_presentation() -> void:
    var app = _new_app()
    if app == null:
        return
    Engine.get_main_loop().root.add_child(app)
    app.set_physics_process(false)
    var shell = app.get_node("SessionShell")
    var view = shell.get_track_field_view()
    var field = view.get_logical_track_field()
    var hidden_count := 0
    for candidate in field.get_node("DepartureCandidates").get_children():
        if not candidate.visible:
            hidden_count += 1
    assert_equal(hidden_count, 8, "All unselected authoring markers must be runtime-invisible")
    var prep = view.get_render_observation()
    assert_equal(prep.selected_departure_id, app.session_start_config.departure_candidate_id, "Only selected marker ID is represented")
    assert_equal(prep.selected_departure_position, app.session_start_config.departure_position, "Selected marker uses copied position")
    assert_equal(prep.built_route, app.session_controller.get_snapshot().get_built_route(), "Preparation draws built route")
    assert_equal(prep.reserved_route, app.session_controller.get_snapshot().get_reserved_route(), "Preparation draws reserved route")
    assert_equal(prep.construction_head, app.session_controller.get_snapshot().get_construction_head(), "Preparation draws construction head")
    app.free()


func _test_hud_and_pure_render_values() -> void:
    var app = _new_composed_app()
    if app == null:
        return
    var config = app.session_start_config
    var shell = _new_shell()
    if shell == null:
        app.free()
        return
    var prep = _preparation_snapshot(config)
    shell.configure(app.layout_profile, prep, config)
    var prep_layout: Dictionary = shell.get_layout_observation()
    assert_equal(prep_layout.hud_texts[1], "0:04", "Preparation time string")
    assert_equal(prep_layout.hud_texts[3], "180.0 / 720.0", "Preparation inventory string")
    assert_equal(prep_layout.hud_texts[13], "0.0 / 360.0", "Preparation progress string")
    assert_false(prep_layout.track_end_urgent, "Preparation warning style is normal")

    var departure: Vector2 = config.departure_position
    var running = _snapshot(
        config,
        SessionControllerScript.State.RUNNING,
        PackedVector2Array([departure, departure + Vector2(30.0, 0.0)]),
        PackedVector2Array([departure, departure + Vector2(40.0, 0.0)]),
        departure + Vector2(30.0, 0.0),
        true,
        departure + Vector2(10.0, 0.0),
        Vector2.RIGHT,
        150.0,
        30.0,
        20.0,
        0.6,
        true,
        15,
        25
    )
    shell.present(running)
    var layout: Dictionary = shell.get_layout_observation()
    assert_equal(layout.hud_texts[1], "0:03", "Running time string")
    assert_equal(layout.hud_texts[3], "150.0 / 720.0", "Running inventory string")
    assert_equal(layout.hud_texts[13], "0.6 s", "Running warning seconds string")
    assert_true(layout.track_end_urgent, "Running urgent observation")

    var view = shell.get_track_field_view()
    var observation: Dictionary = view.get_render_observation()
    var expected_keys := PackedStringArray([
        "built_route", "construction_head", "hover_cancel_route", "logical_size",
        "reserved_route", "selected_departure_id", "selected_departure_position",
        "train_active", "train_heading", "train_position",
    ])
    var actual_keys := PackedStringArray()
    for key in observation.keys():
        actual_keys.append(String(key))
        assert_false(observation[key] is Object, "Render observation values must not expose Objects")
    actual_keys.sort()
    expected_keys.sort()
    assert_equal(actual_keys, expected_keys, "Render observation must expose exact primitive keys")
    assert_true(observation.train_active, "Running render observation activates train")
    assert_equal(observation.train_position, running.get_train_position(), "Running train position")
    assert_equal(observation.train_heading, running.get_train_heading(), "Running train heading")
    var leaked_built: PackedVector2Array = observation.built_route
    var leaked_reserved: PackedVector2Array = observation.reserved_route
    var leaked_hover: PackedVector2Array = observation.hover_cancel_route
    leaked_built.append(Vector2(999.0, 999.0))
    leaked_reserved.append(Vector2(999.0, 999.0))
    leaked_hover.append(Vector2(999.0, 999.0))
    var fresh: Dictionary = view.get_render_observation()
    assert_false(fresh.built_route.has(Vector2(999.0, 999.0)), "Built observation must be copied")
    assert_false(fresh.reserved_route.has(Vector2(999.0, 999.0)), "Reserved observation must be copied")
    assert_false(fresh.hover_cancel_route.has(Vector2(999.0, 999.0)), "Hover observation must be copied")
    shell.free()
    app.free()


func _test_hover_projection_and_clearing() -> void:
    var app = _new_composed_app()
    if app == null:
        return
    var config = app.session_start_config
    var shell = _new_shell()
    if shell == null:
        app.free()
        return
    var origin := Vector2(300.0, 200.0)
    var reserved := PackedVector2Array([
        origin,
        origin + Vector2(100.0, 0.0),
        origin + Vector2(100.0, 10.0),
        origin + Vector2(0.0, 10.0),
    ])
    var hover_snapshot = _snapshot(
        config,
        SessionControllerScript.State.PREPARING_DEPARTURE,
        PackedVector2Array([origin]),
        reserved,
        origin,
        false,
        origin,
        Vector2.RIGHT,
        90.0,
        0.0,
        0.0,
        0.0,
        false
    )
    var view = shell.get_track_field_view()
    view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    view.size = config.logical_field_size
    shell.configure(app.layout_profile, hover_snapshot, config)
    var epsilon: float = TrackSystemScript.GEOMETRY_EPSILON
    var tie_point := origin + Vector2(50.0, 5.0 - epsilon * 0.25)
    view.call("_gui_input", _motion(_logical_to_local(view, tie_point, config.logical_field_size)))
    var tie_hover: PackedVector2Array = view.get_render_observation().hover_cancel_route
    assert_true(tie_hover.size() >= 2, "Reserved hover must produce a projected suffix")
    if tie_hover.size() >= 2:
        _assert_vector_close(tie_hover[0], origin + Vector2(50.0, 10.0), "Epsilon/2 tie favors greatest route distance")

    var nearer_point := origin + Vector2(50.0, 5.0 - epsilon * 0.75)
    view.call("_gui_input", _motion(_logical_to_local(view, nearer_point, config.logical_field_size)))
    var nearer_hover: PackedVector2Array = view.get_render_observation().hover_cancel_route
    assert_true(nearer_hover.size() >= 2, "Nearest hover must produce a projected suffix")
    if nearer_hover.size() >= 2:
        _assert_vector_close(nearer_hover[0], origin + Vector2(50.0, 0.0), "Distance beyond epsilon favors nearest Euclidean projection")

    var chain_route := PackedVector2Array([
        Vector2(100.0, 100.0),
        Vector2(200.0, 100.0),
        Vector2(300.0, 100.000075),
        Vector2(100.0, 100.000075),
        Vector2(0.0, 100.00015),
        Vector2(200.0, 100.00015),
    ])
    var chain_snapshot = _snapshot(
        config,
        SessionControllerScript.State.PREPARING_DEPARTURE,
        PackedVector2Array([chain_route[0]]),
        chain_route,
        chain_route[0],
        false,
        chain_route[0],
        Vector2.RIGHT,
        90.0,
        0.0,
        0.0,
        0.0,
        false
    )
    view.present(chain_snapshot)
    var chain_query := Vector2(150.0, 100.0)
    view.call("_gui_input", _motion(_logical_to_local(view, chain_query, config.logical_field_size)))
    var chain_hover: PackedVector2Array = view.get_render_observation().hover_cancel_route
    assert_true(chain_hover.size() >= 2, "Three nearby segments must produce a hover suffix")
    if chain_hover.size() >= 2:
        assert_true(
            chain_hover[0].distance_to(Vector2(150.0, 100.000075)) <= epsilon * 0.1,
            "Hover epsilon ties must stay relative to the global nearest projection"
        )

    view.call("_gui_input", _button(_logical_to_local(view, nearer_point, config.logical_field_size), MOUSE_BUTTON_RIGHT))
    assert_equal(view.get_render_observation().hover_cancel_route.size(), 0, "Right press clears hover preview")
    view.call("_gui_input", _motion(_logical_to_local(view, tie_point, config.logical_field_size)))
    view.call("_notification", Control.NOTIFICATION_MOUSE_EXIT)
    assert_equal(view.get_render_observation().hover_cancel_route.size(), 0, "Mouse exit clears hover preview")
    view.call("_gui_input", _motion(_logical_to_local(view, Vector2(20.0, 500.0), config.logical_field_size)))
    assert_equal(view.get_render_observation().hover_cancel_route.size(), 0, "Lost reserved hit clears hover preview")
    view.call("_gui_input", _motion(_logical_to_local(view, tie_point, config.logical_field_size)))
    var completed = _snapshot(
        config, SessionControllerScript.State.COMPLETED, PackedVector2Array([origin]), reserved,
        origin, false, origin, Vector2.RIGHT, 90.0, 0.0, 0.0, 0.0, false, 1, 0
    )
    view.present(completed)
    assert_equal(view.get_render_observation().hover_cancel_route.size(), 0, "Completed snapshot clears hover preview")
    shell.free()
    app.free()


func _test_results_and_inactive_future_surface() -> void:
    var app = _new_composed_app()
    if app == null:
        return
    for reason in [
        SessionResultScript.Reason.REGULAR_TIME_EXPIRED,
        SessionResultScript.Reason.TRACK_END_REACHED,
    ]:
        var shell = _new_shell()
        if shell == null:
            continue
        shell.configure(app.layout_profile, _preparation_snapshot(app.session_start_config), app.session_start_config)
        shell.show_result(null)
        assert_false(shell.is_showing_result(), "Null result must be ignored")
        var result = SessionResultScript.new(reason, 40, 10, 30)
        shell.show_result(result)
        assert_true(shell.is_showing_result(), "Each supported reason must present")
        var expected_reason := "REGULAR TIME EXPIRED"
        if reason == SessionResultScript.Reason.TRACK_END_REACHED:
            expected_reason = "TRACK END REACHED"
        assert_equal(shell.get_layout_observation().result_texts[1], expected_reason, "Exact result reason text")
        shell.show_result(SessionResultScript.new(SessionResultScript.Reason.REGULAR_TIME_EXPIRED, 40, 40, 0))
        assert_equal(shell.get_layout_observation().result_texts[1], expected_reason, "Repeated result must be ignored")
        var layout: Dictionary = shell.get_layout_observation()
        for index in [5, 7, 9, 11]:
            assert_equal(layout.hud_texts[index], "—", "Future HUD value stays inactive")
        assert_equal(layout.result_texts[0], "SESSION COMPLETE", "Result title stays noninteractive")
        assert_equal(layout.result_texts[2], "Settlement is not available in this milestone.", "No settlement action text")
        assert_equal(shell.find_children("*", "Button", true, false).size(), 0, "No restart or action button exists")
        shell.free()
    app.free()


func run() -> PackedStringArray:
    var guard_app = _new_app()
    if guard_app == null:
        return finish()
    var guard_view = guard_app.get_node("SessionShell").get_track_field_view()
    if not guard_view.has_method("get_render_observation"):
        assert_true(false, "TrackFieldView must expose built track render observation")
        guard_app.free()
        return finish()
    var guard_observation: Dictionary = guard_view.get_render_observation()
    if not guard_observation.has("built_route"):
        assert_true(false, "TrackFieldView must expose built track render observation")
        guard_app.free()
        return finish()
    guard_app.free()

    _test_composition_and_detachment()
    _test_runtime_candidate_and_snapshot_presentation()
    _test_hud_and_pure_render_values()
    _test_hover_projection_and_clearing()
    _test_results_and_inactive_future_surface()
    return finish()
