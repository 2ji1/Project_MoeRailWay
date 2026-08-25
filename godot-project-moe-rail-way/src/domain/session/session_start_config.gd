class_name SessionStartConfig
extends RefCounted

var seed: int
var session_duration_seconds: float
var simulation_ticks_per_second: int
var train_speed_cells_per_second: float
var total_track_cells: int
var recovery_lag_cells: int
var urgent_warning_seconds: float
var build_cells_per_second: float
var departure_required_built_cells: int
var logical_field_size: Vector2
var grid_size: Vector2i
var grid_cell_size_units: float
var grid_origin_units: Vector2
var departure_candidate_id: StringName
var departure_position: Vector2
var departure_cell: Vector2i


func _init(
	seed_value: int,
	duration_seconds: float,
	ticks_per_second: int,
	train_speed_cells_value: float = 0.0,
	total_track_cells_value: int = 0,
	recovery_lag_cells_value: int = 0,
	urgent_warning_value: float = 0.0,
	build_cells_value: float = 0.0,
	departure_required_cells_value: int = 0,
	logical_field_size_value: Vector2 = Vector2.ZERO,
	grid_size_value: Vector2i = Vector2i.ZERO,
	grid_cell_size_value: float = 0.0,
	grid_origin_value: Vector2 = Vector2.ZERO,
	departure_candidate_id_value: StringName = StringName(),
	departure_position_value: Vector2 = Vector2.ZERO,
	departure_cell_value: Vector2i = Vector2i(-1, -1)
) -> void:
	seed = seed_value
	session_duration_seconds = duration_seconds
	simulation_ticks_per_second = ticks_per_second
	train_speed_cells_per_second = train_speed_cells_value
	total_track_cells = total_track_cells_value
	recovery_lag_cells = recovery_lag_cells_value
	urgent_warning_seconds = urgent_warning_value
	build_cells_per_second = build_cells_value
	departure_required_built_cells = departure_required_cells_value
	logical_field_size = logical_field_size_value
	grid_size = grid_size_value
	grid_cell_size_units = grid_cell_size_value
	grid_origin_units = grid_origin_value
	departure_candidate_id = departure_candidate_id_value
	departure_position = departure_position_value
	departure_cell = departure_cell_value
