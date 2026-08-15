class_name PrototypeBalance
extends Resource

const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")

@export_range(1.0, 3600.0, 1.0) var session_duration_seconds := 180.0
@export_range(1, 240, 1) var simulation_ticks_per_second := 60


func create_session_start_config(seed_value: int) -> SessionStartConfigScript:
    return SessionStartConfigScript.new(
        seed_value,
        session_duration_seconds,
        simulation_ticks_per_second
    )
