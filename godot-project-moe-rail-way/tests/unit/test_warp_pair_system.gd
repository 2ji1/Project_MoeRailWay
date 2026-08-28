extends "res://tests/support/prototype_test.gd"

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const PrototypeConfigValidatorScript = preload("res://src/config/prototype_config_validator.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")
const WarpPairSystemScript = preload("res://src/domain/warp/warp_pair_system.gd")


func run() -> PackedStringArray:
    _test_balance_defaults_and_copy()
    _test_balance_validation()
    _test_row_major_mapping()
    _test_equal_cell_generation_and_draw_order()
    _test_forecast_activation_and_anchors()
    _test_capacity_gating_and_delayed_cadence()
    _test_expiry_void_and_idempotence()
    _test_fixed_seed_replay_and_detached_observations()
    return finish()


func _test_balance_defaults_and_copy() -> void:
    var balance := PrototypeBalanceScript.new()
    assert_equal(
        balance.warp_lifecycle_balance.forecast_duration_seconds,
        8.0,
        "Warp forecast duration default must be 8 seconds"
    )
    assert_equal(
        balance.warp_lifecycle_balance.generation_interval_seconds,
        12.0,
        "Warp generation interval default must be 12 seconds"
    )
    assert_equal(
        balance.warp_lifecycle_balance.lifetime_min_seconds,
        24.0,
        "Warp minimum lifetime default must be 24 seconds"
    )
    assert_equal(
        balance.warp_lifecycle_balance.lifetime_max_seconds,
        36.0,
        "Warp maximum lifetime default must be 36 seconds"
    )
    assert_equal(
        balance.warp_lifecycle_balance.max_live_pairs,
        3,
        "Warp live-pair default must be 3"
    )
    assert_equal(balance.cargo_balance.base_slot_count, 2, "Cargo slot default must be 2")
    assert_equal(
        balance.cargo_balance.base_delivery_reward,
        100,
        "Cargo base reward default must be 100"
    )

    balance.simulation_ticks_per_second = 10
    balance.warp_lifecycle_balance.forecast_duration_seconds = 0.21
    balance.warp_lifecycle_balance.generation_interval_seconds = 1.01
    balance.warp_lifecycle_balance.lifetime_min_seconds = 1.01
    balance.warp_lifecycle_balance.lifetime_max_seconds = 1.29
    balance.warp_lifecycle_balance.max_live_pairs = 4
    balance.cargo_balance.base_slot_count = 5
    balance.cargo_balance.base_delivery_reward = 37
    var config = _complete_config(balance, 73013, Vector2i(3, 2))
    assert_equal(config.warp_forecast_ticks, 3, "Forecast seconds must ceil to ticks")
    assert_equal(
        config.warp_generation_interval_ticks,
        11,
        "Generation seconds must ceil to ticks"
    )
    assert_equal(config.warp_lifetime_min_ticks, 11, "Minimum lifetime must ceil to ticks")
    assert_equal(config.warp_lifetime_max_ticks, 13, "Maximum lifetime must ceil to ticks")
    assert_equal(config.warp_max_live_pairs, 4, "Live-pair count must copy by value")
    assert_equal(config.cargo_base_slot_count, 5, "Cargo slot count must copy by value")
    assert_equal(
        config.cargo_base_delivery_reward,
        37,
        "Cargo reward must copy by value"
    )
    balance.warp_lifecycle_balance.max_live_pairs = 1
    balance.cargo_balance.base_slot_count = 1
    assert_equal(config.warp_max_live_pairs, 4, "Running config must detach from balance edits")
    assert_equal(config.cargo_base_slot_count, 5, "Cargo config must detach from balance edits")


