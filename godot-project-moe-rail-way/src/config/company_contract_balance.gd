class_name CompanyContractBalance
extends Resource

@export var company_id: StringName
@export var display_name: String
@export_range(1, 1000000, 1) var generation_weight := 1
@export_range(0, 1000000, 1) var base_delivery_fee := 100
@export_range(1, 1000000, 1) var quota := 3
@export_range(0, 1000000, 1) var maximum_shortfall_penalty := 100
@export_range(0, 1000000, 1) var completion_bonus_at_quota := 150
@export_range(0, 1000000, 1) var trust_per_excess_delivery_milli := 100


func _init(
	company_id_value: StringName = &"",
	display_name_value: String = ""
) -> void:
	company_id = company_id_value
	display_name = display_name_value
