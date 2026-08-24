extends SceneTree

const APP_SCENE_PATH := "res://src/app/prototype_app.tscn"
const NONDEFAULT_SCENE_PATH := "res://tests/integration/nondefault_track_train_app.tscn"
const INVALID_SCENE_PATH := "res://tests/integration/invalid_track_train_app.tscn"
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")

var _failures := PackedStringArray()
var _app_scene: PackedScene
var _nondefault_scene: PackedScene
var _invalid_scene: PackedScene


func _initialize() -> void:
    call_deferred("_run")


func _fresh_app(scene: PackedScene):
    var app = scene.instantiate()
    app.balance = app.balance.duplicate(true)
    app.balance.session_balance = app.balance.session_balance.duplicate(true)
    app.balance.train_balance = app.balance.train_balance.duplicate(true)
    app.balance.track_inventory_balance = app.balance.track_inventory_balance.duplicate(true)
    app.balance.track_construction_balance = app.balance.track_construction_balance.duplicate(true)
    app.balance.departure_balance = app.balance.departure_balance.duplicate(true)
    app.layout_profile = app.layout_profile.duplicate(true)
    return app


func _draw_frame(config, length: float) -> TrackInputFrameScript:
    var direction := _horizontal_direction(config)
    var target: Vector2 = config.departure_position + Vector2(direction * length, 0.0)
    return TrackInputFrameScript.new(
        target,
        true,
        true,
        true,
        false,
        false,
        config.departure_position,
        true
    )


func _held_frame(config, endpoint: Vector2, length: float) -> TrackInputFrameScript:
    var target := endpoint + Vector2(_horizontal_direction(config) * length, 0.0)
    return TrackInputFrameScript.new(
        target,
        true,
        false,
        true,
        false,
        false,
        Vector2.ZERO,
        false
    )


func _horizontal_direction(config) -> float:
    if config.logical_field_size.x - config.departure_position.x >= config.departure_position.x:
        return 1.0
    return -1.0


func _snapshot_signature(snapshot) -> Dictionary:
    return {
        "state": snapshot.get_state(),
        "total_ticks": snapshot.get_total_ticks(),
        "elapsed": snapshot.get_elapsed_ticks(),
        "remaining": snapshot.get_remaining_ticks(),
        "ticks_per_second": snapshot.get_ticks_per_second(),
        "has_track_train_data": snapshot.has_track_train_data(),
        "built": snapshot.get_built_route(),
        "reserved": snapshot.get_reserved_route(),
        "head": snapshot.get_construction_head(),
        "train_active": snapshot.is_train_active(),
        "train_position": snapshot.get_train_position(),
        "train_heading": snapshot.get_train_heading(),
        "available": snapshot.get_available_track_units(),
        "total": snapshot.get_total_track_units(),
        "departure_built": snapshot.get_departure_built_units(),
        "departure_required": snapshot.get_departure_required_units(),
        "built_ahead": snapshot.get_built_distance_ahead(),
        "warning_seconds": snapshot.get_estimated_track_end_seconds(),
        "urgent": snapshot.is_track_end_warning_urgent(),
        "selected_departure_candidate_id": snapshot.get_selected_departure_candidate_id(),
    }


func _assert_error(errors: PackedStringArray, fragment: String, message: String) -> void:
    var found := false
    for error_message in errors:
        found = found or error_message.contains(fragment)
    _assert_true(found, "%s | errors=%s" % [message, errors])


func _assert_no_domain(app, message: String) -> void:
    _assert_equal(app.session_start_config, null, message + " config")
    _assert_equal(app.session_rng, null, message + " RNG")
    _assert_equal(app.track_system, null, message + " track")
    _assert_equal(app.train_system, null, message + " train")
    _assert_equal(app.session_controller, null, message + " controller")


func _left_input(
    cursor_position: Vector2,
    left_pressed: bool,
    press_position: Vector2
) -> TrackInputFrameScript:
    return TrackInputFrameScript.new(
        cursor_position,
        true,
        left_pressed,
        true,
        false,
        false,
        press_position,
        true
    )


func _right_input(position: Vector2) -> TrackInputFrameScript:
    return TrackInputFrameScript.new(
        position,
        true,
        false,
        false,
        false,
        true,
        Vector2.ZERO,
        false,
        position,
        true
    )


