extends "res://tests/support/prototype_test.gd"

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const ValidatorScript = preload("res://src/config/prototype_config_validator.gd")

const HAZARD_SYSTEM_PATH := "res://src/domain/hazard/hazard_system.gd"
const HAZARD_SALT := 0x5249534B48415A44


func run() -> PackedStringArray:
	_test_resource_and_completed_config_contract()
	_test_exact_seeded_layout_and_rng_isolation()
	_test_damage_calculation_and_detachment()
	return finish()


func _test_resource_and_completed_config_contract() -> void:
	var balance := PrototypeBalanceScript.new()
	for property_name in [&"hazard_generation_balance", &"durability_balance"]:
		assert_true(_object_has_property(balance, property_name), "Prototype balance exposes %s" % property_name)
	if not _object_has_property(balance, &"hazard_generation_balance"):
		return
	var hazard_balance: Variant = balance.get("hazard_generation_balance")
	var durability_balance: Variant = balance.get("durability_balance")
	assert_equal(hazard_balance.get("hazard_cell_count"), 12, "Hazard count defaults to 12")
	assert_equal(durability_balance.get("maximum_durability"), 100.0, "Maximum durability defaults to 100")
	assert_equal(durability_balance.get("damage_per_traveled_cell"), 10.0, "Damage defaults to 10")
	assert_equal(durability_balance.get("repair_cost_per_durability"), 1.0, "Repair basis rate defaults to 1")

	var base_config: Variant = balance.create_session_start_config(73)
	var completed: Variant = balance.complete_session_start_config(
		base_config, Vector2(200.0, 120.0), &"hazard_departure", Vector2(60.0, 60.0),
		40.0, Vector2i(5, 3), Vector2.ZERO, Vector2i(1, 1)
	)
	var validator_script: Script = load("res://src/config/prototype_config_validator.gd")
	assert_true(_script_has_method(validator_script, &"validate_completed_session_start_config"), "Validator exposes completed-config validation")
	if not _script_has_method(validator_script, &"validate_completed_session_start_config"):
		return
	assert_equal(
		validator_script.call("validate_completed_session_start_config", completed),
		PackedStringArray(),
		"Default completed hazard config is valid"
	)
	hazard_balance.set("hazard_cell_count", 12)
	var impossible: Variant = balance.complete_session_start_config(
		balance.create_session_start_config(73), Vector2(80.0, 80.0), &"small", Vector2(20.0, 20.0),
		40.0, Vector2i(2, 2), Vector2.ZERO, Vector2i(0, 0)
	)
	_assert_contains(
		validator_script.call("validate_completed_session_start_config", impossible),
		"prototype_balance.hazard_generation_balance.hazard_cell_count"
	)


func _test_exact_seeded_layout_and_rng_isolation() -> void:
	assert_true(ResourceLoader.exists(HAZARD_SYSTEM_PATH), "Hazard system script exists")
	if not ResourceLoader.exists(HAZARD_SYSTEM_PATH):
		return
	var hazard_script: Script = load(HAZARD_SYSTEM_PATH)
	var config: Variant = _completed_config(73013, 5)
	if config == null:
		return
	var warp_rng := SessionRngScript.new(config.seed)
	var warp_state_before := warp_rng.capture_state()
	var hazard: Variant = hazard_script.new(config)
	assert_equal(warp_rng.capture_state(), warp_state_before, "Hazard generation does not consume Warp RNG")
	var expected := _reference_cells(config.seed, config.grid_size, config.departure_cell, 5)
	assert_equal(hazard.call("get_hazard_cells"), expected, "Literal seed and partial shuffle select exact cells")
	assert_equal(hazard_script.new(config).call("get_hazard_cells"), expected, "Matching seed reproduces layout")
	var alternate: Variant = hazard_script.new(_completed_config(73014, 5))
	assert_false(alternate.call("get_hazard_cells") == expected, "Different seed changes layout")
	assert_false(expected.has(config.departure_cell), "Departure cell is excluded")
	var unique := {}
	for cell in expected:
		unique[cell] = true
	assert_equal(unique.size(), expected.size(), "Hazard cells are unique")


func _test_damage_calculation_and_detachment() -> void:
	if not ResourceLoader.exists(HAZARD_SYSTEM_PATH):
		return
	var hazard: Variant = load(HAZARD_SYSTEM_PATH).new(_completed_config(901, 3))
	assert_equal(hazard.call("calculate_damage", 0.0), 0.0, "No traveled hazard distance causes no damage")
	assert_equal(hazard.call("calculate_damage", 0.25), 2.5, "Partial hazard distance causes proportional damage")
	assert_equal(hazard.call("calculate_damage", 2.0), 20.0, "Multiple actual passes accumulate damage")
	var cells: Array = hazard.call("get_hazard_cells")
	if not cells.is_empty():
		cells[0] = Vector2i(-1, -1)
		assert_false(hazard.call("get_hazard_cells")[0] == Vector2i(-1, -1), "Hazard observation is detached")


func _completed_config(seed_value: int, count: int) -> Variant:
	var balance := PrototypeBalanceScript.new()
	if not _object_has_property(balance, &"hazard_generation_balance"):
		assert_true(false, "Prototype balance exposes hazard generation")
		return null
	balance.hazard_generation_balance.hazard_cell_count = count
	return balance.complete_session_start_config(
		balance.create_session_start_config(seed_value),
		Vector2(200.0, 160.0), &"hazard", Vector2(20.0, 20.0),
		40.0, Vector2i(5, 4), Vector2.ZERO, Vector2i(0, 0)
	)


func _reference_cells(seed_value: int, grid_size: Vector2i, departure: Vector2i, count: int) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Vector2i(x, y)
			if cell != departure:
				candidates.append(cell)
	var rng := SessionRngScript.new(seed_value ^ HAZARD_SALT)
	var selected: Array[Vector2i] = []
	for index in range(count):
		var swap_index := index + rng.next_index(candidates.size() - index)
		var swap_cell := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = swap_cell
		selected.append(candidates[index])
	return selected


func _assert_contains(errors: PackedStringArray, fragment: String) -> void:
	var found := false
	for error_message in errors:
		found = found or error_message.contains(fragment)
	assert_true(found, "Expected error containing %s" % fragment)


func _object_has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if property.get("name", StringName()) == property_name:
			return true
	return false


func _script_has_method(script: Script, method_name: StringName) -> bool:
	for method in script.get_script_method_list():
		if method.get("name", StringName()) == method_name:
			return true
	return false