func _test_balance_validation() -> void:
    var missing_warp := PrototypeBalanceScript.new()
    missing_warp.warp_lifecycle_balance = null
    _assert_contains(
        PrototypeConfigValidatorScript.validate(missing_warp),
        "prototype_balance.warp_lifecycle_balance.resource"
    )

    var missing_cargo := PrototypeBalanceScript.new()
    missing_cargo.cargo_balance = null
    _assert_contains(
        PrototypeConfigValidatorScript.validate(missing_cargo),
        "prototype_balance.cargo_balance.resource"
    )

    var invalid_float_cases := [
        ["forecast_duration_seconds", -0.1],
        ["forecast_duration_seconds", 60.1],
        ["forecast_duration_seconds", NAN],
        ["generation_interval_seconds", 0.0],
        ["generation_interval_seconds", 120.1],
        ["generation_interval_seconds", INF],
        ["lifetime_min_seconds", 0.9],
        ["lifetime_min_seconds", 180.1],
        ["lifetime_min_seconds", NAN],
        ["lifetime_max_seconds", 0.9],
        ["lifetime_max_seconds", 180.1],
        ["lifetime_max_seconds", INF],
    ]
    for invalid_case in invalid_float_cases:
        var balance := PrototypeBalanceScript.new()
        balance.warp_lifecycle_balance.set(invalid_case[0], invalid_case[1])
        _assert_contains(
            PrototypeConfigValidatorScript.validate(balance),
            "prototype_balance.warp_lifecycle_balance.%s" % invalid_case[0]
        )

    var reversed_lifetime := PrototypeBalanceScript.new()
    reversed_lifetime.warp_lifecycle_balance.lifetime_min_seconds = 20.0
    reversed_lifetime.warp_lifecycle_balance.lifetime_max_seconds = 19.9
    _assert_contains(
        PrototypeConfigValidatorScript.validate(reversed_lifetime),
        "prototype_balance.warp_lifecycle_balance.lifetime_max_seconds"
    )

    for invalid_live_count in [0, 7]:
        var balance := PrototypeBalanceScript.new()
        balance.warp_lifecycle_balance.max_live_pairs = invalid_live_count
        _assert_contains(
            PrototypeConfigValidatorScript.validate(balance),
            "prototype_balance.warp_lifecycle_balance.max_live_pairs"
        )

    for invalid_slot_count in [0, 9]:
        var balance := PrototypeBalanceScript.new()
        balance.cargo_balance.base_slot_count = invalid_slot_count
        _assert_contains(
            PrototypeConfigValidatorScript.validate(balance),
            "prototype_balance.cargo_balance.base_slot_count"
        )

    for invalid_reward in [-1, 1000001]:
        var balance := PrototypeBalanceScript.new()
        balance.cargo_balance.base_delivery_reward = invalid_reward
        _assert_contains(
            PrototypeConfigValidatorScript.validate(balance),
            "prototype_balance.cargo_balance.base_delivery_reward"
        )


func _test_row_major_mapping() -> void:
    var expected := [
        Vector2i(0, 0),
        Vector2i(1, 0),
        Vector2i(2, 0),
        Vector2i(0, 1),
        Vector2i(1, 1),
        Vector2i(2, 1),
    ]
    for index in range(expected.size()):
        assert_equal(
            WarpPairSystemScript.cell_from_row_major_index(index, Vector2i(3, 2)),
            expected[index],
            "Row-major index %d must map across the complete grid" % index
        )
    assert_equal(
        WarpPairSystemScript.cell_from_row_major_index(-1, Vector2i(3, 2)),
        Vector2i(-1, -1),
        "Negative row-major index must be rejected"
    )
    assert_equal(
        WarpPairSystemScript.cell_from_row_major_index(6, Vector2i(3, 2)),
        Vector2i(-1, -1),
        "Out-of-range row-major index must be rejected"
    )
    assert_equal(
        WarpPairSystemScript.cell_from_row_major_index(0, Vector2i.ZERO),
        Vector2i(-1, -1),
        "Invalid grid size must be rejected"
    )


