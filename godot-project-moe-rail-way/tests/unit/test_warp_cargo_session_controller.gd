extends "res://tests/support/prototype_test.gd"

const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")
const WarpPairSystemScript = preload("res://src/domain/warp/warp_pair_system.gd")
const CargoSystemScript = preload("res://src/domain/cargo/cargo_system.gd")


class ContactTrackSpy extends TrackSystemScript:
    var event_log: Array[String] = []
    var anchor_batches: Array = []
    var query_ranges: Array[Vector2] = []
    var query_mode: StringName = &"none"
    var allow_prepare := true
    var _current_anchors: Array[RouteContactAnchorScript] = []

    func set_contact_anchors(anchors: Array[RouteContactAnchorScript]) -> void:
        super.set_contact_anchors(anchors)
        _current_anchors = []
        var batch: Array[Dictionary] = []
        for anchor in anchors:
            _current_anchors.append(anchor.duplicate_anchor())
            batch.append({"anchor_id": anchor.anchor_id, "cell": anchor.cell})
        anchor_batches.append(batch)
        event_log.append("anchors:%d" % anchors.size())

    func apply_right_input(input_frame: TrackInputFrameScript) -> bool:
        event_log.append("right")
        return super.apply_right_input(input_frame)

    func apply_left_input(input_frame: TrackInputFrameScript) -> void:
        event_log.append("left")
        super.apply_left_input(input_frame)

    func advance_construction(progress_cells: float) -> float:
        event_log.append("construction")
        return super.advance_construction(progress_cells)

    func prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool:
        event_log.append("prepare")
        if not allow_prepare:
            return false
        return super.prepare_for_train_sampling(current_distance, through_distance)

    func get_contact_hits_between(
        previous_distance_cells: float,
        through_distance_cells: float
    ) -> Array[Dictionary]:
        query_ranges.append(Vector2(previous_distance_cells, through_distance_cells))
        event_log.append("hits")
        var hits: Array[Dictionary] = []
        for anchor in _current_anchors:
            var id_text := String(anchor.anchor_id)
            var include := false
            var distance := 0.2
            if query_mode == &"all_same":
                include = true
            elif query_mode == &"origin_only":
                include = id_text.ends_with("/origin")
            elif query_mode == &"ordinal_origins":
                include = id_text.ends_with("/origin")
                distance = 0.3
            elif query_mode == &"turnover":
                if id_text == "warp_pair_1/origin":
                    include = true
                    distance = 0.30
                elif id_text == "warp_pair_1/destination":
                    include = true
                    distance = 0.35
                elif id_text == "warp_pair_2/origin":
                    include = true
                    distance = 0.40
            if include:
                hits.push_front({
                    "anchor_id": anchor.anchor_id,
                    "cell": anchor.cell,
                    "contact_distance_cells": distance,
                })
        return hits

    func recover_behind(cutoff_distance_cells: float) -> int:
        event_log.append("recovery")
        return super.recover_behind(cutoff_distance_cells)

    func terminate_for_session_completion() -> bool:
        event_log.append("terminate")
        return super.terminate_for_session_completion()


func run() -> PackedStringArray:
    _test_skipped_planning_snapshot_never_repeats_warp_events()
    _verify_partial_dependency_probe()
    _test_snapshot_and_result_expose_warp_cargo_observations()
    _test_preparation_freezes_scheduling_and_departure_starts_tick_one()
    _test_running_prepare_failure_rolls_back_warp_tick()
    _test_controller_resolves_ordinal_and_physical_hit_order()
    _test_final_life_delivery_survives_regular_track_end_tie()
    _test_regular_and_early_completion_void_nonterminal_cargo()
    _test_pair_expiry_precedes_regular_completion_void()
    return finish()


