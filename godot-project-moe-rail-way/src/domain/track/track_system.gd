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
var _left_press_latched := false


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
	if _left_capture_active and _runtime.gesture_is_active():
		_runtime.gesture_abort()
		_left_capture_active = false
		if input_frame.left_released:
			_left_press_latched = false
		return true
	_left_capture_active = false
	if input_frame.left_released:
		_left_press_latched = false
	if input_frame.right_press_inside_grid:
		_runtime.cancel_ghost_suffix(input_frame.right_press_cell)
	return true


func apply_left_input(input_frame: TrackInputFrameScript) -> void:
	assert(input_frame != null, "Track input frame is required")
	if _left_capture_active and not _runtime.gesture_is_active():
		_left_capture_active = false
	if input_frame.left_pressed and not _left_press_latched:
		_left_press_latched = true
		var endpoint := _runtime.get_endpoint_cell()
		if (
			input_frame.left_press_inside_grid
			and input_frame.left_press_cell == endpoint
			and _runtime.gesture_has_legal_operation(endpoint)
		):
			_left_capture_active = not _runtime.gesture_begin(endpoint).is_empty()
	if _left_capture_active and _runtime.gesture_is_active():
		var gesture_cells: Array[Vector2i] = input_frame.crossed_cells.duplicate()
		if (
			input_frame.current_pointer_inside_grid
			and (
				gesture_cells.is_empty()
				or gesture_cells[-1] != input_frame.current_pointer_cell
			)
		):
			gesture_cells.append(input_frame.current_pointer_cell)
		if not gesture_cells.is_empty():
			_runtime.gesture_update(gesture_cells)
		if input_frame.left_released:
			_runtime.gesture_finalize()
			_left_capture_active = false
	if input_frame.left_released:
		_left_capture_active = false
		_left_press_latched = false


func is_left_capture_active() -> bool:
	return _left_capture_active


func is_runtime_gesture_active() -> bool:
	return _runtime.gesture_is_active()


func is_endpoint_gesture_eligible() -> bool:
	return _runtime.gesture_has_legal_operation(_runtime.get_endpoint_cell())


func terminate_for_session_completion() -> bool:
	var was_active := _left_capture_active or _runtime.gesture_is_active()
	if _runtime.gesture_is_active():
		_runtime.gesture_finalize()
	_left_capture_active = false
	_left_press_latched = false
	return was_active


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


func prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool:
	var was_active := _left_capture_active
	var result := _runtime.prepare_for_train_sampling(current_distance, through_distance)
	var active_after := _runtime.gesture_is_active()
	if was_active and not active_after:
		_left_capture_active = false
	return result


func get_pose_sample_at_distance(route_distance: float) -> Dictionary:
	return _runtime.get_pose_sample_at_distance(route_distance)


func get_position_at_distance_cells(route_distance_cells: float) -> Vector2:
	return get_pose_sample_at_distance(route_distance_cells).position


func get_heading_at_distance_cells(route_distance_cells: float) -> Vector2:
	return get_pose_sample_at_distance(route_distance_cells).heading


func get_contact_observations() -> Array[Dictionary]:
	return _runtime.get_contact_observations()


func _cell_is_inside(cell: Vector2i, grid_size: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y
