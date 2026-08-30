extends "res://tests/support/prototype_test.gd"

const FIELD_SCENE_PATH := "res://src/presentation/track/logical_track_field.tscn"
const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackFieldViewScript = preload("res://src/presentation/track/track_field_view.gd")


func run() -> PackedStringArray:
	_test_horizontal_and_l_shaped_physical_events()
	_test_corner_order_and_consume_once()
	_test_outside_and_right_cell_mapping()
	_test_crossing_interval_exposes_primitive_gap_identity()
	_test_held_reentry_preserves_intermediate_cells_across_frames()
	_test_held_reentry_gap_grants_bounded_connection_authority()
	_test_resize_and_nonzero_canvas_offset_preserve_cells()
	_test_grid_render_observation_reports_inclusive_nonzero_origin_geometry()
	_test_valid_start_render_observation_tracks_empty_route_endpoint_and_completion()
	_test_built_reflow_interval_stays_solid_without_provisional_style()
	_test_unanchored_local_corner_presentation()
	_test_exact_center_local_corner_presentation()
	_test_ordinary_provisional_ghost_keeps_cancel_hover()
	_test_locked_non_support_ghost_has_no_cancel_hover()
	_test_exit_support_ghost_has_no_cancel_hover()
	_test_endpoint_reshape_consume_frame_carries_current_pointer_facts()
	_test_live_gesture_path_backtracks_and_rebranches_while_held()
	_test_live_gesture_path_returns_to_press_origin()
	_test_pending_release_and_fresh_press_share_frame_facts()
	_test_explicit_release_snapshot_detaches_before_fresh_cleanup()
	_test_endpoint_reshape_actionable_endpoint_is_green()
	_test_endpoint_reshape_green_over_gold_retains_cancellation()
	_test_endpoint_reshape_pending_right_suppresses_present_hover()
	_test_endpoint_reshape_left_held_gold_remains_independent()
	_test_endpoint_reshape_outside_completion_and_inactive_clear_hover()
	_test_endpoint_reshape_snapshot_termination_clears_view_capture_and_buffer()
	_test_endpoint_reshape_no_green_negatives()
	_test_endpoint_reshape_locked_extendable_endpoint_is_green()
	_test_endpoint_reshape_no_operation_endpoint_is_not_green()
	_test_endpoint_reshape_whole_suffix_dependency_is_negative()
	_test_endpoint_reshape_mouse_exit_clears_pointer_facts()
	_test_endpoint_reshape_train_occupied_endpoint_is_not_green()
	_test_endpoint_reshape_actual_abort_clears_and_allows_fresh_press()
	_test_endpoint_reshape_actual_train_preparation_clears_and_allows_fresh_press()
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


func _local_for_cell(view, cell: Vector2i) -> Vector2:
	return _local_for_logical(view, Vector2(cell) * 40.0 + Vector2(20.0, 20.0))


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


func _record_cells(records: Array) -> Array:
	var cells: Array = []
	for record in records:
		cells.append(record.cell)
	return cells


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


func _three_points_are_forward_collinear(
	first: Vector2, second: Vector2, third: Vector2
) -> bool:
	var first_delta := second - first
	var second_delta := third - second
	return (
		absf(first_delta.cross(second_delta)) <= 0.0001
		and first_delta.dot(second_delta) > 0.0
	)


func _points_contain_bend(points: PackedVector2Array) -> bool:
	for index in range(1, points.size() - 1):
		var incoming := points[index] - points[index - 1]
		var outgoing := points[index + 1] - points[index]
		if absf(incoming.cross(outgoing)) > 0.0001:
			return true
	return false


func _view_straight_piece(
	route_serial: int, cell: Vector2i, distance_cells: float = -1.0
) -> TrackGeometryPieceScript:
	var piece = TrackGeometryPieceScript.new()
	piece.group_id = route_serial
	piece.kind = TrackGeometryPieceScript.Kind.STRAIGHT
	piece.first_route_serial = route_serial
	piece.last_route_serial = route_serial
	piece.nominal_length_cells = 1
	piece.absolute_start_distance_cells = distance_cells if distance_cells >= 0.0 else float(route_serial - 1)
	var footprint: Array[Vector2i] = [cell]
	piece.footprint_cells = footprint
	var center := Vector2((float(cell.x) + 0.5) * 40.0, (float(cell.y) + 0.5) * 40.0)
	piece.centerline = PackedVector2Array([center - Vector2(20.0, 0.0), center])
	piece.active_local_end_cells = 1.0
	return piece


func _view_snapshot(
	records: Array[TrackCellRecordScript],
	pieces: Array[TrackGeometryPieceScript],
	state: int = SessionControllerScript.State.PREPARING_DEPARTURE,
	endpoint_eligible := false,
	gesture_active := false,
	train_active := false,
	train_position := Vector2.ZERO,
	has_track_train_data := true
) -> SessionSnapshotScript:
	return SessionSnapshotScript.new(
		1, 0, 1, 60, has_track_train_data, state,
		records, pieces, [], 0.0, 0, 0, Vector2.ZERO, 0, 0, 0.0,
		train_active, 0.0, train_position, Vector2.RIGHT, 0.0, false, &"view",
		Vector2i(-1, -1), endpoint_eligible, gesture_active
	)


func _endpoint_record(
	cell: Vector2i,
	state: int = TrackCellRecordScript.State.BUILT,
	route_serial: int = 1,
	distance_cells: float = -1.0
) -> TrackCellRecordScript:
	var record := TrackCellRecordScript.new(
		route_serial,
		cell,
		distance_cells if distance_cells >= 0.0 else float(route_serial - 1)
	)
	record.state = state
	return record


func _present_endpoint(
	view,
	records: Array[TrackCellRecordScript],
	pieces: Array[TrackGeometryPieceScript],
	eligible := true,
	active := false,
	state: int = SessionControllerScript.State.PREPARING_DEPARTURE,
	train_active := false,
	train_position := Vector2.ZERO,
	has_track_train_data := true
) -> void:
	view.present(_view_snapshot(records, pieces, state, eligible, active, train_active, train_position, has_track_train_data))


func _snapshot_for_track(
	track: TrackSystemScript,
	state: int = SessionControllerScript.State.PREPARING_DEPARTURE,
	train_active := false,
	train_position := Vector2.ZERO
) -> SessionSnapshotScript:
	return _view_snapshot(
		track.get_cell_records(), track.get_geometry_pieces(), state,
		track.is_endpoint_gesture_eligible(), track.is_runtime_gesture_active(),
		train_active, train_position
	)


func _test_endpoint_reshape_consume_frame_carries_current_pointer_facts() -> void:
	print("Endpoint reshape: consume frame carries current pointer facts")
	var fixture := _fixture()
	var endpoint := _local_for_logical(fixture.view, Vector2(20.0, 20.0))
	_deliver(fixture.view, _motion(endpoint))
	var frame = fixture.view.consume_input_frame()
	assert_equal(frame.current_pointer_cell, Vector2i(0, 0), "Consumed frame carries the latest pointer cell")
	assert_true(frame.current_pointer_inside_grid, "Consumed frame carries the latest inside-grid fact")
	fixture.parent.free()


