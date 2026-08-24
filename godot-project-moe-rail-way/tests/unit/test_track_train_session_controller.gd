extends "res://tests/support/prototype_test.gd"

const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")


func _config(
    duration := 4.0,
    ticks_per_second := 10,
    train_speed := 10.0,
    total_units := 100.0,
    recovery_distance := 10.0,
    urgent_seconds := 0.5,
    construction_speed := 20.0,
    required_built := 4.0,
    minimum_sample := 1.0
) -> SessionStartConfigScript:
    return SessionStartConfigScript.new(
        123,
        duration,
        ticks_per_second,
        train_speed,
        total_units,
        recovery_distance,
        urgent_seconds,
        construction_speed,
        5.0,
        3.0,
        minimum_sample,
        minf(0.5, minimum_sample),
        required_built,
        Vector2(800.0, 400.0),
        &"departure_02",
        Vector2(100.0, 100.0)
    )


func _fixture(config: SessionStartConfigScript) -> Dictionary:
    var track = TrackSystemScript.new(config)
    var train = TrainSystemScript.new(config.train_speed_units_per_second)
    return {
        "config": config,
        "track": track,
        "train": train,
        "controller": SessionControllerScript.new(config, track, train),
    }


func _frame(
    cursor := Vector2.ZERO,
    left_pressed := false,
    left_held := false,
    left_released := false,
    right_pressed := false,
    left_press := Vector2.ZERO,
    right_press := Vector2.ZERO
) -> TrackInputFrameScript:
    return TrackInputFrameScript.new(
        cursor,
        true,
        left_pressed,
        left_held,
        left_released,
        right_pressed,
        left_press,
        true,
        right_press,
        true
    )


func _draw_from_departure(target: Vector2) -> TrackInputFrameScript:
    return _frame(target, true, true, false, false, Vector2(100.0, 100.0))


func _reserve_direct(track, target: Vector2) -> void:
    track.apply_left_input(_draw_from_departure(target))
    track.apply_left_input(_frame(target, false, false, true))


func _capture_results(controller) -> Array:
    var results := []
    controller.session_completed.connect(func(result) -> void: results.append(result))
    return results


func _assert_close(actual: float, expected: float, message: String) -> void:
    assert_true(is_equal_approx(actual, expected), "%s | expected=%s actual=%s" % [
        message, expected, actual,
    ])


func _test_preparation_and_exact_departure_tick() -> void:
    var fixture := _fixture(_config())
    var controller = fixture.controller
    var track = fixture.track
    var train = fixture.train
    var snapshots := []
    controller.snapshot_published.connect(func(snapshot) -> void: snapshots.append(snapshot))

    assert_equal(controller.get_state(), SessionControllerScript.State.READY, "New state")
    var ready_snapshot = controller.get_snapshot()
    controller.advance_tick(_draw_from_departure(Vector2(140.0, 100.0)))
    assert_equal(controller.get_snapshot(), ready_snapshot, "Pre-start tick is inert")
    assert_equal(snapshots.size(), 0, "Pre-start tick publishes nothing")

    controller.start()
    var initial = controller.get_snapshot()
    assert_equal(controller.get_state(), SessionControllerScript.State.PREPARING_DEPARTURE, "Start enters preparation")
    assert_true(initial.has_track_train_data(), "Preparation snapshot has gameplay data")
    assert_equal(initial.get_remaining_ticks(), initial.get_total_ticks(), "Preparation retains full time")
    assert_equal(initial.get_selected_departure_candidate_id(), &"departure_02", "Selected departure copied")
    _assert_close(initial.get_departure_built_units(), 0.0, "Initial built progress")
    _assert_close(initial.get_available_track_units(), 100.0, "Initial inventory")
    assert_false(initial.is_train_active(), "Train inactive during initial preparation")
    controller.start()
    assert_equal(snapshots.size(), 1, "Second start is a no-op")

    controller.advance_tick(_draw_from_departure(Vector2(140.0, 100.0)))
    var below = controller.get_snapshot()
    assert_equal(controller.get_state(), SessionControllerScript.State.PREPARING_DEPARTURE, "Below threshold remains preparation")
    _assert_close(track.get_built_end_distance(), 2.0, "Preparation constructs one fixed increment")
    assert_false(train.is_active(), "Preparation does not move train")
    assert_equal(below.get_elapsed_ticks(), 0, "Preparation consumes no timer tick")

    controller.advance_tick()
    var departed = controller.get_snapshot()
    assert_equal(controller.get_state(), SessionControllerScript.State.RUNNING, "Exact threshold enters running")
    assert_true(train.is_active(), "Threshold tick departs train")
    _assert_close(train.get_route_distance(), 1.0, "Threshold tick advances train once")
    assert_equal(departed.get_elapsed_ticks(), 1, "Threshold tick consumes first timer tick")
    _assert_close(departed.get_departure_built_units(), 4.0, "Threshold built progress")


