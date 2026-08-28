extends "res://tests/support/prototype_test.gd"

const BalanceScript = preload("res://src/config/prototype_balance.gd")
const CargoSlotRecordScript = preload("res://src/domain/cargo/cargo_slot_record.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")
const WarpPairSystemScript = preload("res://src/domain/warp/warp_pair_system.gd")
const CargoSlotStripScript = preload("res://src/presentation/cargo/cargo_slot_strip.gd")
const TrackFieldViewScript = preload("res://src/presentation/track/track_field_view.gd")
const LogicalTrackFieldScene = preload("res://src/presentation/track/logical_track_field.tscn")
const WarpCargoBalance = preload("res://tests/fixtures/warp_cargo_balance.tres")

const STYLE_COLORS := [
    Color("2ec4b6"), Color("ff9f1c"), Color("9b5de5"),
    Color("f4d35e"), Color("3a86ff"), Color("ff5d8f"),
]
const STYLE_SHAPES := [&"circle", &"diamond", &"square", &"circle", &"diamond", &"square"]


func run() -> PackedStringArray:
    _test_fixture_and_seed_sequence()
    _test_field_placeholder_observations()
    _test_cargo_slot_observations()
    return finish()


func _test_fixture_and_seed_sequence() -> void:
    var balance: BalanceScript = WarpCargoBalance
    assert_equal(balance.session_balance.session_duration_seconds, 13.9, "Fixture session duration")
    assert_equal(balance.session_balance.simulation_ticks_per_second, 10, "Fixture tick rate")
    assert_equal(balance.train_balance.speed_cells_per_second, 3.237410072, "Fixture train speed")
    assert_equal(balance.track_inventory_balance.urgent_warning_seconds, 0.5, "Fixture warning")
    assert_equal(balance.track_inventory_balance.total_track_cells, 60, "Fixture inventory")
    assert_equal(balance.track_inventory_balance.recovery_lag_cells, 59, "Fixture recovery lag")
    assert_equal(balance.track_construction_balance.build_cells_per_second, 600.0, "Fixture build rate")
    assert_equal(balance.departure_balance.required_built_cells, 1, "Fixture departure cells")
    assert_equal(balance.warp_lifecycle_balance.forecast_duration_seconds, 0.2, "Fixture forecast")
    assert_equal(balance.warp_lifecycle_balance.generation_interval_seconds, 0.5, "Fixture interval")
    assert_equal(balance.warp_lifecycle_balance.lifetime_min_seconds, 1.5, "Fixture lifetime min")
    assert_equal(balance.warp_lifecycle_balance.lifetime_max_seconds, 16.5, "Fixture lifetime max")
    assert_equal(balance.warp_lifecycle_balance.max_live_pairs, 3, "Fixture live limit")
    assert_equal(balance.cargo_balance.base_slot_count, 2, "Fixture cargo slots")
    assert_equal(balance.cargo_balance.base_delivery_reward, 37, "Fixture reward")

    var config = _config()
    assert_equal(config.warp_forecast_ticks, 2, "Fixture forecast ticks")
    assert_equal(config.warp_generation_interval_ticks, 5, "Fixture interval ticks")
    assert_equal(config.warp_lifetime_min_ticks, 15, "Fixture minimum lifetime ticks")
    assert_equal(config.warp_lifetime_max_ticks, 165, "Fixture maximum lifetime ticks")

    var actual_rng := SessionRngScript.new(73013)
    var expected_rng := SessionRngScript.new(73013)
    var expected: Array[Dictionary] = []
    for ordinal in range(1, 4):
        expected.append({
            "origin": WarpPairSystemScript.cell_from_row_major_index(expected_rng.next_index(144), Vector2i(12, 12)),
            "destination": WarpPairSystemScript.cell_from_row_major_index(expected_rng.next_index(144), Vector2i(12, 12)),
            "lifetime": 15 + expected_rng.next_index(151),
            "style": ordinal - 1,
        })
    var warp := WarpPairSystemScript.new(config, actual_rng)
    for tick in range(1, 12):
        warp.begin_running_tick(tick)
    var records: Array = warp.get_pair_records()
    assert_equal(records.size(), 3, "Seed fixture generates three live records")
    for index in range(mini(records.size(), expected.size())):
        assert_equal(records[index].origin_cell, expected[index].origin, "Seeded origin %d" % index)
        assert_equal(records[index].destination_cell, expected[index].destination, "Seeded destination %d" % index)
        assert_equal(records[index].lifetime_total_ticks, expected[index].lifetime, "Seeded lifetime %d" % index)
        assert_equal(records[index].style_index, expected[index].style, "Seeded style %d" % index)