func _test_live_gesture_path_backtracks_and_rebranches_while_held() -> void:
	print("Live gesture path: held backtrack truncates and rebranches")
	var fixture := _fixture()
	var view = fixture.view
	var origin := _local_for_cell(view, Vector2i(0, 0))
	_deliver(view, _button(origin, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_cell(view, Vector2i(3, 0))))
	var first = view.consume_input_frame()
	assert_false(first.has_explicit_release_snapshot, "Held non-release frame has no explicit release snapshot")
	assert_not_null(first.get("live_gesture_path"), "First held frame exposes the live gesture path")
	assert_equal(first.live_gesture_path, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], "First held frame publishes the complete path")
	_deliver(view, _motion(_local_for_cell(view, Vector2i(1, 0))))
	_deliver(view, _motion(_local_for_cell(view, Vector2i(1, 2))))
	var rebranched = view.consume_input_frame()
	assert_true(rebranched.left_held and not rebranched.left_released, "Rebranch remains in the same press")
	assert_equal(rebranched.live_gesture_path, [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)], "Earlier suffix is replaced by the new branch")
	assert_equal(first.live_gesture_path, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], "Consumed snapshots remain detached")
	fixture.parent.free()


func _test_live_gesture_path_returns_to_press_origin() -> void:
	print("Live gesture path: returning to press origin clears the path")
	var fixture := _fixture()
	var view = fixture.view
	var origin := _local_for_cell(view, Vector2i(0, 0))
	_deliver(view, _button(origin, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_cell(view, Vector2i(2, 0))))
	view.consume_input_frame()
	_deliver(view, _motion(origin))
	var cleared = view.consume_input_frame()
	assert_true(cleared.left_held and not cleared.left_released, "Origin return remains held")
	assert_not_null(cleared.get("live_gesture_path"), "Origin return exposes the live gesture path")
	assert_equal(cleared.live_gesture_path, [], "Origin return publishes an explicitly empty path")
	fixture.parent.free()


func _test_pending_release_and_fresh_press_share_frame_facts() -> void:
	print("Live gesture path: pending release and fresh press share frame facts")
	var fixture := _fixture()
	var view = fixture.view
	var origin := _local_for_cell(view, Vector2i(0, 0))
	_deliver(view, _button(origin, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_cell(view, Vector2i(3, 0))))
	var first = view.consume_input_frame()
	assert_true(first.left_pressed and first.left_held and not first.left_released, "First gesture is held before release")
	_deliver(view, _button(_local_for_cell(view, Vector2i(3, 0)), MOUSE_BUTTON_LEFT, false))
	_deliver(view, _button(_local_for_cell(view, Vector2i(3, 0)), MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_cell(view, Vector2i(4, 0))))
	var coalesced = view.consume_input_frame()
	assert_true(coalesced.left_pressed, "Fresh press edge survives in the coalesced frame")
	assert_true(coalesced.left_held, "Fresh press remains held in the coalesced frame")
	assert_true(coalesced.left_released, "Prior release remains observable in the coalesced frame")
	assert_equal(coalesced.left_press_cell, Vector2i(3, 0), "Fresh press cell is preserved")
	assert_equal(coalesced.live_gesture_path, [Vector2i(4, 0)], "Fresh held path is preserved")
	_deliver(view, _motion(_local_for_cell(view, Vector2i(5, 0))))
	var followup = view.consume_input_frame()
	assert_true(followup.left_held and not followup.left_released, "Follow-up motion remains held")
	assert_equal(followup.live_gesture_path, [Vector2i(4, 0), Vector2i(5, 0)], "Follow-up frame retains the complete fresh path")
	assert_equal(coalesced.live_gesture_path, [Vector2i(4, 0)], "Coalesced frame remains detached after follow-up motion")
	fixture.parent.free()


func _test_explicit_release_snapshot_detaches_before_fresh_cleanup() -> void:
	print("Live gesture path: release snapshot detaches before fresh press cleanup")
	var fixture := _fixture()
	var view = fixture.view
	var origin := _local_for_cell(view, Vector2i(0, 0))
	_deliver(view, _button(origin, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_cell(view, Vector2i(3, 0))))
	view.consume_input_frame()
	var release_position := _local_for_cell(view, Vector2i(4, 0))
	_deliver(view, _button(release_position, MOUSE_BUTTON_LEFT, false))
	_deliver(view, _button(release_position, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_cell(view, Vector2i(5, 0))))
	var coalesced = view.consume_input_frame()
	assert_true(coalesced.has_explicit_release_snapshot, "Coalesced frame identifies detached release snapshot")
	assert_equal(coalesced.release_live_gesture_path, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)], "Release snapshot keeps A-to-B path")
	assert_equal(coalesced.left_release_pointer_cell, Vector2i(4, 0), "Release snapshot keeps old release pointer")
	assert_true(coalesced.left_release_pointer_inside_grid, "Release snapshot keeps old pointer inside fact")
	assert_equal(coalesced.live_gesture_path, [Vector2i(5, 0)], "Fresh path remains independent")
	assert_equal(coalesced.left_press_cell, Vector2i(4, 0), "Fresh press starts at release endpoint")
	assert_equal(coalesced.current_pointer_cell, Vector2i(5, 0), "Fresh pointer remains authoritative")
	assert_equal(coalesced.release_live_gesture_path, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)], "Release snapshot is detached from later view mutation")
	_deliver(view, _button(_local_for_cell(view, Vector2i(5, 0)), MOUSE_BUTTON_LEFT, false))
	view.consume_input_frame()
	assert_equal(view._release_live_gesture_path, [], "Consumed release buffer is cleared")
	fixture.parent.free()


func _test_endpoint_reshape_actionable_endpoint_is_green() -> void:
	print("Endpoint reshape: actionable endpoint is green")
	var fixture := _fixture()
	var record := _endpoint_record(Vector2i(2, 2))
	_present_endpoint(fixture.view, [record], [], true)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 100.0))))
	assert_equal(
		fixture.view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)),
		Vector2i(2, 2),
		"Actionable presented endpoint publishes green hover"
	)
	fixture.parent.free()