func _test_input_and_construction_phase_order() -> void:
    var fixture := _fixture(_config(4.0, 10, 10.0, 100.0, 10.0, 0.5, 20.0, 100.0))
    var controller = fixture.controller
    var track = fixture.track
    controller.start()
    controller.advance_tick(_draw_from_departure(Vector2(140.0, 100.0)))
    _assert_close(track.get_reserved_end_distance(), 40.0, "Initial suffix reserved")
    _assert_close(track.get_built_end_distance(), 2.0, "Initial construction")

    var same_tick = _frame(
        Vector2(180.0, 100.0),
        true,
        true,
        false,
        true,
        Vector2(140.0, 100.0),
        Vector2(110.0, 100.0)
    )
    controller.advance_tick(same_tick)
    _assert_close(track.get_reserved_end_distance(), 10.0, "Right cancellation wins before left")
    _assert_close(track.get_built_end_distance(), 4.0, "Construction runs after cancellation")
    assert_true(
        track.get_built_end_distance() <= track.get_reserved_end_distance(),
        "Canceled suffix cannot be constructed in the same tick"
    )

    var movement_fixture := _fixture(_config(4.0, 10, 10.0, 100.0, 10.0, 0.5, 20.0, 2.0))
    var movement_controller = movement_fixture.controller
    movement_controller.start()
    movement_controller.advance_tick(_draw_from_departure(Vector2(120.0, 100.0)))
    _assert_close(movement_fixture.train.get_route_distance(), 1.0, "Departure tick movement")
    movement_controller.advance_tick()
    assert_equal(
        movement_controller.get_state(),
        SessionControllerScript.State.RUNNING,
        "Construction extending old built end prevents a same-tick track-end request"
    )
    _assert_close(movement_fixture.track.get_built_end_distance(), 4.0, "Construction extends before movement")
    _assert_close(movement_fixture.train.get_route_distance(), 2.0, "Train moves after extension")


