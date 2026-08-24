class_name TrackFieldView
extends Control

const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const LogicalTrackFieldScript = preload("res://src/presentation/track/logical_track_field.gd")

const BUILT_COLOR := Color(0.12, 0.18, 0.20, 1.0)
const RESERVED_COLOR := Color(0.12, 0.18, 0.20, 0.38)
const HEAD_COLOR := Color(0.91, 0.73, 0.29, 1.0)
const DEPARTURE_COLOR := Color(0.22, 0.55, 0.38, 1.0)
const TRAIN_COLOR := Color(0.82, 0.26, 0.20, 1.0)
const HOVER_COLOR := Color(0.91, 0.73, 0.29, 0.72)
const BUILT_WIDTH := 7.0
const RESERVED_WIDTH := 4.0
const HOVER_WIDTH := 5.0
const HEAD_RADIUS := 7.0
const DEPARTURE_RADIUS := 9.0
const TRAIN_LENGTH := 13.0
const TRAIN_HALF_WIDTH := 7.0

var _session_configured := false
var _session_logical_size := Vector2.ZERO
var _selected_candidate_id := StringName()
var _selected_departure_position := Vector2.ZERO
var _route_hit_radius := 0.0
var _warning_threshold := 0.0
var _latest_cursor_local := Vector2.ZERO
var _left_press_local := Vector2.ZERO
var _left_press_pending := false
var _left_held := false
var _left_released_pending := false
var _right_press_local := Vector2.ZERO
var _right_press_pending := false
var _left_capture_active := false
var _cursor_observed := false
var _presented_state := SessionControllerScript.State.READY
var _has_track_train_data := false
var _built_route := PackedVector2Array()
var _reserved_route := PackedVector2Array()
var _construction_head := Vector2.ZERO
var _train_active := false
var _train_position := Vector2.ZERO
var _train_heading := Vector2.RIGHT
var _hover_cancel_route := PackedVector2Array()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_latest_cursor_local = event.position
		_cursor_observed = true
		_update_hover_preview(event.position)
		return
	if not event is InputEventMouseButton:
		return
	_latest_cursor_local = event.position
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not _left_press_pending:
				_left_press_local = event.position
				_left_press_pending = true
				_left_capture_active = _local_point_is_inside(event.position)
			_left_held = true
		else:
			if _left_held:
				_left_released_pending = true
			_left_held = false
			_left_capture_active = false
		accept_event()
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and not _right_press_pending:
			_right_press_local = event.position
			_right_press_pending = true
			_clear_hover_preview()
		accept_event()


func consume_input_frame() -> TrackInputFrameScript:
	var cursor_mapping := _map_local_point(
		_latest_cursor_local,
		_left_capture_active
	)
	var left_mapping := _map_local_point(_left_press_local)
	var right_mapping := _map_local_point(_right_press_local)
	var frame = TrackInputFrameScript.new(
		cursor_mapping["position"],
		cursor_mapping["inside"],
		_left_press_pending,
		_left_held,
		_left_released_pending,
		_right_press_pending,
		left_mapping["position"],
		_left_press_pending and left_mapping["inside"],
		right_mapping["position"],
		_right_press_pending and right_mapping["inside"]
	)
	_left_press_pending = false
	_left_press_local = Vector2.ZERO
	_left_released_pending = false
	_right_press_pending = false
	_right_press_local = Vector2.ZERO
	return frame


func _map_local_point(
	local_position: Vector2,
	allow_unclamped := false
) -> Dictionary:
	var viewport_position := get_global_transform_with_canvas() * local_position
	var mapped: Variant = try_viewport_to_logical(viewport_position)
	var logical_position := Vector2.ZERO
	if mapped != null:
		logical_position = Vector2(mapped)
	elif allow_unclamped:
		logical_position = viewport_to_logical_unclamped(viewport_position)
	return {
		"position": logical_position,
		"inside": mapped != null,
	}


func _local_point_is_inside(local_position: Vector2) -> bool:
	var viewport_position := get_global_transform_with_canvas() * local_position
	return try_viewport_to_logical(viewport_position) != null


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_logical_transform()
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_cursor_observed = false
		_clear_hover_preview()


