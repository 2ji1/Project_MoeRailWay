class_name SessionEconomy
extends RefCounted

const MAX_CASH := 1000000

var _starting_cash: int
var _cash: int
var _total_spent := 0


func _init(starting_cash: int) -> void:
	assert(starting_cash >= 0 and starting_cash <= MAX_CASH, "Starting session cash must be between 0 and 1000000")
	_starting_cash = starting_cash
	_cash = starting_cash


func try_spend(cost: int) -> bool:
	if cost < 0 or cost > _cash:
		return false
	_cash -= cost
	_total_spent += cost
	return true


func get_starting_cash() -> int:
	return _starting_cash


func get_cash() -> int:
	return _cash


func get_total_spent() -> int:
	return _total_spent


func get_observation() -> Dictionary:
	return {
		"starting_cash": _starting_cash,
		"cash": _cash,
		"total_spent": _total_spent,
	}


func duplicate_economy() -> SessionEconomy:
	var copy: SessionEconomy = get_script().new(_starting_cash)
	copy._cash = _cash
	copy._total_spent = _total_spent
	return copy


func replace_with(source: SessionEconomy) -> void:
	assert(source != null, "Source economy is required")
	_starting_cash = source._starting_cash
	_cash = source._cash
	_total_spent = source._total_spent