func _test_track_end_and_regular_expiry_priority() -> void:
    var end_fixture := _fixture(_config(4.0, 10, 10.0, 100.0, 10.0, 0.5, 5.0, 0.5))
    var end_results := _capture_results(end_fixture.controller)
    end_fixture.controller.start()
    end_fixture.controller.advance_tick(_draw_from_departure(Vector2(120.0, 100.0)))
    assert_equal(end_fixture.controller.get_state(), SessionControllerScript.State.COMPLETED, "Built-end request completes")
    _assert_close(end_fixture.track.get_reserved_end_distance(), 20.0, "Unbuilt reservation remains ahead")
    assert_equal(end_results.size(), 1, "Track end emits one result")
    assert_equal(end_results[0].get_reason(), SessionResultScript.Reason.TRACK_END_REACHED, "Track-end reason")
    var end_terminal_snapshot = end_fixture.controller.get_snapshot()
    assert_true(end_terminal_snapshot.get_remaining_ticks() > 0, "Track end leaves observable time")
    var end_elapsed_before: int = end_terminal_snapshot.get_elapsed_ticks()
    var end_remaining_before: int = end_terminal_snapshot.get_remaining_ticks()
    end_fixture.controller.advance_tick()
    assert_equal(
        end_fixture.controller.get_snapshot(),
        end_terminal_snapshot,
        "Track-end terminal snapshot identity is inert"
    )
    assert_equal(
        end_fixture.controller.get_snapshot().get_elapsed_ticks(),
        end_elapsed_before,
        "Track-end terminal elapsed ticks are inert"
    )
    assert_equal(
        end_fixture.controller.get_snapshot().get_remaining_ticks(),
        end_remaining_before,
        "Track-end terminal remaining ticks are inert"
    )

    var expiry_fixture := _fixture(_config(0.2, 10, 1.0, 100.0, 10.0, 0.5, 100.0, 1.0))
    var expiry_results := _capture_results(expiry_fixture.controller)
    expiry_fixture.controller.start()
    expiry_fixture.controller.advance_tick(_draw_from_departure(Vector2(120.0, 100.0)))
    expiry_fixture.controller.advance_tick()
    assert_equal(expiry_results[0].get_reason(), SessionResultScript.Reason.REGULAR_TIME_EXPIRED, "Regular expiry completes normally")

    var tie_fixture := _fixture(_config(0.1, 10, 10.0, 100.0, 10.0, 0.5, 5.0, 0.5))
    var tie_results := _capture_results(tie_fixture.controller)
    tie_fixture.controller.start()
    tie_fixture.controller.advance_tick(_draw_from_departure(Vector2(120.0, 100.0)))
    assert_equal(tie_results.size(), 1, "Tie emits one result")
    assert_equal(tie_results[0].get_reason(), SessionResultScript.Reason.REGULAR_TIME_EXPIRED, "Regular expiry wins track-end tie")


func _test_recovery_funding_and_warning_snapshot() -> void:
    var fixture := _fixture(_config(4.0, 10, 10.0, 4.0, 0.5, 0.1, 20.0, 2.0, 0.1))
    var controller = fixture.controller
    var track = fixture.track
    controller.start()
    controller.advance_tick(_draw_from_departure(Vector2(108.0, 100.0)))
    var first = controller.get_snapshot()
    _assert_close(track.get_reserved_end_distance(), 4.0, "Current input cannot spend later recovery")
    _assert_close(first.get_available_track_units(), 0.5, "Recovery appears in same tick snapshot")
    _assert_close(first.get_built_distance_ahead(), 1.0, "Built distance ahead excludes reservation")
    _assert_close(first.get_estimated_track_end_seconds(), 0.1, "Warning divides built ahead by train speed")
    assert_true(first.is_track_end_warning_urgent(), "Warning is urgent at threshold")

    controller.advance_tick(_frame(Vector2(105.0, 100.0), false, true))
    _assert_close(track.get_reserved_end_distance(), 4.5, "Prior recovery funds next tick reservation")
    assert_true(controller.get_snapshot().get_available_track_units() > 0.5, "Later recovery remains visible")