func _test_skipped_planning_snapshot_never_repeats_warp_events() -> void:
    var config := _config(20.0, 0.1, 40, 2)
    config.planning_time_scale_percent = 25
    var fixture := _fixture(config)
    var controller: SessionControllerScript = fixture["controller"]
    var track: ContactTrackSpy = fixture["track"]
    controller.start()
    controller.advance_tick(_draw_frame([
        Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
    ]))
    controller.advance_tick(_held_endpoint(track.get_endpoint_cell()))
    var due_snapshot: SessionSnapshotScript = controller.get_snapshot()
    assert_true(due_snapshot.is_planning_slowdown_active(), "Warp fixture accepts a running planning gesture")
    assert_true(due_snapshot.did_advance_simulation_tick(), "Accepted press advances the canonical simulation tick")
    assert_false(due_snapshot.get_warp_cargo_events().is_empty(), "Due press tick exposes its one-shot Warp events")
    var pairs_before_skip := _pair_signatures(due_snapshot.get_warp_pair_records())
    var elapsed_before_skip := due_snapshot.get_elapsed_ticks()
    var distance_before_skip := due_snapshot.get_train_route_distance_cells()
    controller.advance_tick(_held_endpoint(track.get_endpoint_cell()))
    var skipped: SessionSnapshotScript = controller.get_snapshot()
    assert_true(skipped.is_planning_slowdown_active(), "Held skipped tick remains planning-active")
    assert_false(skipped.did_advance_simulation_tick(), "First held planning tick is skipped at 25 percent")
    assert_equal(skipped.get_warp_cargo_events(), [], "Skipped snapshot never repeats prior Warp events")
    assert_equal(_pair_signatures(skipped.get_warp_pair_records()), pairs_before_skip, "Skipped snapshot freezes Warp lifecycle")
    assert_equal(skipped.get_elapsed_ticks(), elapsed_before_skip, "Skipped snapshot freezes session elapsed ticks")
    assert_equal(skipped.get_train_route_distance_cells(), distance_before_skip, "Skipped snapshot freezes train distance")


func _verify_partial_dependency_probe() -> void:
    var output: Array = []
    var arguments := PackedStringArray([
        "--headless",
        "--path", ProjectSettings.globalize_path("res://"),
        "--script", "res://tests/run_all.gd",
        "--quit-after", "1",
        "--",
        "--warp-cargo-controller-invalid-probe=partial_dependency",
    ])
    OS.execute(OS.get_executable_path(), arguments, output, true)
    var output_lines := PackedStringArray()
    for chunk in output:
        output_lines.append(str(chunk))
    var captured_text := "\n".join(output_lines)
    assert_true(
        captured_text.contains("WARP_CARGO_CONTROLLER_INVALID_PROBE_BEGIN:partial_dependency"),
        "Partial dependency probe starts"
    )
    assert_true(
        captured_text.contains("Warp pair and cargo systems must both be provided or both be null"),
        "Partial dependency probe reports the owner assertion"
    )


func run_invalid_probe(case_name: String) -> void:
    if case_name != "partial_dependency":
        return
    var config := _config()
    var track := TrackSystemScript.new(config)
    var train := TrainSystemScript.new(config.train_speed_cells_per_second)
    var warp := WarpPairSystemScript.new(config, SessionRngScript.new(config.seed))
    SessionControllerScript.new(config, track, train, warp, null)


func _test_snapshot_and_result_expose_warp_cargo_observations() -> void:
    var snapshot := SessionSnapshotScript.new(10, 2, 8, 1)
    for method_name in [
        "get_warp_pair_records",
        "get_cargo_slot_records",
        "get_occupied_cargo_slots",
        "get_total_cargo_slots",
        "get_delivered_pair_count",
        "get_base_delivery_reward_total",
        "get_warp_cargo_events",
    ]:
        assert_true(snapshot.has_method(method_name), "Snapshot exposes " + method_name)

    var result := SessionResultScript.new(
        SessionResultScript.Reason.REGULAR_TIME_EXPIRED, 10, 10, 0
    )
    assert_true(
        result.has_method("get_delivered_pair_count"),
        "Result exposes delivered pair count"
    )
    assert_true(
        result.has_method("get_base_delivery_reward_total"),
        "Result exposes base delivery reward total"
    )