func _test_field_placeholder_observations() -> void:
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
    view.configure_session(_config())
    var child_count_before := view.get_child_count()

    var pairs: Array[WarpPairRecordScript] = []
    for style_index in range(6):
        var pair := _pair(style_index, WarpPairRecordScript.State.FORECAST)
        pair.forecast_remaining_ticks = 2
        pairs.append(pair)
    view.present(_snapshot(pairs))
    var observation: Dictionary = view.get_render_observation()
    assert_true(observation.has("warp_endpoints"), "Field exposes Warp endpoint observations")
    if not observation.has("warp_endpoints"):
        view.free()
        return
    var endpoints: Array = observation.warp_endpoints
    assert_equal(endpoints.size(), 12, "Six styles expose two forecast endpoints each")
    for style_index in range(6):
        var origin := _endpoint(endpoints, StringName("warp_pair_%d" % (style_index + 1)), &"origin")
        var destination := _endpoint(endpoints, StringName("warp_pair_%d" % (style_index + 1)), &"destination")
        assert_true(not origin.is_empty(), "Style %d origin exists" % style_index)
        assert_true(not destination.is_empty(), "Style %d destination exists" % style_index)
        if origin.is_empty() or destination.is_empty():
            continue
        assert_equal(origin.color, STYLE_COLORS[style_index], "Style %d color" % style_index)
        assert_equal(origin.shape, STYLE_SHAPES[style_index], "Style %d shape" % style_index)
        assert_true(origin.filled, "Forecast origin is filled")
        assert_false(destination.filled, "Forecast destination is outlined")
        assert_equal(origin.alpha, 0.35, "Forecast origin is low alpha")
        assert_equal(origin.countdown_text, "F 1s", "Forecast countdown rounds up")

    var active := _pair(0, WarpPairRecordScript.State.ACTIVE_UNLOADED)
    active.origin_cell = Vector2i(5, 6)
    active.lifetime_remaining_ticks = 7
    var transit := _pair(1, WarpPairRecordScript.State.IN_TRANSIT)
    transit.lifetime_remaining_ticks = 6
    view.present(_snapshot([active, transit]))
    endpoints = view.get_render_observation().warp_endpoints
    var active_origin := _endpoint(endpoints, active.pair_id, &"origin")
    var active_destination := _endpoint(endpoints, active.pair_id, &"destination")
    var transit_origin := _endpoint(endpoints, transit.pair_id, &"origin")
    assert_true(active_origin.filled, "Active origin is filled")
    assert_false(active_destination.filled, "Active destination is outlined")
    assert_false(transit_origin.filled, "In-transit origin changes to outline")
    assert_true(active_origin.position.is_equal_approx(Vector2(306.6666667, 173.3333333)), "Endpoint reuses logical grid mapping")
    assert_equal(active_origin.countdown_text, "1s", "Lifetime countdown rounds up")

    var delivered := _pair(2, WarpPairRecordScript.State.DELIVERED)
    view.present(_snapshot([delivered], [], [_event(&"DELIVERED", delivered.pair_id, 0, 37)]))
    endpoints = view.get_render_observation().warp_endpoints
    assert_equal(endpoints.size(), 1, "Delivery event draws one brief endpoint")
    if endpoints.size() == 1:
        assert_equal(endpoints[0].role, &"destination", "Delivery event draws destination")
        assert_true(endpoints[0].filled, "Delivery event destination is filled")
    view.present(_snapshot([delivered]))
    assert_equal(view.get_render_observation().warp_endpoints, [], "Delivered endpoint disappears next snapshot")

    var expired := _pair(3, WarpPairRecordScript.State.EXPIRED)
    view.present(_snapshot([expired], [], [_event(&"EXPIRED", expired.pair_id, 0)]))
    assert_equal(view.get_render_observation().warp_endpoints, [], "Expiry removes endpoints")
    var voided := _pair(4, WarpPairRecordScript.State.VOIDED)
    view.present(_snapshot([voided], [], [_event(&"VOIDED", voided.pair_id, 0)]))
    assert_equal(view.get_render_observation().warp_endpoints, [], "Void clears endpoints")
    assert_equal(view.get_child_count(), child_count_before, "Warp endpoint rendering adds no input-intercepting Control")
    view.free()