func _test_equal_cell_generation_and_draw_order() -> void:
    var equal_balance := _make_warp_balance(0.0, 5.0, 1.0, 1.0, 1)
    var equal_config = _complete_config(equal_balance, 42, Vector2i.ONE)
    var equal_rng := SessionRngScript.new(42)
    var equal_system := WarpPairSystemScript.new(equal_config, equal_rng)
    equal_system.begin_running_tick(1)
    var equal_records: Array = equal_system.get_pair_records()
    assert_equal(equal_records.size(), 1, "First running tick must generate one pair")
    if equal_records.size() == 1:
        var pair = equal_records[0]
        assert_equal(pair.pair_id, StringName("warp_pair_1"), "Pair ID must use ordinal 1")
        assert_equal(pair.ordinal, 1, "First pair ordinal must be 1")
        assert_equal(pair.origin_cell, Vector2i.ZERO, "1x1 origin must be the only cell")
        assert_equal(
            pair.destination_cell,
            Vector2i.ZERO,
            "Equal-cell destination must be accepted without reroll"
        )
        assert_equal(
            pair.state,
            WarpPairRecordScript.State.ACTIVE_UNLOADED,
            "Zero-tick forecast must activate on its generation tick"
        )
    var equal_mirror := SessionRngScript.new(42)
    equal_mirror.next_index(1)
    equal_mirror.next_index(1)
    equal_mirror.next_index(1)
    assert_equal(
        equal_rng.next_u32(),
        equal_mirror.next_u32(),
        "Equal-cell generation must consume exactly three draws without reroll"
    )

    var draw_balance := _make_warp_balance(2.0, 4.0, 4.0, 9.0, 3)
    var draw_config = _complete_config(draw_balance, 73013, Vector2i(3, 2))
    var actual_rng := SessionRngScript.new(73013)
    var expected_rng := SessionRngScript.new(73013)
    var expected_origin_index := expected_rng.next_index(6)
    var expected_destination_index := expected_rng.next_index(6)
    var expected_lifetime := 4 + expected_rng.next_index(6)
    var draw_system := WarpPairSystemScript.new(draw_config, actual_rng)
    draw_system.begin_running_tick(1)
    var draw_records: Array = draw_system.get_pair_records()
    assert_equal(draw_records.size(), 1, "Draw-order fixture must generate one forecast")
    if draw_records.size() == 1:
        var pair = draw_records[0]
        assert_equal(
            pair.origin_cell,
            WarpPairSystemScript.cell_from_row_major_index(expected_origin_index, Vector2i(3, 2)),
            "Origin must consume the first pair draw"
        )
        assert_equal(
            pair.destination_cell,
            WarpPairSystemScript.cell_from_row_major_index(expected_destination_index, Vector2i(3, 2)),
            "Destination must consume the second pair draw"
        )
        assert_equal(
            pair.lifetime_total_ticks,
            expected_lifetime,
            "Lifetime must consume the third pair draw"
        )
        assert_equal(pair.style_index, 0, "First live pair must receive style zero without RNG")
    assert_equal(
        actual_rng.next_u32(),
        expected_rng.next_u32(),
        "Pair ID and style assignment must not consume RNG"
    )


