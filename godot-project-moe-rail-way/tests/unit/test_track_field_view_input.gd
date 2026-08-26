extends "res://tests/support/prototype_test.gd"

const FIELD_SCENE_PATH := "res://src/presentation/track/logical_track_field.tscn"
const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackFieldViewScript = preload("res://src/presentation/track/track_field_view.gd")


func run() -> PackedStringArray:
	_test_horizontal_and_l_shaped_physical_events()
	_test_corner_order_and_consume_once()
	_test_outside_and_right_cell_mapping()
	_test_resize_and_nonzero_canvas_offset_preserve_cells()
	_test_grid_render_observation_reports_inclusive_nonzero_origin_geometry()
	_test_valid_start_render_observation_tracks_empty_route_endpoint_and_completion()
	_test_built_reflow_interval_stays_solid_without_provisional_style()
	_test_ordinary_provisional_ghost_keeps_cancel_hover()
	_test_locked_non_support_ghost_has_no_cancel_hover()
	_test_exit_support_ghost_has_no_cancel_hover()
	return finish()


func _config(
	grid_size := Vector2i(30, 14),
	grid_cell_size := 40.0,
	grid_origin := Vector2.ZERO,
	departure_cell := Vector2i(0, 0)
) -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		1, 20.0, 60,
		1.0, 10, 2, 2.0, 1.0, 1,
		Vector2(1200.0, 560.0), grid_size, grid_cell_size, grid_origin,
		&"view_departure", Vector2(20.0, 20.0), departure_cell
	)


func _fixture(
	offset: Vector2 = Vector2.ZERO,
	view_size: Vector2 = Vector2(1000.0, 700.0),
	start_config: SessionStartConfigScript = null
) -> Dictionary:
	var parent := Control.new()
	parent.position = offset
	Engine.get_main_loop().root.add_child(parent)
	var view = TrackFieldViewScript.new()
	view.size = view_size
	parent.add_child(view)
	var packed = load(FIELD_SCENE_PATH) as PackedScene
	view.add_child(packed.instantiate())
	view.configure_session(start_config if start_config != null else _config())
	view.get_logical_content_rect()
	return {"parent": parent, "view": view}


func _button(position: Vector2, button_index: int, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = button_index
	event.pressed = pressed
	return event


func _motion(position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	return event


func _local_for_logical(view, logical: Vector2) -> Vector2:
	var content: Rect2 = view.get_logical_content_rect()
	return content.position + logical / Vector2(1200.0, 560.0) * content.size


func _deliver(view, event: InputEvent) -> void:
	view.call("_gui_input", event)


func _runtime_piece_for_serial(
	pieces: Array[TrackGeometryPieceScript], route_serial: int
) -> TrackGeometryPieceScript:
	for piece in pieces:
		if piece.contains_serial(route_serial):
			return piece
	return null


func _runtime_record_for_serial(
	records: Array[TrackCellRecordScript], route_serial: int
) -> TrackCellRecordScript:
	for record in records:
		if record.route_serial == route_serial:
			return record
	return null


func _view_interval_for_serial(observation: Dictionary, route_serial: int) -> Dictionary:
	for interval in observation.get("intervals", []):
		if interval.get("route_serial", -1) == route_serial:
			return interval
	return {}


func _points_materially_differ(first: PackedVector2Array, second: PackedVector2Array) -> bool:
	if first.size() != second.size():
		return true
	for index in range(first.size()):
		if first[index].distance_to(second[index]) >= 1.0:
			return true
	return false


func _view_straight_piece(route_serial: int, cell: Vector2i) -> TrackGeometryPieceScript:
	var piece = TrackGeometryPieceScript.new()
	piece.group_id = route_serial
	piece.kind = TrackGeometryPieceScript.Kind.STRAIGHT
	piece.first_route_serial = route_serial
	piece.last_route_serial = route_serial
	piece.nominal_length_cells = 1
	piece.absolute_start_distance_cells = float(route_serial - 1)
	var footprint: Array[Vector2i] = [cell]
	piece.footprint_cells = footprint
	var center := Vector2((float(cell.x) + 0.5) * 40.0, (float(cell.y) + 0.5) * 40.0)
	piece.centerline = PackedVector2Array([center - Vector2(20.0, 0.0), center])
	piece.active_local_end_cells = 1.0
	return piece


func _view_snapshot(records: Array[TrackCellRecordScript], pieces: Array[TrackGeometryPieceScript]) -> SessionSnapshotScript:
	return SessionSnapshotScript.new(
		1, 0, 1, 60, true, SessionControllerScript.State.PREPARING_DEPARTURE,
		records, pieces
	)


func _built_runtime_straight_head() -> GridTrackRuntimeScript:
	var runtime = GridTrackRuntimeScript.new(Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_equal(runtime.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	]), 3, "B through D begin as actual runtime straights")
	assert_equal(runtime.advance_construction(3.0), 3.0, "B through D are built before the turn exists")
	return runtime


func _exit_support_runtime() -> GridTrackRuntimeScript:
	var runtime = GridTrackRuntimeScript.new(Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0)
	assert_equal(runtime.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	]), 5, "B through F curve fixture appends")
	assert_equal(runtime.append_cells([Vector2i(2, 3)]), 1, "Distinct G continues F direction")
	return runtime


