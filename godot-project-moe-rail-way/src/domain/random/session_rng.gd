class_name SessionRng
extends RefCounted

var _rng: RandomNumberGenerator


func _init(seed_value: int) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value


func next_u32() -> int:
	return _rng.randi()


func next_unit_float() -> float:
	return _rng.randf()


func next_index(exclusive_upper_bound: int) -> int:
	if exclusive_upper_bound <= 0:
		return -1
	return _rng.randi_range(0, exclusive_upper_bound - 1)


func peek_index(exclusive_upper_bound: int) -> int:
	if exclusive_upper_bound <= 0:
		return -1
	var saved_state := _rng.state
	var sampled_index := next_index(exclusive_upper_bound)
	_rng.state = saved_state
	return sampled_index
