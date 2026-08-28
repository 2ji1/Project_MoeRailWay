extends "res://tests/support/prototype_test.gd"

const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const TrackFieldViewScript = preload("res://src/presentation/track/track_field_view.gd")
const LogicalTrackFieldScene = preload("res://src/presentation/track/logical_track_field.tscn")
const WarpCargoBalance = preload("res://tests/fixtures/warp_cargo_balance.tres")


func run() -> PackedStringArray:
    _test_departure_dissolve_and_planning_indicator_contract()
    return finish()


func _test_departure_dissolve_and_planning_indicator_contract() -> void:
    var view := TrackFieldViewScript.new()
    var logical_field = LogicalTrackFieldScene.instantiate()
    logical_field.size_preset = 3
    logical_field.custom_width = 640.0
    logical_field.custom_height = 320.0
    logical_field.grid_cell_size_units = 26.666666
    logical_field.custom_grid_columns = 12
    logical_field.custom_grid_rows = 12
    view.add_child(logical_field)
    view.size = Vector2(640.0, 320.0)
    var config = _config()
    view.configure_session(config)
    assert_false(view.is_processing(), "Configured READY field has no active presentation callback")
    var child_count := view.get_child_count()

    view.present(_snapshot(SessionControllerScript.State.READY))
    var ready := view.get_render_observation()
    assert_true(ready.has("departure_marker"), "Field exposes detached departure marker observation")
    assert_true(ready.has("planning_indicator"), "Field exposes detached planning indicator observation")
    if not ready.has("departure_marker") or not ready.has("planning_indicator"):
        view.free()
        return
    assert_equal(ready.departure_marker, {"visible": true, "alpha": 1.0}, "READY departure is opaque and visible")
    assert_equal(ready.planning_indicator, {"visible": false, "text": ""}, "READY never displays planning")
    view.present(_snapshot(SessionControllerScript.State.PREPARING_DEPARTURE))
    assert_equal(view.get_render_observation().departure_marker.alpha, 1.0, "Preparation keeps departure opaque")

    var running := _snapshot(SessionControllerScript.State.RUNNING)
    view.present(running)
    assert_true(view.is_processing(), "First RUNNING presentation enables the dissolve callback")
    var origin_before := view.get_render_observation()
    assert_equal(origin_before.departure_marker.alpha, 1.0, "First RUNNING presentation starts dissolve at alpha one")
    assert_true(view.has_method("_process"), "Field owns real-time presentation advancement")
    if not view.has_method("_process"):
        view.free()
        return
    view.call("_process", 0.375)
    assert_true(view.is_processing(), "Partial dissolve keeps the presentation callback active")
    assert_true(is_equal_approx(view.get_render_observation().departure_marker.alpha, 0.5), "Departure alpha is one half at 0.375 real seconds")
    view.present(running)
    assert_true(is_equal_approx(view.get_render_observation().departure_marker.alpha, 0.5), "Later RUNNING snapshots never restart dissolve")
    view.call("_process", 0.375)
    var dissolved := view.get_render_observation()
    assert_false(view.is_processing(), "Completed dissolve disables the presentation callback")
    assert_true(is_zero_approx(dissolved.departure_marker.alpha), "Departure alpha reaches zero at 0.75 real seconds")
    assert_false(dissolved.departure_marker.visible, "Departure marker hides at zero alpha")
    assert_equal(dissolved.selected_departure_id, origin_before.selected_departure_id, "Dissolve never changes selected departure ID")
    assert_equal(dissolved.selected_departure_position, origin_before.selected_departure_position, "Dissolve never changes route origin")
    assert_equal(dissolved.train_position, origin_before.train_position, "Dissolve never changes train observations")

    view.present(_snapshot(SessionControllerScript.State.RUNNING, true, false))
    var planning := view.get_render_observation()
    assert_equal(planning.planning_indicator, {"visible": true, "text": "PLANNING 25%"}, "Skipped active running snapshot displays planning percentage")
    view.call("_process", 0.1)
    assert_true(view.get_render_observation().planning_indicator.visible, "Planning indicator remains live on presentation time")
    view.present(_snapshot(SessionControllerScript.State.RUNNING, false, false))
    assert_equal(view.get_render_observation().planning_indicator, {"visible": false, "text": ""}, "Release or abort clears planning")
    view.present(_snapshot(SessionControllerScript.State.PREPARING_DEPARTURE, true, false))
    assert_false(view.get_render_observation().planning_indicator.visible, "Non-running state suppresses planning")
    view.present(_snapshot(SessionControllerScript.State.COMPLETED, true, false))
    assert_false(view.get_render_observation().planning_indicator.visible, "Completion suppresses planning")

    var detached_departure: Dictionary = ready.departure_marker
    var detached_planning: Dictionary = planning.planning_indicator
    detached_departure.alpha = 0.125
    detached_planning.text = "mutated"
    var fresh := view.get_render_observation()
    assert_true(not is_equal_approx(fresh.departure_marker.alpha, 0.125), "Departure observation is detached")
    assert_true(fresh.planning_indicator.text != "mutated", "Planning observation is detached")
    assert_equal(view.get_child_count(), child_count, "Primitive feedback adds no input-intercepting Control")

    view.configure_session(config)
    assert_false(view.is_processing(), "New configuration resets to an idle presentation callback")
    assert_equal(view.get_render_observation().departure_marker, {"visible": true, "alpha": 1.0}, "New session configuration alone resets dissolve")
    view.free()


func _config():
    var base = WarpCargoBalance.create_session_start_config(73013)
    return WarpCargoBalance.complete_session_start_config(
        base,
        Vector2(640.0, 320.0),
        &"departure_08",
        Vector2(220.0, 100.0),
        26.666666,
        Vector2i(12, 12),
        Vector2(160.0, 0.0),
        Vector2i(2, 3)
    )


func _snapshot(
    state: int,
    planning_active: bool = false,
    did_advance: bool = true
) -> SessionSnapshotScript:
    return SessionSnapshotScript.new(
        100, 4, 96, 10, true, state,
        [], [], [], 4.0, 30, 60, Vector2(160.0, 0.0),
        1, 1, 3.0, true, 2.0, Vector2(260.0, 100.0), Vector2.RIGHT,
        1.0, false, &"departure_08", Vector2i(2, 3), false, planning_active,
        [], [], 0, 2, 0, 0, [], planning_active, 25, did_advance
    )
