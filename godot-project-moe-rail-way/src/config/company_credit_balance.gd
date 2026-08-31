class_name CompanyCreditBalance
extends Resource

@export var company_id: StringName
@export_range(0, 10000, 1) var rate_basis_points := 0
@export_range(1, 1000, 1) var term_cycles := 4
@export var trust_limit_knots: Array[Vector2i] = [Vector2i(0, 0), Vector2i(100, 100)]


func _init(
	company_id_value: StringName = &"",
	rate_basis_points_value: int = 0,
	term_cycles_value: int = 4,
	trust_limit_knots_value: Array[Vector2i] = [Vector2i(0, 0), Vector2i(100, 100)]
) -> void:
	company_id = company_id_value
	rate_basis_points = rate_basis_points_value
	term_cycles = term_cycles_value
	trust_limit_knots = trust_limit_knots_value.duplicate()
