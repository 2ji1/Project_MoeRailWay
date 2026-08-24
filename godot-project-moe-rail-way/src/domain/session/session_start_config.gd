class_name SessionStartConfig
extends RefCounted

var seed: int
var session_duration_seconds: float
var simulation_ticks_per_second: int
var train_speed_units_per_second: float
var total_track_units: float
var recovery_distance_units: float
var urgent_warning_seconds: float
var construction_speed_units_per_second: float
var endpoint_grab_radius_units: float
var route_hit_radius_units: float
var minimum_sample_distance_units: float
var intersection_clearance_units: float
var departure_required_built_units: float
var logical_field_size: Vector2
var departure_candidate_id: StringName
var departure_position: Vector2


func _init(
    seed_value: int,
    duration_seconds: float,
    ticks_per_second: int,
    train_speed_value := 0.0,
    total_track_value := 0.0,
    recovery_distance_value := 0.0,
    urgent_warning_value := 0.0,
    construction_speed_value := 0.0,
    endpoint_grab_radius_value := 0.0,
    route_hit_radius_value := 0.0,
    minimum_sample_distance_value := 0.0,
    intersection_clearance_value := 0.0,
    departure_required_built_value := 0.0,
    logical_field_size_value := Vector2.ZERO,
    departure_candidate_id_value := StringName(),
    departure_position_value := Vector2.ZERO
) -> void:
    seed = seed_value
    session_duration_seconds = duration_seconds
    simulation_ticks_per_second = ticks_per_second
    train_speed_units_per_second = train_speed_value
    total_track_units = total_track_value
    recovery_distance_units = recovery_distance_value
    urgent_warning_seconds = urgent_warning_value
    construction_speed_units_per_second = construction_speed_value
    endpoint_grab_radius_units = endpoint_grab_radius_value
    route_hit_radius_units = route_hit_radius_value
    minimum_sample_distance_units = minimum_sample_distance_value
    intersection_clearance_units = intersection_clearance_value
    departure_required_built_units = departure_required_built_value
    logical_field_size = logical_field_size_value
    departure_candidate_id = departure_candidate_id_value
    departure_position = departure_position_value
