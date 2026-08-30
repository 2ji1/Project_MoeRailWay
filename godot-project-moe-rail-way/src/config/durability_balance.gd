class_name DurabilityBalance
extends Resource

@export_range(1.0, 1000000.0, 0.1) var maximum_durability := 100.0
@export_range(0.0, 1000000.0, 0.1) var damage_per_traveled_cell := 10.0
@export_range(0.0, 1000000.0, 0.1) var repair_cost_per_durability := 1.0