func get_logical_track_field() -> LogicalTrackFieldScript:
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
	if local_position.x < content_rect.position.x or local_position.x > content_rect.end.x or local_position.y < content_rect.position.y or local_position.y > content_rect.end.y:
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
	_session_logical_size = Vector2(start_config.logical_field_size)
	_selected_candidate_id = StringName(start_config.departure_candidate_id)
	_selected_departure_position = Vector2(start_config.departure_position)
	_route_hit_radius = float(start_config.route_hit_radius_units)
	_warning_threshold = float(start_config.urgent_warning_seconds)
	if not _session_logical_size.is_equal_approx(field.get_logical_size()):
		push_error("Configured logical field size must equal the authored field size")
		return
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
	_built_route = snapshot.get_built_route()
	_reserved_route = snapshot.get_reserved_route()
	_construction_head = snapshot.get_construction_head()
	_train_active = snapshot.is_train_active()
	_train_position = snapshot.get_train_position()
	_train_heading = snapshot.get_train_heading()
	if _presented_state == SessionControllerScript.State.COMPLETED:
		_clear_hover_preview()
	elif _cursor_observed:
		_update_hover_preview(_latest_cursor_local)
	else:
		_clear_hover_preview()
	queue_redraw()


func get_render_observation() -> Dictionary:
	return {
		"logical_size": Vector2(_get_mapping_logical_size()),
		"built_route": _built_route.duplicate(),
		"reserved_route": _reserved_route.duplicate(),
		"construction_head": Vector2(_construction_head),
		"selected_departure_id": StringName(_selected_candidate_id),
		"selected_departure_position": Vector2(_selected_departure_position),
		"train_active": _train_active,
		"train_position": Vector2(_train_position),
		"train_heading": Vector2(_train_heading),
		"hover_cancel_route": _hover_cancel_route.duplicate(),
	}


func _draw() -> void:
	var logical_size := _get_mapping_logical_size()
	if logical_size.x <= 0.0 or logical_size.y <= 0.0:
		return
	var content_rect := get_logical_content_rect()
	if content_rect.size.x <= 0.0 or content_rect.size.y <= 0.0:
		return
	var uniform_scale: float = content_rect.size.x / logical_size.x
	draw_set_transform(content_rect.position, 0.0, Vector2.ONE * uniform_scale)
	if _built_route.size() >= 2:
		draw_polyline(_built_route, BUILT_COLOR, BUILT_WIDTH, true)
	if _reserved_route.size() >= 2:
		draw_polyline(_reserved_route, RESERVED_COLOR, RESERVED_WIDTH, true)
	if _hover_cancel_route.size() >= 2:
		draw_polyline(_hover_cancel_route, HOVER_COLOR, HOVER_WIDTH, true)
	if _has_track_train_data:
		draw_circle(_construction_head, HEAD_RADIUS, HEAD_COLOR, true)
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


func _clear_hover_preview() -> void:
	if _hover_cancel_route.is_empty():
		return
	_hover_cancel_route = PackedVector2Array()
	queue_redraw()


func _update_hover_preview(local_position: Vector2) -> void:
	if (
		_presented_state == SessionControllerScript.State.COMPLETED
		or _reserved_route.size() < 2
		or _route_hit_radius <= 0.0
	):
		_clear_hover_preview()
		return
	var mapping := _map_local_point(local_position)
	if not mapping["inside"]:
		_clear_hover_preview()
		return
	var cursor: Vector2 = mapping["position"]
	var minimum_distance := INF
	var selected_distance := INF
	var best_route_distance := -INF
	var best_projection := Vector2.ZERO
	var best_segment := -1
	var route_distance := 0.0
	for segment_index in range(_reserved_route.size() - 1):
		var start: Vector2 = _reserved_route[segment_index]
		var finish: Vector2 = _reserved_route[segment_index + 1]
		var segment := finish - start
		var segment_length := segment.length()
		if segment_length <= TrackSystemScript.GEOMETRY_EPSILON:
			continue
		var weight := clampf((cursor - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
		var projection := start + segment * weight
		var distance := cursor.distance_to(projection)
		var candidate_route_distance := route_distance + segment_length * weight
		var should_select := false
		if best_segment < 0:
			minimum_distance = distance
			should_select = true
		elif distance < minimum_distance:
			minimum_distance = distance
			should_select = (
				selected_distance - distance > TrackSystemScript.GEOMETRY_EPSILON
				or candidate_route_distance > best_route_distance
			)
		elif (
			distance - minimum_distance <= TrackSystemScript.GEOMETRY_EPSILON
			and candidate_route_distance > best_route_distance
		):
			should_select = true
		if should_select:
			selected_distance = distance
			best_route_distance = candidate_route_distance
			best_projection = projection
			best_segment = segment_index
		route_distance += segment_length
	if best_segment < 0 or minimum_distance > _route_hit_radius:
		_clear_hover_preview()
		return
	var suffix := PackedVector2Array([best_projection])
	for point_index in range(best_segment + 1, _reserved_route.size()):
		var point: Vector2 = _reserved_route[point_index]
		if suffix[-1] != point:
			suffix.append(point)
	_hover_cancel_route = suffix
	queue_redraw()
