extends "res://tests/support/prototype_test.gd"

const CargoSystemScript = preload("res://src/domain/cargo/cargo_system.gd")


func run() -> PackedStringArray:
    _verify_invalid_configuration_probes()
    _test_empty_full_and_mixed_slot_transitions()
    _test_matching_delivery_and_reward_idempotence()
    _test_removal_clear_all_and_detached_records()
    _test_temporary_capacity_staging_preserves_slot_identity()
    return finish()


func _verify_invalid_configuration_probes() -> void:
    _run_invalid_probe("slot_count", "Cargo slot count must be between 1 and 8")
    _run_invalid_probe("delivery_reward", "Cargo delivery reward must be between 0 and 1000000")


func _run_invalid_probe(case_name: String, expected_message: String) -> void:
    var output: Array = []
    var arguments := PackedStringArray([
        "--headless",
        "--path", ProjectSettings.globalize_path("res://"),
        "--script", "res://tests/run_all.gd",
        "--quit-after", "1",
        "--",
        "--cargo-invalid-probe=" + case_name,
    ])
    OS.execute(OS.get_executable_path(), arguments, output, true)
    var output_lines := PackedStringArray()
    for chunk in output:
        output_lines.append(str(chunk))
    var captured_text := "\n".join(output_lines)
    assert_true(
        captured_text.contains("CARGO_INVALID_PROBE_BEGIN:" + case_name),
        "Cargo invalid probe starts for " + case_name
    )
    assert_true(captured_text.contains(expected_message), expected_message)


func run_invalid_probe(case_name: String) -> void:
    if case_name == "slot_count":
        CargoSystemScript.new(0, 37)
        return
    if case_name == "delivery_reward":
        CargoSystemScript.new(1, -1)


func _test_empty_full_and_mixed_slot_transitions() -> void:
    var cargo := CargoSystemScript.new(3, 100)
    assert_equal(cargo.get_total_slot_count(), 3, "Cargo must create the fixed slot count")
    assert_equal(cargo.get_occupied_slot_count(), 0, "New cargo slots must be empty")
    _assert_conservation(cargo, "Initial slot conservation")
    _assert_slot_ids(cargo, [StringName(), StringName(), StringName()], "Initial slots")

    assert_equal(cargo.try_load(&"pair_a", 2), 0, "First cargo must load into slot zero")
    assert_equal(cargo.try_load(&"pair_b", 4), 1, "Second cargo must load into slot one")
    assert_equal(cargo.get_occupied_slot_count(), 2, "Two successful loads occupy two slots")
    _assert_slot_ids(cargo, [&"pair_a", &"pair_b", StringName()], "Two loaded slots")

    assert_equal(cargo.try_load(&"pair_a", 5), -1, "One pair must not load twice")
    assert_equal(cargo.get_occupied_slot_count(), 2, "Repeated load must be a no-op")
    assert_equal(cargo.try_load(StringName(), 1), -1, "Empty pair ID must not load")

    assert_equal(cargo.remove_pair(&"pair_a"), 0, "Removal must clear the matching slot")
    assert_equal(cargo.try_load(&"pair_c", 1), 0, "Mixed capacity uses the lowest empty slot")
    _assert_slot_ids(cargo, [&"pair_c", &"pair_b", StringName()], "Mixed lowest-slot load")
    assert_equal(cargo.try_load(&"pair_d", 3), 2, "Final empty slot must fill")
    assert_equal(cargo.try_load(&"pair_e", 5), -1, "Full capacity must reject loading")
    _assert_slot_ids(cargo, [&"pair_c", &"pair_b", &"pair_d"], "Full slots remain stable")
    assert_equal(cargo.get_occupied_slot_count(), 3, "Full cargo occupancy must equal total")
    _assert_conservation(cargo, "Full slot conservation")


func _test_matching_delivery_and_reward_idempotence() -> void:
    var cargo := CargoSystemScript.new(2, 37)
    cargo.try_load(&"pair_a", 0)
    cargo.try_load(&"pair_b", 1)

    var missing: Dictionary = cargo.try_deliver(&"pair_missing")
    assert_equal(
        missing,
        {"delivered": false, "slot_index": -1, "amount": 0},
        "Nonmatching destination must not deliver"
    )
    assert_equal(cargo.get_delivered_pair_count(), 0, "Missing delivery changes no count")
    assert_equal(cargo.get_base_delivery_reward_total(), 0, "Missing delivery changes no reward")

    var delivered: Dictionary = cargo.try_deliver(&"pair_b")
    assert_equal(
        delivered,
        {"delivered": true, "slot_index": 1, "amount": 37},
        "Matching delivery must clear one slot and return exact reward"
    )
    assert_equal(cargo.get_delivered_pair_count(), 1, "Delivery increments count once")
    assert_equal(cargo.get_base_delivery_reward_total(), 37, "Delivery adds one base reward")
    assert_equal(cargo.get_occupied_slot_count(), 1, "Delivery clears only the matching slot")
    _assert_slot_ids(cargo, [&"pair_a", StringName()], "Matching delivery slot clear")

    var repeated: Dictionary = cargo.try_deliver(&"pair_b")
    assert_equal(
        repeated,
        {"delivered": false, "slot_index": -1, "amount": 0},
        "Repeated delivery must be a no-op"
    )
    assert_equal(cargo.get_delivered_pair_count(), 1, "Repeated delivery cannot repay")
    assert_equal(cargo.get_base_delivery_reward_total(), 37, "Reward must remain monotonic")
    assert_equal(
        cargo.get_base_delivery_reward_total(),
        cargo.get_delivered_pair_count() * 37,
        "Reward total must equal delivered count times base reward"
    )
    _assert_conservation(cargo, "Post-delivery slot conservation")

    var zero_reward := CargoSystemScript.new(1, 0)
    zero_reward.try_load(&"pair_zero", 0)
    zero_reward.try_deliver(&"pair_zero")
    assert_equal(zero_reward.get_delivered_pair_count(), 1, "Zero reward still counts delivery")
    assert_equal(zero_reward.get_base_delivery_reward_total(), 0, "Zero reward remains zero")