func _test_endpoint_reshape_green_over_gold_retains_cancellation() -> void:
	print("Endpoint reshape: green over gold retains cancellation")
	var fixture := _fixture()
	var ghost := _endpoint_record(Vector2i(2, 2), TrackCellRecordScript.State.RESERVED_GHOST)
	_present_endpoint(fixture.view, [ghost], [_view_straight_piece(1, ghost.cell)], true)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 100.0))))
	var observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(observation.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(2, 2), "Endpoint remains green when it is actionable")
	assert_equal(observation.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(2, 2), "Endpoint retains gold cancellation eligibility")
	var different_cell_position := _local_for_logical(fixture.view, Vector2(140.0, 100.0))
	_deliver(fixture.view, _button(different_cell_position, MOUSE_BUTTON_RIGHT, true))
	var right_press_observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(right_press_observation.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Right press clears green after recomputing its position")
	assert_equal(right_press_observation.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Right press clears gold for its pending action")
	var right_frame = fixture.view.consume_input_frame()
	assert_true(right_frame.right_pressed, "Right press emits one pending right edge")
	assert_equal(right_frame.right_press_cell, Vector2i(3, 2), "Right press retains its inside cell")
	assert_true(right_frame.right_press_inside_grid, "Right press retains its inside-grid fact")
	assert_equal(right_frame.current_pointer_cell, Vector2i(3, 2), "Right press updates current pointer cell")
	assert_true(right_frame.current_pointer_inside_grid, "Right press updates current pointer inside-grid fact")
	assert_false(fixture.view.consume_input_frame().right_pressed, "Consuming right edge does not duplicate it")
	_deliver(fixture.view, _button(_local_for_logical(fixture.view, Vector2(100.0, 100.0)), MOUSE_BUTTON_RIGHT, false))
	var right_release_observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(right_release_observation.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(2, 2), "Right release recomputes green at the endpoint")
	assert_equal(right_release_observation.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(2, 2), "Right release recomputes gold at the endpoint")
	var right_release_frame = fixture.view.consume_input_frame()
	assert_false(right_release_frame.right_pressed, "Right release does not create a duplicate right edge")
	assert_equal(right_release_frame.current_pointer_cell, Vector2i(2, 2), "Right release updates current pointer cell")
	assert_true(right_release_frame.current_pointer_inside_grid, "Right release updates current pointer inside-grid fact")
	_deliver(fixture.view, _button(Vector2(-20.0, -20.0), MOUSE_BUTTON_RIGHT, false))
	var outside_right_observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(outside_right_observation.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Outside right release clears green")
	assert_equal(outside_right_observation.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Outside right release clears gold")
	var outside_right_frame = fixture.view.consume_input_frame()
	assert_false(outside_right_frame.right_pressed, "Outside right release emits no right edge")
	assert_equal(outside_right_frame.current_pointer_cell, Vector2i(-1, -1), "Outside right release emits invalid pointer cell")
	assert_false(outside_right_frame.current_pointer_inside_grid, "Outside right release emits false inside-grid fact")
	_present_endpoint(fixture.view, [ghost], [_view_straight_piece(1, ghost.cell)], true, true)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 100.0))))
	var active_observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(active_observation.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Active gesture suppresses fresh green hover")
	assert_equal(active_observation.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Active gesture suppresses ordinary gold cancellation hover")
	fixture.parent.free()


func _test_endpoint_reshape_pending_right_suppresses_present_hover() -> void:
	print("Endpoint reshape fix round 6: pending right suppresses present hover")
	var fixture := _fixture()
	var ghost := _endpoint_record(Vector2i(2, 2), TrackCellRecordScript.State.RESERVED_GHOST)
	var piece := _view_straight_piece(1, ghost.cell)
	_present_endpoint(fixture.view, [ghost], [piece], true)
	var endpoint_position := _local_for_logical(fixture.view, Vector2(100.0, 100.0))
	_deliver(fixture.view, _motion(endpoint_position))
	var before_right: Dictionary = fixture.view.get_render_observation()
	assert_equal(before_right.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(2, 2), "Pending-right fixture starts with endpoint green")
	assert_equal(before_right.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(2, 2), "Pending-right fixture starts with endpoint gold")
	_deliver(fixture.view, _button(endpoint_position, MOUSE_BUTTON_RIGHT, true))
	var after_right: Dictionary = fixture.view.get_render_observation()
	assert_equal(after_right.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Right press clears green before consume")
	assert_equal(after_right.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Right press clears gold before consume")
	fixture.view.present(_view_snapshot([ghost], [piece], SessionControllerScript.State.PREPARING_DEPARTURE, true, false))
	var republished: Dictionary = fixture.view.get_render_observation()
	assert_equal(republished.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Pending right edge keeps present from republishing green")
	assert_equal(republished.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Pending right edge keeps present from republishing gold")
	fixture.parent.free()


func _test_endpoint_reshape_left_held_gold_remains_independent() -> void:
	print("Endpoint reshape fix round 6: left-held gold remains independent")
	var fixture := _fixture()
	var ghost_nonendpoint := _endpoint_record(Vector2i(2, 2), TrackCellRecordScript.State.RESERVED_GHOST, 1, 0.0)
	var ghost_endpoint := _endpoint_record(Vector2i(3, 2), TrackCellRecordScript.State.RESERVED_GHOST, 2, 1.0)
	var pieces: Array[TrackGeometryPieceScript] = [
		_view_straight_piece(1, ghost_nonendpoint.cell, 0.0),
		_view_straight_piece(2, ghost_endpoint.cell, 1.0),
	]
	_present_endpoint(fixture.view, [ghost_nonendpoint, ghost_endpoint], pieces, true)
	var gold_position := _local_for_logical(fixture.view, Vector2(100.0, 100.0))
	_deliver(fixture.view, _motion(gold_position))
	_deliver(fixture.view, _button(Vector2(-20.0, -20.0), MOUSE_BUTTON_LEFT, true))
	assert_true(fixture.view._left_held, "Left-held gold fixture retains the physical left latch")
	_deliver(fixture.view, _motion(gold_position))
	var held_observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(held_observation.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Left-held motion keeps green independently suppressed")
	assert_equal(held_observation.get("hover_cancel_cell", Vector2i(-1, -1)), ghost_nonendpoint.cell, "Left-held motion retains positive ordinary gold hover")
	_deliver(fixture.view, _button(Vector2(-20.0, -20.0), MOUSE_BUTTON_LEFT, false))
	fixture.view.consume_input_frame()
	fixture.parent.free()


func _test_endpoint_reshape_outside_completion_and_inactive_clear_hover() -> void:
	print("Endpoint reshape: outside, completion, and inactive clear hover")
	var fixture := _fixture()
	var record := _endpoint_record(Vector2i(2, 2))
	_present_endpoint(fixture.view, [record], [], true)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 100.0))))
	_deliver(fixture.view, _motion(Vector2(-20.0, -20.0)))
	var outside: Dictionary = fixture.view.get_render_observation()
	assert_equal(outside.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Outside pointer clears green hover")
	assert_equal(outside.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Outside pointer clears gold hover")
	var outside_frame = fixture.view.consume_input_frame()
	assert_equal(outside_frame.current_pointer_cell, Vector2i(-1, -1), "Outside motion frame carries invalid pointer cell")
	assert_false(outside_frame.current_pointer_inside_grid, "Outside motion frame carries false inside-grid fact")
	_present_endpoint(fixture.view, [record], [], true)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 100.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(2, 2), "Button-hover fixture starts with endpoint green")
	var nonendpoint_position := _local_for_logical(fixture.view, Vector2(140.0, 100.0))
	_deliver(fixture.view, _button(nonendpoint_position, MOUSE_BUTTON_LEFT, true))
	var nonendpoint_button: Dictionary = fixture.view.get_render_observation()
	assert_equal(nonendpoint_button.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Left button recomputes green at its nonendpoint position")
	assert_equal(nonendpoint_button.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Left button recomputes gold at its nonendpoint position")
	fixture.view.consume_input_frame()
	_deliver(fixture.view, _button(Vector2(-20.0, -20.0), MOUSE_BUTTON_LEFT, false))
	var outside_button: Dictionary = fixture.view.get_render_observation()
	assert_equal(outside_button.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Release outside clears green hover immediately")
	assert_equal(outside_button.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Release outside clears gold hover immediately")
	var outside_button_frame = fixture.view.consume_input_frame()
	assert_equal(outside_button_frame.current_pointer_cell, Vector2i(-1, -1), "Outside button frame carries invalid pointer cell")
	assert_false(outside_button_frame.current_pointer_inside_grid, "Outside button frame carries false inside-grid fact")
	_present_endpoint(fixture.view, [record], [], true, true)
	var completion_endpoint := _local_for_logical(fixture.view, Vector2(100.0, 100.0))
	_deliver(fixture.view, _button(completion_endpoint, MOUSE_BUTTON_LEFT, true))
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(140.0, 100.0))))
	_deliver(fixture.view, _button(completion_endpoint, MOUSE_BUTTON_RIGHT, true))
	_deliver(fixture.view, _button(_local_for_logical(fixture.view, Vector2(140.0, 100.0)), MOUSE_BUTTON_LEFT, false))
	fixture.view.present(_view_snapshot([record], [], SessionControllerScript.State.COMPLETED, true, false))
	var completed: Dictionary = fixture.view.get_render_observation()
	assert_equal(completed.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Completion clears green hover")
	assert_equal(completed.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Completion clears gold hover")
	assert_false(fixture.view._left_capture_active, "Completion clears view capture")
	assert_equal(fixture.view._crossed_cells, [], "Completion clears crossed cells")
	assert_false(fixture.view._left_pressed_pending, "Completion clears pending left press")
	assert_equal(fixture.view._left_press_cell, Vector2i(-1, -1), "Completion clears left press cell")
	assert_false(fixture.view._left_press_inside_grid, "Completion clears left press inside fact")
	assert_false(fixture.view._left_released_pending, "Completion clears pending left release")
	assert_false(fixture.view._right_pressed_pending, "Completion clears pending right press")
	assert_equal(fixture.view._right_press_cell, Vector2i(-1, -1), "Completion clears right press cell")
	assert_false(fixture.view._right_press_inside_grid, "Completion clears right press inside fact")
	assert_equal(fixture.view._previous_pointer_cell, Vector2i(-1, -1), "Completion clears previous pointer capture")
	assert_false(fixture.view._release_clears_capture, "Completion clears release capture state")
	assert_equal(fixture.view._live_gesture_path, [], "Completion clears live gesture path")
	assert_equal(fixture.view._release_live_gesture_path, [], "Completion clears release gesture path")
	assert_false(fixture.view._left_held, "Completion preserves physical release semantics")
	var completed_frame = fixture.view.consume_input_frame()
	assert_equal(completed_frame.crossed_cells, [], "Completed consume has no stale crossed cells")
	assert_false(completed_frame.left_pressed, "Completed consume has no stale left press")
	assert_false(completed_frame.left_released, "Completed consume has no stale left release")
	assert_false(completed_frame.right_pressed, "Completed consume has no stale right press")
	fixture.parent.free()


func _test_endpoint_reshape_snapshot_termination_clears_view_capture_and_buffer() -> void:
	print("Endpoint reshape: snapshot termination clears view capture and buffer")
	var fixture := _fixture()
	var view = fixture.view
	var endpoint := _local_for_logical(view, Vector2(20.0, 20.0))
	_present_endpoint(view, [], [], true, true)
	_deliver(view, _button(endpoint, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 20.0))))
	view.consume_input_frame()
	assert_true(view._left_capture_active, "View capture is active before snapshot termination")
	_present_endpoint(view, [], [], true, false)
	assert_false(view._left_capture_active, "Snapshot termination clears view capture")
	assert_equal(view._crossed_cells, [], "Snapshot termination clears crossed cells")
	assert_false(view._left_pressed_pending, "Snapshot termination clears pending press")
	assert_false(view._left_released_pending, "Snapshot termination clears pending release")
	assert_equal(view._live_gesture_path, [], "Snapshot termination clears live gesture path")
	assert_equal(view._release_live_gesture_path, [], "Snapshot termination clears release gesture path")
	_deliver(view, _motion(_local_for_logical(view, Vector2(140.0, 20.0))))
	assert_equal(view.consume_input_frame().crossed_cells, [], "Held motion remains ignored after termination")
	_deliver(view, _button(_local_for_logical(view, Vector2(140.0, 20.0)), MOUSE_BUTTON_LEFT, false))
	view.consume_input_frame()
	assert_false(view._left_held, "Physical release clears the held state")
	fixture.parent.free()


func _test_endpoint_reshape_no_green_negatives() -> void:
	print("Endpoint reshape: no-green negatives")
	var fixture := _fixture()
	var endpoint := _endpoint_record(Vector2i(2, 2))
	_present_endpoint(fixture.view, [endpoint], [], false)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 100.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Ineligible endpoint is not green")
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(140.0, 100.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Arbitrary nonendpoint is not green")
	var built_nonendpoint := _endpoint_record(Vector2i(3, 2), TrackCellRecordScript.State.BUILT, 2, 1.0)
	var built_endpoint := _endpoint_record(Vector2i(2, 2), TrackCellRecordScript.State.BUILT, 3, 2.0)
	_present_endpoint(
		fixture.view,
		[built_nonendpoint, built_endpoint],
		[_view_straight_piece(2, built_nonendpoint.cell, 1.0), _view_straight_piece(3, built_endpoint.cell, 2.0)],
		true
	)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(140.0, 100.0))))
	assert_equal(fixture.view._current_pointer_cell, built_nonendpoint.cell, "Built negative points at an actual nonendpoint route cell")
	assert_equal(fixture.view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Built nonendpoint is not green")
	var locked_nonendpoint := _endpoint_record(Vector2i(3, 2), TrackCellRecordScript.State.RESERVED_GHOST, 3, 1.0)
	locked_nonendpoint.geometry_locked = true
	var locked_endpoint := _endpoint_record(Vector2i(2, 2), TrackCellRecordScript.State.RESERVED_GHOST, 4, 2.0)
	var locked_nonendpoint_piece := _view_straight_piece(3, locked_nonendpoint.cell, 1.0)
	locked_nonendpoint_piece.locked = true
	_present_endpoint(
		fixture.view,
		[locked_nonendpoint, locked_endpoint],
		[locked_nonendpoint_piece, _view_straight_piece(4, locked_endpoint.cell, 2.0)],
		true
	)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(140.0, 100.0))))
	assert_equal(fixture.view._current_pointer_cell, locked_nonendpoint.cell, "Locked negative points at an actual nonendpoint route cell")
	assert_equal(fixture.view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Locked nonendpoint is not green")
	var inactive_endpoint := _endpoint_record(Vector2i(2, 2), TrackCellRecordScript.State.RESERVED_GHOST)
	var inactive_piece := _view_straight_piece(1, inactive_endpoint.cell)
	_present_endpoint(fixture.view, [inactive_endpoint], [inactive_piece], true, false, SessionControllerScript.State.PREPARING_DEPARTURE, false, Vector2.ZERO, false)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 100.0))))
	var inactive_observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(inactive_observation.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Inactive snapshot does not publish green hover")
	assert_equal(inactive_observation.get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Inactive snapshot does not publish gold hover")
	_deliver(fixture.view, _button(_local_for_logical(fixture.view, Vector2(100.0, 100.0)), MOUSE_BUTTON_LEFT, true))
	var inactive_button_observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(inactive_button_observation.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Inactive button position keeps green cleared")
	fixture.parent.free()
	var held_fixture := _fixture()
	var held_view = held_fixture.view
	var held_endpoint_position := _local_for_logical(held_view, Vector2(100.0, 100.0))
	_present_endpoint(held_view, [_endpoint_record(Vector2i(2, 2))], [], true)
	_deliver(held_view, _motion(held_endpoint_position))
	_deliver(held_view, _button(_local_for_logical(held_view, Vector2(140.0, 100.0)), MOUSE_BUTTON_LEFT, true))
	_deliver(held_view, _motion(held_endpoint_position))
	assert_equal(held_view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Held rejected nonendpoint press cannot publish endpoint green")
	_deliver(held_view, _button(held_endpoint_position, MOUSE_BUTTON_LEFT, false))
	assert_equal(held_view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(2, 2), "Released rejected press may publish endpoint green again")
	held_fixture.parent.free()


func _test_endpoint_reshape_locked_extendable_endpoint_is_green() -> void:
	print("Endpoint reshape: locked extendable endpoint is green")
	var fixture := _fixture()
	var endpoint := _endpoint_record(Vector2i(2, 2))
	endpoint.geometry_locked = true
	var piece := _view_straight_piece(1, endpoint.cell)
	piece.locked = true
	_present_endpoint(fixture.view, [endpoint], [piece], true)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 100.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(2, 2), "Locked endpoint with detached extension eligibility is green")
	fixture.parent.free()


func _test_endpoint_reshape_no_operation_endpoint_is_not_green() -> void:
	print("Endpoint reshape: no-operation endpoint is not green")
	var fixture := _fixture()
	var endpoint := _endpoint_record(Vector2i(2, 2))
	_present_endpoint(fixture.view, [endpoint], [], false)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 100.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "No-operation endpoint is not green")
	fixture.parent.free()


func _test_endpoint_reshape_whole_suffix_dependency_is_negative() -> void:
	print("Endpoint reshape: whole suffix dependency is negative")
	var fixture := _fixture()
	var clicked := _endpoint_record(Vector2i(2, 2), TrackCellRecordScript.State.RESERVED_GHOST, 10, 0.0)
	var clicked_piece := _view_straight_piece(10, clicked.cell, clicked.route_distance_start_cells)
	var built_suffix := _endpoint_record(Vector2i(3, 2), TrackCellRecordScript.State.BUILT, 11, 1.0)
	_assert_suffix_cancel_blocked(
		fixture.view, clicked, built_suffix, clicked_piece,
		_view_straight_piece(11, built_suffix.cell, built_suffix.route_distance_start_cells),
		"Built suffix blocks clicked-to-end gold cancellation"
	)
	var locked_record := _endpoint_record(Vector2i(3, 2), TrackCellRecordScript.State.RESERVED_GHOST, 21, 1.0)
	locked_record.geometry_locked = true
	_assert_suffix_cancel_blocked(
		fixture.view, clicked, locked_record, clicked_piece,
		_view_straight_piece(21, locked_record.cell, locked_record.route_distance_start_cells),
		"Geometry-locked suffix blocks clicked-to-end gold cancellation"
	)
	var locked_owner := _view_straight_piece(31, Vector2i(3, 2), 1.0)
	locked_owner.locked = true
	var locked_owner_record := _endpoint_record(Vector2i(3, 2), TrackCellRecordScript.State.RESERVED_GHOST, 31, 1.0)
	_assert_suffix_cancel_blocked(
		fixture.view, clicked, locked_owner_record, clicked_piece, locked_owner,
		"Locked owner suffix blocks clicked-to-end gold cancellation"
	)
	var exit_support_predecessor := _endpoint_record(Vector2i(1, 2), TrackCellRecordScript.State.BUILT, 40, 0.0)
	var exit_support_record := _endpoint_record(Vector2i(2, 2), TrackCellRecordScript.State.RESERVED_GHOST, 41, 1.0)
	var predecessor_piece := _view_straight_piece(40, exit_support_predecessor.cell, exit_support_predecessor.route_distance_start_cells)
	predecessor_piece.locked = true
	predecessor_piece.exit_support_route_serial = exit_support_record.route_serial
	var exit_support_piece := _view_straight_piece(41, exit_support_record.cell, exit_support_record.route_distance_start_cells)
	assert_equal(exit_support_record.route_serial, exit_support_predecessor.route_serial + 1, "Exit-support fixture uses an immediately following route serial")
	assert_equal(exit_support_record.route_distance_start_cells, exit_support_predecessor.route_distance_start_cells + 1.0, "Exit-support fixture uses an immediately following route distance")
	assert_equal(exit_support_record.cell, exit_support_predecessor.cell + Vector2i(1, 0), "Exit-support fixture uses an immediately adjacent route cell")
	_present_endpoint(
		fixture.view, [exit_support_predecessor, exit_support_record], [predecessor_piece, exit_support_piece], true
	)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(100.0, 100.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Exit-support dependency blocks whole suffix cancellation")
	fixture.parent.free()


func _assert_suffix_cancel_blocked(
	view,
	clicked: TrackCellRecordScript,
	suffix: TrackCellRecordScript,
	clicked_piece: TrackGeometryPieceScript,
	suffix_piece: TrackGeometryPieceScript,
	message: String,
	extra_pieces: Array[TrackGeometryPieceScript] = []
) -> void:
	var pieces: Array[TrackGeometryPieceScript] = extra_pieces.duplicate()
	pieces.append(clicked_piece)
	pieces.append(suffix_piece)
	_present_endpoint(view, [clicked, suffix], pieces, true)
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 100.0))))
	assert_equal(view.get_render_observation().get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(-1, -1), message)


