extends "res://tests/support/prototype_test.gd"

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const Validator = preload("res://src/config/prototype_config_validator.gd")


func run() -> PackedStringArray:
	_test_planning_time_scale_contract()
	var valid_balance := PrototypeBalanceScript.new()
	assert_equal(
		Validator.validate(valid_balance).size(),
		0,
        "Default balance must be valid"
	)

	var invalid_balance := PrototypeBalanceScript.new()
	invalid_balance.session_duration_seconds = 0.0
	invalid_balance.simulation_ticks_per_second = 0
	var errors: PackedStringArray = Validator.validate(invalid_balance)
	assert_equal(errors.size(), 2, "Both invalid fields must be reported")
	var duration_error_found := false
	var tick_rate_error_found := false
	for error_message in errors:
		duration_error_found = (
			error_message.contains("session_duration_seconds")
			or duration_error_found
		)
		tick_rate_error_found = (
			error_message.contains("simulation_ticks_per_second")
			or tick_rate_error_found
		)
	assert_true(duration_error_found, "Duration error must name the field")
	assert_true(tick_rate_error_found, "Tick-rate error must name the field")

	var start_config = valid_balance.create_session_start_config(4242)
	assert_equal(start_config.seed, 4242, "SessionStartConfig must preserve seed")
	assert_equal(
		start_config.session_duration_seconds,
		valid_balance.session_duration_seconds,
        "SessionStartConfig must copy session duration"
	)
	assert_equal(
		start_config.simulation_ticks_per_second,
		valid_balance.simulation_ticks_per_second,
        "SessionStartConfig must copy tick rate"
	)

	var default_balance := PrototypeBalanceScript.new()
	assert_equal(
		default_balance.session_cash_balance.starting_session_cash,
		300,
		"Default starting_session_cash must be 300"
	)
	assert_equal(default_balance.hazard_generation_balance.hazard_cell_count, 12, "Default hazard count is 12")
	assert_equal(default_balance.durability_balance.maximum_durability, 100.0, "Default durability is 100")
	assert_equal(default_balance.durability_balance.damage_per_traveled_cell, 10.0, "Default hazard damage is 10")
	assert_equal(default_balance.durability_balance.repair_cost_per_durability, 1.0, "Default repair rate is 1")
	assert_equal(
		default_balance.track_inventory_balance.total_track_cells,
		18,
        "Default total_track_cells must be 18"
	)
	assert_equal(
		default_balance.track_inventory_balance.recovery_lag_cells,
		6,
        "Default recovery_lag_cells must be 6"
	)
	assert_equal(
		default_balance.track_construction_balance.build_cells_per_second,
		3.0,
        "Default build_cells_per_second must be 3.0"
	)
	assert_equal(
		default_balance.train_balance.speed_cells_per_second,
		1.5,
        "Default speed_cells_per_second must be 1.5"
	)
	assert_equal(
		default_balance.departure_balance.required_built_cells,
		9,
        "Default required_built_cells must be 9"
	)

	var invalid_total := PrototypeBalanceScript.new()
	invalid_total.track_inventory_balance.total_track_cells = 0
	_assert_contains(Validator.validate(invalid_total), "total_track_cells")

	var invalid_negative_lag := PrototypeBalanceScript.new()
	invalid_negative_lag.track_inventory_balance.recovery_lag_cells = -1
	_assert_contains(Validator.validate(invalid_negative_lag), "recovery_lag_cells")

	var invalid_full_lag := PrototypeBalanceScript.new()
	invalid_full_lag.track_inventory_balance.recovery_lag_cells = (
		invalid_full_lag.track_inventory_balance.total_track_cells
	)
	_assert_contains(Validator.validate(invalid_full_lag), "recovery_lag_cells")

	var invalid_build_speed := PrototypeBalanceScript.new()
	invalid_build_speed.track_construction_balance.build_cells_per_second = 0.0
	_assert_contains(Validator.validate(invalid_build_speed), "build_cells_per_second")

	var invalid_train_speed := PrototypeBalanceScript.new()
	invalid_train_speed.train_balance.speed_cells_per_second = 0.0
	_assert_contains(Validator.validate(invalid_train_speed), "speed_cells_per_second")

	var invalid_zero_departure := PrototypeBalanceScript.new()
	invalid_zero_departure.departure_balance.required_built_cells = 0
	_assert_contains(Validator.validate(invalid_zero_departure), "required_built_cells")

	var invalid_large_departure := PrototypeBalanceScript.new()
	invalid_large_departure.departure_balance.required_built_cells = (
		invalid_large_departure.track_inventory_balance.total_track_cells + 1
	)
	_assert_contains(Validator.validate(invalid_large_departure), "required_built_cells")

	var invalid_negative_cash := PrototypeBalanceScript.new()
	invalid_negative_cash.session_cash_balance.starting_session_cash = -1
	_assert_contains(
		Validator.validate(invalid_negative_cash),
		"prototype_balance.session_cash_balance.starting_session_cash"
	)

	var invalid_large_cash := PrototypeBalanceScript.new()
	invalid_large_cash.session_cash_balance.starting_session_cash = 1000001
	_assert_contains(
		Validator.validate(invalid_large_cash),
		"prototype_balance.session_cash_balance.starting_session_cash"
	)

	var missing_cash_resource := PrototypeBalanceScript.new()
	missing_cash_resource.session_cash_balance = null
	_assert_contains(
		Validator.validate(missing_cash_resource),
		"prototype_balance.session_cash_balance.resource"
	)

	var invalid_hazard_count := PrototypeBalanceScript.new()
	invalid_hazard_count.hazard_generation_balance.hazard_cell_count = -1
	_assert_contains(Validator.validate(invalid_hazard_count), "prototype_balance.hazard_generation_balance.hazard_cell_count")
	invalid_hazard_count.hazard_generation_balance.hazard_cell_count = 4097
	_assert_contains(Validator.validate(invalid_hazard_count), "prototype_balance.hazard_generation_balance.hazard_cell_count")
	invalid_hazard_count.hazard_generation_balance = null
	_assert_contains(Validator.validate(invalid_hazard_count), "prototype_balance.hazard_generation_balance.resource")

	var invalid_durability := PrototypeBalanceScript.new()
	invalid_durability.durability_balance.maximum_durability = NAN
	_assert_contains(Validator.validate(invalid_durability), "prototype_balance.durability_balance.maximum_durability")
	invalid_durability.durability_balance.maximum_durability = 100.0
	invalid_durability.durability_balance.damage_per_traveled_cell = INF
	_assert_contains(Validator.validate(invalid_durability), "prototype_balance.durability_balance.damage_per_traveled_cell")
	invalid_durability.durability_balance.damage_per_traveled_cell = 10.0
	invalid_durability.durability_balance.repair_cost_per_durability = -INF
	_assert_contains(Validator.validate(invalid_durability), "prototype_balance.durability_balance.repair_cost_per_durability")
	invalid_durability.durability_balance = null
	_assert_contains(Validator.validate(invalid_durability), "prototype_balance.durability_balance.resource")

	var risk_copy_balance := PrototypeBalanceScript.new()
	risk_copy_balance.hazard_generation_balance.hazard_cell_count = 7
	risk_copy_balance.durability_balance.maximum_durability = 125.0
	risk_copy_balance.durability_balance.damage_per_traveled_cell = 4.5
	risk_copy_balance.durability_balance.repair_cost_per_durability = 2.0
	var risk_config = risk_copy_balance.create_session_start_config(812)
	assert_equal(risk_config.hazard_cell_count, 7, "Start config copies hazard count")
	assert_equal(risk_config.maximum_durability, 125.0, "Start config copies maximum durability")
	assert_equal(risk_config.damage_per_traveled_cell, 4.5, "Start config copies hazard damage")
	assert_equal(risk_config.repair_cost_per_durability, 2.0, "Start config copies repair rate")
	risk_copy_balance.hazard_generation_balance.hazard_cell_count = 1
	risk_copy_balance.durability_balance.maximum_durability = 1.0
	assert_equal(risk_config.hazard_cell_count, 7, "Risk config is detached from hazard Resource")
	assert_equal(risk_config.maximum_durability, 125.0, "Risk config is detached from durability Resource")

	return finish()