func _verify_nondefault_geometry_behavior(config) -> void:
    var epsilon: float = TrackSystemScript.GEOMETRY_EPSILON
    var departure: Vector2 = config.departure_position
    var horizontal := Vector2(_horizontal_direction(config), 0.0)

    var rejected_grab = TrackSystemScript.new(config)
    rejected_grab.apply_left_input(_left_input(
        departure + horizontal * 30.0,
        true,
        departure + horizontal * (config.endpoint_grab_radius_units + epsilon)
    ))
    _assert_close(
        rejected_grab.get_reserved_end_distance(),
        0.0,
        "Press beyond nondefault endpoint radius must be rejected"
    )

    var sampled = TrackSystemScript.new(config)
    sampled.apply_left_input(_left_input(
        departure + horizontal * (config.minimum_sample_distance_units - epsilon),
        true,
        departure + horizontal * config.endpoint_grab_radius_units
    ))
    _assert_true(sampled.is_stroke_active(), "Exact nondefault endpoint radius must start a stroke")
    _assert_close(
        sampled.get_reserved_end_distance(),
        0.0,
        "Sample below nondefault minimum distance must be ignored"
    )
    sampled.apply_left_input(_left_input(
        departure + horizontal * config.minimum_sample_distance_units,
        false,
        Vector2.ZERO
    ))
    _assert_close(
        sampled.get_reserved_end_distance(),
        config.minimum_sample_distance_units,
        "Exact nondefault minimum sample distance must reserve"
    )

    var missed_cut = TrackSystemScript.new(config)
    missed_cut.apply_left_input(_left_input(
        departure + horizontal * 30.0,
        true,
        departure
    ))
    var perpendicular := Vector2(0.0, 1.0)
    if departure.y + config.route_hit_radius_units + epsilon > config.logical_field_size.y:
        perpendicular = Vector2(0.0, -1.0)
    missed_cut.apply_right_input(_right_input(
        departure + horizontal * 15.0
            + perpendicular * (config.route_hit_radius_units + epsilon)
    ))
    _assert_close(
        missed_cut.get_reserved_end_distance(),
        30.0,
        "Press beyond nondefault route hit radius must not cancel"
    )

    var exact_cut = TrackSystemScript.new(config)
    exact_cut.apply_left_input(_left_input(
        departure + horizontal * 30.0,
        true,
        departure
    ))
    exact_cut.apply_right_input(_right_input(
        departure + horizontal * 15.0
            + perpendicular * config.route_hit_radius_units
    ))
    _assert_close(
        exact_cut.get_reserved_end_distance(),
        15.0,
        "Exact nondefault route hit radius must cancel at projection"
    )

    var vertical := Vector2(0.0, 1.0)
    if departure.y + 40.0 > config.logical_field_size.y:
        vertical = Vector2(0.0, -1.0)
    var clearance_track = TrackSystemScript.new(config)
    var first := departure + horizontal * 40.0
    var second := first + vertical * 40.0
    var third := departure + vertical * 40.0
    clearance_track.apply_left_input(_left_input(first, true, departure))
    clearance_track.apply_left_input(_left_input(second, false, Vector2.ZERO))
    clearance_track.apply_left_input(_left_input(third, false, Vector2.ZERO))
    clearance_track.apply_left_input(_left_input(
        departure - vertical * 10.0,
        false,
        Vector2.ZERO
    ))
    _assert_close(
        clearance_track.get_reserved_end_distance(),
        160.0 - config.intersection_clearance_units,
        "Nondefault intersection clearance must clip before contact"
    )
    _assert_true(
        clearance_track.get_reserved_endpoint().distance_to(
            departure + vertical * config.intersection_clearance_units
        ) <= epsilon,
        "Nondefault clearance must determine the clipped endpoint"
    )


