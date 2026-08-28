extends SceneTree

const SCENE_PATH := "res://tests/integration/warp_cargo_app.tscn"
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")

const ROUTE_CELLS: Array[Vector2i] = [
    Vector2i(6, 2), Vector2i(7, 2), Vector2i(7, 3), Vector2i(7, 4), Vector2i(7, 5),
    Vector2i(7, 6), Vector2i(7, 7), Vector2i(7, 8), Vector2i(7, 9), Vector2i(7, 10),
    Vector2i(6, 10), Vector2i(5, 10), Vector2i(4, 10), Vector2i(3, 10),
    Vector2i(2, 10), Vector2i(1, 10), Vector2i(0, 10), Vector2i(0, 9),
    Vector2i(0, 8), Vector2i(0, 7), Vector2i(0, 6), Vector2i(1, 6),
    Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(4, 5),
    Vector2i(4, 4), Vector2i(4, 3), Vector2i(4, 2), Vector2i(4, 1), Vector2i(4, 0),
    Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0),
    Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0), Vector2i(11, 1),
    Vector2i(11, 2), Vector2i(11, 3), Vector2i(11, 4), Vector2i(11, 5),
    Vector2i(11, 6), Vector2i(11, 7), Vector2i(11, 8), Vector2i(11, 9),
]

const EXPECTED_EVENT_TICKS := {
    1: ["FORECASTED:warp_pair_1:-1:0"],
    3: ["ACTIVATED:warp_pair_1:-1:0"],
    4: ["LOADED:warp_pair_1:0:0"],
    6: ["FORECASTED:warp_pair_2:-1:0"],
    8: ["ACTIVATED:warp_pair_2:-1:0"],
    10: ["LOADED:warp_pair_2:1:0"],
    11: ["FORECASTED:warp_pair_3:-1:0"],
    13: ["ACTIVATED:warp_pair_3:-1:0"],
    120: ["EXPIRED:warp_pair_1:0:0"],
    121: ["FORECASTED:warp_pair_4:-1:0"],
    123: ["ACTIVATED:warp_pair_4:-1:0"],
    124: ["LOADED:warp_pair_4:0:0"],
    139: ["DELIVERED:warp_pair_2:1:37", "VOIDED:warp_pair_3:-1:0", "VOIDED:warp_pair_4:0:0"],
}

