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
    permissive.train_balance.speed_cells_per_second = 0.05
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
    var base_config = balance.create_session_start_config(77)
    balance.track_inventory_balance.total_track_cells = 23
    balance.track_inventory_balance.recovery_lag_cells = 7
    balance.track_inventory_balance.urgent_warning_seconds = 2.5
    balance.track_construction_balance.build_cells_per_second = 2.25
    balance.train_balance.speed_cells_per_second = 1.75
    balance.departure_balance.required_built_cells = 11
    var grid_config = balance.complete_session_start_config(
        base_config,
        Vector2(1200.0, 560.0),
        &"departure_03",
        Vector2(984.0, 123.2),
        40.0,
        Vector2i(30, 14),
        Vector2.ZERO,
        Vector2i(24, 3)
    )
    assert_equal(grid_config.seed, 77, "Completed config must preserve factory seed")
    assert_equal(grid_config.session_duration_seconds, 12.0, "Completed config must preserve factory duration")
    assert_equal(grid_config.simulation_ticks_per_second, 30, "Completed config must preserve factory tick rate")
    assert_equal(grid_config.total_track_cells, 23, "Completed config must copy total_track_cells")
    assert_equal(grid_config.recovery_lag_cells, 7, "Completed config must copy recovery_lag_cells")
    assert_equal(grid_config.urgent_warning_seconds, 2.5, "Completed config must copy urgent_warning_seconds")
    assert_equal(grid_config.build_cells_per_second, 2.25, "Completed config must copy build_cells_per_second")
    assert_equal(grid_config.train_speed_cells_per_second, 1.75, "Completed config must copy speed_cells_per_second")
    assert_equal(grid_config.departure_required_built_cells, 11, "Completed config must copy required_built_cells")
    assert_equal(grid_config.logical_field_size, Vector2(1200.0, 560.0), "Completed config must copy logical_field_size")
    assert_equal(grid_config.grid_cell_size_units, 40.0, "Completed config must copy grid_cell_size_units")
    assert_equal(grid_config.grid_size, Vector2i(30, 14), "Completed config must copy grid_size")
    assert_equal(grid_config.grid_origin_units, Vector2.ZERO, "Completed config must copy grid_origin_units")
    assert_equal(grid_config.departure_candidate_id, &"departure_03", "Completed config must copy candidate ID")
    assert_equal(grid_config.departure_position, Vector2(984.0, 123.2), "Completed config must copy position")
    assert_equal(grid_config.departure_cell, Vector2i(24, 3), "Completed config must copy departure_cell")

    var removed_properties: Array = [
        [balance.train_balance, "speed", "_units_per_second"],
        [balance.track_inventory_balance, "total", "_units"],
        [balance.track_inventory_balance, "recovery_distance", "_units"],
        [balance.track_construction_balance, "speed", "_units_per_second"],
        [balance.track_construction_balance, "endpoint_grab_radius", "_units"],
        [balance.track_construction_balance, "route_hit_radius", "_units"],
        [balance.track_construction_balance, "minimum_sample_distance", "_units"],
        [balance.track_construction_balance, "intersection_clearance", "_units"],
        [balance.departure_balance, "required_built", "_units"],
        [grid_config, "train_speed", "_units_per_second"],
        [grid_config, "total_track", "_units"],
        [grid_config, "recovery_distance", "_units"],
        [grid_config, "construction_speed", "_units_per_second"],
        [grid_config, "endpoint_grab_radius", "_units"],
        [grid_config, "route_hit_radius", "_units"],
        [grid_config, "minimum_sample_distance", "_units"],
        [grid_config, "intersection_clearance", "_units"],
        [grid_config, "departure_required_built", "_units"],
    ]
    for entry in removed_properties:
        _assert_property_absent(entry[0], StringName(entry[1] + entry[2]))

    balance.track_inventory_balance.total_track_cells = 99
    balance.track_inventory_balance.recovery_lag_cells = 99
    balance.track_inventory_balance.urgent_warning_seconds = 99.0
    balance.track_construction_balance.build_cells_per_second = 99.0
    balance.train_balance.speed_cells_per_second = 99.0
    balance.departure_balance.required_built_cells = 99
    assert_equal(grid_config.total_track_cells, 23, "Detached config must not reread total_track_cells")
    assert_equal(grid_config.recovery_lag_cells, 7, "Detached config must not reread recovery_lag_cells")
    assert_equal(grid_config.urgent_warning_seconds, 2.5, "Detached config must not reread urgent_warning_seconds")
    assert_equal(grid_config.build_cells_per_second, 2.25, "Detached config must not reread build_cells_per_second")
    assert_equal(grid_config.train_speed_cells_per_second, 1.75, "Detached config must not reread speed_cells_per_second")
    assert_equal(grid_config.departure_required_built_cells, 11, "Detached config must not reread required_built_cells")
    return finish()


func _assert_contains(errors: PackedStringArray, fragment: String, message: String) -> void:
    var found := false
    for error_message in errors:
        found = found or error_message.contains(fragment)
    assert_true(found, message)


func _assert_property_absent(value: Object, property_name: StringName) -> void:
    var found := false
    for property in value.get_property_list():
        if property.name == property_name:
            found = true
            break
    assert_true(
        not found,
        "Removed property '%s' must not exist on %s" % [property_name, value]
    )
