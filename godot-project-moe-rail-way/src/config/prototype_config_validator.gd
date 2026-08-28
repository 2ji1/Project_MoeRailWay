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
        if (
            balance.session_balance.planning_time_scale_percent < 10
            or balance.session_balance.planning_time_scale_percent > 100
        ):
            errors.append(
                "prototype_balance.session_balance.planning_time_scale_percent must be between 10 and 100"
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

    if balance.warp_lifecycle_balance == null:
        errors.append("prototype_balance.warp_lifecycle_balance.resource is required")
    else:
        if (
            not is_finite(balance.warp_lifecycle_balance.forecast_duration_seconds)
            or balance.warp_lifecycle_balance.forecast_duration_seconds < 0.0
            or balance.warp_lifecycle_balance.forecast_duration_seconds > 60.0
        ):
            errors.append(
                "prototype_balance.warp_lifecycle_balance.forecast_duration_seconds must be finite and between 0.0 and 60.0"
            )
        if (
            not is_finite(balance.warp_lifecycle_balance.generation_interval_seconds)
            or balance.warp_lifecycle_balance.generation_interval_seconds < 0.1
            or balance.warp_lifecycle_balance.generation_interval_seconds > 120.0
        ):
            errors.append(
                "prototype_balance.warp_lifecycle_balance.generation_interval_seconds must be finite and between 0.1 and 120.0"
            )
        if (
            not is_finite(balance.warp_lifecycle_balance.lifetime_min_seconds)
            or balance.warp_lifecycle_balance.lifetime_min_seconds < 1.0
            or balance.warp_lifecycle_balance.lifetime_min_seconds > 180.0
        ):
            errors.append(
                "prototype_balance.warp_lifecycle_balance.lifetime_min_seconds must be finite and between 1.0 and 180.0"
            )
        if (
            not is_finite(balance.warp_lifecycle_balance.lifetime_max_seconds)
            or balance.warp_lifecycle_balance.lifetime_max_seconds < 1.0
            or balance.warp_lifecycle_balance.lifetime_max_seconds > 180.0
            or (
                is_finite(balance.warp_lifecycle_balance.lifetime_min_seconds)
                and balance.warp_lifecycle_balance.lifetime_max_seconds
                < balance.warp_lifecycle_balance.lifetime_min_seconds
            )
        ):
            errors.append(
                "prototype_balance.warp_lifecycle_balance.lifetime_max_seconds must be finite, between 1.0 and 180.0, and at least lifetime_min_seconds"
            )
        if (
            balance.warp_lifecycle_balance.max_live_pairs < 1
            or balance.warp_lifecycle_balance.max_live_pairs > 6
        ):
            errors.append(
                "prototype_balance.warp_lifecycle_balance.max_live_pairs must be between 1 and 6"
            )

    if balance.cargo_balance == null:
        errors.append("prototype_balance.cargo_balance.resource is required")
    else:
        if (
            balance.cargo_balance.base_slot_count < 1
            or balance.cargo_balance.base_slot_count > 8
        ):
            errors.append(
                "prototype_balance.cargo_balance.base_slot_count must be between 1 and 8"
            )
        if (
            balance.cargo_balance.base_delivery_reward < 0
            or balance.cargo_balance.base_delivery_reward > 1000000
        ):
            errors.append(
                "prototype_balance.cargo_balance.base_delivery_reward must be between 0 and 1000000"
            )

    return errors
