class_name SessionSnapshot
extends RefCounted

var _total_ticks: int
var _elapsed_ticks: int
var _remaining_ticks: int
var _ticks_per_second: int
var _has_track_train_data: bool
var _state: int
var _built_route: PackedVector2Array
var _reserved_route: PackedVector2Array
var _construction_head: Vector2
var _train_active: bool
var _train_position: Vector2
var _train_heading: Vector2
var _available_track_units: float
var _total_track_units: float
var _departure_built_units: float
var _departure_required_units: float
var _built_distance_ahead: float
var _estimated_track_end_seconds: float
var _track_end_warning_urgent: bool
var _selected_departure_candidate_id: StringName


func _init(
    total_ticks_value: int,
    elapsed_ticks_value: int,
    remaining_ticks_value: int,
    ticks_per_second_value: int,
    has_track_train_data_value: bool = false,
    state_value: int = 0,
    built_route_value: PackedVector2Array = PackedVector2Array(),
    reserved_route_value: PackedVector2Array = PackedVector2Array(),
    construction_head_value: Vector2 = Vector2.ZERO,
    train_active_value: bool = false,
    train_position_value: Vector2 = Vector2.ZERO,
    train_heading_value: Vector2 = Vector2.RIGHT,
    available_track_units_value: float = 0.0,
    total_track_units_value: float = 0.0,
    departure_built_units_value: float = 0.0,
    departure_required_units_value: float = 0.0,
    built_distance_ahead_value: float = 0.0,
    estimated_track_end_seconds_value: float = 0.0,
    track_end_warning_urgent_value: bool = false,
    selected_departure_candidate_id_value: StringName = StringName()
) -> void:
    _total_ticks = total_ticks_value
    _elapsed_ticks = elapsed_ticks_value
    _remaining_ticks = remaining_ticks_value
    _ticks_per_second = ticks_per_second_value
    _has_track_train_data = has_track_train_data_value
    _state = state_value
    _built_route = built_route_value.duplicate()
    _reserved_route = reserved_route_value.duplicate()
    _construction_head = construction_head_value
    _train_active = train_active_value
    _train_position = train_position_value
    _train_heading = train_heading_value
    _available_track_units = available_track_units_value
    _total_track_units = total_track_units_value
    _departure_built_units = departure_built_units_value
    _departure_required_units = departure_required_units_value
    _built_distance_ahead = built_distance_ahead_value
    _estimated_track_end_seconds = estimated_track_end_seconds_value
    _track_end_warning_urgent = track_end_warning_urgent_value
    _selected_departure_candidate_id = selected_departure_candidate_id_value


func get_total_ticks() -> int:
    return _total_ticks


func get_elapsed_ticks() -> int:
    return _elapsed_ticks


func get_remaining_ticks() -> int:
    return _remaining_ticks


func get_ticks_per_second() -> int:
    return _ticks_per_second


func get_display_seconds() -> int:
    if _remaining_ticks <= 0:
        return 0
    return int(ceil(float(_remaining_ticks) / float(_ticks_per_second)))


func has_track_train_data() -> bool:
    return _has_track_train_data


func get_state() -> int:
    return _state


func get_built_route() -> PackedVector2Array:
    return _built_route.duplicate()


func get_reserved_route() -> PackedVector2Array:
    return _reserved_route.duplicate()


func get_construction_head() -> Vector2:
    return _construction_head


func is_train_active() -> bool:
    return _train_active


func get_train_position() -> Vector2:
    return _train_position


func get_train_heading() -> Vector2:
    return _train_heading


func get_available_track_units() -> float:
    return _available_track_units


func get_total_track_units() -> float:
    return _total_track_units


func get_departure_built_units() -> float:
    return _departure_built_units


func get_departure_required_units() -> float:
    return _departure_required_units


func get_built_distance_ahead() -> float:
    return _built_distance_ahead


func get_estimated_track_end_seconds() -> float:
    return _estimated_track_end_seconds


func is_track_end_warning_urgent() -> bool:
    return _track_end_warning_urgent


func get_selected_departure_candidate_id() -> StringName:
    return _selected_departure_candidate_id
