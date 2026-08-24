extends "res://tests/support/prototype_test.gd"

const SessionBalanceScript = preload("res://src/config/session_balance.gd")
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const ValidatorScript = preload("res://src/config/prototype_config_validator.gd")


func run() -> PackedStringArray:
    var balance = PrototypeBalanceScript.new()
    assert_not_null(balance.session_balance, "SessionBalance must exist by default")
    assert_not_null(balance.train_balance, "TrainBalance must exist by default")
    assert_not_null(balance.track_inventory_balance, "TrackInventoryBalance must exist by default")
    assert_not_null(balance.track_construction_balance, "TrackConstructionBalance must exist by default")
    assert_not_null(balance.departure_balance, "DepartureBalance must exist by default")
    assert_equal(ValidatorScript.validate(balance).size(), 0, "Approved defaults must validate")
    assert_equal(balance.session_duration_seconds, 180.0, "Legacy duration getter must delegate")
    assert_equal(balance.simulation_ticks_per_second, 60, "Legacy tick getter must delegate")

    var missing = PrototypeBalanceScript.new()
    missing.track_construction_balance = null
    _assert_contains(
        ValidatorScript.validate(missing),
        "prototype_balance.track_construction_balance.resource",
        "Missing construction Resource must name its owner"
    )

    var invalid = PrototypeBalanceScript.new()
    invalid.track_inventory_balance.total_units = 720.0
    invalid.track_inventory_balance.recovery_distance_units = 720.0
    invalid.track_construction_balance.endpoint_grab_radius_units = 7.0
    invalid.track_construction_balance.minimum_sample_distance_units = 8.0
    invalid.track_construction_balance.intersection_clearance_units = 9.0
    invalid.departure_balance.required_built_units = 721.0
    var errors := ValidatorScript.validate(invalid)
    _assert_contains(errors, "recovery_distance_units", "Recovery cross-check must name its field")
    _assert_contains(errors, "minimum_sample_distance_units", "Sample cross-check must name its field")
    _assert_contains(errors, "intersection_clearance_units", "Clearance cross-check must name its field")
    _assert_contains(errors, "required_built_units", "Departure cross-check must name its field")

    var invalid_ticks = PrototypeBalanceScript.new()
    invalid_ticks.session_balance.simulation_ticks_per_second = 0
    _assert_contains(
        ValidatorScript.validate(invalid_ticks),
        "prototype_balance.session_balance.simulation_ticks_per_second",
        "Tick rate below the supported range must name its owner and field"
    )
    invalid_ticks.session_balance.simulation_ticks_per_second = 241
    _assert_contains(
        ValidatorScript.validate(invalid_ticks),
        "prototype_balance.session_balance.simulation_ticks_per_second",
        "Tick rate above the supported range must name its owner and field"
    )

    var permissive = PrototypeBalanceScript.new()
    permissive.train_balance.speed_units_per_second = 0.05
    assert_equal(
        ValidatorScript.validate(permissive).size(),
        0,
        "Positive train speed must not have a hidden tuning range"
    )
    permissive.session_balance.session_duration_seconds = 1000000.0
    assert_equal(
        ValidatorScript.validate(permissive).size(),
        0,
        "Positive session duration must not have a hidden tuning range"
    )

    balance.session_duration_seconds = 12.0
    balance.simulation_ticks_per_second = 30
    balance.train_balance.speed_units_per_second = 45.0
    balance.track_inventory_balance.total_units = 900.0
    var base_config = balance.create_session_start_config(77)
    var config = balance.complete_session_start_config(
        base_config,
        Vector2(1200.0, 560.0),
        &"departure_03",
        Vector2(984.0, 123.2)
    )
    assert_equal(config.seed, 77, "Completed config must preserve factory seed")
    assert_equal(config.session_duration_seconds, 12.0, "Completed config must preserve factory duration")
    assert_equal(config.simulation_ticks_per_second, 30, "Completed config must preserve factory tick rate")
    assert_equal(config.train_speed_units_per_second, 45.0, "Completed config must copy train speed")
    assert_equal(config.total_track_units, 900.0, "Completed config must copy inventory")
    assert_equal(config.departure_candidate_id, &"departure_03", "Completed config must copy candidate ID")
    assert_equal(config.departure_position, Vector2(984.0, 123.2), "Completed config must copy position")
    balance.train_balance.speed_units_per_second = 99.0
    assert_equal(config.train_speed_units_per_second, 45.0, "Active config must not reread Resources")
    return finish()


func _assert_contains(errors: PackedStringArray, fragment: String, message: String) -> void:
    var found := false
    for error_message in errors:
        found = found or error_message.contains(fragment)
    assert_true(found, message)