func _verify_nondefault_copy_contract() -> void:
    var app = _fresh_app(_nondefault_scene)
    var errors: PackedStringArray = app.compose_session_dependencies()
    _assert_equal(errors, PackedStringArray(), "Nondefault app must compose outside the tree")
    if not errors.is_empty():
        app.free()
        return
    var config = app.session_start_config
    _assert_close(config.session_duration_seconds, 4.0, "Copied duration")
    _assert_equal(config.simulation_ticks_per_second, 10, "Copied ticks per second")
    _assert_close(config.train_speed_units_per_second, 25.0, "Copied train speed")
    _assert_close(config.total_track_units, 200.0, "Copied total inventory")
    _assert_close(config.recovery_distance_units, 40.0, "Copied recovery distance")
    _assert_close(config.urgent_warning_seconds, 1.5, "Copied warning threshold")
    _assert_close(config.construction_speed_units_per_second, 50.0, "Copied construction speed")
    _assert_close(config.endpoint_grab_radius_units, 18.0, "Copied endpoint radius")
    _assert_close(config.route_hit_radius_units, 12.0, "Copied route hit radius")
    _assert_close(config.minimum_sample_distance_units, 6.0, "Copied sample distance")
    _assert_close(config.intersection_clearance_units, 3.0, "Copied clearance")
    _assert_close(config.departure_required_built_units, 50.0, "Copied departure requirement")
    var fresh_rng = SessionRngScript.new(config.seed)
    _assert_equal(app.session_rng.next_u32(), fresh_rng.next_u32(), "Composition must not consume public RNG")

    var expected_values := [
        config.session_duration_seconds,
        config.simulation_ticks_per_second,
        config.train_speed_units_per_second,
        config.total_track_units,
        config.recovery_distance_units,
        config.urgent_warning_seconds,
        config.construction_speed_units_per_second,
        config.endpoint_grab_radius_units,
        config.route_hit_radius_units,
        config.minimum_sample_distance_units,
        config.intersection_clearance_units,
        config.departure_required_built_units,
    ]
    var initial_snapshot = app.session_controller.get_snapshot()
    app.balance.session_balance.session_duration_seconds = 99.0
    app.balance.session_balance.simulation_ticks_per_second = 20
    app.balance.train_balance.speed_units_per_second = 99.0
    app.balance.track_inventory_balance.total_units = 999.0
    app.balance.track_inventory_balance.recovery_distance_units = 99.0
    app.balance.track_inventory_balance.urgent_warning_seconds = 9.0
    app.balance.track_construction_balance.speed_units_per_second = 99.0
    app.balance.track_construction_balance.endpoint_grab_radius_units = 24.0
    app.balance.track_construction_balance.route_hit_radius_units = 16.0
    app.balance.track_construction_balance.minimum_sample_distance_units = 8.0
    app.balance.track_construction_balance.intersection_clearance_units = 4.0
    app.balance.departure_balance.required_built_units = 99.0
    _assert_equal(
        [
            config.session_duration_seconds,
            config.simulation_ticks_per_second,
            config.train_speed_units_per_second,
            config.total_track_units,
            config.recovery_distance_units,
            config.urgent_warning_seconds,
            config.construction_speed_units_per_second,
            config.endpoint_grab_radius_units,
            config.route_hit_radius_units,
            config.minimum_sample_distance_units,
            config.intersection_clearance_units,
            config.departure_required_built_units,
        ],
        expected_values,
        "Source Resource mutation must not change copied config"
    )
    _assert_equal(app.session_controller.get_snapshot(), initial_snapshot, "Resource mutation must not change controller")
    _assert_close(app.track_system.get_total_units(), 200.0, "Resource mutation must not change domain inventory")
    _verify_nondefault_geometry_behavior(config)

    var repeat = _fresh_app(_nondefault_scene)
    _assert_equal(repeat.compose_session_dependencies(), PackedStringArray(), "Repeated composition")
    _assert_equal(
        repeat.session_start_config.departure_candidate_id,
        config.departure_candidate_id,
        "Equal seed must select the same candidate"
    )
    repeat.free()
    app.free()


