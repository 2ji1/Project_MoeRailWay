class_name TrackSystem
extends RefCounted

const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")

var _runtime: GridTrackRuntimeScript
var _left_capture_active := false


func _init(start_config: SessionStartConfigScript) -> void:
	assert(start_config != null, "Session start config is required")
	assert(start_config.total_track_cells > 0, "Track inventory must be positive")
	assert(start_config.grid_size.x > 0 and start_config.grid_size.y > 0, "Grid size must be positive")
	assert(start_config.grid_cell_size_units > 0.0, "Grid cell size must be positive")
	assert(_cell_is_inside(start_config.departure_cell, start_config.grid_size), "Departure cell must be in grid")
	assert(
		start_config.grid_origin_units.is_equal_approx(
			(
				start_config.logical_field_size
				- Vector2(start_config.grid_size) * start_config.grid_cell_size_units
			) * 0.5
		),
		"Grid origin must center within logical field"
	)
	assert(
		start_config.departure_position.is_equal_approx(
			start_config.grid_origin_units
			+ (Vector2(start_config.departure_cell) + Vector2(0.5, 0.5))
				* start_config.grid_cell_size_units
		),
		"Departure position must match departure cell center"
	)
	_runtime = GridTrackRuntimeScript.new(
		start_config.departure_cell,
		start_config.total_track_cells,
		Vector2(start_config.grid_origin_units),
		Vector2i(start_config.grid_size),
		start_config.grid_cell_size_units
	)


func apply_right_input(input_frame: TrackInputFrameScript) -> bool:
	assert(input_frame != null, "Track input frame is required")
	if not input_frame.right_pressed:
		return false
	_left_capture_active = false
	if input_frame.right_press_inside_grid:
		_runtime.cancel_ghost_suffix(input_frame.right_press_cell)
	return true


func apply_left_input(input_frame: TrackInputFrameScript) -> void:
	assert(input_frame != null, "Track input frame is required")
	if input_frame.left_pressed:
		_left_capture_active = (
			input_frame.left_press_inside_grid
			and input_frame.left_press_cell == _runtime.get_endpoint_cell()
		)
	if _left_capture_active:
		_runtime.append_cells(input_frame.crossed_cells)
	if input_frame.left_released:
		_left_capture_active = false


func set_contact_anchors(anchors: Array[RouteContactAnchorScript]) -> void:
	_runtime.set_contact_anchors(anchors)


func advance_construction(progress_cells: float) -> float:
	return _runtime.advance_construction(progress_cells)


func recover_behind(cutoff_distance_cells: float) -> int:
	return _runtime.recover_behind(cutoff_distance_cells)


func get_cell_records() -> Array[TrackCellRecordScript]:
	return _runtime.get_cell_records()


func get_geometry_pieces() -> Array[TrackGeometryPieceScript]:
	return _runtime.get_geometry_pieces()


func get_endpoint_cell() -> Vector2i:
	return _runtime.get_endpoint_cell()


func get_built_end_distance_cells() -> float:
	return _runtime.get_built_end_distance_cells()


func get_reserved_end_distance_cells() -> float:
	return _runtime.get_reserved_end_distance_cells()


func get_available_track_cells() -> int:
	return _runtime.get_available_track_cells()


func get_total_track_cells() -> int:
	return _runtime.get_total_track_cells()


func get_grid_origin_units() -> Vector2:
	return _runtime.get_grid_origin_units()


func get_position_at_distance_cells(route_distance_cells: float) -> Vector2:
	return _runtime.get_position_at_distance_cells(route_distance_cells)


func get_heading_at_distance_cells(route_distance_cells: float) -> Vector2:
	return _runtime.get_heading_at_distance_cells(route_distance_cells)


func get_contact_observations() -> Array[Dictionary]:
	return _runtime.get_contact_observations()


func _cell_is_inside(cell: Vector2i, grid_size: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y
