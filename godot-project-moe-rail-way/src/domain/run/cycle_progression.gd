class_name CycleProgression
extends RefCounted

var _hazard_growth_interval_cycles: int
var _hazard_cells_per_step: int
var _damage_per_cell_per_cycle: float
var _maximum_damage_per_cell: float


func _init(hazard_growth_interval_cycles_value: int = 2, hazard_cells_per_step_value: int = 1, damage_per_cell_per_cycle_value: float = 1.0, maximum_damage_per_cell_value: float = 10.0) -> void:
	assert(hazard_growth_interval_cycles_value >= 1, "Hazard growth interval must be positive")
	assert(hazard_cells_per_step_value >= 0, "Hazard cells per step must be nonnegative")
	assert(is_finite(damage_per_cell_per_cycle_value) and damage_per_cell_per_cycle_value >= 0.0, "Damage growth must be finite and nonnegative")
	assert(is_finite(maximum_damage_per_cell_value) and maximum_damage_per_cell_value >= 0.0, "Maximum damage must be finite and nonnegative")
	_hazard_growth_interval_cycles = hazard_growth_interval_cycles_value
	_hazard_cells_per_step = hazard_cells_per_step_value
	_damage_per_cell_per_cycle = damage_per_cell_per_cycle_value
	_maximum_damage_per_cell = maximum_damage_per_cell_value


static func hazard_count_for_cycle(cycle: int, base_count: int, eligible_cells: int, interval_cycles: int, cells_per_step: int) -> int:
	assert(cycle >= 1 and base_count >= 0 and eligible_cells >= 0 and interval_cycles >= 1 and cells_per_step >= 0)
	var clamped_base := mini(base_count, eligible_cells)
	if cells_per_step == 0: return clamped_base
	var requested_steps := (cycle - 1) / interval_cycles
	var applied_steps := mini(requested_steps, (eligible_cells - clamped_base) / cells_per_step)
	return clamped_base + applied_steps * cells_per_step


static func damage_for_cycle(cycle: int, base_damage: float, damage_per_cycle: float, maximum_damage: float) -> float:
	assert(cycle >= 1 and is_finite(base_damage) and base_damage >= 0.0)
	assert(is_finite(damage_per_cycle) and damage_per_cycle >= 0.0)
	assert(is_finite(maximum_damage) and maximum_damage >= base_damage)
	if damage_per_cycle == 0.0: return base_damage
	var requested_steps := cycle - 1
	var maximum_steps_float: float = floor((maximum_damage - base_damage) / damage_per_cycle)
	var applied_steps: int = requested_steps if maximum_steps_float >= float(requested_steps) else int(maximum_steps_float)
	return minf(maximum_damage, base_damage + float(applied_steps) * damage_per_cycle)


func compose(cycle: int, base_hazard_count: int, eligible_cells: int, base_damage: float) -> Dictionary:
	return {
		"cycle": cycle,
		"hazard_cell_count": hazard_count_for_cycle(cycle, base_hazard_count, eligible_cells, _hazard_growth_interval_cycles, _hazard_cells_per_step),
		"damage_per_traveled_cell": damage_for_cycle(cycle, base_damage, _damage_per_cell_per_cycle, _maximum_damage_per_cell),
	}