func _test_forecast_activation_and_anchors() -> void:
    var balance := _make_warp_balance(2.0, 10.0, 5.0, 5.0, 2)
    var config = _complete_config(balance, 91, Vector2i(2, 2))
    var system := WarpPairSystemScript.new(config, SessionRngScript.new(91))
    system.begin_running_tick(1)
    var records: Array = system.get_pair_records()
    assert_equal(records.size(), 1, "Tick 1 must publish its forecast")
    if records.size() == 1:
        assert_equal(
            records[0].forecast_remaining_ticks,
            2,
            "Generation tick must retain the full forecast counter"
        )
        assert_equal(
            records[0].state,
            WarpPairRecordScript.State.FORECAST,
            "Positive forecast must remain informational"
        )
    assert_equal(system.get_route_contact_anchors().size(), 0, "Forecast must have no anchors")
    _assert_event_types(system.get_tick_events(), [&"FORECASTED"], "Forecast tick event order")

    system.begin_running_tick(2)
    records = system.get_pair_records()
    if records.size() == 1:
        assert_equal(
            records[0].forecast_remaining_ticks,
            1,
            "Second running tick must decrement forecast to one"
        )
    assert_equal(system.get_route_contact_anchors().size(), 0, "Counter one must remain anchor-free")

    system.begin_running_tick(3)
    records = system.get_pair_records()
    if records.size() == 1:
        assert_equal(
            records[0].state,
            WarpPairRecordScript.State.ACTIVE_UNLOADED,
            "Counter reaching zero must activate before publication"
        )
        assert_equal(records[0].lifetime_remaining_ticks, 5, "Activation starts full lifetime")
    var anchors: Array = system.get_route_contact_anchors()
    assert_equal(anchors.size(), 2, "Active unloaded pair must publish both anchors")
    if anchors.size() == 2 and records.size() == 1:
        assert_equal(
            anchors[0].anchor_id,
            StringName("warp_pair_1/origin"),
            "Origin anchor ID must be stable"
        )
        assert_equal(anchors[0].cell, records[0].origin_cell, "Origin anchor must use generated cell")
        assert_equal(
            anchors[1].anchor_id,
            StringName("warp_pair_1/destination"),
            "Destination anchor ID must be stable"
        )
        assert_equal(
            anchors[1].cell,
            records[0].destination_cell,
            "Destination anchor must use generated cell"
        )
    _assert_event_types(system.get_tick_events(), [&"ACTIVATED"], "Activation tick event order")


func _test_capacity_gating_and_delayed_cadence() -> void:
    var balance := _make_warp_balance(0.0, 1.0, 3.0, 3.0, 2)
    var config = _complete_config(balance, 404, Vector2i(3, 2))
    var system_rng := SessionRngScript.new(404)
    var mirror_rng := SessionRngScript.new(404)
    var system := WarpPairSystemScript.new(config, system_rng)

    system.begin_running_tick(1)
    mirror_rng.next_index(6)
    mirror_rng.next_index(6)
    mirror_rng.next_index(1)
    system.expire_after_contact(1)
    system.begin_running_tick(2)
    mirror_rng.next_index(6)
    mirror_rng.next_index(6)
    mirror_rng.next_index(1)
    system.expire_after_contact(2)
    system.begin_running_tick(3)
    assert_equal(
        system.get_pair_records().size(),
        2,
        "Due generation must remain pending while the live-pair limit is full"
    )
    assert_equal(system.get_tick_events().size(), 0, "Blocked due tick must consume no generation")
    assert_equal(
        system_rng.next_u32(),
        mirror_rng.next_u32(),
        "Blocked due tick must consume no RNG"
    )
    system.expire_after_contact(3)

    var expected_origin_index := mirror_rng.next_index(6)
    var expected_destination_index := mirror_rng.next_index(6)
    var expected_lifetime := 3 + mirror_rng.next_index(1)
    system.begin_running_tick(4)
    var tick_four_records: Array = system.get_pair_records()
    assert_equal(
        tick_four_records.size(),
        3,
        "One delayed opportunity must generate when a live slot opens"
    )
    if tick_four_records.size() == 3:
        assert_equal(tick_four_records[2].ordinal, 3, "Delayed pair ordinal must remain monotonic")
        assert_equal(
            tick_four_records[2].style_index,
            0,
            "Delayed pair must take the lowest unused live style"
        )
        assert_equal(
            tick_four_records[2].origin_cell,
            WarpPairSystemScript.cell_from_row_major_index(
                expected_origin_index,
                Vector2i(3, 2)
            ),
            "Delayed pair origin must use the first unconsumed draw"
        )
        assert_equal(
            tick_four_records[2].destination_cell,
            WarpPairSystemScript.cell_from_row_major_index(
                expected_destination_index,
                Vector2i(3, 2)
            ),
            "Delayed pair destination must use the second unconsumed draw"
        )
        assert_equal(
            tick_four_records[2].lifetime_total_ticks,
            expected_lifetime,
            "Delayed pair lifetime must use the third unconsumed draw"
        )
    system.expire_after_contact(4)

    system.begin_running_tick(5)
    var tick_five_records: Array = system.get_pair_records()
    assert_equal(
        tick_five_records.size(),
        4,
        "Delayed pair actual tick must become the next interval base"
    )
    if tick_five_records.size() == 4:
        assert_equal(tick_five_records[3].style_index, 1, "Live style ownership must stay unique")


