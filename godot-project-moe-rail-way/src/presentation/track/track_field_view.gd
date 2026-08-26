class_name TrackFieldView
extends Control

const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const LogicalTrackFieldScript = preload("res://src/presentation/track/logical_track_field.gd")
const GridPointerRasterizerScript = preload("res://src/presentation/track/grid_pointer_rasterizer.gd")

const INVALID_CELL := Vector2i(-1, -1)
const BUILT_COLOR := Color(0.12, 0.18, 0.20, 1.0)
const RESERVED_COLOR := Color(0.12, 0.18, 0.20, 0.38)
const DEPARTURE_COLOR := Color(0.22, 0.55, 0.38, 1.0)
const TRAIN_COLOR := Color(0.82, 0.26, 0.20, 1.0)
const HOVER_COLOR := Color(0.91, 0.73, 0.29, 0.72)
const VALID_START_COLOR := Color(0.78, 0.88, 0.90, 0.16)
const EXTEND_HOVER_COLOR := Color(0.29, 0.92, 0.45, 0.82)
const BUILT_WIDTH := 7.0
const RESERVED_WIDTH := 4.0
const DEPARTURE_RADIUS := 9.0
const TRAIN_LENGTH := 13.0
const TRAIN_HALF_WIDTH := 7.0
const INTERVAL_SAMPLE_COUNT := 9

@export_color_no_alpha var grid_line_color := Color(0.5, 0.5, 0.5, 1.0):
	set(value):
		grid_line_color = Color(value.r, value.g, value.b, 1.0)
		queue_redraw()

var _session_configured := false
var _session_logical_size := Vector2.ZERO
var _grid_rect := Rect2()
var _grid_size := Vector2i.ZERO
var _selected_candidate_id := StringName()
var _selected_departure_position := Vector2.ZERO
var _selected_departure_cell := INVALID_CELL
var _field_draw_order := PackedStringArray(["grid_lines", "valid_start"])

var _rasterizer = GridPointerRasterizerScript.new()
var _crossed_cells: Array[Vector2i] = []
var _left_press_cell := INVALID_CELL
var _left_press_inside_grid := false
var _right_press_cell := INVALID_CELL
var _right_press_inside_grid := false
var _left_pressed_pending := false
var _left_held := false
var _left_released_pending := false
var _right_pressed_pending := false
var _left_capture_active := false
var _release_clears_capture := false
var _last_pointer_logical := Vector2.ZERO
var _previous_pointer_cell := INVALID_CELL
var _latest_cursor_local := Vector2.ZERO
var _cursor_observed := false

var _presented_state := SessionControllerScript.State.READY
var _has_track_train_data := false
var _presented_cells: Array[TrackCellRecordScript] = []
var _presented_pieces: Array[TrackGeometryPieceScript] = []
var _presented_contacts: Array[Dictionary] = []
var _presented_intervals: Array[Dictionary] = []
var _train_active := false
var _train_position := Vector2.ZERO
var _train_heading := Vector2.RIGHT
var _hover_cancel_cell := INVALID_CELL
var _hover_extend_cell := INVALID_CELL
var _current_pointer_cell := INVALID_CELL
var _current_pointer_inside_grid := false
var _presented_gesture_active := false
var _presented_snapshot_has_endpoint_eligibility := false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_latest_cursor_local = event.position
		_cursor_observed = true
		if _left_capture_active and _left_held:
			_rasterize_to(event.position)
		_update_hover_cell(event.position)
		return
	if not event is InputEventMouseButton:
		return

	_latest_cursor_local = event.position
	_cursor_observed = true
	var button_mapping := _map_local_to_grid(event.position)
	_set_current_pointer(button_mapping)
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_left_press(event.position)
		else:
			_end_left_press(event.position)
		_update_hover_cell(event.position)
		accept_event()
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and not _right_pressed_pending:
			var mapping := _map_local_to_grid(event.position)
			_right_pressed_pending = true
			_right_press_inside_grid = mapping.inside_grid
			_right_press_cell = mapping.cell
		_update_hover_cell(event.position)
		if event.pressed:
			_clear_hover_cell()
		accept_event()


