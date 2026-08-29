class_name HazardSystem
extends RefCounted

const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")

const HAZARD_SEED_SALT := 0x5249534B48415A44

var _hazard_cells: Array[Vector2i] = []
var _damage_per_traveled_cell: float


func _init(start_config: SessionStartConfigScript) -> void:
	assert(start_config != null, "Session start config is required")
	assert(start_config.grid_size.x > 0 and start_config.grid_size.y > 0, "Hazard grid must be positive")
	assert(_cell_is_inside(start_config.departure_cell, start_config.grid_size), "Hazard departure cell must be in grid")
	assert(start_config.hazard_cell_count >= 0, "Hazard cell count must be nonnegative")
	assert(
		start_config.hazard_cell_count <= start_config.grid_size.x * start_config.grid_size.y - 1,
		"Hazard cell count must fit eligible cells"
	)
	assert(
		is_finite(start_config.damage_per_traveled_cell)
		and start_config.damage_per_traveled_cell >= 0.0,
		"Hazard damage must be finite and nonnegative"
	)
	_damage_per_traveled_cell = start_config.damage_per_traveled_cell
	_generate(start_config.seed, start_config.grid_size, start_config.departure_cell, start_config.hazard_cell_count)


func get_hazard_cells() -> Array[Vector2i]:
	return _hazard_cells.duplicate()


func calculate_damage(traveled_hazard_distance_cells: float) -> float:
	if not is_finite(traveled_hazard_distance_cells) or traveled_hazard_distance_cells <= 0.0:
		return 0.0
	return traveled_hazard_distance_cells * _damage_per_traveled_cell


func _generate(seed_value: int, grid_size: Vector2i, departure_cell: Vector2i, count: int) -> void:
	var candidates: Array[Vector2i] = []
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Vector2i(x, y)
			if cell != departure_cell:
				candidates.append(cell)
	var hazard_rng = SessionRngScript.new(seed_value ^ HAZARD_SEED_SALT)
	for index in range(count):
		var swap_index := index + hazard_rng.next_index(candidates.size() - index)
		var swap_cell := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = swap_cell
		_hazard_cells.append(candidates[index])


func _cell_is_inside(cell: Vector2i, grid_size: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y
