class_name PrototypeConfigValidator
extends RefCounted

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const MAX_SIGNED_INTEGER := 9223372036854775807
const MAX_CARGO_SLOT_COUNT := 8

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

    if balance.session_cash_balance == null:
        errors.append("prototype_balance.session_cash_balance.resource is required")
    elif (
        balance.session_cash_balance.starting_session_cash < 0
        or balance.session_cash_balance.starting_session_cash > 1000000
    ):
        errors.append(
            "prototype_balance.session_cash_balance.starting_session_cash must be between 0 and 1000000"
        )

    if balance.hazard_generation_balance == null:
        errors.append("prototype_balance.hazard_generation_balance.resource is required")
    elif (
        balance.hazard_generation_balance.hazard_cell_count < 0
        or balance.hazard_generation_balance.hazard_cell_count > 4096
    ):
        errors.append(
            "prototype_balance.hazard_generation_balance.hazard_cell_count must be between 0 and 4096"
        )

    if balance.durability_balance == null:
        errors.append("prototype_balance.durability_balance.resource is required")
    else:
        if (
            not is_finite(balance.durability_balance.maximum_durability)
            or balance.durability_balance.maximum_durability < 1.0
            or balance.durability_balance.maximum_durability > 1000000.0
        ):
            errors.append(
                "prototype_balance.durability_balance.maximum_durability must be finite and between 1.0 and 1000000.0"
            )
        if (
            not is_finite(balance.durability_balance.damage_per_traveled_cell)
            or balance.durability_balance.damage_per_traveled_cell < 0.0
            or balance.durability_balance.damage_per_traveled_cell > 1000000.0
        ):
            errors.append(
                "prototype_balance.durability_balance.damage_per_traveled_cell must be finite and between 0.0 and 1000000.0"
            )
        if (
            not is_finite(balance.durability_balance.repair_cost_per_durability)
            or balance.durability_balance.repair_cost_per_durability < 0.0
            or balance.durability_balance.repair_cost_per_durability > 1000000.0
        ):
            errors.append(
                "prototype_balance.durability_balance.repair_cost_per_durability must be finite and between 0.0 and 1000000.0"
            )

    if balance.track_investment_balance == null:
        errors.append("prototype_balance.track_investment_balance.resource is required")
    else:
        _validate_track_investment(
            errors,
            "prototype_balance.track_investment_balance",
            balance.track_investment_balance.major_track_action_cost,
            balance.track_investment_balance.temporary_track_purchase_cost,
            balance.track_investment_balance.temporary_track_cells_per_purchase,
            balance.track_investment_balance.maximum_temporary_track_purchases,
            (
                balance.track_inventory_balance.total_track_cells
                if balance.track_inventory_balance != null
                else -1
            )
        )

    if balance.cargo_investment_balance == null:
        errors.append("prototype_balance.cargo_investment_balance.resource is required")
    else:
        _validate_cargo_investment(
            errors,
            "prototype_balance.cargo_investment_balance",
            balance.cargo_investment_balance.temporary_cargo_purchase_cost,
            balance.cargo_investment_balance.temporary_cargo_slots_per_purchase,
            balance.cargo_investment_balance.maximum_temporary_cargo_purchases,
            balance.cargo_balance.base_slot_count if balance.cargo_balance != null else -1
        )

    return errors


static func validate_completed_session_start_config(
    config: SessionStartConfigScript
) -> PackedStringArray:
    var errors := PackedStringArray()
    if config == null:
        errors.append("session_start_config is required")
        return errors
    var eligible_cell_count := config.grid_size.x * config.grid_size.y - 1
    if config.hazard_cell_count > eligible_cell_count:
        errors.append(
            "prototype_balance.hazard_generation_balance.hazard_cell_count must not exceed completed grid eligible cells"
        )
    _validate_track_investment(
        errors,
        "prototype_balance.track_investment_balance",
        config.major_track_action_cost,
        config.temporary_track_purchase_cost,
        config.temporary_track_cells_per_purchase,
        config.maximum_temporary_track_purchases,
        config.total_track_cells
    )
    _validate_cargo_investment(
        errors,
        "prototype_balance.cargo_investment_balance",
        config.temporary_cargo_purchase_cost,
        config.temporary_cargo_slots_per_purchase,
        config.maximum_temporary_cargo_purchases,
        config.cargo_base_slot_count
    )
    return errors


static func _validate_track_investment(
    errors: PackedStringArray,
    prefix: String,
    major_action_cost: int,
    purchase_cost: int,
    cells_per_purchase: int,
    maximum_purchases: int,
    base_capacity: int
) -> void:
    if major_action_cost < 0 or major_action_cost > 1000000:
        errors.append(prefix + ".major_track_action_cost must be between 0 and 1000000")
    if purchase_cost < 0 or purchase_cost > 1000000:
        errors.append(prefix + ".temporary_track_purchase_cost must be between 0 and 1000000")
    if cells_per_purchase < 1 or cells_per_purchase > 4096:
        errors.append(prefix + ".temporary_track_cells_per_purchase must be between 1 and 4096")
    if maximum_purchases < 0 or maximum_purchases > 100:
        errors.append(prefix + ".maximum_temporary_track_purchases must be between 0 and 100")
    if (
        _maximum_total_exceeds(base_capacity, cells_per_purchase, maximum_purchases, MAX_SIGNED_INTEGER)
    ):
        errors.append(prefix + ".maximum_temporary_track_purchases must not overflow maximum track capacity")
    if _product_exceeds(purchase_cost, maximum_purchases, MAX_SIGNED_INTEGER):
        errors.append(prefix + ".maximum_temporary_track_purchases must not overflow maximum track purchase cost")


static func _validate_cargo_investment(
    errors: PackedStringArray,
    prefix: String,
    purchase_cost: int,
    slots_per_purchase: int,
    maximum_purchases: int,
    base_capacity: int
) -> void:
    if purchase_cost < 0 or purchase_cost > 1000000:
        errors.append(prefix + ".temporary_cargo_purchase_cost must be between 0 and 1000000")
    if slots_per_purchase < 1 or slots_per_purchase > MAX_CARGO_SLOT_COUNT:
        errors.append(prefix + ".temporary_cargo_slots_per_purchase must be between 1 and 8")
    if maximum_purchases < 0 or maximum_purchases > MAX_CARGO_SLOT_COUNT:
        errors.append(prefix + ".maximum_temporary_cargo_purchases must be between 0 and 8")
    if (
        _maximum_total_exceeds(
            base_capacity,
            slots_per_purchase,
            maximum_purchases,
            MAX_CARGO_SLOT_COUNT
        )
    ):
        errors.append(prefix + ".maximum_temporary_cargo_purchases must keep total cargo slots at or below 8")
    if _product_exceeds(purchase_cost, maximum_purchases, MAX_SIGNED_INTEGER):
        errors.append(prefix + ".maximum_temporary_cargo_purchases must not overflow maximum cargo purchase cost")


static func _maximum_total_exceeds(
    base_value: int,
    increment: int,
    count: int,
    maximum: int
) -> bool:
    if base_value < 0 or increment <= 0 or count < 0:
        return false
    if base_value > maximum:
        return true
    return count > (maximum - base_value) / increment


static func _product_exceeds(value: int, count: int, maximum: int) -> bool:
    if value < 0 or count < 0:
        return false
    if value == 0:
        return false
    return count > maximum / value