func _begin_left_press(local_position: Vector2) -> void:
	if _left_held:
		return
	var mapping := _map_local_to_grid(local_position)
	_set_current_pointer(mapping)
	_left_pressed_pending = true
	_left_press_inside_grid = mapping.inside_grid
	_left_press_cell = mapping.cell
	_left_held = true
	_left_capture_active = mapping.inside_grid
	_release_clears_capture = false
	_crossed_cells.clear()
	if _left_capture_active:
		_last_pointer_logical = mapping.logical
		_previous_pointer_cell = mapping.cell
	else:
		_previous_pointer_cell = INVALID_CELL


func _end_left_press(local_position: Vector2) -> void:
	if not _left_held:
		return
	if _left_capture_active:
		_rasterize_to(local_position)
	_left_released_pending = true
	_left_held = false
	_release_clears_capture = true


func _rasterize_to(local_position: Vector2) -> void:
	var mapping := _map_local_to_grid(local_position, true)
	_set_current_pointer(mapping)
	var segment_cells: Array[Vector2i] = _rasterizer.rasterize_motion(
		_last_pointer_logical,
		mapping.logical,
		_grid_rect,
		_grid_size,
		_previous_pointer_cell
	)
	for cell in segment_cells:
		if _crossed_cells.is_empty() or _crossed_cells[-1] != cell:
			_crossed_cells.append(cell)
	if not segment_cells.is_empty():
		_previous_pointer_cell = segment_cells[-1]
	_last_pointer_logical = mapping.logical


func consume_input_frame():
	var frame = TrackInputFrameScript.new(
		_crossed_cells,
		_left_press_cell,
		_left_press_inside_grid,
		_right_press_cell,
		_right_press_inside_grid,
		_left_pressed_pending,
		_left_held,
		_left_released_pending,
		_right_pressed_pending,
		_current_pointer_cell,
		_current_pointer_inside_grid
	)
	_crossed_cells.clear()
	_left_pressed_pending = false
	_left_press_cell = INVALID_CELL
	_left_press_inside_grid = false
	_left_released_pending = false
	_right_pressed_pending = false
	_right_press_cell = INVALID_CELL
	_right_press_inside_grid = false
	if _release_clears_capture:
		_left_capture_active = false
		_release_clears_capture = false
		_previous_pointer_cell = INVALID_CELL
	return frame