func _test_built_reflow_interval_stays_solid_without_provisional_style() -> void:
	var fixture := _fixture()
	var runtime := _built_runtime_straight_head()
	var initially_built_serials := [1, 2, 3]
	var before_records: Array[TrackCellRecordScript] = runtime.get_cell_records()
	var before_pieces: Array[TrackGeometryPieceScript] = runtime.get_geometry_pieces()
	fixture.view.present(_view_snapshot(before_records, before_pieces))
	var before_observation: Dictionary = fixture.view.get_render_observation()
	var before_points_by_serial: Dictionary = {}
	for route_serial in initially_built_serials:
		var before_record := _runtime_record_for_serial(before_records, route_serial)
		var before_owner := _runtime_piece_for_serial(before_pieces, route_serial)
		assert_not_null(before_record, "Built serial %d exists before the turn" % route_serial)
		assert_not_null(before_owner, "Built serial %d has an actual runtime owner before the turn" % route_serial)
		if before_record != null:
			assert_equal(before_record.route_serial, route_serial, "Initial record serial is preserved")
			assert_equal(before_record.state, TrackCellRecordScript.State.BUILT, "Initial serial %d is built" % route_serial)
			assert_false(before_record.geometry_locked, "Initial serial %d remains provisional" % route_serial)
		if before_owner != null:
			assert_equal(before_owner.kind, TrackGeometryPieceScript.Kind.STRAIGHT, "Initial serial %d has a straight runtime owner" % route_serial)
			assert_false(before_owner.locked, "Initial serial %d owner is provisional" % route_serial)
		var before_interval := _view_interval_for_serial(before_observation, route_serial)
		assert_false(before_interval.is_empty(), "The view captures actual serial %d before reflow" % route_serial)
		if not before_interval.is_empty():
			assert_equal(before_interval.route_serial, route_serial, "Initial rendered serial is preserved")
			assert_equal(before_interval.state, TrackCellRecordScript.State.BUILT, "Initial built serial uses solid render state")
			assert_false(before_interval.locked, "Initial rendered serial is provisional, not a style")
			before_points_by_serial[route_serial] = before_interval.points

	assert_equal(runtime.append_cells([
		Vector2i(2, 1), Vector2i(2, 2),
	]), 2, "E and F make the same B through D serials reclassify through the runtime")
	var after_records: Array[TrackCellRecordScript] = runtime.get_cell_records()
	var after_pieces: Array[TrackGeometryPieceScript] = runtime.get_geometry_pieces()
	var after_owner := _runtime_piece_for_serial(after_pieces, 1)
	assert_not_null(after_owner, "B retains one runtime owner after reflow")
	if after_owner == null:
		fixture.parent.free()
		return
	assert_equal(after_owner.kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Runtime reclassifies B through F as a 3x3 curve")
	assert_equal(after_owner.first_route_serial, 1, "Reflow curve still owns B")
	assert_equal(after_owner.last_route_serial, 5, "Reflow curve now owns B through F")
	assert_false(after_owner.locked, "Reflowed owner remains provisional")
	fixture.view.present(_view_snapshot(after_records, after_pieces))
	var after_observation: Dictionary = fixture.view.get_render_observation()
	var geometry_materially_reflowed := false
	for route_serial in initially_built_serials:
		var record := _runtime_record_for_serial(after_records, route_serial)
		var owner := _runtime_piece_for_serial(after_pieces, route_serial)
		assert_not_null(record, "Built serial %d survives runtime reflow" % route_serial)
		assert_not_null(owner, "Built serial %d retains a runtime owner after reflow" % route_serial)
		if record != null:
			assert_equal(record.route_serial, route_serial, "Reflow preserves serial identity")
			assert_equal(record.state, TrackCellRecordScript.State.BUILT, "Runtime reflow preserves built state for serial %d" % route_serial)
			assert_false(record.geometry_locked, "Runtime reflow does not lock serial %d" % route_serial)
		if owner != null:
			assert_equal(owner.kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Reflowed serial %d belongs to the curve" % route_serial)
			assert_false(owner.locked, "Reflowed serial %d owner remains provisional" % route_serial)
		var after_interval := _view_interval_for_serial(after_observation, route_serial)
		assert_false(after_interval.is_empty(), "The view captures actual serial %d after reflow" % route_serial)
		if not after_interval.is_empty():
			assert_equal(after_interval.route_serial, route_serial, "Reflowed rendered serial is preserved")
			assert_equal(after_interval.state, TrackCellRecordScript.State.BUILT, "Reflowed built serial remains in the solid render state")
			assert_false(after_interval.locked, "Reflowed built serial has no provisional render style")
			if before_points_by_serial.has(route_serial):
				var before_points: PackedVector2Array = before_points_by_serial[route_serial]
				geometry_materially_reflowed = geometry_materially_reflowed or _points_materially_differ(before_points, after_interval.points)
	assert_true(geometry_materially_reflowed, "Runtime reflow materially changes rendered centerline points while built serials stay solid")
	fixture.parent.free()


func _test_ordinary_provisional_ghost_keeps_cancel_hover() -> void:
	var fixture := _fixture()
	var ghost = TrackCellRecordScript.new(6, Vector2i(3, 2), 5.0)
	ghost.state = TrackCellRecordScript.State.RESERVED_GHOST
	fixture.view.present(_view_snapshot([ghost], [_view_straight_piece(6, ghost.cell)]))
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(140.0, 100.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(3, 2), "Ordinary provisional ghost has cancel hover")
	fixture.parent.free()


func _test_locked_non_support_ghost_has_no_cancel_hover() -> void:
	var fixture := _fixture()
	var ghost = TrackCellRecordScript.new(6, Vector2i(3, 2), 5.0)
	ghost.state = TrackCellRecordScript.State.RESERVED_GHOST
	ghost.geometry_locked = true
	var locked_piece = _view_straight_piece(6, ghost.cell)
	locked_piece.locked = true
	fixture.view.present(_view_snapshot([ghost], [locked_piece]))
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(140.0, 100.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Locked non-support ghost has no hover")
	fixture.parent.free()


func _test_exit_support_ghost_has_no_cancel_hover() -> void:
	var fixture := _fixture()
	var runtime = _exit_support_runtime()
	var records: Array[TrackCellRecordScript] = runtime.get_cell_records()
	var pieces: Array[TrackGeometryPieceScript] = runtime.get_geometry_pieces()
	assert_equal(records.size(), 6, "Snapshot contains active B through G records")
	var predecessor = null
	var support_owner = null
	for piece in pieces:
		if piece.contains_serial(1):
			predecessor = piece
		if piece.contains_serial(6):
			support_owner = piece
	assert_not_null(predecessor, "B through F predecessor piece exists")
	assert_not_null(support_owner, "G has its own detached active piece")
	if predecessor != null:
		assert_true(predecessor.locked, "Horizon locks B through F")
		assert_equal(predecessor.exit_support_route_serial, 6, "Locked predecessor names G as support")
	if support_owner != null:
		assert_false(support_owner.locked, "G support piece remains provisional")
	var support_owners := 0
	for piece in pieces:
		if piece.contains_serial(6):
			support_owners += 1
	assert_equal(support_owners, 1, "G has exactly one owning detached piece")
	fixture.view.present(_view_snapshot(records, pieces))
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 140.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_cancel_cell", Vector2i.ZERO), Vector2i(-1, -1), "Support has no hover")
	fixture.parent.free()


func _test_horizontal_and_l_shaped_physical_events() -> void:
	var fixture := _fixture()
	var view = fixture.view
	var start := _local_for_logical(view, Vector2(20.0, 20.0))
	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(140.0, 20.0))))
	var horizontal = view.consume_input_frame()
	assert_equal(
		horizontal.crossed_cells,
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
		"One fast event preserves all three horizontal cells"
	)
	_deliver(view, _button(_local_for_logical(view, Vector2(140.0, 20.0)), MOUSE_BUTTON_LEFT, false))
	view.consume_input_frame()

	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 20.0))))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 100.0))))
	var l_shape = view.consume_input_frame()
	assert_equal(
		l_shape.crossed_cells,
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)],
		"Two real events preserve an L without a diagonal shortcut"
	)
	fixture.parent.free()


