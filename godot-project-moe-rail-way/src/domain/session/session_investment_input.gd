class_name SessionInvestmentInput
extends RefCounted

const ACTION_PAID_DEMOLITION := &"paid_demolition"
const ACTION_TEMPORARY_TRACK_PURCHASE := &"temporary_track_purchase"
const ACTION_TEMPORARY_CARGO_PURCHASE := &"temporary_cargo_purchase"
const VALID_ACTIONS := [
	ACTION_PAID_DEMOLITION,
	ACTION_TEMPORARY_TRACK_PURCHASE,
	ACTION_TEMPORARY_CARGO_PURCHASE,
]

var _ordered_priced_actions: Array[StringName] = []


func _init(actions: Array = []) -> void:
	for action_value in actions:
		var action := StringName(action_value)
		assert(action in VALID_ACTIONS, "Unknown session investment action")
		_ordered_priced_actions.append(action)


func get_ordered_priced_actions() -> Array[StringName]:
	return _ordered_priced_actions.duplicate()


func take_ordered_priced_actions() -> Array[StringName]:
	var actions := _ordered_priced_actions.duplicate()
	_ordered_priced_actions.clear()
	return actions


static func empty() -> SessionInvestmentInput:
	return load("res://src/domain/session/session_investment_input.gd").new()
