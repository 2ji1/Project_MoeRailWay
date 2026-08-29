class_name TrainSystem
extends RefCounted

const NominalTrainMotionScript = preload("res://src/domain/train/nominal_train_motion.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")

var _motion: NominalTrainMotionScript
var _maximum_durability: float
var _current_durability: float


func _init(speed_cells_per_second: float, maximum_durability: float = 0.0) -> void:
	assert(is_finite(maximum_durability) and maximum_durability >= 0.0, "Maximum durability must be finite and nonnegative")
	_motion = NominalTrainMotionScript.new(speed_cells_per_second)
	_maximum_durability = maximum_durability
	_current_durability = maximum_durability


func depart(route_distance_cells: float = 0.0) -> void:
	_motion.depart(route_distance_cells)


func advance_tick(track_system: TrackSystemScript, seconds_per_tick: float) -> bool:
	assert(track_system != null, "Track system is required")
	return _motion.advance(track_system.get_built_end_distance_cells(), seconds_per_tick)


func is_active() -> bool:
	return _motion.is_active()


func get_route_distance_cells() -> float:
	return _motion.get_route_distance_cells()


func capture_pose(track_system: TrackSystemScript) -> Dictionary:
	assert(track_system != null, "Track system is required")
	return track_system.get_pose_sample_at_distance(_motion.get_route_distance_cells())


func get_position(track_system: TrackSystemScript) -> Vector2:
	return capture_pose(track_system).position


func get_heading(track_system: TrackSystemScript) -> Vector2:
	return capture_pose(track_system).heading


func apply_damage(amount: float) -> float:
	if not is_finite(amount) or amount <= 0.0 or _current_durability <= 0.0:
		return 0.0
	var applied := minf(amount, _current_durability)
	_current_durability -= applied
	if _current_durability < 0.0:
		_current_durability = 0.0
	return applied


func get_maximum_durability() -> float:
	return _maximum_durability


func get_current_durability() -> float:
	return _current_durability


func is_durability_depleted() -> bool:
	return _maximum_durability > 0.0 and _current_durability <= 0.0
