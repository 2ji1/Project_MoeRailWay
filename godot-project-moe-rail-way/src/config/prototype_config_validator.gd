class_name PrototypeConfigValidator
extends RefCounted

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")

static func validate(balance: PrototypeBalanceScript) -> PackedStringArray:
    var errors := PackedStringArray()

    if balance == null:
        errors.append("prototype balance resource is required")
        return errors

    if balance.session_balance == null:
        errors.append("prototype_balance.session_balance.resource is required")
    else:
        if balance.session_balance.session_duration_seconds <= 0.0:
            errors.append(
                "prototype_balance.session_balance.session_duration_seconds must be greater than 0"
            )
        if (
            balance.session_balance.simulation_ticks_per_second < 1
            or balance.session_balance.simulation_ticks_per_second > 240
        ):
            errors.append(
                "prototype_balance.session_balance.simulation_ticks_per_second must be between 1 and 240"
            )

    if balance.train_balance == null:
        errors.append("prototype_balance.train_balance.resource is required")
    elif balance.train_balance.speed_cells_per_second <= 0.0:
        errors.append(
            "prototype_balance.train_balance.speed_cells_per_second must be greater than 0"
        )

    if balance.track_inventory_balance == null:
        errors.append("prototype_balance.track_inventory_balance.resource is required")
    else:
        if balance.track_inventory_balance.urgent_warning_seconds <= 0.0:
            errors.append(
                "prototype_balance.track_inventory_balance.urgent_warning_seconds must be greater than 0"
            )
        if balance.track_inventory_balance.total_track_cells <= 0:
            errors.append(
                "prototype_balance.track_inventory_balance.total_track_cells must be greater than 0"
            )
        if (
            balance.track_inventory_balance.recovery_lag_cells < 0
            or balance.track_inventory_balance.recovery_lag_cells
            >= balance.track_inventory_balance.total_track_cells
        ):
            errors.append(
                "prototype_balance.track_inventory_balance.recovery_lag_cells must be greater than or equal to 0 and less than total_track_cells"
            )

    if balance.track_construction_balance == null:
        errors.append("prototype_balance.track_construction_balance.resource is required")
    elif balance.track_construction_balance.build_cells_per_second <= 0.0:
        errors.append(
            "prototype_balance.track_construction_balance.build_cells_per_second must be greater than 0"
        )

    if balance.departure_balance == null:
        errors.append("prototype_balance.departure_balance.resource is required")
    else:
        if (
            balance.departure_balance.required_built_cells < 1
            or (
                balance.track_inventory_balance != null
                and balance.departure_balance.required_built_cells
                > balance.track_inventory_balance.total_track_cells
            )
        ):
            errors.append(
                "prototype_balance.departure_balance.required_built_cells must be between 1 and total_track_cells"
            )

    return errors