func _test_corner_order_and_consume_once() -> void:
	var fixture := _fixture()
	var view = fixture.view
	var start := _local_for_logical(view, Vector2(20.0, 20.0))
	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(140.0, 60.0))))
	var dominant = view.consume_input_frame()
	assert_equal(
		dominant.crossed_cells,
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(3, 1)],
		"Horizontal-dominant exact corner is ordered"
	)
	var consumed = view.consume_input_frame()
	assert_equal(consumed.crossed_cells, [], "Cell buffer clears exactly once per consume")
	assert_true(consumed.left_held, "Held state persists after the buffer clears")
	_deliver(view, _button(_local_for_logical(view, Vector2(140.0, 60.0)), MOUSE_BUTTON_LEFT, false))
	view.consume_input_frame()
	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 100.0))))
	assert_equal(
		view.consume_input_frame().crossed_cells,
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		"Equal-axis corner is horizontal first"
	)
	fixture.parent.free()


func _test_outside_and_right_cell_mapping() -> void:
	var fixture := _fixture()
	var view = fixture.view
	var content: Rect2 = view.get_logical_content_rect()
	var letterbox := Vector2(content.get_center().x, content.position.y * 0.5)
	_deliver(view, _button(letterbox, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(letterbox + Vector2(50.0, 0.0)))
	var outside = view.consume_input_frame()
	assert_false(outside.left_press_inside_grid, "Letterbox press is outside the grid")
	assert_equal(outside.crossed_cells, [], "Letterbox events emit no cells")
	_deliver(view, _button(letterbox, MOUSE_BUTTON_LEFT, false))
	view.consume_input_frame()
	var right_position := _local_for_logical(view, Vector2(100.0, 60.0))
	_deliver(view, _button(right_position, MOUSE_BUTTON_RIGHT, true))
	var right = view.consume_input_frame()
	assert_true(right.right_pressed, "Right edge appears once")
	assert_true(right.right_press_inside_grid, "Right center is inside the grid")
	assert_equal(right.right_press_cell, Vector2i(2, 1), "Right press resolves one exact cell")
	assert_false(view.consume_input_frame().right_pressed, "Right edge clears after consume")
	fixture.parent.free()


func _test_resize_and_nonzero_canvas_offset_preserve_cells() -> void:
	var fixture := _fixture(Vector2(137.0, 83.0))
	var view = fixture.view
	var start := _local_for_logical(view, Vector2(20.0, 20.0))
	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 20.0))))
	var before: Array[Vector2i] = view.consume_input_frame().crossed_cells
	_deliver(view, _button(_local_for_logical(view, Vector2(100.0, 20.0)), MOUSE_BUTTON_LEFT, false))
	view.consume_input_frame()
	view.size = Vector2(1400.0, 700.0)
	start = _local_for_logical(view, Vector2(20.0, 20.0))
	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 20.0))))
	assert_equal(view.consume_input_frame().crossed_cells, before, "Resize changes scale, not grid cells")
	assert_equal(fixture.parent.position, Vector2(137.0, 83.0), "Nonzero canvas offset is preserved")
	fixture.parent.free()