func _map_local_to_grid(local_position: Vector2, allow_unclamped := false) -> Dictionary:
	var viewport_position := get_global_transform_with_canvas() * local_position
	var mapped: Variant = try_viewport_to_logical(viewport_position)
	var logical_position := Vector2.ZERO
	if mapped != null:
		logical_position = Vector2(mapped)
	elif allow_unclamped:
		logical_position = viewport_to_logical_unclamped(viewport_position)
	logical_position = logical_position.snapped(Vector2(0.0001, 0.0001))
	var inside_grid := mapped != null and _grid_rect.has_point(logical_position)
	var cell := INVALID_CELL
	if inside_grid:
		var cell_size := Vector2(
			_grid_rect.size.x / float(_grid_size.x),
			_grid_rect.size.y / float(_grid_size.y)
		)
		cell = Vector2i(floor((logical_position - _grid_rect.position) / cell_size))
	return {
		"logical": logical_position,
		"inside_grid": inside_grid,
		"cell": cell,
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_logical_transform()
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_cursor_observed = false
		_current_pointer_cell = INVALID_CELL
		_current_pointer_inside_grid = false
		_clear_hover_cell()


func get_logical_track_field():
	return get_node_or_null("LogicalTrackField") as LogicalTrackFieldScript


func get_logical_content_rect() -> Rect2:
	var logical_size := _get_mapping_logical_size()
	if logical_size.x <= 0.0 or logical_size.y <= 0.0:
		return Rect2()
	var uniform_scale: float = minf(size.x / logical_size.x, size.y / logical_size.y)
	var content_size: Vector2 = logical_size * uniform_scale
	var content_offset: Vector2 = (size - content_size) * 0.5
	_apply_logical_transform(content_offset, uniform_scale)
	return Rect2(content_offset, content_size)


func try_viewport_to_logical(viewport_position: Vector2) -> Variant:
	var local_position := get_global_transform_with_canvas().affine_inverse() * viewport_position
	var content_rect := get_logical_content_rect()
	if (
		local_position.x < content_rect.position.x
		or local_position.x > content_rect.end.x
		or local_position.y < content_rect.position.y
		or local_position.y > content_rect.end.y
	):
		return null
	return viewport_to_logical_unclamped(viewport_position)


func viewport_to_logical_unclamped(viewport_position: Vector2) -> Vector2:
	var local_position := get_global_transform_with_canvas().affine_inverse() * viewport_position
	var content_rect := get_logical_content_rect()
	if content_rect.size.x <= 0.0 or content_rect.size.y <= 0.0:
		return Vector2.ZERO
	return (local_position - content_rect.position) * (_get_mapping_logical_size() / content_rect.size)


func configure_session(start_config: SessionStartConfigScript) -> void:
	var field = get_logical_track_field()
	if field == null:
		push_error("TrackFieldView requires LogicalTrackField before session configuration")
		return
	var candidate_logical_size := Vector2(start_config.logical_field_size)
	var candidate_grid_size := Vector2i(start_config.grid_size)
	var candidate_grid_rect := Rect2(
		Vector2(start_config.grid_origin_units),
		Vector2(candidate_grid_size) * float(start_config.grid_cell_size_units)
	)
	var candidate_departure_id := StringName(start_config.departure_candidate_id)
	var candidate_departure_position := Vector2(start_config.departure_position)
	var candidate_departure_cell := Vector2i(start_config.departure_cell)
	if not candidate_logical_size.is_equal_approx(field.get_logical_size()):
		push_error("Configured logical field size must equal the authored field size")
		return
	_session_logical_size = candidate_logical_size
	_grid_size = candidate_grid_size
	_grid_rect = candidate_grid_rect
	_selected_candidate_id = candidate_departure_id
	_selected_departure_position = candidate_departure_position
	_selected_departure_cell = candidate_departure_cell
	_session_configured = true
	if not Engine.is_editor_hint():
		var candidate_parent = field.get_node_or_null("DepartureCandidates")
		if candidate_parent != null:
			for candidate in candidate_parent.get_children():
				candidate.hide()
	_apply_logical_transform()
	queue_redraw()


func _get_mapping_logical_size() -> Vector2:
	if _session_configured:
		return _session_logical_size
	var field = get_logical_track_field()
	if field == null:
		return Vector2.ZERO
	return field.get_logical_size()


func _apply_logical_transform(
	content_offset := Vector2.INF,
	uniform_scale := -1.0
) -> void:
	var field = get_logical_track_field()
	var logical_size := _get_mapping_logical_size()
	if field == null or logical_size.x <= 0.0 or logical_size.y <= 0.0:
		return
	if uniform_scale < 0.0:
		uniform_scale = minf(size.x / logical_size.x, size.y / logical_size.y)
	if content_offset == Vector2.INF:
		content_offset = (size - logical_size * uniform_scale) * 0.5
	field.position = content_offset
	field.scale = Vector2.ONE * uniform_scale


func present(snapshot: SessionSnapshotScript) -> void:
	if snapshot == null:
		return
	_presented_state = snapshot.get_state()
	_has_track_train_data = snapshot.has_track_train_data()
	_presented_cells = snapshot.get_cell_records()
	_presented_pieces = snapshot.get_geometry_pieces()
	_presented_contacts = snapshot.get_contact_observations()
	_presented_intervals = _build_intervals(_presented_cells, _presented_pieces)
	_train_active = snapshot.is_train_active()
	_train_position = snapshot.get_train_position()
	_train_heading = snapshot.get_train_heading()
	_presented_snapshot_has_endpoint_eligibility = snapshot.is_endpoint_gesture_eligible()
	var snapshot_gesture_active := snapshot.is_endpoint_gesture_active()
	if _presented_gesture_active and not snapshot_gesture_active:
		_clear_view_capture_after_termination()
	_presented_gesture_active = snapshot_gesture_active
	if _presented_state == SessionControllerScript.State.COMPLETED:
		_clear_hover_observations()
		_clear_view_capture_after_termination()
	elif _cursor_observed:
		_update_hover_cell(_latest_cursor_local)
	else:
		_clear_hover_cell()
	queue_redraw()


func _build_intervals(records: Array, pieces: Array) -> Array[Dictionary]:
	var intervals: Array[Dictionary] = []
	for record in records:
		var owner = null
		for piece in pieces:
			if piece.contains_serial(record.route_serial):
				owner = piece
				break
		if owner == null:
			continue
		var nominal_start: float = (
			record.route_distance_start_cells - owner.absolute_start_distance_cells
		)
		var nominal_end := nominal_start + 1.0
		var points := PackedVector2Array()
		for sample_index in range(INTERVAL_SAMPLE_COUNT):
			var weight := float(sample_index) / float(INTERVAL_SAMPLE_COUNT - 1)
			points.append(owner.sample_nominal(lerpf(nominal_start, nominal_end, weight)).position)
		intervals.append({
			"route_serial": record.route_serial,
			"piece_group_id": owner.group_id,
			"state": record.state,
			"build_progress": record.build_progress,
			"nominal_start_cells": nominal_start,
			"nominal_end_cells": nominal_end,
			"points": points,
			"locked": owner.locked,
		})
	return intervals


func get_render_observation() -> Dictionary:
	var field_render_facts := _get_field_render_facts()
	var observation := {
		"logical_size": Vector2(_get_mapping_logical_size()),
		"grid_rect": field_render_facts.grid_rect,
		"grid_size": field_render_facts.grid_size,
		"grid_line_color": field_render_facts.grid_line_color,
		"grid_lines": field_render_facts.grid_lines,
		"field_draw_order": field_render_facts.field_draw_order,
		"valid_start_cell": field_render_facts.valid_start_cell,
		"valid_start_rect": field_render_facts.valid_start_rect,
		"cells": _duplicate_records(_presented_cells),
		"pieces": _duplicate_pieces(_presented_pieces),
		"contacts": _presented_contacts.duplicate(true),
		"intervals": _duplicate_intervals(_presented_intervals),
		"selected_departure_id": StringName(_selected_candidate_id),
		"selected_departure_position": Vector2(_selected_departure_position),
		"train_active": _train_active,
		"train_position": Vector2(_train_position),
		"train_heading": Vector2(_train_heading),
		"hover_cancel_cell": Vector2i(_hover_cancel_cell),
	}
	if _hover_extend_cell != INVALID_CELL:
		observation["hover_extend_cell"] = Vector2i(_hover_extend_cell)
	return observation


func _get_valid_start_cell() -> Vector2i:
	if not _session_configured or _presented_state == SessionControllerScript.State.COMPLETED:
		return INVALID_CELL
	if _presented_cells.is_empty():
		return _selected_departure_cell
	return _presented_cells[-1].cell


func _get_field_render_facts() -> Dictionary:
	var grid_lines: Array[Dictionary] = []
	var valid_start_cell := _get_valid_start_cell()
	var valid_start_rect := Rect2()
	if _session_configured and _grid_size.x > 0 and _grid_size.y > 0:
		var cell_size := Vector2(
			_grid_rect.size.x / float(_grid_size.x),
			_grid_rect.size.y / float(_grid_size.y)
		)
		for column in range(_grid_size.x + 1):
			var x := _grid_rect.position.x + float(column) * cell_size.x
			grid_lines.append({
				"from": Vector2(x, _grid_rect.position.y),
				"to": Vector2(x, _grid_rect.end.y),
				"color": Color(grid_line_color),
			})
		for row in range(_grid_size.y + 1):
			var y := _grid_rect.position.y + float(row) * cell_size.y
			grid_lines.append({
				"from": Vector2(_grid_rect.position.x, y),
				"to": Vector2(_grid_rect.end.x, y),
				"color": Color(grid_line_color),
			})
		if valid_start_cell != INVALID_CELL:
			valid_start_rect = Rect2(_grid_rect.position + Vector2(valid_start_cell) * cell_size, cell_size)
	return {
		"grid_rect": Rect2(_grid_rect),
		"grid_size": Vector2i(_grid_size),
		"grid_line_color": Color(grid_line_color),
		"grid_lines": grid_lines,
		"field_draw_order": _field_draw_order.duplicate(),
		"valid_start_cell": Vector2i(valid_start_cell),
		"valid_start_rect": Rect2(valid_start_rect),
	}


func _duplicate_records(source: Array) -> Array:
	var copies: Array = []
	for record in source:
		copies.append(record.duplicate_record())
	return copies


func _duplicate_pieces(source: Array) -> Array:
	var copies: Array = []
	for piece in source:
		copies.append(piece.duplicate_piece())
	return copies


func _duplicate_intervals(source: Array) -> Array:
	var copies: Array = []
	for interval in source:
		copies.append({
			"route_serial": interval.route_serial,
			"piece_group_id": interval.piece_group_id,
			"state": interval.state,
			"build_progress": interval.build_progress,
			"nominal_start_cells": interval.nominal_start_cells,
			"nominal_end_cells": interval.nominal_end_cells,
			"points": interval.points.duplicate(),
			"locked": interval.locked,
		})
	return copies


func _draw() -> void:
	var logical_size := _get_mapping_logical_size()
	if logical_size.x <= 0.0 or logical_size.y <= 0.0:
		return
	var content_rect := get_logical_content_rect()
	if content_rect.size.x <= 0.0 or content_rect.size.y <= 0.0:
		return
	var uniform_scale: float = content_rect.size.x / logical_size.x
	draw_set_transform(content_rect.position, 0.0, Vector2.ONE * uniform_scale)
	var field_render_facts := _get_field_render_facts()
	for layer in field_render_facts.field_draw_order:
		if layer == "grid_lines":
			for grid_line in field_render_facts.grid_lines:
				draw_line(grid_line.from, grid_line.to, grid_line.color)
		elif layer == "valid_start" and field_render_facts.valid_start_cell != INVALID_CELL:
			draw_rect(field_render_facts.valid_start_rect, VALID_START_COLOR, true)
	for interval in _presented_intervals:
		var points: PackedVector2Array = interval.points
		if points.size() < 2:
			continue
		if interval.state == TrackCellRecordScript.State.BUILT:
			draw_polyline(points, BUILT_COLOR, BUILT_WIDTH, true)
		elif interval.state == TrackCellRecordScript.State.BUILDING:
			draw_polyline(points, RESERVED_COLOR, RESERVED_WIDTH, true)
			var prefix := _polyline_prefix(points, interval.build_progress)
			if prefix.size() >= 2:
				draw_polyline(prefix, BUILT_COLOR, BUILT_WIDTH, true)
		else:
			draw_polyline(points, RESERVED_COLOR, RESERVED_WIDTH, true)
	if _hover_cancel_cell != INVALID_CELL and _grid_size.x > 0 and _grid_size.y > 0:
		var cell_size := Vector2(
			_grid_rect.size.x / float(_grid_size.x),
			_grid_rect.size.y / float(_grid_size.y)
		)
		var hover_rect := Rect2(_grid_rect.position + Vector2(_hover_cancel_cell) * cell_size, cell_size)
		draw_rect(hover_rect, HOVER_COLOR, false, 3.0, true)
	if _hover_extend_cell != INVALID_CELL and _grid_size.x > 0 and _grid_size.y > 0:
		var cell_size := Vector2(
			_grid_rect.size.x / float(_grid_size.x),
			_grid_rect.size.y / float(_grid_size.y)
		)
		var extend_rect := Rect2(_grid_rect.position + Vector2(_hover_extend_cell) * cell_size, cell_size)
		draw_rect(extend_rect, EXTEND_HOVER_COLOR, false, 4.0, true)
	if _session_configured:
		draw_circle(_selected_departure_position, DEPARTURE_RADIUS, DEPARTURE_COLOR, true)
	if _train_active:
		var heading := _train_heading.normalized()
		if heading == Vector2.ZERO:
			heading = Vector2.RIGHT
		var side := Vector2(-heading.y, heading.x)
		var triangle := PackedVector2Array([
			_train_position + heading * TRAIN_LENGTH,
			_train_position - heading * TRAIN_LENGTH * 0.55 + side * TRAIN_HALF_WIDTH,
			_train_position - heading * TRAIN_LENGTH * 0.55 - side * TRAIN_HALF_WIDTH,
		])
		draw_colored_polygon(triangle, TRAIN_COLOR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _polyline_prefix(points: PackedVector2Array, progress: float) -> PackedVector2Array:
	var prefix := PackedVector2Array()
	if points.is_empty() or progress <= 0.0:
		return prefix
	var scaled := clampf(progress, 0.0, 1.0) * float(points.size() - 1)
	var complete_segments := int(floor(scaled))
	for index in range(mini(complete_segments + 1, points.size())):
		prefix.append(points[index])
	if complete_segments < points.size() - 1:
		var weight := scaled - float(complete_segments)
		prefix.append(points[complete_segments].lerp(points[complete_segments + 1], weight))
	return prefix


func _update_hover_cell(local_position: Vector2) -> void:
	if _presented_state == SessionControllerScript.State.COMPLETED:
		_clear_hover_observations()
		return
	if _presented_gesture_active:
		_clear_hover_observations()
		return
	var mapping := _map_local_to_grid(local_position)
	_set_current_pointer(mapping)
	if not mapping.inside_grid:
		_clear_hover_observations()
		return
	var changed := false
	var next_cancel: Vector2i = mapping.cell if _is_cancelable_cell(mapping.cell) else INVALID_CELL
	var next_extend: Vector2i = _current_pointer_cell if _is_extendable_endpoint(_current_pointer_cell) else INVALID_CELL
	if _hover_cancel_cell != next_cancel:
		_hover_cancel_cell = next_cancel
		changed = true
	if _hover_extend_cell != next_extend:
		_hover_extend_cell = next_extend
		changed = true
	if changed:
		queue_redraw()


func _set_current_pointer(mapping: Dictionary) -> void:
	_current_pointer_cell = mapping.cell if mapping.inside_grid else INVALID_CELL
	_current_pointer_inside_grid = mapping.inside_grid


func _is_extendable_endpoint(cell: Vector2i) -> bool:
	if (
		_presented_state == SessionControllerScript.State.COMPLETED
		or not _session_configured
		or not _current_pointer_inside_grid
		or _current_pointer_cell != cell
		or not _presented_gesture_eligible()
	):
		return false
	var endpoint := _get_valid_start_cell()
	if _train_occupies_cell(endpoint):
		return false
	return endpoint != INVALID_CELL and cell == endpoint


func _presented_gesture_eligible() -> bool:
	return _presented_snapshot_has_endpoint_eligibility


func _is_cancelable_cell(cell: Vector2i) -> bool:
	var clicked_index := -1
	for index in range(_presented_cells.size()):
		if _presented_cells[index].cell == cell:
			clicked_index = index
			break
	if clicked_index < 0:
		return false
	for index in range(clicked_index, _presented_cells.size()):
		var record = _presented_cells[index]
		if record.state != TrackCellRecordScript.State.RESERVED_GHOST or record.geometry_locked:
			return false
		for piece in _presented_pieces:
			if piece.contains_serial(record.route_serial) and piece.locked:
				return false
			if piece.exit_support_route_serial == record.route_serial:
				return false
	return true


func _train_occupies_cell(cell: Vector2i) -> bool:
	if not _train_active or cell == INVALID_CELL or _grid_size.x <= 0 or _grid_size.y <= 0:
		return false
	var cell_size := Vector2(
		_grid_rect.size.x / float(_grid_size.x),
		_grid_rect.size.y / float(_grid_size.y)
	)
	var train_cell := Vector2i(floor((_train_position - _grid_rect.position) / cell_size))
	return train_cell == cell


func _clear_hover_cell() -> void:
	_clear_hover_observations()


func _clear_hover_observations() -> void:
	if _hover_cancel_cell == INVALID_CELL and _hover_extend_cell == INVALID_CELL:
		return
	_hover_cancel_cell = INVALID_CELL
	_hover_extend_cell = INVALID_CELL
	queue_redraw()


func _clear_view_capture_after_termination() -> void:
	_left_capture_active = false
	_crossed_cells.clear()
	_left_pressed_pending = false
	_left_press_cell = INVALID_CELL
	_left_press_inside_grid = false
	_left_released_pending = false
	_right_pressed_pending = false
	_right_press_cell = INVALID_CELL
	_right_press_inside_grid = false
	_previous_pointer_cell = INVALID_CELL
	_release_clears_capture = false