func _test_endpoint_reshape_mouse_exit_clears_pointer_facts() -> void:
	var fixture := _fixture()
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(20.0, 20.0))))
	fixture.view.call("_notification", 42)
	var frame = fixture.view.consume_input_frame()
	assert_equal(frame.current_pointer_cell, Vector2i(-1, -1), "Mouse exit clears current pointer cell")
	assert_false(frame.current_pointer_inside_grid, "Mouse exit clears current pointer inside-grid fact")
	fixture.parent.free()


func _test_endpoint_reshape_train_occupied_endpoint_is_not_green() -> void:
	var fixture := _fixture()
	var endpoint := Vector2i(2, 2)
	var endpoint_position := Vector2(100.0, 100.0)
	_present_endpoint(fixture.view, [_endpoint_record(endpoint)], [], true, false, SessionControllerScript.State.RUNNING, true, endpoint_position)
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, endpoint_position)))
	var observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(observation.get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Train occupying endpoint suppresses green hover")
	fixture.parent.free()


func _test_endpoint_reshape_actual_abort_clears_and_allows_fresh_press() -> void:
	var fixture := _fixture()
	var view = fixture.view
	var endpoint := _local_for_logical(view, Vector2(20.0, 20.0))
	_present_endpoint(view, [], [], true, false)
	_deliver(view, _button(endpoint, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(100.0, 20.0))))
	var held_frame = view.consume_input_frame()
	assert_true(held_frame.left_pressed, "Abort fixture emits a real left press")
	assert_true(view._left_capture_active, "Abort fixture captures the real view gesture")
	var system = TrackSystemScript.new(_config())
	system.apply_left_input(held_frame)
	assert_true(system.is_runtime_gesture_active(), "Abort fixture starts a real domain gesture")
	assert_true(system.is_left_capture_active(), "Abort fixture has facade capture before right abort")
	assert_true(view._left_capture_active, "Abort fixture has view capture before right abort")
	view.present(_snapshot_for_track(system))
	_deliver(view, _button(endpoint, MOUSE_BUTTON_RIGHT, true))
	var right_frame = view.consume_input_frame()
	assert_true(system.apply_right_input(right_frame), "Abort fixture routes the real right edge")
	assert_false(system.is_runtime_gesture_active(), "Abort fixture terminates the real domain gesture")
	assert_false(system.is_left_capture_active(), "Abort fixture clears facade capture before physical release")
	view.present(_snapshot_for_track(system))
	assert_false(view._left_capture_active, "Actual abort clears view capture")
	assert_equal(view._crossed_cells, [], "Actual abort clears view buffer")
	assert_false(view._left_pressed_pending, "Actual abort clears pending left press")
	assert_false(view._left_released_pending, "Actual abort clears pending left release")
	assert_false(view._right_pressed_pending, "Actual abort clears pending right press")
	assert_equal(view._left_press_cell, Vector2i(-1, -1), "Actual abort clears left press cell")
	assert_equal(view._right_press_cell, Vector2i(-1, -1), "Actual abort clears right press cell")
	assert_equal(view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Held abort pointer does not republish green")
	var aborted_endpoint := system.get_endpoint_cell()
	_deliver(view, _motion(_local_for_cell(view, aborted_endpoint)))
	assert_equal(view.consume_input_frame().crossed_cells, [], "Held motion after actual abort is ignored")
	var release_position := _local_for_cell(view, aborted_endpoint)
	_deliver(view, _button(release_position, MOUSE_BUTTON_LEFT, false))
	assert_equal(view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), aborted_endpoint, "Released abort pointer may republish endpoint green")
	var release_frame = view.consume_input_frame()
	system.apply_left_input(release_frame)
	assert_false(view._left_held, "Physical release clears the view held latch after abort")
	assert_false(system.is_runtime_gesture_active(), "Physical release clears the domain gesture latch after abort")
	var fresh_endpoint := system.get_endpoint_cell()
	var fresh_baseline_records := system.get_cell_records()
	var fresh_baseline_cells := _record_cells(fresh_baseline_records)
	var fresh_position := _local_for_cell(view, fresh_endpoint)
	var fresh_next_position := _local_for_cell(view, fresh_endpoint + Vector2i(1, 0))
	_deliver(view, _button(fresh_position, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(fresh_next_position))
	var fresh_frame = view.consume_input_frame()
	system.apply_left_input(fresh_frame)
	assert_true(fresh_frame.left_pressed, "Fresh press after actual abort is observable")
	assert_true(system.is_runtime_gesture_active(), "Fresh legal motion starts a new domain gesture after abort")
	var fresh_candidate_records := system.get_cell_records()
	assert_equal(fresh_candidate_records.size(), fresh_baseline_records.size() + 1, "Fresh abort gesture publishes one new record")
	assert_equal(_record_cells(fresh_candidate_records), fresh_baseline_cells + [fresh_endpoint + Vector2i(1, 0)], "Fresh abort gesture publishes the legal adjacent cell")
	assert_equal(system.get_endpoint_cell(), fresh_endpoint + Vector2i(1, 0), "Fresh abort gesture changes the endpoint")
	fixture.parent.free()


func _test_endpoint_reshape_actual_train_preparation_clears_and_allows_fresh_press() -> void:
	var fixture := _fixture()
	var view = fixture.view
	var config := _config()
	var system = TrackSystemScript.new(config)
	var endpoint := _local_for_logical(view, Vector2(20.0, 20.0))
	_present_endpoint(view, [], [], true, false)
	_deliver(view, _button(endpoint, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(60.0, 20.0))))
	var held_frame = view.consume_input_frame()
	system.apply_left_input(held_frame)
	assert_true(system.is_runtime_gesture_active(), "Preparation fixture starts a real domain gesture")
	assert_true(system.is_left_capture_active(), "Preparation fixture has facade capture before train preparation")
	assert_true(view._left_capture_active, "Preparation fixture has view capture before train preparation")
	view.present(_snapshot_for_track(system))
	assert_true(system.prepare_for_train_sampling(0.0, 1.0), "Preparation fixture performs real overlapping preparation")
	assert_false(system.is_runtime_gesture_active(), "Preparation fixture terminates the real domain gesture")
	assert_false(system.is_left_capture_active(), "Preparation fixture clears facade capture before physical release")
	view.present(_snapshot_for_track(system))
	assert_false(view._left_capture_active, "Actual preparation clears view capture")
	assert_equal(view._crossed_cells, [], "Actual preparation clears view buffer")
	assert_false(view._left_pressed_pending, "Actual preparation clears pending left press")
	assert_false(view._left_released_pending, "Actual preparation clears pending left release")
	assert_false(view._right_pressed_pending, "Actual preparation clears pending right press")
	assert_equal(view._left_press_cell, Vector2i(-1, -1), "Actual preparation clears left press cell")
	assert_equal(view._right_press_cell, Vector2i(-1, -1), "Actual preparation clears right press cell")
	var prepared_endpoint := system.get_endpoint_cell()
	_deliver(view, _motion(_local_for_cell(view, prepared_endpoint)))
	assert_equal(view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Held preparation pointer does not republish green")
	assert_equal(view.consume_input_frame().crossed_cells, [], "Held motion after preparation is ignored")
	var release_position := _local_for_cell(view, prepared_endpoint)
	_deliver(view, _button(release_position, MOUSE_BUTTON_LEFT, false))
	assert_equal(view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), prepared_endpoint, "Released preparation pointer may republish endpoint green")
	var release_frame = view.consume_input_frame()
	system.apply_left_input(release_frame)
	assert_false(view._left_held, "Physical release clears the view held latch after preparation")
	assert_false(system.is_runtime_gesture_active(), "Physical release leaves the domain gesture inactive after preparation")
	var fresh_endpoint := system.get_endpoint_cell()
	var fresh_baseline_records := system.get_cell_records()
	var fresh_baseline_cells := _record_cells(fresh_baseline_records)
	var fresh_position := _local_for_cell(view, fresh_endpoint)
	var fresh_next_position := _local_for_cell(view, fresh_endpoint + Vector2i(1, 0))
	_deliver(view, _button(fresh_position, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(fresh_next_position))
	var fresh_frame = view.consume_input_frame()
	system.apply_left_input(fresh_frame)
	assert_true(fresh_frame.left_pressed, "Fresh press after preparation is observable")
	assert_true(system.is_runtime_gesture_active(), "Fresh legal motion starts a new domain gesture after preparation")
	var fresh_candidate_records := system.get_cell_records()
	assert_equal(fresh_candidate_records.size(), fresh_baseline_records.size() + 1, "Fresh preparation gesture publishes one new record")
	assert_equal(_record_cells(fresh_candidate_records), fresh_baseline_cells + [fresh_endpoint + Vector2i(1, 0)], "Fresh preparation gesture publishes the legal adjacent cell")
	assert_equal(system.get_endpoint_cell(), fresh_endpoint + Vector2i(1, 0), "Fresh preparation gesture changes the endpoint")
	fixture.parent.free()


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


func _test_exact_center_local_corner_presentation() -> void:
	var fixture := _fixture()
	var runtime := GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(runtime.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	]), 5, "Exact-center presentation fixture appends the excessive 3x3 route")
	var anchor = RouteContactAnchorScript.new(&"view_exact", Vector2i(2, 0))
	anchor.contact_mode = RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER
	runtime.set_contact_anchors([anchor])
	var records: Array[TrackCellRecordScript] = runtime.get_cell_records()
	var pieces: Array[TrackGeometryPieceScript] = runtime.get_geometry_pieces()
	var owner := _runtime_piece_for_serial(pieces, 3)
	assert_not_null(owner, "Exact-center presentation fixture has one owner")
	if owner == null:
		fixture.parent.free()
		return
	assert_equal(
		owner.kind,
		TrackGeometryPieceScript.Kind.CURVE_3X3,
		"Exact-center presentation retains the accepted 3x3 owner"
	)
	fixture.view.present(_view_snapshot(records, pieces))
	var observation: Dictionary = fixture.view.get_render_observation()
	assert_equal(
		observation.get("intervals", []).size(),
		records.size(),
		"Presentation retains one detached interval per owned route serial"
	)
	var interval := _view_interval_for_serial(observation, 3)
	assert_false(interval.is_empty(), "Presentation exposes the exact-anchor cell interval")
	if interval.is_empty():
		fixture.parent.free()
		return
	assert_equal(interval.route_serial, 3, "Presentation retains the anchored route serial")
	assert_equal(interval.piece_group_id, owner.group_id, "Presentation retains owner identity")
	assert_equal(interval.state, records[2].state, "Presentation retains construction state")
	assert_equal(interval.locked, owner.locked, "Presentation retains lock state")
	var points: PackedVector2Array = interval.points
	assert_equal(points.size(), 9, "Presentation samples each nominal cell at one-eighth cadence")
	if points.size() != 9:
		fixture.parent.free()
		return
	var exact_center := Vector2(100.0, 20.0)
	assert_true(
		points[4].distance_to(exact_center) <= 0.0001,
		"Presentation retains the literal exact center at the interval midpoint"
	)
	assert_true(
		_three_points_are_forward_collinear(points[0], points[1], points[2]),
		"Presentation keeps the distant incoming samples straight"
	)
	assert_true(
		_three_points_are_forward_collinear(points[6], points[7], points[8]),
		"Presentation keeps the distant outgoing samples straight"
	)
	assert_true(
		absf((points[3] - points[2]).cross(points[4] - points[3])) > 0.0001,
		"Presentation captures the incoming half of the local exact-center bend"
	)
	assert_true(
		absf((points[5] - points[4]).cross(points[6] - points[5])) > 0.0001,
		"Presentation captures the outgoing half of the local exact-center bend"
	)
	points[4] += Vector2(999.0, 999.0)
	var replay_interval := _view_interval_for_serial(
		fixture.view.get_render_observation(), 3
	)
	assert_true(
		PackedVector2Array(replay_interval.points)[4].distance_to(exact_center) <= 0.0001,
		"Presented interval points are detached from the stored render observation"
	)
	fixture.parent.free()


