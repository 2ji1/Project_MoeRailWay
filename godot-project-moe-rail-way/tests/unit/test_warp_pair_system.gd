extends "res://tests/support/prototype_test.gd"

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const PrototypeConfigValidatorScript = preload("res://src/config/prototype_config_validator.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const CargoSystemScript = preload("res://src/domain/cargo/cargo_system.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")
const WarpPairSystemScript = preload("res://src/domain/warp/warp_pair_system.gd")


func run() -> PackedStringArray:
    _verify_invalid_contact_probes()
    _test_balance_defaults_and_copy()
    _test_balance_validation()
    _test_row_major_mapping()
    _test_equal_cell_generation_and_draw_order()
    _test_forecast_activation_and_anchors()
    _test_active_warp_anchors_use_exact_center_mode()
    _test_capacity_gating_and_delayed_cadence()
    _test_expiry_void_and_idempotence()
    _test_contact_loading_delivery_and_removal()
    _test_fixed_seed_replay_and_detached_observations()
    return finish()


func _test_active_warp_anchors_use_exact_center_mode() -> void:
    var balance := _make_warp_balance(0.0, 10.0, 5.0, 5.0, 2)
    var config = _complete_config(balance, 91, Vector2i(2, 2))
    var system := WarpPairSystemScript.new(config, SessionRngScript.new(91))
    system.begin_running_tick(1)
    var anchors: Array = system.get_route_contact_anchors()
    assert_equal(anchors.size(), 2, "Zero-forecast Warp publishes origin and destination anchors")
    for anchor in anchors:
        var has_mode := _object_has_property(anchor, &"contact_mode")
        assert_true(has_mode, "Active Warp anchor publishes a concrete contact mode")
        if has_mode:
            assert_equal(anchor.get(&"contact_mode"), 1, "Active Warp anchor uses exact cell-center mode")
            var copy = anchor.duplicate_anchor()
            assert_equal(copy.get(&"contact_mode"), 1, "Detached Warp anchor preserves exact mode")


func _object_has_property(object: Object, property_name: StringName) -> bool:
    for property in object.get_property_list():
        if property.get("name", StringName()) == property_name:
            return true
    return false


func _verify_invalid_contact_probes() -> void:
    _run_invalid_contact_probe("malformed", "Contact hit must match a well-formed active anchor")
    _run_invalid_contact_probe("unknown", "Contact hit must match a well-formed active anchor")
    _run_invalid_contact_probe("duplicate", "Contact hit anchor IDs must be unique per sweep")


func _run_invalid_contact_probe(case_name: String, expected_message: String) -> void:
    var output: Array = []
    var arguments := PackedStringArray([
        "--headless",
        "--path", ProjectSettings.globalize_path("res://"),
        "--script", "res://tests/run_all.gd",
        "--quit-after", "1",
        "--",
        "--warp-pair-invalid-probe=" + case_name,
    ])
    OS.execute(OS.get_executable_path(), arguments, output, true)
    var output_lines := PackedStringArray()
    for chunk in output:
        output_lines.append(str(chunk))
    var captured_text := "\n".join(output_lines)
    assert_true(
        captured_text.contains("WARP_PAIR_INVALID_PROBE_BEGIN:" + case_name),
        "Warp pair invalid probe starts for " + case_name
    )
    assert_true(captured_text.contains(expected_message), expected_message)


func run_invalid_probe(case_name: String) -> void:
    var balance := _make_warp_balance(0.0, 10.0, 5.0, 5.0, 1)
    var config = _complete_config(balance, 909, Vector2i(2, 2))
    var system := WarpPairSystemScript.new(config, SessionRngScript.new(909))
    var cargo := CargoSystemScript.new(1, 37)
    system.begin_running_tick(1)
    var records: Array = system.get_pair_records()
    if records.size() != 1:
        return
    if case_name == "malformed":
        system.resolve_contact_hits(1, [{}], cargo)
        return
    if case_name == "unknown":
        system.resolve_contact_hits(
            1,
            [{
                "anchor_id": &"unknown/origin",
                "cell": Vector2i.ZERO,
                "contact_distance_cells": 1.0,
            }],
            cargo
        )
        return
    if case_name == "duplicate":
        var hit := _contact_hit(records[0], "origin", 1.0)
        system.resolve_contact_hits(1, [hit, hit.duplicate(true)], cargo)


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
    var cargo := CargoSystemScript.new(1, 37)

    system.begin_running_tick(1)
    mirror_rng.next_index(6)
    mirror_rng.next_index(6)
    mirror_rng.next_index(1)
    system.expire_after_contact(1, cargo)
    system.begin_running_tick(2)
    mirror_rng.next_index(6)
    mirror_rng.next_index(6)
    mirror_rng.next_index(1)
    system.expire_after_contact(2, cargo)
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
    system.expire_after_contact(3, cargo)

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
    system.expire_after_contact(4, cargo)

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
    var expiry_cargo := CargoSystemScript.new(1, 37)
    expiry_system.begin_running_tick(1)
    expiry_system.begin_running_tick(1)
    assert_equal(
        expiry_system.get_pair_records().size(),
        1,
        "Repeated begin on one tick must not generate twice"
    )
    expiry_system.expire_after_contact(1, expiry_cargo)
    expiry_system.expire_after_contact(1, expiry_cargo)
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
    var void_cargo := CargoSystemScript.new(1, 37)
    void_system.begin_running_tick(1)
    void_system.void_nonterminal(1, void_cargo)
    void_system.void_nonterminal(1, void_cargo)
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


func _test_contact_loading_delivery_and_removal() -> void:
    var equal_balance := _make_warp_balance(0.0, 10.0, 3.0, 3.0, 1)
    var equal_config = _complete_config(equal_balance, 77, Vector2i.ONE)
    var equal_system := WarpPairSystemScript.new(equal_config, SessionRngScript.new(77))
    var equal_cargo := CargoSystemScript.new(1, 37)
    equal_system.begin_running_tick(1)
    var equal_records: Array = equal_system.get_pair_records()
    if equal_records.size() == 1:
        var equal_hits: Array[Dictionary] = [
            _contact_hit(equal_records[0], "destination", 1.0),
            _contact_hit(equal_records[0], "origin", 1.0),
        ]
        equal_system.resolve_contact_hits(1, equal_hits, equal_cargo)
        var delivered_records: Array = equal_system.get_pair_records()
        assert_equal(
            delivered_records[0].state,
            WarpPairRecordScript.State.DELIVERED,
            "Equal-cell hit must load then deliver in one ordered sweep"
        )
        assert_equal(equal_cargo.get_occupied_slot_count(), 0, "Delivery clears equal-cell cargo")
        assert_equal(equal_cargo.get_delivered_pair_count(), 1, "Equal-cell delivery counts once")
        assert_equal(equal_cargo.get_base_delivery_reward_total(), 37, "Delivery pays once")
        _assert_event_types(
            equal_system.get_tick_events(),
            [&"FORECASTED", &"ACTIVATED", &"LOADED", &"DELIVERED"],
            "Equal-cell load and delivery event order"
        )
        var equal_events: Array[Dictionary] = equal_system.get_tick_events()
        if equal_events.size() == 4:
            assert_equal(equal_events[2]["slot_index"], 0, "Load event names the occupied slot")
            assert_equal(equal_events[2]["amount"], 0, "Load event has no reward")
            assert_equal(equal_events[3]["slot_index"], 0, "Delivery event names the cleared slot")
            assert_equal(equal_events[3]["amount"], 37, "Delivery event names exact reward")
        equal_system.resolve_contact_hits(1, equal_hits, equal_cargo)
        equal_system.resolve_contact_hits(2, equal_hits, equal_cargo)
        assert_equal(equal_cargo.get_delivered_pair_count(), 1, "Repeated contacts cannot redeliver")
        assert_equal(equal_cargo.get_base_delivery_reward_total(), 37, "Repeated contacts cannot repay")
        assert_equal(
            equal_system.get_route_contact_anchors().size(),
            0,
            "Delivered pair publishes no anchors"
        )

    var full_balance := _make_warp_balance(0.0, 10.0, 4.0, 4.0, 1)
    var full_config = _complete_config(full_balance, 78, Vector2i(2, 2))
    var full_system := WarpPairSystemScript.new(full_config, SessionRngScript.new(78))
    var full_cargo := CargoSystemScript.new(1, 37)
    full_cargo.try_load(&"blocker", 5)
    full_system.begin_running_tick(1)
    var full_records: Array = full_system.get_pair_records()
    if full_records.size() == 1:
        var full_hits: Array[Dictionary] = [
            _contact_hit(full_records[0], "origin", 1.0),
            _contact_hit(full_records[0], "destination", 2.0),
        ]
        full_system.resolve_contact_hits(1, full_hits, full_cargo)
        assert_equal(
            full_system.get_pair_records()[0].state,
            WarpPairRecordScript.State.ACTIVE_UNLOADED,
            "Full capacity leaves the pair active and unloaded"
        )
        var blocked_slots: Array = full_cargo.get_slot_records()
        assert_equal(blocked_slots.size(), 1, "Full fixture must retain one slot")
        if blocked_slots.size() == 1:
            assert_equal(blocked_slots[0].pair_id, &"blocker", "Full load changes no slot")
        assert_equal(full_cargo.get_delivered_pair_count(), 0, "Destination before load is a no-op")

        full_cargo.remove_pair(&"blocker")
        full_system.resolve_contact_hits(
            2,
            [_contact_hit(full_records[0], "origin", 1.0)],
            full_cargo
        )
        assert_equal(
            full_system.get_pair_records()[0].state,
            WarpPairRecordScript.State.IN_TRANSIT,
            "Successful later load changes lifecycle to in transit"
        )
        var loaded_slots: Array = full_cargo.get_slot_records()
        assert_equal(loaded_slots.size(), 1, "Loaded fixture must retain one slot")
        if loaded_slots.size() == 1:
            assert_equal(loaded_slots[0].pair_id, &"warp_pair_1", "Loaded pair owns slot")
        full_system.resolve_contact_hits(
            3,
            [_contact_hit(full_records[0], "origin", 1.0)],
            full_cargo
        )
        assert_equal(full_cargo.get_occupied_slot_count(), 1, "Repeated origin contact is a no-op")

    var ordered_balance := _make_warp_balance(0.0, 1.0, 1.0, 1.0, 2)
    var ordered_config = _complete_config(ordered_balance, 79, Vector2i(2, 2))
    var ordered_system := WarpPairSystemScript.new(ordered_config, SessionRngScript.new(79))
    var ordered_cargo := CargoSystemScript.new(1, 37)
    ordered_system.begin_running_tick(1)
    ordered_system.begin_running_tick(2)
    var ordered_records: Array = ordered_system.get_pair_records()
    if ordered_records.size() == 2:
        var ordered_hits: Array[Dictionary] = [
            _contact_hit(ordered_records[1], "origin", 3.0),
            _contact_hit(ordered_records[0], "destination", 2.0),
            _contact_hit(ordered_records[0], "origin", 1.0),
        ]
        ordered_system.resolve_contact_hits(2, ordered_hits, ordered_cargo)
        var after_contacts: Array = ordered_system.get_pair_records()
        assert_equal(
            after_contacts[0].state,
            WarpPairRecordScript.State.DELIVERED,
            "Earlier route delivery must complete the first pair"
        )
        assert_equal(
            after_contacts[1].state,
            WarpPairRecordScript.State.IN_TRANSIT,
            "Later route origin must reuse the slot freed in the same sweep"
        )
        var ordered_slots: Array = ordered_cargo.get_slot_records()
        assert_equal(ordered_slots.size(), 1, "Ordered fixture must retain one slot")
        if ordered_slots.size() == 1:
            assert_equal(
                ordered_slots[0].pair_id,
                &"warp_pair_2",
                "Physical hit order controls same-sweep slot turnover"
            )
        ordered_system.expire_after_contact(2, ordered_cargo)
        var after_expiry: Array = ordered_system.get_pair_records()
        assert_equal(
            after_expiry[1].state,
            WarpPairRecordScript.State.EXPIRED,
            "In-transit final lifetime must expire after contact"
        )
        assert_equal(ordered_cargo.get_occupied_slot_count(), 0, "In-transit expiry clears slot")
        assert_equal(ordered_cargo.get_delivered_pair_count(), 1, "Expiry adds no delivery")
        assert_equal(ordered_cargo.get_base_delivery_reward_total(), 37, "Expiry adds no reward")
        var expiry_events: Array[Dictionary] = ordered_system.get_tick_events()
        assert_equal(expiry_events[-1]["type"], &"EXPIRED", "Expiry event is published")
        assert_equal(expiry_events[-1]["slot_index"], 0, "Expiry event names cleared slot")
        assert_equal(expiry_events[-1]["amount"], 0, "Expiry event has no reward")

    var close_balance := _make_warp_balance(0.0, 1.0, 5.0, 5.0, 2)
    var close_config = _complete_config(close_balance, 790, Vector2i(2, 2))
    var close_system := WarpPairSystemScript.new(close_config, SessionRngScript.new(790))
    var close_cargo := CargoSystemScript.new(1, 37)
    close_system.begin_running_tick(1)
    var close_first: Array = close_system.get_pair_records()
    if close_first.size() == 1:
        close_system.resolve_contact_hits(
            1,
            [_contact_hit(close_first[0], "origin", 0.5)],
            close_cargo
        )
    close_system.begin_running_tick(2)
    var close_records: Array = close_system.get_pair_records()
    if close_records.size() == 2:
        close_system.resolve_contact_hits(
            2,
            [
                _contact_hit(close_records[0], "destination", 1.00000001),
                _contact_hit(close_records[1], "origin", 1.0),
            ],
            close_cargo
        )
        var close_after: Array = close_system.get_pair_records()
        assert_equal(
            close_after[1].state,
            WarpPairRecordScript.State.ACTIVE_UNLOADED,
            "Distinct close distances must preserve physical origin-before-delivery order"
        )
        assert_equal(
            close_cargo.get_occupied_slot_count(),
            0,
            "Later close-distance delivery cannot retroactively load an earlier origin"
        )

    var void_balance := _make_warp_balance(0.0, 10.0, 5.0, 5.0, 1)
    var void_config = _complete_config(void_balance, 80, Vector2i(2, 2))
    var void_system := WarpPairSystemScript.new(void_config, SessionRngScript.new(80))
    var void_cargo := CargoSystemScript.new(1, 37)
    void_system.begin_running_tick(1)
    var void_records: Array = void_system.get_pair_records()
    if void_records.size() == 1:
        void_system.resolve_contact_hits(
            1,
            [_contact_hit(void_records[0], "origin", 1.0)],
            void_cargo
        )
        void_system.void_nonterminal(1, void_cargo)
        assert_equal(
            void_system.get_pair_records()[0].state,
            WarpPairRecordScript.State.VOIDED,
            "In-transit regular end must void the pair"
        )
        assert_equal(void_cargo.get_occupied_slot_count(), 0, "Void clears in-transit cargo")
        assert_equal(void_cargo.get_delivered_pair_count(), 0, "Void adds no delivery")
        assert_equal(void_cargo.get_base_delivery_reward_total(), 0, "Void adds no reward")


func _test_fixed_seed_replay_and_detached_observations() -> void:
    var replay_balance := _make_warp_balance(1.0, 2.0, 2.0, 4.0, 3)
    var first_config = _complete_config(replay_balance, 8181, Vector2i(3, 3))
    var second_config = _complete_config(replay_balance, 8181, Vector2i(3, 3))
    var first := WarpPairSystemScript.new(first_config, SessionRngScript.new(8181))
    var second := WarpPairSystemScript.new(second_config, SessionRngScript.new(8181))
    var first_cargo := CargoSystemScript.new(2, 37)
    var second_cargo := CargoSystemScript.new(2, 37)
    var first_history := []
    var second_history := []
    for tick in range(1, 9):
        first.begin_running_tick(tick)
        second.begin_running_tick(tick)
        first.expire_after_contact(tick, first_cargo)
        second.expire_after_contact(tick, second_cargo)
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


func _contact_hit(record: RefCounted, endpoint: String, distance: float) -> Dictionary:
    var cell: Vector2i = record.origin_cell
    if endpoint == "destination":
        cell = record.destination_cell
    return {
        "anchor_id": StringName("%s/%s" % [record.pair_id, endpoint]),
        "cell": cell,
        "contact_distance_cells": distance,
    }


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