func _test_preparation_freezes_scheduling_and_departure_starts_tick_one() -> void:
    var fixture := _fixture(_config())
    var controller: SessionControllerScript = fixture["controller"]
    var track: ContactTrackSpy = fixture["track"]
    controller.start()
    controller.advance_tick()
    assert_equal(
        controller.get_snapshot().get_warp_pair_records(),
        [],
        "Preparing departure schedules no Warp pair"
    )
    assert_equal(track.anchor_batches, [], "Preparing departure installs no Warp anchors")

    track.allow_prepare = false
    controller.advance_tick(_draw_frame([Vector2i(1, 0), Vector2i(2, 0)]))
    assert_equal(controller.get_state(), SessionControllerScript.State.PREPARING_DEPARTURE, "Failed readiness stays preparing")
    assert_equal(controller.get_snapshot().get_warp_pair_records(), [], "Failed readiness schedules no pair")
    assert_equal(track.anchor_batches, [], "Failed readiness installs no Warp anchors")

    track.allow_prepare = true
    track.event_log.clear()
    controller.advance_tick()
    var snapshot: SessionSnapshotScript = controller.get_snapshot()
    assert_equal(controller.get_state(), SessionControllerScript.State.RUNNING, "Fixture departs")
    assert_equal(snapshot.get_warp_pair_records().size(), 1, "Departure creates running tick one")
    _assert_event_types(
        snapshot.get_warp_cargo_events(),
        [&"FORECASTED", &"ACTIVATED"],
        "Zero forecast activates on departure tick one"
    )
    assert_equal(track.query_ranges, [Vector2(0.0, 0.25)], "Departure query receives actual sweep")
    assert_true(
		_event_index(track.event_log, "construction") < _event_index(track.event_log, "prepare")
		and _event_index(track.event_log, "prepare") < _event_index(track.event_log, "anchors:")
		and _event_index(track.event_log, "anchors:") < _event_index(track.event_log, "hits"),
		"Departure installs active anchors after readiness and before movement contact"
    )

    track.event_log.clear()
    controller.advance_tick()
    assert_true(
        not track.event_log.is_empty() and track.event_log[0].begins_with("anchors:"),
        "A running tick installs begin-tick anchors before input"
    )
    if not track.query_ranges.is_empty():
        assert_equal(
            track.query_ranges[-1],
            Vector2(0.25, 0.5),
            "Running query receives previous and through train distances"
        )


func _test_running_prepare_failure_rolls_back_warp_tick() -> void:
    var reference_fixture := _fixture(_config())
    var reference_controller: SessionControllerScript = reference_fixture["controller"]
    reference_controller.start()
    reference_controller.advance_tick(_draw_frame([Vector2i(1, 0), Vector2i(2, 0)]))
    reference_controller.advance_tick()
    var reference_snapshot: SessionSnapshotScript = reference_controller.get_snapshot()

    var fixture := _fixture(_config())
    var controller: SessionControllerScript = fixture["controller"]
    var track: ContactTrackSpy = fixture["track"]
    controller.start()
    controller.advance_tick(_draw_frame([Vector2i(1, 0), Vector2i(2, 0)]))
    var tick_one_snapshot: SessionSnapshotScript = controller.get_snapshot()

    track.allow_prepare = false
    controller.advance_tick()
    assert_true(
        controller.get_snapshot() == tick_one_snapshot,
        "Failed running preparation publishes no snapshot"
    )

    track.allow_prepare = true
    controller.advance_tick()
    var tick_two_snapshot: SessionSnapshotScript = controller.get_snapshot()
    assert_equal(tick_two_snapshot.get_elapsed_ticks(), 2, "Retry advances exactly one session tick")
    assert_equal(tick_two_snapshot.get_warp_pair_records().size(), 2, "Retry creates only the tick-two pair")
    _assert_event_types(
        tick_two_snapshot.get_warp_cargo_events(),
        [&"FORECASTED", &"ACTIVATED"],
        "Retry publishes the tick-two Warp events"
    )
    for event in tick_two_snapshot.get_warp_cargo_events():
        assert_equal(event["tick"], 2, "Retry events retain the accepted running tick index")
    assert_equal(
        _pair_signatures(tick_two_snapshot.get_warp_pair_records()),
        _pair_signatures(reference_snapshot.get_warp_pair_records()),
        "Failed preparation consumes no Warp RNG or lifecycle state"
    )