func _verify_track_end_lifecycle() -> void:
    var app = _fresh_app(_nondefault_scene)
    var presented_results := []
    app.session_result_presented.connect(func(result) -> void: presented_results.append(result))
    root.add_child(app)
    app.set_physics_process(false)
    await process_frame
    var config = app.session_start_config
    var controller = app.session_controller
    var track = app.track_system
    var train = app.train_system
    var shell = app.get_node("SessionShell")
    var view = shell.get_track_field_view()
    var hidden_candidates := 0
    for candidate in view.get_logical_track_field().get_node("DepartureCandidates").get_children():
        if not candidate.visible:
            hidden_candidates += 1
    _assert_equal(hidden_candidates, 8, "All authoring candidates must be hidden at runtime")
    var render: Dictionary = view.get_render_observation()
    _assert_equal(render.selected_departure_id, config.departure_candidate_id, "Render observation selected ID")
    _assert_equal(render.selected_departure_position, config.departure_position, "Render observation selected position")

    controller.advance_tick(_draw_frame(config, 50.0))
    _assert_close(track.get_reserved_end_distance(), 50.0, "Logical draw reserves fifty units")
    _assert_close(track.get_built_end_distance(), 5.0, "First nondefault construction increment")
    _assert_close(track.get_available_units(), 150.0, "Reservation immediately spends inventory")
    _assert_equal(controller.get_state(), SessionControllerScript.State.PREPARING_DEPARTURE, "Below threshold remains preparation")
    _assert_equal(controller.get_snapshot().get_elapsed_ticks(), 0, "Preparation freezes timer")
    var prep_layout: Dictionary = shell.get_layout_observation()
    _assert_equal(prep_layout.hud_texts[3], "150.0 / 200.0", "Preparation inventory HUD")
    _assert_equal(prep_layout.hud_texts[13], "5.0 / 50.0", "Preparation progress HUD")

    var preparation_ticks := 1
    while controller.get_state() == SessionControllerScript.State.PREPARING_DEPARTURE and preparation_ticks < 12:
        var built_before: float = track.get_built_end_distance()
        controller.advance_tick(TrackInputFrameScript.empty())
        preparation_ticks += 1
        _assert_close(
            track.get_built_end_distance() - built_before,
            5.0,
            "Construction advances five units per fixed tick"
        )
    _assert_equal(preparation_ticks, 10, "Exactly ten construction ticks reach departure")
    _assert_equal(controller.get_state(), SessionControllerScript.State.RUNNING, "Exact threshold enters running")
    _assert_close(train.get_route_distance(), 2.5, "Threshold tick moves train 2.5 units")
    _assert_equal(controller.get_snapshot().get_elapsed_ticks(), 1, "Threshold tick starts timer")
    _assert_true(controller.get_snapshot().is_train_active(), "Threshold tick activates train")
    _assert_equal(shell.get_layout_observation().hud_texts[13], "1.9 s", "Running HUD shows built-end seconds")

    var warning_seen: bool = controller.get_snapshot().is_track_end_warning_urgent()
    var recovery_seen := false
    var recovery_funded_draw := false
    var previous_available: float = track.get_available_units()
    var safety := 40
    while controller.get_state() == SessionControllerScript.State.RUNNING and safety > 0:
        if recovery_seen and not recovery_funded_draw and track.get_available_units() >= 156.0:
            var reserved_before: float = track.get_reserved_end_distance()
            var available_before: float = track.get_available_units()
            controller.advance_tick(_held_frame(config, track.get_reserved_endpoint(), 6.0))
            _assert_close(track.get_reserved_end_distance() - reserved_before, 6.0, "Prior recovery funds next-tick drawing")
            _assert_true(track.get_available_units() < available_before, "Recovered inventory is spent by the later draw")
            recovery_funded_draw = true
        else:
            var train_before: float = train.get_route_distance()
            controller.advance_tick(TrackInputFrameScript.empty())
            if controller.get_state() != SessionControllerScript.State.COMPLETED:
                _assert_close(train.get_route_distance() - train_before, 2.5, "Running movement is 2.5 units per tick")
        var snapshot = controller.get_snapshot()
        warning_seen = warning_seen or snapshot.is_track_end_warning_urgent()
        if track.get_available_units() > previous_available + TrackSystemScript.GEOMETRY_EPSILON:
            recovery_seen = true
        previous_available = track.get_available_units()
        safety -= 1
    _assert_true(warning_seen, "Nondefault 1.5-second urgent warning must appear")
    _assert_true(recovery_seen, "Rear recovery must return inventory after train passes forty units")
    _assert_true(recovery_funded_draw, "Recovered inventory must become drawable on the following tick")
    _assert_equal(controller.get_state(), SessionControllerScript.State.COMPLETED, "Short built route must complete")
    _assert_equal(presented_results.size(), 1, "Track end result presents exactly once")
    if presented_results.size() == 1:
        _assert_equal(presented_results[0].get_reason(), SessionResultScript.Reason.TRACK_END_REACHED, "Track-end result reason")
        _assert_equal(shell.get_layout_observation().result_texts[1], "TRACK END REACHED", "Track-end presentation text")
        app.present_session_result(presented_results[0])
        for _index in range(3):
            controller.advance_tick()
        _assert_equal(presented_results.size(), 1, "Track-end presentation remains one-shot")
    app.queue_free()
    await process_frame