func _test_removal_clear_all_and_detached_records() -> void:
    var cargo := CargoSystemScript.new(3, 19)
    cargo.try_load(&"pair_a", 0)
    cargo.try_load(&"pair_b", 1)
    cargo.try_load(&"pair_c", 2)
    cargo.try_deliver(&"pair_b")

    assert_equal(cargo.remove_pair(&"pair_missing"), -1, "Missing removal must be a no-op")
    assert_equal(cargo.remove_pair(&"pair_a"), 0, "Expiry removal returns cleared slot index")
    assert_equal(cargo.remove_pair(&"pair_a"), -1, "Repeated removal must be a no-op")
    assert_equal(cargo.get_occupied_slot_count(), 1, "Removal clears exactly one slot")
    assert_equal(cargo.get_delivered_pair_count(), 1, "Removal creates no delivery")
    assert_equal(cargo.get_base_delivery_reward_total(), 19, "Removal creates no reward")

    var records: Array = cargo.get_slot_records()
    assert_equal(records.size(), 3, "Slot observations must retain fixed length")
    if records.size() == 3:
        records[2].pair_id = &"mutated"
        records[2].style_index = 99
        records[2].slot_index = 99
        var fresh: Array = cargo.get_slot_records()
        assert_equal(fresh[2].pair_id, &"pair_c", "Returned pair ID must be detached")
        assert_equal(fresh[2].style_index, 2, "Returned style must be detached")
        assert_equal(fresh[2].slot_index, 2, "Returned slot index must be detached")

    cargo.clear_all()
    assert_equal(cargo.get_occupied_slot_count(), 0, "clear_all must empty every slot")
    assert_equal(cargo.get_total_slot_count(), 3, "clear_all must preserve fixed capacity")
    assert_equal(cargo.get_delivered_pair_count(), 1, "clear_all preserves delivered count")
    assert_equal(cargo.get_base_delivery_reward_total(), 19, "clear_all preserves earned reward")
    _assert_slot_ids(cargo, [StringName(), StringName(), StringName()], "Cleared slots")
    _assert_conservation(cargo, "Cleared slot conservation")


func _test_temporary_capacity_staging_preserves_slot_identity() -> void:
    var cargo := CargoSystemScript.new(2, 19)
    cargo.try_load(&"pair_a", 3)
    cargo.try_load(&"pair_b", 4)
    cargo.try_deliver(&"pair_b")
    var live_before := JSON.stringify(cargo.get_slot_records().map(func(slot): return {
        "index": slot.slot_index,
        "pair": String(slot.pair_id),
        "style": slot.style_index,
    }))
    var candidate = cargo.duplicate_cargo()
    assert_true(candidate.try_append_empty_slots(1), "Candidate appends one empty temporary slot")
    assert_equal(cargo.get_total_slot_count(), 2, "Candidate staging does not mutate live capacity")
    assert_equal(JSON.stringify(cargo.get_slot_records().map(func(slot): return {
        "index": slot.slot_index,
        "pair": String(slot.pair_id),
        "style": slot.style_index,
    })), live_before, "Candidate staging preserves every live slot byte")
    cargo.replace_with(candidate)
    assert_equal(cargo.get_slot_records().map(func(slot): return slot.slot_index), [0, 1, 2], "Installed slot indices append monotonically")
    assert_equal(cargo.get_slot_records()[0].pair_id, &"pair_a", "Install preserves occupied pair identity")
    assert_equal(cargo.get_delivered_pair_count(), 1, "Install preserves delivery count")
    assert_equal(cargo.get_base_delivery_reward_total(), 19, "Install preserves delivery reward total")
    assert_equal(cargo.try_load(&"pair_c", 5), 1, "Original lowest empty slot still wins after expansion")
    var full_before := JSON.stringify(cargo.get_slot_records().map(func(slot): return String(slot.pair_id)))
    assert_false(cargo.try_append_empty_slots(6), "Concrete capacity rejects totals above eight")
    assert_equal(JSON.stringify(cargo.get_slot_records().map(func(slot): return String(slot.pair_id))), full_before, "Rejected expansion preserves every slot")
    _assert_conservation(cargo, "Expanded slot conservation")


func _assert_slot_ids(cargo: RefCounted, expected: Array, message: String) -> void:
    var actual := []
    for record in cargo.get_slot_records():
        actual.append(record.pair_id)
    assert_equal(actual, expected, message)


func _assert_conservation(cargo: RefCounted, message: String) -> void:
    var records: Array = cargo.get_slot_records()
    var empty_count := 0
    for record in records:
        if record.is_empty():
            empty_count += 1
    assert_equal(
        cargo.get_occupied_slot_count() + empty_count,
        cargo.get_total_slot_count(),
        message
    )