func _test_controller_resolves_ordinal_and_physical_hit_order() -> void:
    var ordinal_fixture := _fixture(_config())
    var ordinal_controller: SessionControllerScript = ordinal_fixture["controller"]
    var ordinal_track: ContactTrackSpy = ordinal_fixture["track"]
    ordinal_controller.start()
    ordinal_controller.advance_tick(_draw_frame([Vector2i(1, 0), Vector2i(2, 0)]))
    ordinal_track.query_mode = &"ordinal_origins"
    ordinal_controller.advance_tick()
    var ordinal_pairs: Array = ordinal_controller.get_snapshot().get_warp_pair_records()
    assert_equal(ordinal_pairs.size(), 2, "Ordinal fixture creates two active pairs")
    if ordinal_pairs.size() == 2:
        assert_equal(
            ordinal_pairs[0].state,
            WarpPairRecordScript.State.IN_TRANSIT,
            "Lower ordinal wins equal-distance cargo capacity"
        )
        assert_equal(
            ordinal_pairs[1].state,
            WarpPairRecordScript.State.ACTIVE_UNLOADED,
            "Higher ordinal remains unloaded at full capacity"
        )

    var turnover_fixture := _fixture(_config())
    var turnover_controller: SessionControllerScript = turnover_fixture["controller"]
    var turnover_track: ContactTrackSpy = turnover_fixture["track"]
    turnover_controller.start()
    turnover_controller.advance_tick(_draw_frame([Vector2i(1, 0), Vector2i(2, 0)]))
    turnover_track.query_mode = &"turnover"
    turnover_controller.advance_tick()
    var turnover_snapshot: SessionSnapshotScript = turnover_controller.get_snapshot()
    _assert_event_types(
        turnover_snapshot.get_warp_cargo_events(),
        [&"FORECASTED", &"ACTIVATED", &"LOADED", &"DELIVERED", &"LOADED"],
        "Physical hit order frees and reuses one slot in the same controller sweep"
    )
    assert_equal(turnover_snapshot.get_delivered_pair_count(), 1, "Turnover pays one delivery")
    assert_equal(turnover_snapshot.get_base_delivery_reward_total(), 37, "Turnover pays exact reward")
    var slots: Array = turnover_snapshot.get_cargo_slot_records()
    if slots.size() == 1:
        assert_equal(slots[0].pair_id, &"warp_pair_2", "Later physical origin reuses freed slot")
        slots[0].pair_id = &"mutated"
        slots[0].slot_index = 99
        var fresh_slots: Array = turnover_snapshot.get_cargo_slot_records()
        assert_equal(fresh_slots[0].pair_id, &"warp_pair_2", "Snapshot cargo slot ID is detached")
        assert_equal(fresh_slots[0].slot_index, 0, "Snapshot cargo slot index is detached")


