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

    return finish()