func _test_expiry_void_and_idempotence() -> void:
    var expiry_balance := _make_warp_balance(0.0, 10.0, 1.0, 1.0, 1)
    var expiry_config = _complete_config(expiry_balance, 51, Vector2i(2, 2))
    var expiry_system := WarpPairSystemScript.new(expiry_config, SessionRngScript.new(51))
    expiry_system.begin_running_tick(1)
    expiry_system.begin_running_tick(1)
    assert_equal(
        expiry_system.get_pair_records().size(),
        1,
        "Repeated begin on one tick must not generate twice"
    )
    expiry_system.expire_after_contact(1)
    expiry_system.expire_after_contact(1)
    var expired_records: Array = expiry_system.get_pair_records()
    if expired_records.size() == 1:
        assert_equal(
            expired_records[0].state,
            WarpPairRecordScript.State.EXPIRED,
            "Final active lifetime tick must expire once"
        )
        assert_equal(
            expired_records[0].lifetime_remaining_ticks,
            0,
            "Expiry must consume exactly one final lifetime tick"
        )
    _assert_event_types(
        expiry_system.get_tick_events(),
        [&"FORECASTED", &"ACTIVATED", &"EXPIRED"],
        "Zero-forecast expiry event order"
    )
    assert_equal(expiry_system.get_route_contact_anchors().size(), 0, "Expired pair has no anchors")

    var void_balance := _make_warp_balance(4.0, 10.0, 5.0, 5.0, 1)
    var void_config = _complete_config(void_balance, 52, Vector2i(2, 2))
    var void_system := WarpPairSystemScript.new(void_config, SessionRngScript.new(52))
    void_system.begin_running_tick(1)
    void_system.void_nonterminal(1)
    void_system.void_nonterminal(1)
    var void_records: Array = void_system.get_pair_records()
    if void_records.size() == 1:
        assert_equal(
            void_records[0].state,
            WarpPairRecordScript.State.VOIDED,
            "Regular end must void a forecast exactly once"
        )
    _assert_event_types(
        void_system.get_tick_events(),
        [&"FORECASTED", &"VOIDED"],
        "Void event order must be idempotent"
    )
    void_system.begin_running_tick(2)
    assert_equal(
        void_system.get_pair_records().size(),
        1,
        "Terminal void must prevent later generation"
    )


