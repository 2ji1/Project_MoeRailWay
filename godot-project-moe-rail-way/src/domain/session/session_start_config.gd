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
var warp_forecast_ticks: int
var warp_generation_interval_ticks: int
var warp_lifetime_min_ticks: int
var warp_lifetime_max_ticks: int
var warp_max_live_pairs: int
var cargo_base_slot_count: int
var cargo_base_delivery_reward: int
var planning_time_scale_percent: int
var starting_session_cash: int
var hazard_cell_count: int
var maximum_durability: float
var damage_per_traveled_cell: float
var repair_cost_per_durability: float


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
	departure_cell_value: Vector2i = Vector2i(-1, -1),
	warp_forecast_ticks_value: int = 0,
	warp_generation_interval_ticks_value: int = 0,
	warp_lifetime_min_ticks_value: int = 0,
	warp_lifetime_max_ticks_value: int = 0,
	warp_max_live_pairs_value: int = 0,
	cargo_base_slot_count_value: int = 0,
	cargo_base_delivery_reward_value: int = 0,
	planning_time_scale_percent_value: int = 100,
	starting_session_cash_value: int = 0,
	hazard_cell_count_value: int = 0,
	maximum_durability_value: float = 0.0,
	damage_per_traveled_cell_value: float = 0.0,
	repair_cost_per_durability_value: float = 0.0
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
	warp_forecast_ticks = warp_forecast_ticks_value
	warp_generation_interval_ticks = warp_generation_interval_ticks_value
	warp_lifetime_min_ticks = warp_lifetime_min_ticks_value
	warp_lifetime_max_ticks = warp_lifetime_max_ticks_value
	warp_max_live_pairs = warp_max_live_pairs_value
	cargo_base_slot_count = cargo_base_slot_count_value
	cargo_base_delivery_reward = cargo_base_delivery_reward_value
	planning_time_scale_percent = planning_time_scale_percent_value
	starting_session_cash = starting_session_cash_value
	hazard_cell_count = hazard_cell_count_value
	maximum_durability = maximum_durability_value
	damage_per_traveled_cell = damage_per_traveled_cell_value
	repair_cost_per_durability = repair_cost_per_durability_value
