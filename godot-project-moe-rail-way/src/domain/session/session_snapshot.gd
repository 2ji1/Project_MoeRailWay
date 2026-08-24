class_name SessionSnapshot
extends RefCounted

const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")

var _total_ticks: int
var _elapsed_ticks: int
var _remaining_ticks: int
var _ticks_per_second: int
var _has_track_train_data: bool
var _state: int
var _cell_records: Array[TrackCellRecordScript] = []
var _geometry_pieces: Array[TrackGeometryPieceScript] = []
var _contact_observations: Array[Dictionary] = []
var _built_end_distance_cells: float
var _available_track_cells: int
var _total_track_cells: int
var _grid_origin_units: Vector2
var _departure_built_cells: int
var _departure_required_cells: int
var _built_distance_ahead_cells: float
var _train_active: bool
var _train_route_distance_cells: float
var _train_position: Vector2
var _train_heading: Vector2
var _estimated_track_end_seconds: float
var _track_end_warning_urgent: bool
var _selected_departure_candidate_id: StringName
var _departure_cell: Vector2i


func _init(
	total_ticks_value: int,
	elapsed_ticks_value: int,
	remaining_ticks_value: int,
	ticks_per_second_value: int,
	has_track_train_data_value: bool = false,
	state_value: int = 0,
	cell_records_value: Array[TrackCellRecordScript] = [],
	geometry_pieces_value: Array[TrackGeometryPieceScript] = [],
	contact_observations_value: Array[Dictionary] = [],
	built_end_distance_cells_value: float = 0.0,
	available_track_cells_value: int = 0,
	total_track_cells_value: int = 0,
	grid_origin_units_value: Vector2 = Vector2.ZERO,
	departure_built_cells_value: int = 0,
	departure_required_cells_value: int = 0,
	built_distance_ahead_cells_value: float = 0.0,
	train_active_value: bool = false,
	train_route_distance_cells_value: float = 0.0,
	train_position_value: Vector2 = Vector2.ZERO,
	train_heading_value: Vector2 = Vector2.RIGHT,
	estimated_track_end_seconds_value: float = 0.0,
	track_end_warning_urgent_value: bool = false,
	selected_departure_candidate_id_value: StringName = StringName(),
	departure_cell_value: Vector2i = Vector2i(-1, -1)
) -> void:
	_total_ticks = total_ticks_value
	_elapsed_ticks = elapsed_ticks_value
	_remaining_ticks = remaining_ticks_value
	_ticks_per_second = ticks_per_second_value
	_has_track_train_data = has_track_train_data_value
	_state = state_value
	_cell_records = _duplicate_records(cell_records_value)
	_geometry_pieces = _duplicate_pieces(geometry_pieces_value)
	_contact_observations = contact_observations_value.duplicate(true)
	_built_end_distance_cells = built_end_distance_cells_value
	_available_track_cells = available_track_cells_value
	_total_track_cells = total_track_cells_value
	_grid_origin_units = Vector2(grid_origin_units_value)
	_departure_built_cells = departure_built_cells_value
	_departure_required_cells = departure_required_cells_value
	_built_distance_ahead_cells = built_distance_ahead_cells_value
	_train_active = train_active_value
	_train_route_distance_cells = train_route_distance_cells_value
	_train_position = Vector2(train_position_value)
	_train_heading = Vector2(train_heading_value)
	_estimated_track_end_seconds = estimated_track_end_seconds_value
	_track_end_warning_urgent = track_end_warning_urgent_value
	_selected_departure_candidate_id = StringName(selected_departure_candidate_id_value)
	_departure_cell = Vector2i(departure_cell_value)


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


func get_cell_records() -> Array[TrackCellRecordScript]:
	return _duplicate_records(_cell_records)


func get_geometry_pieces() -> Array[TrackGeometryPieceScript]:
	return _duplicate_pieces(_geometry_pieces)


func get_contact_observations() -> Array[Dictionary]:
	return _contact_observations.duplicate(true)


func get_built_end_distance_cells() -> float:
	return _built_end_distance_cells


func get_available_track_cells() -> int:
	return _available_track_cells


func get_total_track_cells() -> int:
	return _total_track_cells


func get_grid_origin_units() -> Vector2:
	return _grid_origin_units


func get_departure_built_cells() -> int:
	return _departure_built_cells


func get_departure_required_cells() -> int:
	return _departure_required_cells


func get_built_distance_ahead_cells() -> float:
	return _built_distance_ahead_cells


func is_train_active() -> bool:
	return _train_active


func get_train_route_distance_cells() -> float:
	return _train_route_distance_cells


func get_train_position() -> Vector2:
	return _train_position


func get_train_heading() -> Vector2:
	return _train_heading


func get_estimated_track_end_seconds() -> float:
	return _estimated_track_end_seconds


func is_track_end_warning_urgent() -> bool:
	return _track_end_warning_urgent


func get_selected_departure_candidate_id() -> StringName:
	return _selected_departure_candidate_id


func get_departure_cell() -> Vector2i:
	return _departure_cell


func _duplicate_records(source: Array[TrackCellRecordScript]) -> Array[TrackCellRecordScript]:
	var copies: Array[TrackCellRecordScript] = []
	for record in source:
		copies.append(record.duplicate_record())
	return copies


func _duplicate_pieces(source: Array[TrackGeometryPieceScript]) -> Array[TrackGeometryPieceScript]:
	var copies: Array[TrackGeometryPieceScript] = []
	for piece in source:
		copies.append(piece.duplicate_piece())
	return copies