func _verify_regular_lifecycle() -> void:
    var app = _fresh_app(_nondefault_scene)
    var presented_results := []
    app.session_result_presented.connect(func(result) -> void: presented_results.append(result))
    root.add_child(app)
    app.set_physics_process(false)
    await process_frame
    var config = app.session_start_config
    var controller = app.session_controller
    controller.advance_tick(_draw_frame(config, 150.0))
    var safety := 60
    while controller.get_state() != SessionControllerScript.State.COMPLETED and safety > 0:
        controller.advance_tick(TrackInputFrameScript.empty())
        safety -= 1
    _assert_equal(controller.get_state(), SessionControllerScript.State.COMPLETED, "Long route completes within bound")
    _assert_equal(presented_results.size(), 1, "Regular result presents exactly once")
    if presented_results.size() == 1:
        _assert_equal(presented_results[0].get_reason(), SessionResultScript.Reason.REGULAR_TIME_EXPIRED, "Forty running ticks expire regularly")
        _assert_equal(app.get_node("SessionShell").get_layout_observation().result_texts[1], "REGULAR TIME EXPIRED", "Regular presentation text")
        app.present_session_result(presented_results[0])
        _assert_equal(presented_results.size(), 1, "Regular presentation remains one-shot")
    app.queue_free()
    await process_frame


func _invalid_logical_case(fragment: String, mutate: Callable) -> void:
    var app = _fresh_app(_app_scene)
    var field = app.get_node("SessionShell").get_track_field_view().get_logical_track_field()
    mutate.call(field)
    var errors: PackedStringArray = app.compose_session_dependencies()
    _assert_error(errors, "logical_track_field", "%s error must own logical field" % fragment)
    _assert_error(errors, fragment, "%s error must name exact field" % fragment)
    _assert_no_domain(app, "%s invalid composition" % fragment)
    app.free()


func _verify_startup_validation() -> void:
    var invalid = _fresh_app(_invalid_scene)
    var invalid_errors: PackedStringArray = invalid.compose_session_dependencies()
    _assert_error(invalid_errors, "track_inventory_balance.recovery_distance_units", "Invalid fixture exact owner field")
    _assert_no_domain(invalid, "Invalid inventory fixture")
    invalid.free()

    var missing = _fresh_app(_app_scene)
    missing.balance.train_balance = null
    var missing_errors: PackedStringArray = missing.compose_session_dependencies()
    _assert_error(missing_errors, "prototype_balance.train_balance.resource", "Missing feature Resource ownership")
    _assert_no_domain(missing, "Missing train Resource")
    missing.free()

    var numeric = _fresh_app(_app_scene)
    numeric.balance.track_construction_balance.speed_units_per_second = 0.0
    var numeric_errors: PackedStringArray = numeric.compose_session_dependencies()
    _assert_error(
        numeric_errors,
        "prototype_balance.track_construction_balance.speed_units_per_second",
        "Invalid positive field ownership"
    )
    _assert_no_domain(numeric, "Invalid construction speed")
    numeric.free()

    _invalid_logical_case("custom_width", func(field) -> void:
        field.size_preset = field.SizePreset.CUSTOM
        field.custom_width = 639.0
    )
    _invalid_logical_case("custom_height", func(field) -> void:
        field.size_preset = field.SizePreset.CUSTOM
        field.custom_height = 319.0
    )
    _invalid_logical_case("DepartureCandidates", func(field) -> void:
        var parent = field.get_node("DepartureCandidates")
        for child in parent.get_children():
            parent.remove_child(child)
            child.free()
    )
    _invalid_logical_case("logical_track_field.DepartureCandidates/Departure01.candidate_id", func(field) -> void:
        field.get_node("DepartureCandidates").get_child(0).candidate_id = StringName()
    )
    _invalid_logical_case("logical_track_field.DepartureCandidates/Departure02.candidate_id", func(field) -> void:
        var parent = field.get_node("DepartureCandidates")
        parent.get_child(1).candidate_id = parent.get_child(0).candidate_id
    )
    _invalid_logical_case("logical_track_field.DepartureCandidates/Departure01.position", func(field) -> void:
        field.get_node("DepartureCandidates").get_child(0).position = Vector2(-1.0, 20.0)
    )


