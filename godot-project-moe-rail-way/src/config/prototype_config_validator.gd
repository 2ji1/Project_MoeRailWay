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
    elif balance.train_balance.speed_units_per_second <= 0.0:
        errors.append(
            "prototype_balance.train_balance.speed_units_per_second must be greater than 0"
        )

    if balance.track_inventory_balance == null:
        errors.append("prototype_balance.track_inventory_balance.resource is required")
    else:
        if balance.track_inventory_balance.total_units <= 0.0:
            errors.append(
                "prototype_balance.track_inventory_balance.total_units must be greater than 0"
            )
        if balance.track_inventory_balance.recovery_distance_units <= 0.0:
            errors.append(
                "prototype_balance.track_inventory_balance.recovery_distance_units must be greater than 0"
            )
        elif (
            balance.track_inventory_balance.total_units > 0.0
            and balance.track_inventory_balance.recovery_distance_units
            >= balance.track_inventory_balance.total_units
        ):
            errors.append(
                "prototype_balance.track_inventory_balance.recovery_distance_units must be less than total_units"
            )
        if balance.track_inventory_balance.urgent_warning_seconds <= 0.0:
            errors.append(
                "prototype_balance.track_inventory_balance.urgent_warning_seconds must be greater than 0"
            )

    if balance.track_construction_balance == null:
        errors.append("prototype_balance.track_construction_balance.resource is required")
    else:
        if balance.track_construction_balance.speed_units_per_second <= 0.0:
            errors.append(
                "prototype_balance.track_construction_balance.speed_units_per_second must be greater than 0"
            )
        if balance.track_construction_balance.endpoint_grab_radius_units <= 0.0:
            errors.append(
                "prototype_balance.track_construction_balance.endpoint_grab_radius_units must be greater than 0"
            )
        if balance.track_construction_balance.route_hit_radius_units <= 0.0:
            errors.append(
                "prototype_balance.track_construction_balance.route_hit_radius_units must be greater than 0"
            )
        if balance.track_construction_balance.minimum_sample_distance_units <= 0.0:
            errors.append(
                "prototype_balance.track_construction_balance.minimum_sample_distance_units must be greater than 0"
            )
        elif (
            balance.track_construction_balance.endpoint_grab_radius_units > 0.0
            and balance.track_construction_balance.minimum_sample_distance_units
            > balance.track_construction_balance.endpoint_grab_radius_units
        ):
            errors.append(
                "prototype_balance.track_construction_balance.minimum_sample_distance_units must be less than or equal to endpoint_grab_radius_units"
            )
        if balance.track_construction_balance.intersection_clearance_units <= 0.0:
            errors.append(
                "prototype_balance.track_construction_balance.intersection_clearance_units must be greater than 0"
            )
        elif (
            balance.track_construction_balance.minimum_sample_distance_units > 0.0
            and balance.track_construction_balance.intersection_clearance_units
            > balance.track_construction_balance.minimum_sample_distance_units
        ):
            errors.append(
                "prototype_balance.track_construction_balance.intersection_clearance_units must be less than or equal to minimum_sample_distance_units"
            )

    if balance.departure_balance == null:
        errors.append("prototype_balance.departure_balance.resource is required")
    else:
        if balance.departure_balance.required_built_units <= 0.0:
            errors.append(
                "prototype_balance.departure_balance.required_built_units must be greater than 0"
            )
        elif (
            balance.track_inventory_balance != null
            and balance.track_inventory_balance.total_units > 0.0
            and balance.departure_balance.required_built_units
            > balance.track_inventory_balance.total_units
        ):
            errors.append(
                "prototype_balance.departure_balance.required_built_units must be less than or equal to total_units"
            )

    return errors
