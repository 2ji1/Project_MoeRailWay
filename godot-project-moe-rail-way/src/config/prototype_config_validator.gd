class_name PrototypeConfigValidator
extends RefCounted

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")

static func validate(balance: PrototypeBalanceScript) -> PackedStringArray:
    var errors := PackedStringArray()

    if balance == null:
        errors.append("prototype balance resource is required")
        return errors

    if balance.session_duration_seconds <= 0.0:
        errors.append("session_duration_seconds must be greater than 0")

    if balance.simulation_ticks_per_second <= 0:
        errors.append("simulation_ticks_per_second must be greater than 0")

    return errors