func _test_final_life_delivery_survives_regular_track_end_tie() -> void:
    var config := _config(1.0, 1.0, 1, 1)
    var fixture := _fixture(config)
    var controller: SessionControllerScript = fixture["controller"]
    var track: ContactTrackSpy = fixture["track"]
    track.query_mode = &"all_same"
    var publish_order: Array[String] = []
    var results: Array[SessionResultScript] = []
    controller.snapshot_published.connect(func(snapshot):
        if snapshot.get_state() == SessionControllerScript.State.COMPLETED:
            publish_order.append("snapshot")
    )
    controller.session_completed.connect(func(result):
        publish_order.append("result")
        results.append(result)
    )
    controller.start()
    controller.advance_tick(_draw_frame([Vector2i(1, 0)]))
    assert_equal(publish_order, ["snapshot", "result"], "Terminal snapshot precedes one result")
    assert_equal(results.size(), 1, "Completion emits one result")
    var terminal: SessionSnapshotScript = controller.get_snapshot()
    _assert_event_types(
        terminal.get_warp_cargo_events(),
        [&"FORECASTED", &"ACTIVATED", &"LOADED", &"DELIVERED"],
        "Final-life movement delivers before pair expiry and session completion"
    )
    var terminal_pairs: Array = terminal.get_warp_pair_records()
    if terminal_pairs.size() == 1:
        assert_equal(terminal_pairs[0].state, WarpPairRecordScript.State.DELIVERED, "Delivered pair does not expire or void")
    assert_equal(terminal.get_delivered_pair_count(), 1, "Terminal snapshot retains delivery")
    assert_equal(terminal.get_base_delivery_reward_total(), 37, "Terminal snapshot retains reward")
    if results.size() == 1:
        assert_equal(results[0].get_reason(), SessionResultScript.Reason.REGULAR_TIME_EXPIRED, "Regular expiry wins track-end tie")
        assert_equal(results[0].get_delivered_pair_count(), 1, "Result retains delivery")
        assert_equal(results[0].get_base_delivery_reward_total(), 37, "Result retains reward")

    var pairs := terminal.get_warp_pair_records()
    var events := terminal.get_warp_cargo_events()
    if not pairs.is_empty():
        pairs[0].pair_id = &"mutated"
        assert_equal(terminal.get_warp_pair_records()[0].pair_id, &"warp_pair_1", "Pair getter is detached")
    if not events.is_empty():
        events[0]["type"] = &"MUTATED"
        assert_equal(terminal.get_warp_cargo_events()[0]["type"], &"FORECASTED", "Event getter is detached")
    controller.advance_tick(_draw_frame([Vector2i(2, 0)]))
    controller.start()
    assert_true(controller.get_snapshot() == terminal, "Post-completion mutation calls are inert")
    assert_equal(results.size(), 1, "Post-completion calls emit no second result")


func _test_regular_and_early_completion_void_nonterminal_cargo() -> void:
    _assert_completion_voids(1.0, 0.25, 2, SessionResultScript.Reason.REGULAR_TIME_EXPIRED, "Regular")
    _assert_completion_voids(10.0, 1.0, 1, SessionResultScript.Reason.TRACK_END_REACHED, "Early")


func _assert_completion_voids(
    duration: float,
    speed: float,
    route_cells: int,
    expected_reason: int,
    label: String
) -> void:
    var fixture := _fixture(_config(duration, speed, 5, 1))
    var controller: SessionControllerScript = fixture["controller"]
    var track: ContactTrackSpy = fixture["track"]
    track.query_mode = &"origin_only"
    var results: Array[SessionResultScript] = []
    controller.session_completed.connect(func(result): results.append(result))
    controller.start()
    var cells: Array[Vector2i] = []
    for index in range(1, route_cells + 1):
        cells.append(Vector2i(index, 0))
    controller.advance_tick(_draw_frame(cells))
    var terminal: SessionSnapshotScript = controller.get_snapshot()
    assert_equal(terminal.get_occupied_cargo_slots(), 0, "%s completion clears cargo" % label)
    var pairs: Array = terminal.get_warp_pair_records()
    if pairs.size() == 1:
        assert_equal(pairs[0].state, WarpPairRecordScript.State.VOIDED, "%s completion voids the in-transit pair" % label)
    assert_equal(_event_count(terminal.get_warp_cargo_events(), &"VOIDED"), 1, "%s completion voids once" % label)
    assert_equal(terminal.get_delivered_pair_count(), 0, "%s void adds no delivery" % label)
    assert_equal(terminal.get_base_delivery_reward_total(), 0, "%s void adds no reward" % label)
    if results.size() == 1:
        assert_equal(results[0].get_reason(), expected_reason, "%s completion reason is stable" % label)


