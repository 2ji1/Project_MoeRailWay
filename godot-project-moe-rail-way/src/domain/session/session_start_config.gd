class_name SessionStartConfig
extends RefCounted

var seed: int
var session_duration_seconds: float
var simulation_ticks_per_second: int


func _init(
    seed_value: int,
    duration_seconds: float,
    ticks_per_second: int
) -> void:
    seed = seed_value
    session_duration_seconds = duration_seconds
    simulation_ticks_per_second = ticks_per_second