func _test_terminal_order_detachment_and_inertness() -> void:
    var fixture := _fixture(_config(0.1, 10, 10.0, 100.0, 1.0, 0.5, 100.0, 1.0))
    var controller = fixture.controller
    var track = fixture.track
    var train = fixture.train
    var events := PackedStringArray()
    var terminal_snapshots := []
    var results := []
    var reentered := [false]
    var snapshot_listener := (
        func(snapshot) -> void:
            if snapshot.get_remaining_ticks() != 0:
                return
            events.append("snapshot")
            terminal_snapshots.append(snapshot)
            assert_equal(controller.get_state(), SessionControllerScript.State.COMPLETED, "Terminal listener sees completed")
            if not reentered[0]:
                reentered[0] = true
                controller.advance_tick(_draw_from_departure(Vector2(180.0, 100.0)))
    )
    var result_listener := (
        func(result) -> void:
            events.append("result")
            results.append(result)
    )
    controller.snapshot_published.connect(snapshot_listener)
    controller.session_completed.connect(result_listener)
    controller.start()
    var preparation_snapshot = controller.get_snapshot()
    var preparation_built: PackedVector2Array = preparation_snapshot.get_built_route()
    var preparation_reserved: PackedVector2Array = preparation_snapshot.get_reserved_route()
    preparation_built.append(Vector2(999.0, 999.0))
    preparation_reserved.append(Vector2(999.0, 999.0))
    assert_false(
        preparation_snapshot.get_built_route().has(Vector2(999.0, 999.0)),
        "Getter mutation cannot mutate snapshot storage"
    )
    assert_false(
        preparation_snapshot.get_reserved_route().has(Vector2(999.0, 999.0)),
        "Reserved getter mutation cannot mutate snapshot storage"
    )

    controller.advance_tick(_draw_from_departure(Vector2(120.0, 100.0)))
    assert_equal(events, PackedStringArray(["snapshot", "result"]), "Terminal snapshot precedes result")
    assert_equal(terminal_snapshots.size(), 1, "One terminal snapshot")
    assert_equal(results.size(), 1, "One result")
    assert_equal(preparation_snapshot.get_built_route().size(), 1, "Earlier snapshot detached from domain")
    assert_equal(
        preparation_snapshot.get_reserved_route().size(),
        1,
        "Earlier reserved route snapshot is detached from domain"
    )

    var final_snapshot = controller.get_snapshot()
    assert_false(train.advance_tick(track, 0.4), "Setup movement stays before built track end")
    _assert_close(train.get_route_distance(), 5.0, "Setup movement creates recoverable distance")
    var built_before: float = track.get_built_end_distance()
    var reserved_before: float = track.get_reserved_end_distance()
    var active_before: float = track.get_active_start_distance()
    var available_before: float = track.get_available_units()
    var train_before: float = train.get_route_distance()
    var completed_endpoint: Vector2 = track.get_reserved_endpoint()
    controller.advance_tick(_frame(
        completed_endpoint + Vector2(20.0, 0.0),
        true,
        true,
        false,
        false,
        completed_endpoint
    ))
    for index in range(3):
        controller.advance_tick(_frame(
            Vector2(180.0, 100.0),
            true,
            true,
            true,
            true,
            Vector2(120.0, 100.0),
            Vector2(110.0, 100.0)
        ))
    assert_equal(controller.get_snapshot(), final_snapshot, "Post-completion snapshot is inert")
    assert_equal(terminal_snapshots.size(), 1, "Post-completion publishes no snapshot")
    assert_equal(results.size(), 1, "Post-completion emits no result")
    _assert_close(track.get_built_end_distance(), built_before, "Post-completion construction inert")
    _assert_close(track.get_reserved_end_distance(), reserved_before, "Post-completion input inert")
    _assert_close(track.get_active_start_distance(), active_before, "Post-completion recovery inert")
    _assert_close(track.get_available_units(), available_before, "Post-completion inventory inert")
    _assert_close(train.get_route_distance(), train_before, "Post-completion train inert")
    controller.snapshot_published.disconnect(snapshot_listener)
    controller.session_completed.disconnect(result_listener)


func run() -> PackedStringArray:
    if not SessionControllerScript.State.has("PREPARING_DEPARTURE"):
        assert_true(false, "A new session must begin in PREPARING_DEPARTURE")
        return finish()
    _test_preparation_and_exact_departure_tick()
    _test_input_and_construction_phase_order()
    _test_track_end_and_regular_expiry_priority()
    _test_recovery_funding_and_warning_snapshot()
    _test_terminal_order_detachment_and_inertness()
    return finish()
