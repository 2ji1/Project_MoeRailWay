class_name TrainSystem
extends RefCounted

const NominalTrainMotionScript = preload("res://src/domain/train/nominal_train_motion.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")

var _motion: NominalTrainMotionScript


func _init(speed_cells_per_second: float) -> void:
	_motion = NominalTrainMotionScript.new(speed_cells_per_second)


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
