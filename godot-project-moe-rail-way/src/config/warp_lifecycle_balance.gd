class_name WarpLifecycleBalance
extends Resource

@export_range(0.0, 60.0, 0.1) var forecast_duration_seconds := 8.0
@export_range(0.1, 120.0, 0.1) var generation_interval_seconds := 12.0
@export_range(1.0, 180.0, 0.1) var lifetime_min_seconds := 24.0
@export_range(1.0, 180.0, 0.1) var lifetime_max_seconds := 36.0
@export_range(1, 6, 1) var max_live_pairs := 3