func _test_pair_expiry_precedes_regular_completion_void() -> void:
    var fixture := _fixture(_config(1.0, 0.25, 1, 1))
    var controller: SessionControllerScript = fixture["controller"]
    controller.start()
    controller.advance_tick(_draw_frame([Vector2i(1, 0), Vector2i(2, 0)]))
    var terminal: SessionSnapshotScript = controller.get_snapshot()
    _assert_event_types(
        terminal.get_warp_cargo_events(),
        [&"FORECASTED", &"ACTIVATED", &"EXPIRED"],
        "Pair expiry resolves before regular completion has anything to void"
    )
    var pairs: Array = terminal.get_warp_pair_records()
    if pairs.size() == 1:
        assert_equal(pairs[0].state, WarpPairRecordScript.State.EXPIRED, "Expired pair is not rewritten as voided")


func _config(
    duration: float = 10.0,
    speed: float = 0.25,
    lifetime_ticks: int = 5,
    cargo_slots: int = 1
) -> SessionStartConfigScript:
    return SessionStartConfigScript.new(
        73013, duration, 1,
        speed, 8, 1, 2.0, 10.0, 1,
        Vector2(240.0, 160.0), Vector2i(6, 4), 40.0, Vector2.ZERO,
        &"warp_departure", Vector2(20.0, 20.0), Vector2i(0, 0),
        0, 1, lifetime_ticks, lifetime_ticks, 2, cargo_slots, 37
    )


func _fixture(config: SessionStartConfigScript) -> Dictionary:
    var track := ContactTrackSpy.new(config)
    var train := TrainSystemScript.new(config.train_speed_cells_per_second)
    var warp := WarpPairSystemScript.new(config, SessionRngScript.new(config.seed))
    var cargo := CargoSystemScript.new(
        config.cargo_base_slot_count, config.cargo_base_delivery_reward
    )
    var controller := SessionControllerScript.new(config, track, train, warp, cargo)
    return {
        "track": track,
        "train": train,
        "warp": warp,
        "cargo": cargo,
        "controller": controller,
    }


func _draw_frame(cells: Array[Vector2i]) -> TrackInputFrameScript:
    return TrackInputFrameScript.new(
        cells, Vector2i(0, 0), true, Vector2i(-1, -1), false,
        true, false, true, false, cells[-1], true
    )


func _held_endpoint(endpoint: Vector2i) -> TrackInputFrameScript:
    var empty: Array[Vector2i] = []
    return TrackInputFrameScript.new(
        empty, endpoint, true, Vector2i(-1, -1), false,
        true, true, false, false, endpoint, true
    )


func _assert_event_types(events: Array[Dictionary], expected: Array, message: String) -> void:
    var actual: Array[StringName] = []
    for event in events:
        actual.append(event["type"])
    assert_equal(actual, expected, message)


func _event_count(events: Array[Dictionary], type: StringName) -> int:
    var count := 0
    for event in events:
        if event["type"] == type:
            count += 1
    return count


func _event_index(events: Array[String], prefix: String) -> int:
    for index in range(events.size()):
        if events[index].begins_with(prefix):
            return index
    return -1


func _pair_signatures(records: Array) -> Array[Dictionary]:
    var signatures: Array[Dictionary] = []
    for record in records:
        signatures.append({
            "ordinal": record.ordinal,
            "pair_id": record.pair_id,
            "origin_cell": record.origin_cell,
            "destination_cell": record.destination_cell,
            "lifetime_total_ticks": record.lifetime_total_ticks,
            "lifetime_remaining_ticks": record.lifetime_remaining_ticks,
            "forecast_remaining_ticks": record.forecast_remaining_ticks,
            "style_index": record.style_index,
            "state": record.state,
        })
    return signatures
