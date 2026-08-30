class_name CargoInvestmentBalance
extends Resource

@export_range(0, 1000000, 1) var temporary_cargo_purchase_cost := 80
@export_range(1, 8, 1) var temporary_cargo_slots_per_purchase := 1
@export_range(0, 8, 1) var maximum_temporary_cargo_purchases := 4
