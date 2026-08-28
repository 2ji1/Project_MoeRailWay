class_name SessionBalance
extends Resource

@export var session_duration_seconds := 180.0
@export_range(1, 240, 1) var simulation_ticks_per_second := 60
@export_range(10, 100, 1) var planning_time_scale_percent := 25