func _test_grid_render_observation_reports_inclusive_nonzero_origin_geometry() -> void:
	var fixture := _fixture(
		Vector2.ZERO,
		Vector2(1000.0, 700.0),
		_config(Vector2i(2, 2), 40.0, Vector2(120.0, 80.0), Vector2i(1, 1))
	)
	var observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(
		observation.get("grid_size", Vector2i(-1, -1)),
		Vector2i(2, 2),
		"Grid render observation preserves the configured cell count"
	)
	assert_equal(
		observation.get("grid_rect", Rect2()),
		Rect2(Vector2(120.0, 80.0), Vector2(80.0, 80.0)),
		"Grid render observation preserves the nonzero authoritative rectangle"
	)
	assert_equal(
		observation.get("grid_line_color", Color.TRANSPARENT),
		Color(0.5, 0.5, 0.5, 1.0),
		"Grid render observation exposes opaque fifty-percent gray"
	)
	var lines: Array = observation.get("grid_lines", [])
	assert_equal(
		lines.size(),
		6,
		"A two-by-two grid renders all three vertical and three horizontal boundaries"
	)
	assert_equal(
		lines[0] if not lines.is_empty() else {},
		{"from": Vector2(120.0, 80.0), "to": Vector2(120.0, 160.0), "color": Color(0.5, 0.5, 0.5, 1.0)},
		"First grid boundary starts at the nonzero grid origin"
	)
	assert_equal(
		lines[-1] if not lines.is_empty() else {},
		{"from": Vector2(120.0, 160.0), "to": Vector2(200.0, 160.0), "color": Color(0.5, 0.5, 0.5, 1.0)},
		"Last grid boundary closes the inclusive bottom edge"
	)
	assert_equal(
		observation.get("field_draw_order", PackedStringArray()),
		PackedStringArray(["grid_lines", "valid_start"]),
		"Field draw order places the endpoint highlight above the grid"
	)
	if observation.has("grid_line_color"):
		fixture.view.grid_line_color = Color(0.25, 0.75, 1.0, 0.2)
		assert_equal(
			fixture.view.get_render_observation().get("grid_line_color", Color.TRANSPARENT),
			Color(0.25, 0.75, 1.0, 1.0),
			"Programmatic grid color changes remain opaque in the next render observation"
		)
	fixture.parent.free()


