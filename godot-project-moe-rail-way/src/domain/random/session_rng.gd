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