const EXPECTED_STATE_TRACE := [
    {"tick": 1, "state": "RUNNING", "pairs": ["warp_pair_1:FORECAST:0:F2:L118"], "occupied": 0, "delivered": 0, "reward": 0},
    {"tick": 3, "state": "RUNNING", "pairs": ["warp_pair_1:ACTIVE_UNLOADED:0:F0:L117"], "occupied": 0, "delivered": 0, "reward": 0},
    {"tick": 4, "state": "RUNNING", "pairs": ["warp_pair_1:IN_TRANSIT:0:F0:L116"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 8, "state": "RUNNING", "pairs": ["warp_pair_1:IN_TRANSIT:0:F0:L112", "warp_pair_2:ACTIVE_UNLOADED:1:F0:L131"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 10, "state": "RUNNING", "pairs": ["warp_pair_1:IN_TRANSIT:0:F0:L110", "warp_pair_2:IN_TRANSIT:1:F0:L129"], "occupied": 2, "delivered": 0, "reward": 0},
    {"tick": 13, "state": "RUNNING", "pairs": ["warp_pair_1:IN_TRANSIT:0:F0:L107", "warp_pair_2:IN_TRANSIT:1:F0:L126", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L152"], "occupied": 2, "delivered": 0, "reward": 0},
    {"tick": 64, "state": "RUNNING", "pairs": ["warp_pair_1:IN_TRANSIT:0:F0:L56", "warp_pair_2:IN_TRANSIT:1:F0:L75", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L101"], "occupied": 2, "delivered": 0, "reward": 0},
    {"tick": 119, "state": "RUNNING", "pairs": ["warp_pair_1:IN_TRANSIT:0:F0:L1", "warp_pair_2:IN_TRANSIT:1:F0:L20", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L46"], "occupied": 2, "delivered": 0, "reward": 0},
    {"tick": 120, "state": "RUNNING", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:IN_TRANSIT:1:F0:L19", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L45"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 121, "state": "RUNNING", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:IN_TRANSIT:1:F0:L18", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L44", "warp_pair_4:FORECAST:0:F2:L159"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 123, "state": "RUNNING", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:IN_TRANSIT:1:F0:L16", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L42", "warp_pair_4:ACTIVE_UNLOADED:0:F0:L158"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 124, "state": "RUNNING", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:IN_TRANSIT:1:F0:L15", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L41", "warp_pair_4:IN_TRANSIT:0:F0:L157"], "occupied": 2, "delivered": 0, "reward": 0},
    {"tick": 138, "state": "RUNNING", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:IN_TRANSIT:1:F0:L1", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L27", "warp_pair_4:IN_TRANSIT:0:F0:L143"], "occupied": 2, "delivered": 0, "reward": 0},
    {"tick": 139, "state": "COMPLETED", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:DELIVERED:1:F0:L1", "warp_pair_3:VOIDED:2:F0:L26", "warp_pair_4:VOIDED:0:F0:L142"], "occupied": 0, "delivered": 1, "reward": 37},
]

var _failures := PackedStringArray()


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var packed := load(SCENE_PATH) as PackedScene
    _assert_true(packed != null, "Warp Cargo app scene loads")
    if packed == null:
        _finish()
        return
    var app = packed.instantiate()
    root.add_child(app)
    app.set_physics_process(false)
    await process_frame
    app.set_physics_process(false)

    _assert_equal(app.startup_seed, 73013, "Scene uses the fixed seed")
    _assert_equal(app.session_start_config.grid_size, Vector2i(12, 12), "Scene uses the custom grid")
    _assert_true(app.session_start_config.grid_origin_units.is_equal_approx(Vector2(160.0, 0.0)), "Scene uses centered logical mapping")
    _assert_equal(app.session_start_config.departure_cell, Vector2i(5, 2), "Scene authors the deterministic departure cell")

    var controller = app.session_controller
    var shell = app.get_node("SessionShell")
    var view = shell.get_track_field_view()
    var actual_events_by_tick: Array = []
    var actual_state_trace: Array[Dictionary] = []
    var trace_ticks := {1: true, 3: true, 4: true, 8: true, 10: true, 13: true, 64: true, 119: true, 120: true, 121: true, 123: true, 124: true, 138: true, 139: true}
    var results: Array = []
    var result_observer := func(result): results.append(result)
    app.session_result_presented.connect(result_observer)

    for tick in range(1, 140):
        var frame = _route_frame() if tick == 1 else TrackInputFrameScript.empty()
        var previous_train_distance: float = controller.get_snapshot().get_train_route_distance_cells()
        controller.advance_tick(frame)
        var snapshot = controller.get_snapshot()
        actual_events_by_tick.append(_event_signatures(snapshot))
        if trace_ticks.has(tick):
            actual_state_trace.append(_state_trace_entry(tick, snapshot))

        if tick == 1:
            var field_observation: Dictionary = view.get_render_observation()
            _assert_true(field_observation.has("warp_endpoints"), "Real field exposes forecast endpoints")
            if field_observation.has("warp_endpoints") and not field_observation.warp_endpoints.is_empty():
                var forecast_origin: Dictionary = field_observation.warp_endpoints[0]
                _assert_equal(forecast_origin.alpha, 0.35, "Real forecast is low alpha")
                _assert_equal(forecast_origin.countdown_text, "F 1s", "Real forecast countdown is readable")
                _assert_true(forecast_origin.position.is_equal_approx(Vector2(360.0, 66.6666667)), "Real endpoint uses logical grid center")
        if tick == 10:
            _assert_equal(_cargo_text(shell), "2 / 2", "Real HUD shows full cargo")
        if tick == 64:
            var tick_pairs: Array = snapshot.get_warp_pair_records()
            var sweep_anchor_ids := _hit_anchor_ids(app.track_system.get_contact_hits_between(
                previous_train_distance,
                snapshot.get_train_route_distance_cells()
            ))
            _assert_true(sweep_anchor_ids.has(&"warp_pair_3/origin"), "Full-slot tick crosses pair three origin in the real route sweep")
            _assert_equal(snapshot.get_occupied_cargo_slots(), 2, "Full-slot sweep begins with both cargo slots occupied")
            _assert_true(tick_pairs.size() >= 3, "Full-slot tick retains pair three")
            if tick_pairs.size() >= 3:
                _assert_equal(tick_pairs[2].state, WarpPairRecordScript.State.ACTIVE_UNLOADED, "Full-slot origin contact leaves pair three unloaded")
                _assert_true(not _event_signatures(snapshot).has("LOADED:warp_pair_3:0:0"), "Full-slot origin contact emits no load event")
        if tick == 120:
            _assert_equal(_cargo_text(shell), "1 / 2", "Expiry clears one real cargo slot")
        if tick == 124:
            _assert_equal(_cargo_text(shell), "2 / 2", "Mixed-slot load refills the lowest empty slot")
        if tick == 139:
            _assert_equal(_reward_text(shell), "37", "Final-life delivery updates base reward immediately")

    _assert_equal(actual_events_by_tick, _expected_events_by_tick(), "Every fixed-seed tick produces the approved event trace")
    _assert_equal(actual_state_trace, EXPECTED_STATE_TRACE, "Fixed seed produces the approved state and lifetime trace")
    _assert_equal(results.size(), 1, "Regular completion presents one result")
    _assert_equal(controller.get_state(), SessionControllerScript.State.COMPLETED, "Trace ends by regular completion")
    _assert_equal(_cargo_text(shell), "0 / 2", "Regular end clears the cargo HUD")
    _assert_equal(_reward_text(shell), "37", "Regular end retains earned reward")
    _assert_true(shell.get_layout_observation().hud_texts.has("BASE REWARD"), "Cash placeholder is renamed BASE REWARD")
    _assert_true(shell.has_method("get_cargo_slot_strip"), "Real shell exposes the cargo slot strip")
    if shell.has_method("get_cargo_slot_strip"):
        var strip = shell.get_cargo_slot_strip()
        _assert_true(strip != null, "Real shell contains the cargo slot strip")
        if strip != null:
            _assert_equal(strip.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Cargo strip never intercepts input")
            _assert_equal(strip.get_render_observation().occupied, 0, "Regular end clears rendered slots")
    var terminal_field: Dictionary = view.get_render_observation()
    _assert_true(terminal_field.has("warp_endpoints"), "Terminal field exposes endpoint observations")
    if terminal_field.has("warp_endpoints"):
        _assert_equal(terminal_field.warp_endpoints.size(), 1, "Regular end clears live endpoints but retains the same-tick delivery brief")
        if terminal_field.warp_endpoints.size() == 1:
            _assert_equal(terminal_field.warp_endpoints[0].pair_id, &"warp_pair_2", "Terminal delivery brief belongs to the delivered pair")
            _assert_equal(terminal_field.warp_endpoints[0].role, &"destination", "Terminal delivery brief marks the destination")
            _assert_true(terminal_field.warp_endpoints[0].filled, "Terminal delivery brief is filled")

    app.session_result_presented.disconnect(result_observer)
    app.queue_free()
    await process_frame
    _finish()


func _route_frame() -> TrackInputFrameScript:
    return TrackInputFrameScript.new(
        ROUTE_CELLS,
        Vector2i(5, 2),
        true,
        Vector2i(-1, -1),
        false,
        true,
        false,
        true,
        false,
        ROUTE_CELLS[-1],
        true
    )


func _event_signatures(snapshot) -> Array[String]:
    var events: Array[String] = []
    for event in snapshot.get_warp_cargo_events():
        events.append("%s:%s:%d:%d" % [event.type, event.pair_id, event.slot_index, event.amount])
    return events


func _hit_anchor_ids(hits: Array[Dictionary]) -> Array[StringName]:
    var anchor_ids: Array[StringName] = []
    for hit in hits:
        anchor_ids.append(StringName(hit.anchor_id))
    return anchor_ids


func _expected_events_by_tick() -> Array:
    var expected: Array = []
    for tick in range(1, 140):
        expected.append(EXPECTED_EVENT_TICKS.get(tick, []))
    return expected


func _state_trace_entry(tick: int, snapshot) -> Dictionary:
    var pairs: Array[String] = []
    for pair in snapshot.get_warp_pair_records():
        pairs.append("%s:%s:%d:F%d:L%d" % [
            pair.pair_id,
            WarpPairRecordScript.State.keys()[pair.state],
            pair.style_index,
            pair.forecast_remaining_ticks,
            pair.lifetime_remaining_ticks,
        ])
    return {
        "tick": tick,
        "state": SessionControllerScript.State.keys()[snapshot.get_state()],
        "pairs": pairs,
        "occupied": snapshot.get_occupied_cargo_slots(),
        "delivered": snapshot.get_delivered_pair_count(),
        "reward": snapshot.get_base_delivery_reward_total(),
    }


func _cargo_text(shell) -> String:
    return shell.get_node("OuterMargin/MainColumn/BottomHud/BottomContent/BottomItems/CargoItem/CargoText/CargoValue").text


func _reward_text(shell) -> String:
    return shell.get_node("OuterMargin/MainColumn/TopHud/TopContent/TopItems/CashItem/CashText/CashValue").text


func _assert_true(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        _failures.append("%s | expected=%s actual=%s" % [message, expected, actual])


func _finish() -> void:
    if _failures.is_empty():
        print("PASS: warp cargo integration")
        quit(0)
        return
    for failure in _failures:
        push_error(failure)
    print("FAIL: %d warp cargo integration assertion(s)" % _failures.size())
    quit(1)