func _test_cargo_slot_observations() -> void:
    var strip := CargoSlotStripScript.new()
    assert_equal(strip.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Cargo strip ignores mouse input")
    assert_true(strip.has_method("present"), "Cargo strip accepts snapshots")
    assert_true(strip.has_method("get_render_observation"), "Cargo strip exposes render observations")
    if not strip.has_method("present") or not strip.has_method("get_render_observation"):
        strip.free()
        return
    var slots: Array[CargoSlotRecordScript] = [_slot(0, &"warp_pair_3", 2), _slot(1)]
    strip.present(_snapshot([], slots, [], 1, 2))
    var observation: Dictionary = strip.get_render_observation()
    assert_equal(observation.occupied, 1, "Cargo observation counts occupied slots")
    assert_equal(observation.total, 2, "Cargo observation counts total slots")
    assert_equal(observation.text, "1 / 2", "Cargo observation formats occupied / total")
    assert_true(observation.slots[0].filled, "Occupied slot is filled")
    assert_equal(observation.slots[0].color, STYLE_COLORS[2], "Occupied slot uses pair style")
    assert_false(observation.slots[1].filled, "Empty slot is outlined")
    strip.present(_snapshot([], [_slot(0), _slot(1)], [], 0, 2))
    assert_equal(strip.get_render_observation().occupied, 0, "Cleared snapshot empties cargo strip")
    strip.free()


func _config():
    var base = WarpCargoBalance.create_session_start_config(73013)
    return WarpCargoBalance.complete_session_start_config(
        base, Vector2(640.0, 320.0), &"departure_08", Vector2(306.666667, 66.666669),
        26.666666, Vector2i(12, 12), Vector2(160.000004, 0.000004), Vector2i(5, 2)
    )


func _pair(style_index: int, state: int) -> WarpPairRecordScript:
    var pair := WarpPairRecordScript.new()
    pair.ordinal = style_index + 1
    pair.pair_id = StringName("warp_pair_%d" % pair.ordinal)
    pair.origin_cell = Vector2i(style_index % 5, style_index / 5)
    pair.destination_cell = Vector2i((style_index + 1) % 5, (style_index + 2) % 6)
    pair.state = state
    pair.forecast_remaining_ticks = 0
    pair.lifetime_total_ticks = 8
    pair.lifetime_remaining_ticks = 8
    pair.style_index = style_index
    return pair


func _slot(
    index: int,
    pair_id: StringName = StringName(),
    style_index: int = -1
) -> CargoSlotRecordScript:
    var slot := CargoSlotRecordScript.new()
    slot.slot_index = index
    slot.pair_id = pair_id
    slot.style_index = style_index
    return slot


func _event(type: StringName, pair_id: StringName, slot_index: int = -1, amount: int = 0) -> Dictionary:
    return {"tick": 1, "type": type, "pair_id": pair_id, "slot_index": slot_index, "amount": amount}


func _snapshot(
    pairs: Array = [],
    slots: Array = [],
    events: Array[Dictionary] = [],
    occupied: int = 0,
    total: int = 2,
    delivered: int = 0,
    reward: int = 0,
    state: int = SessionControllerScript.State.RUNNING
) -> SessionSnapshotScript:
    var typed_pairs: Array[WarpPairRecordScript] = []
    for pair in pairs:
        typed_pairs.append(pair)
    var typed_slots: Array[CargoSlotRecordScript] = []
    for slot in slots:
        typed_slots.append(slot)
    return SessionSnapshotScript.new(
        16, 1, 15, 10, true, state,
        [], [], [], 0.0, 30, 30, Vector2(200.0, 40.0),
        1, 1, 29.0, true, 0.0, Vector2(220.0, 100.0), Vector2.RIGHT,
        1.0, false, &"departure_08", Vector2i(0, 1), false, false,
        typed_pairs, typed_slots, occupied, total, delivered, reward, events
    )


func _endpoint(endpoints: Array, pair_id: StringName, role: StringName) -> Dictionary:
    for endpoint in endpoints:
        if endpoint.pair_id == pair_id and endpoint.role == role:
            return endpoint
    return {}