func _test_unanchored_local_corner_presentation() -> void:
	var fixture := _fixture()
	var runtime := GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(runtime.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2),
	]), 5, "Warp-free presentation fixture appends the reported 3x3 route")
	var records: Array[TrackCellRecordScript] = runtime.get_cell_records()
	var pieces: Array[TrackGeometryPieceScript] = runtime.get_geometry_pieces()
	var owner := _runtime_piece_for_serial(pieces, 3)
	assert_not_null(owner, "Warp-free presentation fixture has one curve owner")
	if owner == null:
		fixture.parent.free()
		return
	assert_equal(owner.kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Warp-free presentation retains 3x3 ownership")
	assert_equal(owner.centerline.size(), 81, "Warp-free presentation receives fixed-count local-corner samples")
	fixture.view.present(_view_snapshot(records, pieces))
	var observation: Dictionary = fixture.view.get_render_observation()
	for index in range(records.size()):
		var interval := _view_interval_for_serial(
			observation, records[index].route_serial
		)
		assert_false(interval.is_empty(), "Warp-free presentation exposes each owned interval")
		if interval.is_empty():
			continue
		var points := PackedVector2Array(interval.points)
		assert_equal(points.size(), 9, "Presentation keeps one-eighth nominal cadence")
		if points.size() != 9:
			continue
		var enters_owned_cell := false
		for point in points:
			var point_cell := Vector2i(
				int(floor(point.x / 40.0)), int(floor(point.y / 40.0))
			)
			if point_cell == records[index].cell:
				enters_owned_cell = true
				break
		assert_true(
			enters_owned_cell,
			"Presented route serial %d enters its owned route cell"
				% records[index].route_serial
		)
		if index == 2:
			assert_true(
				_points_contain_bend(points),
				"Presentation confines the local bend to the actual turn interval"
			)
		else:
			for point_index in range(points.size() - 2):
				assert_true(
					_three_points_are_forward_collinear(
						points[point_index], points[point_index + 1], points[point_index + 2]
					),
					"Non-turn interval %d remains straight" % records[index].route_serial
				)
	fixture.parent.free()


func _test_ordinary_provisional_ghost_keeps_cancel_hover() -> void:
	var fixture := _fixture()
	var runtime := GridTrackRuntimeScript.new(Vector2i(0, 0), 18, Vector2.ZERO, Vector2i(30, 14), 40.0)
	assert_equal(runtime.append_cells([Vector2i(1, 0), Vector2i(2, 0)]), 2, "Runtime creates an all-ghost suffix")
	var records: Array[TrackCellRecordScript] = runtime.get_cell_records()
	var pieces: Array[TrackGeometryPieceScript] = runtime.get_geometry_pieces()
	fixture.view.present(_view_snapshot(records, pieces))
	_deliver(fixture.view, _motion(_local_for_logical(fixture.view, Vector2(60.0, 20.0))))
	assert_equal(fixture.view.get_render_observation().get("hover_cancel_cell", Vector2i(-1, -1)), Vector2i(1, 0), "Ordinary provisional ghost has cancel hover")
	var available_before := runtime.get_available_track_cells()
	assert_true(runtime.cancel_ghost_suffix(Vector2i(1, 0)), "Runtime cancels the observed ghost suffix")
	assert_equal(runtime.get_cell_records().size(), 0, "Actual cancellation removes the clicked-to-end suffix")
	assert_equal(runtime.get_available_track_cells(), available_before + 2, "Actual cancellation refunds every suffix cell")
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
	assert_true(right.right_press_position_available, "Inside right press retains its exact logical position")
	assert_true(right.right_press_position_units.distance_to(Vector2(100.0, 60.0)) <= 0.001, "Inside right press preserves logical pointer units")
	assert_false(view.consume_input_frame().right_pressed, "Right edge clears after consume")
	var outside_right_position := Vector2(-20.0, -20.0)
	_deliver(view, _button(outside_right_position, MOUSE_BUTTON_RIGHT, true))
	var outside_right = view.consume_input_frame()
	assert_true(outside_right.right_pressed, "Outside right press still emits one edge")
	assert_false(outside_right.right_press_inside_grid, "Outside right press carries a false inside-grid fact")
	assert_equal(outside_right.right_press_cell, Vector2i(-1, -1), "Outside right press carries an invalid cell")
	assert_false(outside_right.right_press_position_available, "Outside right press exposes no selectable logical position")
	assert_equal(outside_right.current_pointer_cell, Vector2i(-1, -1), "Outside right press clears current pointer cell")
	assert_false(outside_right.current_pointer_inside_grid, "Outside right press clears current pointer inside-grid fact")
	_deliver(view, _button(outside_right_position, MOUSE_BUTTON_RIGHT, false))
	var outside_right_release = view.consume_input_frame()
	assert_false(outside_right_release.right_pressed, "Outside right release does not create a duplicate edge")
	assert_equal(outside_right_release.current_pointer_cell, Vector2i(-1, -1), "Outside right release keeps an invalid pointer cell")
	assert_false(outside_right_release.current_pointer_inside_grid, "Outside right release keeps a false inside-grid fact")
	fixture.parent.free()


func _test_crossing_interval_exposes_primitive_gap_identity() -> void:
	var fixture := _fixture()
	var earlier := _endpoint_record(Vector2i(2, 2), TrackCellRecordScript.State.BUILT, 1, 0.0)
	var later := _endpoint_record(Vector2i(2, 2), TrackCellRecordScript.State.RESERVED_GHOST, 2, 1.0)
	later.grade_separated_crossing = true
	later.crossing_partner_route_serial = 1
	var horizontal := _view_straight_piece(1, Vector2i(2, 2), 0.0)
	var vertical := _view_straight_piece(2, Vector2i(2, 2), 1.0)
	var center := Vector2(100.0, 100.0)
	vertical.centerline = PackedVector2Array([
		center - Vector2(0.0, 20.0),
		center + Vector2(0.0, 20.0),
	])
	_present_endpoint(fixture.view, [earlier, later], [horizontal, vertical], true)
	var observation: Dictionary = fixture.view.get_render_observation()
	var interval := _view_interval_for_serial(observation, 2)
	assert_true(interval.get("grade_separated_crossing", false), "Later crossing interval retains primitive overpass identity")
	var gap_points: PackedVector2Array = fixture.view.call(
		"_crossing_gap_points",
		interval.get("points", PackedVector2Array())
	)
	assert_true(gap_points.size() >= 2, "Crossing interval produces a minimal visible gap primitive")
	fixture.parent.free()


func _test_held_reentry_preserves_intermediate_cells_across_frames() -> void:
	var fixture := _fixture(
		Vector2.ZERO,
		Vector2(1000.0, 700.0),
		_config(Vector2i(4, 4), 40.0, Vector2.ZERO, Vector2i(3, 1))
	)
	var view = fixture.view
	var start := _local_for_logical(view, Vector2(140.0, 60.0))
	_deliver(view, _button(start, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(_local_for_logical(view, Vector2(180.0, 60.0))))
	var outside_frame = view.consume_input_frame()
	assert_equal(outside_frame.crossed_cells, [], "Leaving the grid emits no outside cell")
	assert_false(outside_frame.current_pointer_inside_grid, "The held pointer reports its outside state")

	_deliver(view, _motion(_local_for_logical(view, Vector2(140.0, 140.0))))
	var reentry_frame = view.consume_input_frame()
	assert_equal(
		reentry_frame.crossed_cells,
		[Vector2i(3, 2), Vector2i(3, 3)],
		"A held outside-to-inside segment preserves intermediate cells after a frame boundary"
	)
	assert_equal(
		reentry_frame.live_gesture_path,
		[Vector2i(3, 2), Vector2i(3, 3)],
		"The live candidate receives the same continuous reentry path"
	)
	_deliver(view, _button(_local_for_logical(view, Vector2(140.0, 140.0)), MOUSE_BUTTON_LEFT, false))
	view.consume_input_frame()
	fixture.parent.free()


func _test_held_reentry_gap_grants_bounded_connection_authority() -> void:
	var fixture := _fixture(
		Vector2.ZERO,
		Vector2(1000.0, 700.0),
		_config(Vector2i(8, 8), 40.0, Vector2.ZERO, Vector2i(1, 1))
	)
	var view = fixture.view
	var press := _local_for_logical(view, Vector2(60.0, 60.0))
	var first := _local_for_logical(view, Vector2(100.0, 60.0))
	var outside_first := _local_for_logical(view, Vector2(340.0, 60.0))
	var outside_second := _local_for_logical(view, Vector2(340.0, 220.0))
	var reentry := _local_for_logical(view, Vector2(300.0, 220.0))
	_deliver(view, _button(press, MOUSE_BUTTON_LEFT, true))
	_deliver(view, _motion(first))
	_deliver(view, _motion(outside_first))
	_deliver(view, _motion(outside_second))
	_deliver(view, _motion(reentry))
	var held = view.consume_input_frame()
	assert_equal(
		held.live_gesture_path,
		[
			Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
			Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1),
			Vector2i(7, 5),
		],
		"Real held reentry preserves the raw observed gap for runtime normalization"
	)
	assert_true(
		_object_has_property(held, &"allows_bounded_reentry_connection"),
		"Real view frames expose bounded reentry authority"
	)
	if _object_has_property(held, &"allows_bounded_reentry_connection"):
		assert_true(
			bool(held.get(&"allows_bounded_reentry_connection")),
			"Real view capture grants bounded reentry authority"
		)
	_deliver(view, _button(reentry, MOUSE_BUTTON_LEFT, false))
	var released = view.consume_input_frame()
	assert_equal(
		released.release_live_gesture_path,
		[
			Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
			Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1),
			Vector2i(7, 5),
		],
		"Release retains a detached copy of the raw reentry gap"
	)
	if _object_has_property(released, &"allows_bounded_reentry_connection"):
		assert_true(
			bool(released.get(&"allows_bounded_reentry_connection")),
			"Detached release preserves real-view reentry authority"
		)
	fixture.parent.free()


func _object_has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if StringName(property["name"]) == property_name:
			return true
	return false


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
