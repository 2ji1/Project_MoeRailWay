extends "res://tests/support/prototype_test.gd"

const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")


func run() -> PackedStringArray:
    _verify_explicit_tick_lifecycle()
    _verify_fractional_duration_rounds_up()
    _verify_terminal_snapshot_reentrancy_is_guarded()
    return finish()


func _verify_explicit_tick_lifecycle() -> void:
    var config = SessionStartConfigScript.new(7, 2.0, 4)
    var controller = SessionControllerScript.new(config)
    var snapshots := []
    var results := []
    var event_order := PackedStringArray()

    controller.snapshot_published.connect(
        func(snapshot) -> void:
            snapshots.append(snapshot)
            event_order.append("snapshot:%d" % snapshot.get_remaining_ticks())
    )
    controller.session_completed.connect(
        func(result) -> void:
            results.append(result)
            event_order.append("result:%d" % result.get_remaining_ticks())
    )

    assert_equal(
        controller.get_state(),
        SessionControllerScript.State.READY,
        "A new controller must begin ready"
    )
    assert_equal(controller.get_snapshot().get_total_ticks(), 8, "2 seconds at 4 Hz must total 8 ticks")

    controller.advance_tick()
    assert_equal(controller.get_snapshot().get_remaining_ticks(), 8, "A pre-start tick must not consume time")
    assert_equal(snapshots.size(), 0, "A pre-start tick must not publish")

    controller.start()
    assert_equal(controller.get_state(), SessionControllerScript.State.RUNNING, "Start must enter running")
    assert_equal(snapshots.size(), 1, "Start must publish exactly one initial snapshot")
    assert_equal(snapshots[0].get_remaining_ticks(), 8, "The initial snapshot must retain full duration")
    assert_equal(snapshots[0].get_display_seconds(), 2, "The initial display must use ceiling seconds")

    var retained_snapshot = snapshots[0]
    controller.advance_tick()
    assert_equal(controller.get_snapshot().get_remaining_ticks(), 7, "Each running tick must consume one tick")
    assert_equal(retained_snapshot.get_remaining_ticks(), 8, "Published snapshots must be detached from later ticks")

    controller.start()
    assert_equal(snapshots.size(), 2, "A second start must not publish or reset")
    assert_equal(controller.get_snapshot().get_remaining_ticks(), 7, "A second start must preserve elapsed time")

    assert_false(
        retained_snapshot.has_method("set_remaining_ticks"),
        "Snapshots must expose no remaining-tick setter"
    )
    retained_snapshot.set("_remaining_ticks", 0)
    assert_equal(
        controller.get_snapshot().get_remaining_ticks(),
        7,
        "A retained snapshot must not mutate controller state"
    )

    for expected_remaining in range(6, 0, -1):
        controller.advance_tick()
        assert_equal(
            controller.get_snapshot().get_remaining_ticks(),
            expected_remaining,
            "Each running tick must decrement remaining time"
        )
        assert_true(
            controller.get_snapshot().get_display_seconds() > 0,
            "Display seconds must remain positive before completion"
        )

    assert_equal(results.size(), 0, "The controller must not complete before its final tick")
    controller.advance_tick()

    var final_snapshot = controller.get_snapshot()
    assert_equal(controller.get_state(), SessionControllerScript.State.COMPLETED, "The final tick must complete")
    assert_equal(final_snapshot.get_remaining_ticks(), 0, "Completion must publish zero remaining ticks")
    assert_equal(final_snapshot.get_elapsed_ticks(), 8, "Completion must consume every tick")
    assert_equal(final_snapshot.get_display_seconds(), 0, "Display seconds reach zero only on completion")
    assert_equal(results.size(), 1, "Regular expiry must emit exactly one result")
    assert_equal(
        event_order.slice(event_order.size() - 2),
        PackedStringArray(["snapshot:0", "result:0"]),
        "The zero snapshot must publish before the result"
    )

    var result = results[0]
    assert_equal(
        result.get_reason(),
        SessionResultScript.Reason.REGULAR_TIME_EXPIRED,
        "The milestone result reason must be regular time expiry"
    )
    assert_equal(result.get_total_ticks(), final_snapshot.get_total_ticks(), "Result total must match snapshot")
    assert_equal(result.get_elapsed_ticks(), final_snapshot.get_elapsed_ticks(), "Result elapsed must match snapshot")
    assert_equal(result.get_remaining_ticks(), final_snapshot.get_remaining_ticks(), "Result remaining must match snapshot")
    assert_false(result.has_method("get_settlement"), "A session result must not expose settlement")

    var snapshot_count_at_completion := snapshots.size()
    for index in range(10):
        controller.advance_tick()
    assert_equal(results.size(), 1, "Post-completion ticks must not emit another result")
    assert_equal(
        snapshots.size(),
        snapshot_count_at_completion,
        "Post-completion ticks must not publish snapshots"
    )


func _verify_fractional_duration_rounds_up() -> void:
    var config = SessionStartConfigScript.new(11, 0.11, 10)
    var controller = SessionControllerScript.new(config)
    var results := []
    controller.session_completed.connect(func(result) -> void: results.append(result))

    assert_equal(controller.get_snapshot().get_total_ticks(), 2, "Fractional durations must round up")
    controller.start()
    controller.advance_tick()
    assert_equal(controller.get_snapshot().get_remaining_ticks(), 1, "The first rounded tick must remain running")
    assert_equal(controller.get_snapshot().get_display_seconds(), 1, "Positive fractional time displays one second")
    assert_equal(results.size(), 0, "Rounded duration must not complete early")
    controller.advance_tick()
    assert_equal(results.size(), 1, "The rounded duration must complete on its second tick")


func _verify_terminal_snapshot_reentrancy_is_guarded() -> void:
    var config = SessionStartConfigScript.new(17, 1.0, 2)
    var controller = SessionControllerScript.new(config)
    var terminal_snapshots := []
    var results := []
    var reentered := [false]

    var snapshot_listener := (
        func(snapshot) -> void:
            if snapshot.get_remaining_ticks() != 0:
                return
            terminal_snapshots.append(snapshot)
            if reentered[0]:
                return
            reentered[0] = true
            controller.advance_tick()
    )
    controller.snapshot_published.connect(snapshot_listener)
    controller.session_completed.connect(func(result) -> void: results.append(result))

    controller.start()
    controller.advance_tick()
    controller.advance_tick()

    assert_true(reentered[0], "The regression listener must attempt one terminal reentrant tick")
    assert_equal(terminal_snapshots.size(), 1, "Completion must publish exactly one terminal snapshot")
    assert_equal(results.size(), 1, "Terminal snapshot reentrancy must not duplicate the result")
    assert_equal(controller.get_state(), SessionControllerScript.State.COMPLETED, "Completion must stay terminal")
    assert_equal(controller.get_snapshot().get_total_ticks(), 2, "The terminal snapshot must retain total ticks")
    assert_equal(controller.get_snapshot().get_elapsed_ticks(), 2, "Reentrancy must not advance past total ticks")
    assert_equal(results[0].get_elapsed_ticks(), 2, "The sole result must report exactly total elapsed ticks")
    controller.snapshot_published.disconnect(snapshot_listener)
