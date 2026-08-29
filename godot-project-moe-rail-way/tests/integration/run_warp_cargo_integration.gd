extends SceneTree

const SCENE_PATH := "res://tests/integration/warp_cargo_app.tscn"
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")
const INTEGRATION_SEED := 73013

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
    6: ["FORECASTED:warp_pair_2:-1:0"],
    8: ["ACTIVATED:warp_pair_2:-1:0"],
    11: ["FORECASTED:warp_pair_3:-1:0", "LOADED:warp_pair_2:0:0"],
    13: ["ACTIVATED:warp_pair_3:-1:0"],
    120: ["EXPIRED:warp_pair_1:-1:0"],
    121: ["FORECASTED:warp_pair_4:-1:0"],
    123: ["ACTIVATED:warp_pair_4:-1:0"],
    126: ["LOADED:warp_pair_4:1:0"],
    139: ["EXPIRED:warp_pair_2:0:0", "VOIDED:warp_pair_3:-1:0", "VOIDED:warp_pair_4:1:0"],
}

const EXPECTED_STATE_TRACE := [
    {"tick": 1, "state": "RUNNING", "pairs": ["warp_pair_1:FORECAST:0:F2:L118"], "occupied": 0, "delivered": 0, "reward": 0},
    {"tick": 3, "state": "RUNNING", "pairs": ["warp_pair_1:ACTIVE_UNLOADED:0:F0:L117"], "occupied": 0, "delivered": 0, "reward": 0},
    {"tick": 4, "state": "RUNNING", "pairs": ["warp_pair_1:ACTIVE_UNLOADED:0:F0:L116"], "occupied": 0, "delivered": 0, "reward": 0},
    {"tick": 8, "state": "RUNNING", "pairs": ["warp_pair_1:ACTIVE_UNLOADED:0:F0:L112", "warp_pair_2:ACTIVE_UNLOADED:1:F0:L131"], "occupied": 0, "delivered": 0, "reward": 0},
    {"tick": 10, "state": "RUNNING", "pairs": ["warp_pair_1:ACTIVE_UNLOADED:0:F0:L110", "warp_pair_2:ACTIVE_UNLOADED:1:F0:L129"], "occupied": 0, "delivered": 0, "reward": 0},
    {"tick": 13, "state": "RUNNING", "pairs": ["warp_pair_1:ACTIVE_UNLOADED:0:F0:L107", "warp_pair_2:IN_TRANSIT:1:F0:L126", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L152"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 64, "state": "RUNNING", "pairs": ["warp_pair_1:ACTIVE_UNLOADED:0:F0:L56", "warp_pair_2:IN_TRANSIT:1:F0:L75", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L101"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 119, "state": "RUNNING", "pairs": ["warp_pair_1:ACTIVE_UNLOADED:0:F0:L1", "warp_pair_2:IN_TRANSIT:1:F0:L20", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L46"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 120, "state": "RUNNING", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:IN_TRANSIT:1:F0:L19", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L45"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 121, "state": "RUNNING", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:IN_TRANSIT:1:F0:L18", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L44", "warp_pair_4:FORECAST:0:F2:L159"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 123, "state": "RUNNING", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:IN_TRANSIT:1:F0:L16", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L42", "warp_pair_4:ACTIVE_UNLOADED:0:F0:L158"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 124, "state": "RUNNING", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:IN_TRANSIT:1:F0:L15", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L41", "warp_pair_4:ACTIVE_UNLOADED:0:F0:L157"], "occupied": 1, "delivered": 0, "reward": 0},
    {"tick": 138, "state": "RUNNING", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:IN_TRANSIT:1:F0:L1", "warp_pair_3:ACTIVE_UNLOADED:2:F0:L27", "warp_pair_4:IN_TRANSIT:0:F0:L143"], "occupied": 2, "delivered": 0, "reward": 0},
    {"tick": 139, "state": "COMPLETED", "pairs": ["warp_pair_1:EXPIRED:0:F0:L0", "warp_pair_2:EXPIRED:1:F0:L0", "warp_pair_3:VOIDED:2:F0:L26", "warp_pair_4:VOIDED:0:F0:L142"], "occupied": 0, "delivered": 0, "reward": 0},
]

const MANUAL_CHECKPOINT_TICKS: Array[int] = [1, 3, 11, 13, 64, 120, 121, 123, 126, 138, 139]
const MANUAL_EXPECTATIONS := {
    1: "Empty cargo; pair 1 forecast with low-alpha endpoints and F 1s.",
    3: "Pair 1 active: filled origin, outlined destination, 12s lifetime.",
    11: "Pair 2 loads at its exact origin center into slot 0.",
    13: "Pair 3 activates at its seeded cells without route correction.",
    64: "Impossible exact contacts remain unloaded without route correction.",
    120: "Pair 1 expires unloaded and cargo remains at 1 / 2.",
    121: "Pair 4 forecast appears at its original seeded cells.",
    123: "Pair 4 activates with the original lifetime facts.",
    126: "Pair 4 loads at its exact origin center into slot 1.",
    138: "Both loaded pairs remain in transit; pair 2 has one lifetime tick.",
    139: "Pair 2 expires before completion voids the remaining live pairs.",
}

var _failures := PackedStringArray()
var _manual_mode := false
var _manual_auto_advance := false
var _mouse_manual_mode := false
var _mouse_manual_auto := false
var _manual_checkpoint_ids: Array[String] = []
var _manual_layer: CanvasLayer
var _manual_panel: PanelContainer
var _manual_scroll: ScrollContainer
var _manual_label: Label
var _manual_button: Button
var _last_mouse_gesture_rejection: Dictionary = {}


func _initialize() -> void:
    var user_arguments := OS.get_cmdline_user_args()
    _manual_mode = user_arguments.has("--manual") or user_arguments.has("--manual-auto")
    _manual_auto_advance = user_arguments.has("--manual-auto")
    _mouse_manual_mode = user_arguments.has("--mouse-manual") or user_arguments.has("--mouse-manual-auto")
    _mouse_manual_auto = user_arguments.has("--mouse-manual-auto")
    call_deferred("_run")


func _run() -> void:
    _test_mouse_gesture_rejection_deduplication()
    var packed := load(SCENE_PATH) as PackedScene
    _assert_true(packed != null, "Warp Cargo app scene loads")
    if packed == null:
        _finish()
        return
    await _assert_real_scene_planning_cadence(packed)
    var app = packed.instantiate()
    if _mouse_manual_mode:
        _configure_mouse_manual_balance(app)
    root.add_child(app)
    if _mouse_manual_mode:
        await process_frame
        app.track_system._runtime.set_gesture_rejection_diagnostics_enabled(true)
        app.session_controller.snapshot_published.connect(
            _on_mouse_manual_snapshot.bind(app)
        )
        _assert_equal(app.session_start_config.session_duration_seconds, 90.0, "Mouse manual session lasts 90 seconds")
        _assert_equal(app.session_start_config.train_speed_cells_per_second, 1.5, "Mouse manual train speed is reduced")
        _assert_equal(app.session_start_config.recovery_lag_cells, 2, "Mouse manual recovery begins two cells behind")
        _assert_equal(app.session_start_config.warp_lifetime_min_ticks, 30, "Mouse manual minimum Warp lifetime is doubled")
        _assert_equal(app.session_start_config.warp_lifetime_max_ticks, 330, "Mouse manual maximum Warp lifetime is doubled")
        if not _failures.is_empty() or _mouse_manual_auto:
            app.queue_free()
            await process_frame
            _finish()
        else:
            DisplayServer.window_set_title("Warp Cargo Mouse Test | train 1.5 | recovery 2 | lifetime 3-33s | 90s")
            print("MOUSE MANUAL READY | duration=90 speed=1.5 recovery_lag=2 warp_lifetime=3.0..33.0")
        return
    app.set_physics_process(false)
    await process_frame
    app.set_physics_process(false)

    _assert_equal(app.startup_seed, INTEGRATION_SEED, "Scene uses the exact-center fixed seed")
    _assert_equal(app.session_start_config.grid_size, Vector2i(12, 12), "Scene uses the custom grid")
    _assert_true(app.session_start_config.grid_origin_units.is_equal_approx(Vector2(160.0, 0.0)), "Scene uses centered logical mapping")
    _assert_equal(app.session_start_config.departure_cell, Vector2i(5, 2), "Scene authors the deterministic departure cell")

    var controller = app.session_controller
    var shell = app.get_node("SessionShell")
    var view = shell.get_track_field_view()
    if _manual_mode:
        _create_manual_overlay(app)
    var actual_events_by_tick: Array = []
    var actual_state_trace: Array[Dictionary] = []
    var trace_ticks := {1: true, 3: true, 4: true, 8: true, 10: true, 13: true, 64: true, 119: true, 120: true, 121: true, 123: true, 124: true, 138: true, 139: true}
    var results: Array = []
    var result_observer := func(result): results.append(result)
    app.session_result_presented.connect(result_observer)

    for tick in range(1, 140):
        var frame = _route_frame() if tick == 1 else TrackInputFrameScript.empty()
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
        if tick == 126:
            _assert_equal(_cargo_text(shell), "2 / 2", "Real HUD shows full cargo")
        if tick == 120:
            _assert_equal(_cargo_text(shell), "1 / 2", "Unloaded expiry leaves occupied cargo unchanged")
        if tick == 139:
            _assert_equal(_reward_text(shell), "0", "Final-life expiry leaves base reward unchanged")

        if _manual_mode and tick in MANUAL_CHECKPOINT_TICKS:
            var result_overlay = shell.get_node("ResultOverlay")
            if tick == 139:
                result_overlay.hide()
            await _show_manual_checkpoint(str(tick), tick, snapshot)
            if tick == 139:
                result_overlay.show()
                await _show_manual_checkpoint(
                    "result",
                    tick,
                    snapshot,
                    "Regular end result retains reward 0 and contains no penalty or settlement action."
                )

    _assert_equal(actual_events_by_tick, _expected_events_by_tick(), "Every fixed-seed tick produces the approved event trace")
    _assert_equal(actual_state_trace, EXPECTED_STATE_TRACE, "Fixed seed produces the approved state and lifetime trace")
    _assert_equal(results.size(), 1, "Regular completion presents one result")
    _assert_equal(controller.get_state(), SessionControllerScript.State.COMPLETED, "Trace ends by regular completion")
    _assert_equal(_cargo_text(shell), "0 / 2", "Regular end clears the cargo HUD")
    _assert_equal(_reward_text(shell), "0", "Regular end retains the unchanged base reward")
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
        _assert_equal(terminal_field.warp_endpoints.size(), 0, "Regular end clears all live endpoints after the prior-tick delivery brief")
    if _manual_auto_advance:
        var expected_manual_ids: Array[String] = []
        for checkpoint_tick in MANUAL_CHECKPOINT_TICKS:
            expected_manual_ids.append(str(checkpoint_tick))
        expected_manual_ids.append("result")
        _assert_equal(_manual_checkpoint_ids, expected_manual_ids, "Manual driver visits every approved checkpoint")

    app.session_result_presented.disconnect(result_observer)
    app.queue_free()
    await process_frame
    _finish()


func _assert_real_scene_planning_cadence(packed: PackedScene) -> void:
    var cadence_app = packed.instantiate()
    root.add_child(cadence_app)
    cadence_app.set_physics_process(false)
    await process_frame
    cadence_app.set_physics_process(false)
    var controller = cadence_app.session_controller
    var track_field_view = cadence_app.get_node("SessionShell").get_track_field_view()
    controller.advance_tick(_route_frame())
    var endpoint: Vector2i = cadence_app.track_system.get_endpoint_cell()
    controller.advance_tick(_held_endpoint_frame(endpoint))
    var press = controller.get_snapshot()
    var press_presentation: Dictionary = track_field_view.get_render_observation()
    _assert_true(press.is_planning_slowdown_active(), "Real scene accepted press publishes planning active")
    _assert_equal(press.get_planning_time_scale_percent(), 25, "Real scene publishes configured 25 percent")
    _assert_true(press.did_advance_simulation_tick(), "Real scene accepted press remains a simulation tick")
    _assert_equal(press.get_elapsed_ticks(), 2, "Real scene press advances literal simulation tick two")
    _assert_true(is_equal_approx(press.get_train_route_distance_cells(), 0.6474820144), "Real scene press advances literal train distance")
    _assert_equal(press_presentation.planning_indicator, {"visible": true, "text": "PLANNING 25%"}, "Real scene shows planning feedback")
    _assert_equal(press_presentation.departure_marker, {"visible": true, "alpha": 1.0}, "Real scene starts departure dissolve at alpha one")
    var gesture_origin: Dictionary = cadence_app.track_system._runtime.get_gesture_origin_observation()
    var alternate_target := endpoint
    for target in gesture_origin.get("targets", {}).values():
        var candidate := Vector2i(target)
        if (
            candidate != endpoint
            and candidate.x >= 0 and candidate.y >= 0
            and candidate.x < 12 and candidate.y < 12
        ):
            alternate_target = candidate
            break
    _assert_true(alternate_target != endpoint, "Real scene exposes one in-bounds alternate preview target")
    var planning_targets := [alternate_target, endpoint, alternate_target, endpoint]
    var pairs_before_planning := _pair_lifecycle_signatures(press)
    var construction_before_planning := _construction_signatures(press)
    var expected_did_advance := [false, false, false, true]
    var expected_elapsed := [2, 2, 2, 3]
    var expected_distances := [0.6474820144, 0.6474820144, 0.6474820144, 0.9712230216]
    for index in range(4):
        var preview_path: Array[Vector2i] = [planning_targets[index]]
        controller.advance_tick(_held_live_frame(endpoint, preview_path))
        var snapshot = controller.get_snapshot()
        _assert_equal(snapshot.did_advance_simulation_tick(), expected_did_advance[index], "Real scene literal planning cadence step %d" % (index + 1))
        _assert_equal(snapshot.get_elapsed_ticks(), expected_elapsed[index], "Real scene literal elapsed cadence step %d" % (index + 1))
        _assert_true(is_equal_approx(snapshot.get_train_route_distance_cells(), expected_distances[index]), "Real scene literal train cadence step %d" % (index + 1))
        _assert_equal(cadence_app.track_system.get_endpoint_cell(), planning_targets[index], "Real scene preview updates on planning real tick %d" % (index + 1))
        if not expected_did_advance[index]:
            _assert_equal(snapshot.get_warp_cargo_events(), [], "Real scene skipped tick %d has no repeated Warp events" % (index + 1))
            _assert_equal(_pair_lifecycle_signatures(snapshot), pairs_before_planning, "Real scene skipped tick %d freezes Warp lifecycle" % (index + 1))
            _assert_equal(_construction_signatures(snapshot), construction_before_planning, "Real scene skipped tick %d freezes construction" % (index + 1))
        else:
            _assert_true(_pair_lifecycle_signatures(snapshot) != pairs_before_planning, "Real scene due planning tick advances Warp lifecycle")
            _assert_equal(_construction_signatures(snapshot), construction_before_planning, "Real scene fully-built fixture adds no synthetic construction work")
        if index == 0:
            track_field_view.call("_process", 0.375)
            var half_dissolved: Dictionary = track_field_view.get_render_observation()
            _assert_true(is_equal_approx(half_dissolved.departure_marker.alpha, 0.5), "Real scene dissolve advances on presentation time during skipped simulation")
            _assert_true(half_dissolved.planning_indicator.visible, "Real scene planning feedback remains visible during skipped simulation")
    var due = controller.get_snapshot()
    track_field_view.call("_process", 0.375)
    _assert_equal(track_field_view.get_render_observation().departure_marker, {"visible": false, "alpha": 0.0}, "Real scene departure marker completes its dissolve")
    controller.advance_tick(_release_endpoint_frame(endpoint))
    var released = controller.get_snapshot()
    _assert_true(not released.is_planning_slowdown_active(), "Real scene release clears planning immediately")
    _assert_true(not released.did_advance_simulation_tick(), "Real scene release consumes no simulation tick")
    _assert_equal(released.get_elapsed_ticks(), 3, "Real scene release has no catch-up")
    _assert_equal(track_field_view.get_render_observation().planning_indicator, {"visible": false, "text": ""}, "Real scene release clears planning feedback")
    controller.advance_tick()
    var resumed = controller.get_snapshot()
    _assert_true(resumed.did_advance_simulation_tick(), "Real scene resumes one-for-one after release")
    _assert_equal(resumed.get_elapsed_ticks(), 4, "Real scene first post-release tick advances once")
    _assert_true(is_equal_approx(due.get_train_route_distance_cells() + 0.3237410072, resumed.get_train_route_distance_cells()), "Real scene post-release train advances exactly once")
    cadence_app.queue_free()
    await process_frame


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


func _held_endpoint_frame(endpoint: Vector2i) -> TrackInputFrameScript:
    var empty: Array[Vector2i] = []
    return TrackInputFrameScript.new(
        empty, endpoint, true, Vector2i(-1, -1), false,
        true, true, false, false, endpoint, true
    )


func _held_live_frame(endpoint: Vector2i, live_path: Array[Vector2i]) -> TrackInputFrameScript:
    return TrackInputFrameScript.new(
        live_path, endpoint, true, Vector2i(-1, -1), false,
        true, true, false, false, live_path[-1], true, live_path
    )


func _release_endpoint_frame(endpoint: Vector2i) -> TrackInputFrameScript:
    var empty: Array[Vector2i] = []
    return TrackInputFrameScript.new(
        empty, endpoint, true, Vector2i(-1, -1), false,
        false, false, true, false, endpoint, true
    )


func _configure_mouse_manual_balance(app) -> void:
    var manual_balance = app.balance.duplicate(true)
    manual_balance.session_balance.session_duration_seconds = 90.0
    manual_balance.train_balance.speed_cells_per_second = 1.5
    manual_balance.track_inventory_balance.recovery_lag_cells = 2
    manual_balance.warp_lifecycle_balance.lifetime_min_seconds = 3.0
    manual_balance.warp_lifecycle_balance.lifetime_max_seconds = 33.0
    app.balance = manual_balance


func _on_mouse_manual_snapshot(_snapshot, app) -> void:
    var rejection: Dictionary = app.track_system._runtime.get_last_gesture_rejection()
    if not _accept_new_mouse_gesture_rejection(rejection):
        return
    var candidate_cells: Array[String] = []
    for record in rejection.get("candidate_records", []):
        candidate_cells.append("%d:%s:L%s" % [
            record.get("serial", -1),
            record.get("cell", Vector2i(-1, -1)),
            record.get("locked", false),
        ])
    print("GESTURE_REJECT | stage=%s | reason=%s | pointer=%s | live_path=%s | accepted_endpoint=%s | selected_template=%s | attempted_template=%s | candidate=%s | locked=%s | anchors=%s" % [
        rejection.get("stage", StringName()),
        rejection.get("reason", StringName()),
        rejection.get("pointer_cell", Vector2i(-1, -1)),
        rejection.get("live_path", []),
        rejection.get("accepted_endpoint", Vector2i(-1, -1)),
        rejection.get("selected_template_index", -1),
        rejection.get("attempted_template_index", -1),
        candidate_cells,
        rejection.get("locked_pieces", []),
        rejection.get("anchors", []),
    ])


func _accept_new_mouse_gesture_rejection(rejection: Dictionary) -> bool:
    if rejection.is_empty():
        _last_mouse_gesture_rejection.clear()
        return false
    if rejection == _last_mouse_gesture_rejection:
        return false
    _last_mouse_gesture_rejection = rejection.duplicate(true)
    return true


func _test_mouse_gesture_rejection_deduplication() -> void:
    var rejection := {"stage": &"candidate_sequence", "reason": &"append_path_rejected"}
    _last_mouse_gesture_rejection.clear()
    _assert_true(_accept_new_mouse_gesture_rejection(rejection), "First gesture rejection episode is logged")
    _assert_true(not _accept_new_mouse_gesture_rejection(rejection), "Consecutive duplicate rejection is suppressed")
    _assert_true(not _accept_new_mouse_gesture_rejection({}), "Successful empty diagnostic clears the rejection episode")
    _assert_true(_accept_new_mouse_gesture_rejection(rejection), "The same rejection is logged again after a successful interval")
    _last_mouse_gesture_rejection.clear()


func _event_signatures(snapshot) -> Array[String]:
    var events: Array[String] = []
    for event in snapshot.get_warp_cargo_events():
        events.append("%s:%s:%d:%d" % [event.type, event.pair_id, event.slot_index, event.amount])
    return events


func _pair_lifecycle_signatures(snapshot) -> Array[String]:
    var signatures: Array[String] = []
    for pair in snapshot.get_warp_pair_records():
        signatures.append("%s:%d:%d:%d" % [
            pair.pair_id, pair.state,
            pair.forecast_remaining_ticks, pair.lifetime_remaining_ticks,
        ])
    return signatures


func _construction_signatures(snapshot) -> Array[String]:
    var signatures: Array[String] = []
    for record in snapshot.get_cell_records():
        signatures.append("%d:%d:%.6f" % [
            record.route_serial, record.state, record.build_progress,
        ])
    return signatures


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


func _create_manual_overlay(app) -> void:
    _manual_layer = CanvasLayer.new()
    _manual_layer.layer = 100
    _manual_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    app.add_child(_manual_layer)

    var viewport_size: Vector2 = app.get_viewport().get_visible_rect().size
    var panel_size: Vector2 = Vector2(
        minf(460.0, viewport_size.x - 24.0),
        minf(250.0, viewport_size.y - 24.0)
    )
    _manual_panel = PanelContainer.new()
    _manual_panel.anchor_left = 1.0
    _manual_panel.anchor_top = 1.0
    _manual_panel.anchor_right = 1.0
    _manual_panel.anchor_bottom = 1.0
    _manual_panel.offset_left = -panel_size.x - 12.0
    _manual_panel.offset_top = -panel_size.y - 12.0
    _manual_panel.offset_right = -12.0
    _manual_panel.offset_bottom = -12.0
    _manual_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    _manual_layer.add_child(_manual_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_bottom", 10)
    _manual_panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    margin.add_child(column)
    _manual_scroll = ScrollContainer.new()
    _manual_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _manual_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(_manual_scroll)
    _manual_label = Label.new()
    _manual_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _manual_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _manual_scroll.add_child(_manual_label)
    _manual_button = Button.new()
    _manual_button.text = "Capture evidence, then continue"
    column.add_child(_manual_button)
    _manual_layer.visible = false


func _show_manual_checkpoint(
    checkpoint_id: String,
    tick: int,
    snapshot,
    expectation: String = ""
) -> void:
    _manual_checkpoint_ids.append(checkpoint_id)
    var expected_text: String = expectation if not expectation.is_empty() else MANUAL_EXPECTATIONS[tick]
    _manual_label.text = "WARP CARGO CHECKPOINT %s\n%s\n%s\nCargo %d / %d | Base reward %d" % [
        checkpoint_id,
        expected_text,
        _manual_pair_summary(snapshot),
        snapshot.get_occupied_cargo_slots(),
        snapshot.get_total_cargo_slots(),
        snapshot.get_base_delivery_reward_total(),
    ]
    _manual_layer.visible = true
    print("MANUAL CHECKPOINT %s | %s" % [checkpoint_id, expected_text])
    await process_frame
    _assert_manual_overlay_layout()
    paused = true
    if _manual_auto_advance:
        call_deferred("_auto_press_manual_button")
    await _manual_button.pressed
    paused = false
    _manual_layer.visible = false
    await process_frame


func _manual_pair_summary(snapshot) -> String:
    var pair_summaries: Array[String] = []
    for pair in snapshot.get_warp_pair_records():
        pair_summaries.append("%s %s O%s D%s L%d" % [
            pair.pair_id,
            WarpPairRecordScript.State.keys()[pair.state],
            pair.origin_cell,
            pair.destination_cell,
            pair.lifetime_remaining_ticks,
        ])
    return " | ".join(pair_summaries)


func _auto_press_manual_button() -> void:
    _assert_true(paused, "Manual auto-continue executes while the tree is paused")
    _assert_manual_overlay_layout()
    _manual_button.pressed.emit()


func _assert_manual_overlay_layout() -> void:
    var viewport_rect := _manual_panel.get_viewport_rect()
    var panel_rect := _manual_panel.get_global_rect()
    var button_rect := _manual_button.get_global_rect()
    _assert_true(viewport_rect.encloses(panel_rect), "Manual checkpoint panel remains inside the viewport")
    _assert_true(panel_rect.encloses(button_rect), "Manual continue button remains inside the checkpoint panel")
    _assert_true(_manual_scroll.size.y > 0.0, "Manual checkpoint text has a scrollable viewport")
    _assert_true(_manual_button.is_visible_in_tree() and not _manual_button.disabled, "Manual continue button remains reachable")


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