func _test_planning_time_scale_contract() -> void:
	var balance := PrototypeBalanceScript.new()
	var session_balance = balance.session_balance
	var has_property := _object_has_property(session_balance, &"planning_time_scale_percent")
	assert_true(has_property, "Session balance exposes a planning time-scale percentage")
	if not has_property:
		return
	assert_equal(session_balance.get("planning_time_scale_percent"), 25, "Planning defaults to 25 percent")
	for valid_percent in [10, 100]:
		session_balance.set("planning_time_scale_percent", valid_percent)
		assert_equal(Validator.validate(balance), PackedStringArray(), "Inclusive planning boundary %d is valid" % valid_percent)
	for invalid_percent in [9, 101]:
		session_balance.set("planning_time_scale_percent", invalid_percent)
		var errors := Validator.validate(balance)
		_assert_contains(errors, "prototype_balance.session_balance.planning_time_scale_percent")
	session_balance.set("planning_time_scale_percent", 25)
	var config = balance.create_session_start_config(77)
	assert_equal(config.get("planning_time_scale_percent"), 25, "Runtime config copies planning percentage")
	session_balance.set("planning_time_scale_percent", 75)
	assert_equal(config.get("planning_time_scale_percent"), 25, "Runtime config remains isolated from resource mutation")


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