func _test_fixed_seed_replay_and_detached_observations() -> void:
    var replay_balance := _make_warp_balance(1.0, 2.0, 2.0, 4.0, 3)
    var first_config = _complete_config(replay_balance, 8181, Vector2i(3, 3))
    var second_config = _complete_config(replay_balance, 8181, Vector2i(3, 3))
    var first := WarpPairSystemScript.new(first_config, SessionRngScript.new(8181))
    var second := WarpPairSystemScript.new(second_config, SessionRngScript.new(8181))
    var first_history := []
    var second_history := []
    for tick in range(1, 9):
        first.begin_running_tick(tick)
        second.begin_running_tick(tick)
        first.expire_after_contact(tick)
        second.expire_after_contact(tick)
        first_history.append(_system_observation(first))
        second_history.append(_system_observation(second))
    assert_equal(
        first_history,
        second_history,
        "Matching seed, config, and ticks must replay complete records and events"
    )

    var records: Array = first.get_pair_records()
    var anchors: Array = first.get_route_contact_anchors()
    var events: Array[Dictionary] = first.get_tick_events()
    if not records.is_empty():
        records[0].pair_id = &"mutated"
        records[0].origin_cell = Vector2i(99, 99)
        records[0].state = WarpPairRecordScript.State.DELIVERED
        var fresh_records: Array = first.get_pair_records()
        assert_false(fresh_records[0].pair_id == &"mutated", "Pair records must be detached")
        assert_false(
            fresh_records[0].origin_cell == Vector2i(99, 99),
            "Pair cells must be detached"
        )
        assert_false(
            fresh_records[0].state == WarpPairRecordScript.State.DELIVERED,
            "Pair state must be detached"
        )
    if not anchors.is_empty():
        anchors[0].anchor_id = &"mutated"
        anchors[0].cell = Vector2i(99, 99)
        var fresh_anchors: Array = first.get_route_contact_anchors()
        assert_false(fresh_anchors[0].anchor_id == &"mutated", "Anchors must be detached")
        assert_false(fresh_anchors[0].cell == Vector2i(99, 99), "Anchor cells must be detached")
    if not events.is_empty():
        events[0]["type"] = &"MUTATED"
        var fresh_events: Array[Dictionary] = first.get_tick_events()
        assert_false(fresh_events[0]["type"] == &"MUTATED", "Events must be detached")


func _make_warp_balance(
    forecast_seconds: float,
    interval_seconds: float,
    lifetime_min_seconds: float,
    lifetime_max_seconds: float,
    max_live_pairs: int
) -> Resource:
    var balance := PrototypeBalanceScript.new()
    balance.simulation_ticks_per_second = 1
    balance.warp_lifecycle_balance.forecast_duration_seconds = forecast_seconds
    balance.warp_lifecycle_balance.generation_interval_seconds = interval_seconds
    balance.warp_lifecycle_balance.lifetime_min_seconds = lifetime_min_seconds
    balance.warp_lifecycle_balance.lifetime_max_seconds = lifetime_max_seconds
    balance.warp_lifecycle_balance.max_live_pairs = max_live_pairs
    return balance


func _complete_config(balance: Resource, seed_value: int, grid_size: Vector2i):
    var base_config = balance.create_session_start_config(seed_value)
    return balance.complete_session_start_config(
        base_config,
        Vector2(grid_size) * 40.0,
        &"departure",
        Vector2(20.0, 20.0),
        40.0,
        grid_size,
        Vector2.ZERO,
        Vector2i.ZERO
    )


func _assert_contains(errors: PackedStringArray, fragment: String) -> void:
    var found := false
    for error_message in errors:
        found = found or error_message.contains(fragment)
    assert_true(found, "Expected owner-qualified validation error containing %s" % fragment)


func _assert_event_types(events: Array[Dictionary], expected: Array, message: String) -> void:
    var actual := []
    for event in events:
        actual.append(event.get("type", StringName()))
        assert_true(event.has("tick"), "%s event must include tick" % message)
        assert_true(event.has("pair_id"), "%s event must include pair_id" % message)
        assert_true(event.has("slot_index"), "%s event must include slot_index" % message)
        assert_true(event.has("amount"), "%s event must include amount" % message)
    assert_equal(actual, expected, message)


func _system_observation(system: RefCounted) -> Dictionary:
    var serialized_records := []
    for record in system.get_pair_records():
        serialized_records.append({
            "pair_id": record.pair_id,
            "ordinal": record.ordinal,
            "origin_cell": record.origin_cell,
            "destination_cell": record.destination_cell,
            "state": record.state,
            "forecast_remaining_ticks": record.forecast_remaining_ticks,
            "lifetime_total_ticks": record.lifetime_total_ticks,
            "lifetime_remaining_ticks": record.lifetime_remaining_ticks,
            "style_index": record.style_index,
        })
    return {
        "records": serialized_records,
        "events": system.get_tick_events(),
    }