func _test_valid_start_render_observation_tracks_empty_route_endpoint_and_completion() -> void:
	var fixture := _fixture(
		Vector2.ZERO,
		Vector2(1000.0, 700.0),
		_config(Vector2i(3, 2), 40.0, Vector2(120.0, 80.0), Vector2i(1, 1))
	)
	var empty_observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(
		empty_observation.get("valid_start_cell", Vector2i(-1, -1)),
		Vector2i(1, 1),
		"Empty routes highlight the configured departure cell"
	)
	assert_equal(
		empty_observation.get("valid_start_rect", Rect2()),
		Rect2(Vector2(160.0, 120.0), Vector2(40.0, 40.0)),
		"Empty routes highlight the full configured departure cell rectangle"
	)
	var first_record := TrackCellRecordScript.new(0, Vector2i(1, 0))
	var last_record := TrackCellRecordScript.new(1, Vector2i(2, 1))
	fixture.view.present(SessionSnapshotScript.new(
		1, 0, 1, 60, true, SessionControllerScript.State.PREPARING_DEPARTURE,
		[first_record, last_record]
	))
	var route_observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(
		route_observation.get("valid_start_cell", Vector2i(-1, -1)),
		Vector2i(2, 1),
		"Valid-start render observation follows the last ordered active route cell"
	)
	assert_equal(
		route_observation.get("valid_start_rect", Rect2()),
		Rect2(Vector2(200.0, 120.0), Vector2(40.0, 40.0)),
		"Routed valid-start highlight occupies the last active cell"
	)
	fixture.view.present(SessionSnapshotScript.new(
		1, 1, 0, 60, true, SessionControllerScript.State.COMPLETED,
		[first_record, last_record]
	))
	var completed_observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(
		completed_observation.get("valid_start_cell", Vector2i.ZERO),
		Vector2i(-1, -1),
		"Completed sessions hide the valid-start cell"
	)
	assert_equal(
		completed_observation.get("valid_start_rect", Rect2(Vector2.ONE, Vector2.ONE)),
		Rect2(),
		"Completed sessions expose no valid-start rectangle"
	)
	fixture.parent.free()