func _run_replay(viewport_size: Vector2i) -> Dictionary:
    var previous_size: Vector2i = root.size
    root.size = viewport_size
    var app = _fresh_app(_nondefault_scene)
    root.add_child(app)
    app.set_physics_process(false)
    await process_frame
    var config = app.session_start_config
    var controller = app.session_controller
    var signatures := [_snapshot_signature(controller.get_snapshot())]
    var frames := [
        _draw_frame(config, 80.0),
        TrackInputFrameScript.empty(),
        TrackInputFrameScript.empty(),
        TrackInputFrameScript.empty(),
        TrackInputFrameScript.empty(),
        TrackInputFrameScript.empty(),
    ]
    for frame in frames:
        controller.advance_tick(frame)
        signatures.append(_snapshot_signature(controller.get_snapshot()))
    var result := {
        "selected": config.departure_candidate_id,
        "signatures": signatures,
    }
    app.queue_free()
    await process_frame
    root.size = previous_size
    await process_frame
    return result


func _verify_deterministic_replay() -> void:
    var compact: Dictionary = await _run_replay(Vector2i(960, 540))
    var expansive: Dictionary = await _run_replay(Vector2i(1920, 1080))
    _assert_equal(compact.selected, expansive.selected, "Viewport size must not change seeded candidate")
    _assert_equal(compact.signatures, expansive.signatures, "Viewport size must not change any domain snapshot signature")


func _run() -> void:
    _app_scene = load(APP_SCENE_PATH) as PackedScene
    _nondefault_scene = load(NONDEFAULT_SCENE_PATH) as PackedScene
    _invalid_scene = load(INVALID_SCENE_PATH) as PackedScene
    _assert_true(_app_scene != null, "Real app scene must load")
    _assert_true(_nondefault_scene != null, "Nondefault app scene must load")
    _assert_true(_invalid_scene != null, "Invalid app scene must load")
    if _app_scene == null or _nondefault_scene == null or _invalid_scene == null:
        await _finish()
        return

    var guard = _fresh_app(_nondefault_scene)
    var guard_view = guard.get_node("SessionShell").get_track_field_view()
    if not guard_view.has_method("get_render_observation"):
        push_error("TrackFieldView must expose track train app render observation")
        guard.free()
        quit(1)
        return
    var guard_observation: Dictionary = guard_view.get_render_observation()
    if not guard_observation.has("built_route"):
        push_error("TrackFieldView must expose track train app built_route")
        guard.free()
        quit(1)
        return
    guard.free()

    _verify_nondefault_copy_contract()
    await _verify_track_end_lifecycle()
    await _verify_regular_lifecycle()
    _verify_startup_validation()
    await _verify_deterministic_replay()
    await _finish()


func _finish() -> void:
    if _failures.is_empty():
        print("PASS: track train app lifecycle integration")
        print("PASS: track train startup validation integration")
        print("PASS: track train deterministic replay integration")
        quit(0)
        return
    for failure in _failures:
        push_error(failure)
    print("FAIL: %d track train app assertion(s)" % _failures.size())
    quit(1)


func _assert_true(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        _failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])


func _assert_close(actual: float, expected: float, message: String) -> void:
    if absf(actual - expected) > TrackSystemScript.GEOMETRY_EPSILON:
        _failures.append("%s | expected=%s actual=%s" % [message, expected, actual])
