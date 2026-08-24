extends "res://tests/support/prototype_test.gd"

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const Validator = preload("res://src/config/prototype_config_validator.gd")


func run() -> PackedStringArray:
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

    return finish()


func _assert_contains(errors: PackedStringArray, fragment: String) -> void:
    var found := false
    for error_message in errors:
        found = found or error_message.contains(fragment)
    assert_true(found, "Expected error containing %s" % fragment)
