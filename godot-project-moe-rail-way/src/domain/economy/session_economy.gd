class_name SessionEconomy
extends RefCounted

const MAX_STARTING_CASH := 1000000
const MAX_CASH := 9223372036854775807

var _starting_cash: int
var _cash: int
var _total_spent := 0
var _total_credited := 0


func _init(starting_cash: int) -> void:
	assert(starting_cash >= 0 and starting_cash <= MAX_STARTING_CASH, "Starting session cash must be between 0 and 1000000")
	_starting_cash = starting_cash
	_cash = starting_cash


func try_spend(cost: int) -> bool:
	if cost < 0 or cost > _cash or _total_spent > MAX_CASH - cost:
		return false
	_cash -= cost
	_total_spent += cost
	return true


func try_credit(amount: int) -> bool:
	if not can_credit_total(amount):
		return false
	_cash += amount
	_total_credited += amount
	return true


func can_credit_total(total_amount: int) -> bool:
	return (
		total_amount >= 0
		and _cash <= MAX_CASH - total_amount
		and _total_credited <= MAX_CASH - total_amount
	)


func get_starting_cash() -> int:
	return _starting_cash


func get_cash() -> int:
	return _cash


func get_total_spent() -> int:
	return _total_spent


func get_total_credited() -> int:
	return _total_credited


func get_observation() -> Dictionary:
	return {
		"starting_cash": _starting_cash,
		"cash": _cash,
		"total_spent": _total_spent,
		"total_credited": _total_credited,
	}


func duplicate_economy() -> SessionEconomy:
	var copy: SessionEconomy = get_script().new(_starting_cash)
	copy._cash = _cash
	copy._total_spent = _total_spent
	copy._total_credited = _total_credited
	return copy


func replace_with(source: SessionEconomy) -> void:
	assert(source != null, "Source economy is required")
	_starting_cash = source._starting_cash
	_cash = source._cash
	_total_spent = source._total_spent
	_total_credited = source._total_credited
