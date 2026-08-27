extends SceneTree

const SHELL_SCENE_PATH := "res://src/presentation/session/session_shell.tscn"
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")
const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _config() -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		123, 120.0, 60,
		1.0, 10, 2, 3.0, 60.0, 1,
		Vector2(800.0, 400.0), Vector2i(20, 10), 40.0, Vector2.ZERO,
		&"departure_01", Vector2(100.0, 100.0), Vector2i(2, 2)
	)


func _logical_to_viewport(view, logical: Vector2) -> Vector2:
	var content: Rect2 = view.get_logical_content_rect()
	var local := content.position + logical / Vector2(800.0, 400.0) * content.size
	return view.get_global_transform_with_canvas() * local


func _button(position: Vector2, button: int, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = button
	event.pressed = pressed
	if pressed and button == MOUSE_BUTTON_LEFT:
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
	elif pressed and button == MOUSE_BUTTON_RIGHT:
		event.button_mask = MOUSE_BUTTON_MASK_RIGHT
	return event


func _motion(position: Vector2, button_mask: int = 0) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.button_mask = button_mask
	return event


func _deliver(event: InputEvent) -> void:
	root.push_input(event, true)
	await process_frame


func _consume(shell, track):
	await physics_frame
	var frame = shell.consume_track_input_frame()
	var right_won: bool = track.apply_right_input(frame)
	if not right_won:
		track.apply_left_input(frame)
	return frame


func _consume_view(shell, track = null):
	await physics_frame
	var frame = shell.consume_track_input_frame()
	if track != null:
		var right_won: bool = track.apply_right_input(frame)
		if not right_won:
			track.apply_left_input(frame)
	return frame


func _release_view(shell, position: Vector2) -> void:
	await _deliver(_button(position, MOUSE_BUTTON_LEFT, false))


func _release(shell, track, position: Vector2) -> void:
	await _deliver(_button(position, MOUSE_BUTTON_LEFT, false))
	await _consume(shell, track)


func _track_snapshot(track, state: int = SessionControllerScript.State.PREPARING_DEPARTURE) -> SessionSnapshotScript:
	return SessionSnapshotScript.new(
		1, 0, 1, 60, true, state, track.get_cell_records(), track.get_geometry_pieces(),
		track.get_contact_observations(), track.get_built_end_distance_cells(),
		track.get_available_track_cells(), track.get_total_track_cells(), track.get_grid_origin_units(),
		0, 2, 0.0, false, 0.0, Vector2.ZERO, Vector2.RIGHT, 0.0, false,
		&"integration", Vector2i(2, 2), track.is_endpoint_gesture_eligible(),
		track.is_runtime_gesture_active()
	)


func _record_facts(records: Array) -> Array:
	var facts: Array = []
	for record in records:
		facts.append({
			"serial": record.route_serial,
			"cell": record.cell,
			"distance": record.route_distance_start_cells,
			"state": record.state,
			"progress": record.build_progress,
			"group": record.geometry_group_id,
			"locked": record.geometry_locked,
		})
	return facts


func _record_content_facts(records: Array) -> Array:
	var facts := _record_facts(records)
	for fact in facts:
		fact.erase("group")
		fact.erase("locked")
	return facts


func _record_cells(facts: Array) -> Array:
	var cells: Array = []
	for fact in facts:
		cells.append(fact["cell"])
	return cells


func _piece_facts(pieces: Array, include_lock_metadata := true) -> Array:
	var facts: Array = []
	for piece in pieces:
		var fact := {
			"first_serial": piece.first_route_serial,
			"last_serial": piece.last_route_serial,
			"group": piece.group_id,
			"kind": piece.kind,
			"distance": piece.absolute_start_distance_cells,
			"length": piece.nominal_length_cells,
			"footprint": Array(piece.footprint_cells),
			"centerline": Array(piece.centerline),
			"active_start": piece.active_local_start_cells,
			"active_end": piece.active_local_end_cells,
		}
		if include_lock_metadata:
			fact["locked"] = piece.locked
			fact["exit_support"] = piece.exit_support_route_serial
		facts.append(fact)
	return facts


func _track_facts(track) -> Dictionary:
	return {
		"records": _record_facts(track.get_cell_records()),
		"pieces": _piece_facts(track.get_geometry_pieces()),
		"contacts": track.get_contact_observations(),
		"available": track.get_available_track_cells(),
		"endpoint": track.get_endpoint_cell(),
	}


func _track_geometry_facts(track) -> Array:
	var facts := _piece_facts(track.get_geometry_pieces(), false)
	for fact in facts:
		fact.erase("group")
	return facts


func _piece_fact_for_serial(pieces: Array, route_serial: int) -> Dictionary:
	for piece in pieces:
		if route_serial >= piece["first_serial"] and route_serial <= piece["last_serial"]:
			return piece
	return {}


func _assert_view_termination_clean(view, prefix: String) -> void:
	_assert_true(not view._left_capture_active, "%s clears view capture" % prefix)
	_assert_equal(view._crossed_cells, [], "%s clears crossed cells" % prefix)
	_assert_true(not view._left_pressed_pending, "%s clears pending left press" % prefix)
	_assert_true(not view._left_released_pending, "%s clears pending left release" % prefix)
	_assert_true(not view._right_pressed_pending, "%s clears pending right press" % prefix)
	_assert_equal(view._left_press_cell, Vector2i(-1, -1), "%s clears left press cell" % prefix)
	_assert_equal(view._right_press_cell, Vector2i(-1, -1), "%s clears right press cell" % prefix)
	_assert_true(not view._left_press_inside_grid, "%s clears left press inside fact" % prefix)
	_assert_true(not view._right_press_inside_grid, "%s clears right press inside fact" % prefix)
	_assert_equal(view._previous_pointer_cell, Vector2i(-1, -1), "%s clears previous pointer" % prefix)
	_assert_true(not view._release_clears_capture, "%s clears release capture state" % prefix)


func _train_cell(config: SessionStartConfigScript, position: Vector2) -> Vector2i:
	var cell_size := config.grid_cell_size_units
	return Vector2i(floor((position - config.grid_origin_units) / Vector2(cell_size, cell_size)))


func _preparation_metadata_transition_is_expected(before: Dictionary, after: Dictionary) -> bool:
	var before_records: Array = before["records"]
	var after_records: Array = after["records"]
	if before_records.size() != after_records.size():
		return false
	for index in range(before_records.size()):
		var before_record: Dictionary = before_records[index]
		var after_record: Dictionary = after_records[index]
		for key in ["serial", "cell", "distance", "state", "progress"]:
			if before_record[key] != after_record[key]:
				return false
		if before_record["locked"]:
			if not after_record["locked"] or before_record["group"] != after_record["group"]:
				return false
		elif not after_record["locked"]:
			if before_record["group"] != after_record["group"]:
				return false
	var before_pieces: Array = before["pieces"]
	var after_pieces: Array = after["pieces"]
	if before_pieces.size() != after_pieces.size():
		return false
	var expected_newly_locked := 0
	var actual_newly_locked := 0
	var locked_groups: Dictionary = {}
	for index in range(before_pieces.size()):
		var before_piece: Dictionary = before_pieces[index]
		var after_piece: Dictionary = after_pieces[index]
		for key in [
			"first_serial", "last_serial", "kind", "distance", "length", "footprint",
			"centerline", "active_start", "active_end"
		]:
			if before_piece[key] != after_piece[key]:
				return false
		if not before_piece["locked"]:
			expected_newly_locked += 1
			if not after_piece["locked"]:
				return false
			if int(after_piece["group"]) < 0:
				return false
			var last_record_index := -1
			for record_index in range(after_records.size()):
				if int(after_records[record_index]["serial"]) == int(after_piece["last_serial"]):
					last_record_index = record_index
					break
			if last_record_index < 0:
				return false
			if last_record_index == after_records.size() - 1:
				if int(after_piece["exit_support"]) != -1:
					return false
			elif int(after_piece["exit_support"]) >= 0 \
				and int(after_piece["exit_support"]) != int(after_records[last_record_index + 1]["serial"]):
				return false
		else:
			if before_piece["group"] != after_piece["group"] \
				or before_piece["locked"] != after_piece["locked"] \
				or before_piece["exit_support"] != after_piece["exit_support"]:
				return false
		if after_piece["locked"]:
			if locked_groups.has(after_piece["group"]):
				return false
			locked_groups[after_piece["group"]] = true
		if before_piece["locked"] != after_piece["locked"]:
			actual_newly_locked += 1
	if actual_newly_locked != expected_newly_locked:
		return false
	for index in range(after_records.size()):
		var before_record: Dictionary = before_records[index]
		var after_record: Dictionary = after_records[index]
		var owner := _piece_fact_for_serial(after_pieces, int(after_record["serial"]))
		if owner.is_empty():
			return false
		if owner["locked"]:
			if not after_record["locked"] or after_record["group"] != owner["group"]:
				return false
			var before_owner := _piece_fact_for_serial(before_pieces, int(before_record["serial"]))
			if not before_owner.is_empty() and before_owner["locked"]:
				if before_record["group"] != after_record["group"] \
					or before_record["locked"] != after_record["locked"]:
					return false
		else:
			if before_record["group"] != after_record["group"] \
				or before_record["locked"] != after_record["locked"]:
				return false
	return true


func _run() -> void:
	var packed = load(SHELL_SCENE_PATH) as PackedScene
	_assert_true(packed != null, "Session shell scene loads")
	if packed == null:
		await _finish(null)
		return
	var shell = packed.instantiate()
	root.add_child(shell)
	await process_frame
	var config := _config()
	shell.get_track_field_view().get_logical_track_field().size_preset = 3
	shell.get_track_field_view().get_logical_track_field().custom_width = 800.0
	shell.get_track_field_view().get_logical_track_field().custom_height = 400.0
	shell.get_track_field_view().get_logical_track_field().custom_grid_columns = 20
	shell.get_track_field_view().get_logical_track_field().custom_grid_rows = 10
	shell.configure(UILayoutProfileScript.new(), SessionSnapshotScript.new(10800, 0, 10800, 60), config)
	await process_frame
	await process_frame
	var view = shell.get_track_field_view()
	var departure := _logical_to_viewport(view, Vector2(100.0, 100.0))

	var running_track := TrackSystemScript.new(config)
	var running_train := TrainSystemScript.new(config.train_speed_cells_per_second)
	var running_controller := SessionControllerScript.new(config, running_track, running_train)
	running_controller.start()
	view.present(running_controller.get_snapshot())
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var running_frame = await _consume_view(shell)
	running_controller.advance_tick(running_frame)
	await _release_view(shell, _logical_to_viewport(view, Vector2(220.0, 100.0)))
	var running_release = await _consume_view(shell)
	running_controller.advance_tick(running_release)
	for _tick in range(100):
		running_controller.advance_tick()
	var running_snapshot: SessionSnapshotScript = running_controller.get_snapshot()
	view.present(running_snapshot)
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0))))
	var endpoint_observation: Dictionary = view.get_render_observation()
	var running_train_cell := _train_cell(config, running_snapshot.get_train_position())
	var running_endpoint := running_track.get_endpoint_cell()
	var running_train_cell_inside := running_train_cell.x >= 0 and running_train_cell.y >= 0 \
		and running_train_cell.x < config.grid_size.x and running_train_cell.y < config.grid_size.y
	_assert_true(running_snapshot.get_state() == SessionControllerScript.State.RUNNING, "Running fixture publishes RUNNING state")
	_assert_true(running_snapshot.is_train_active(), "Running fixture publishes an active train")
	_assert_true(running_train_cell_inside, "Running train cell is inside the configured grid")
	_assert_true(running_train_cell != running_endpoint, "Running train cell is distinct from the endpoint")
	var running_green: bool = endpoint_observation.get("hover_extend_cell", Vector2i(-1, -1)) == Vector2i(5, 2)
	_assert_true(running_green, "Endpoint reshape integration assertion failed endpoint green")
	if running_green:
		print("PASS: Endpoint reshape integration running endpoint green")

	var overlap_track := TrackSystemScript.new(config)
	var overlap_frame := TrackInputFrameScript.new(
		[Vector2i(3, 2)], Vector2i(2, 2), true, Vector2i(-1, -1), false,
		true, false, true, false, Vector2i(3, 2), true
	)
	overlap_track.apply_left_input(overlap_frame)
	var overlap_snapshot: SessionSnapshotScript = _track_snapshot(overlap_track)
	view.present(overlap_snapshot)
	await _deliver(_motion(_logical_to_viewport(view, Vector2(140.0, 100.0))))
	var overlap_observation: Dictionary = view.get_render_observation()
	var overlap_green: bool = overlap_observation.get("hover_extend_cell", Vector2i(-1, -1)) == Vector2i(3, 2) \
		and overlap_observation.get("hover_cancel_cell", Vector2i(-1, -1)) == Vector2i(3, 2)
	_assert_true(overlap_green, "Endpoint reshape integration assertion failed overlap endpoint green")
	if overlap_green:
		print("PASS: Endpoint reshape integration overlap endpoint green")
	await _deliver(_button(_logical_to_viewport(view, Vector2(140.0, 100.0)), MOUSE_BUTTON_RIGHT, true))
	var overlap_right: TrackInputFrameScript = await _consume_view(shell, overlap_track)
	var overlap_cancelled: bool = overlap_right.right_pressed and overlap_track.get_cell_records().is_empty()
	_assert_true(overlap_cancelled, "Overlap endpoint retains real right-click cancellation")

	var abort_track := TrackSystemScript.new(config)
	var abort_controller := SessionControllerScript.new(config, abort_track, TrainSystemScript.new(config.train_speed_cells_per_second))
	abort_controller.start()
	view.present(abort_controller.get_snapshot())
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var abort_seed = await _consume_view(shell)
	abort_controller.advance_tick(abort_seed)
	await _release_view(shell, _logical_to_viewport(view, Vector2(220.0, 100.0)))
	var abort_seed_release = await _consume_view(shell)
	abort_controller.advance_tick(abort_seed_release)
	for _tick in range(20):
		abort_controller.advance_tick()
	view.present(abort_controller.get_snapshot())
	var abort_origin := _track_facts(abort_track)
	var abort_origin_endpoint := abort_track.get_endpoint_cell()
	await _deliver(_button(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(260.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var abort_frame = await _consume_view(shell)
	abort_track.apply_left_input(abort_frame)
	var abort_active_before: bool = abort_track.is_runtime_gesture_active()
	var abort_candidate := _track_facts(abort_track)
	var abort_expected_cells: Array = _record_cells(abort_origin["records"])
	abort_expected_cells.append(abort_origin_endpoint + Vector2i(1, 0))
	var abort_candidate_cells: Array = _record_cells(abort_candidate["records"])
	var abort_candidate_changed: bool = abort_candidate["records"].size() == abort_origin["records"].size() + 1 \
		and abort_candidate_cells == abort_expected_cells \
		and abort_candidate["endpoint"] == abort_origin_endpoint + Vector2i(1, 0) \
		and abort_candidate["available"] == abort_origin["available"] - 1
	view.present(_track_snapshot(abort_track, abort_controller.get_state()))
	_assert_true(abort_active_before, "Abort fixture has an active domain gesture before right abort")
	_assert_true(view._left_capture_active, "Abort fixture has view capture before right abort")
	_assert_true(abort_track.is_left_capture_active(), "Abort fixture has facade capture before right abort")
	await _deliver(_button(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_RIGHT, true))
	var abort_right: TrackInputFrameScript = await _consume_view(shell)
	abort_track.apply_right_input(abort_right)
	_assert_true(not abort_track.is_runtime_gesture_active(), "Abort fixture domain gesture is inactive before snapshot presentation")
	_assert_true(not abort_track.is_left_capture_active(), "Abort fixture facade capture is inactive before snapshot presentation")
	view.present(_track_snapshot(abort_track, abort_controller.get_state()))
	_assert_view_termination_clean(view, "Abort")
	_assert_equal(view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Held abort endpoint does not republish green")
	var abort_restored: bool = _track_facts(abort_track) == abort_origin
	var abort_cleared: bool = abort_active_before and abort_candidate_changed \
		and abort_restored and not abort_track.is_runtime_gesture_active() \
		and abort_track.get_endpoint_cell() == abort_origin_endpoint and not view._left_capture_active \
		and view._crossed_cells.is_empty() and not view._left_pressed_pending \
		and not view._left_released_pending and not view._right_pressed_pending
	_assert_true(abort_cleared, "Endpoint reshape integration assertion failed abort clears capture")
	if abort_cleared:
		print("PASS: Endpoint reshape integration abort clears capture")
	await _release_view(shell, _logical_to_viewport(view, Vector2(220.0, 100.0)))
	var abort_release: TrackInputFrameScript = await _consume_view(shell, abort_track)
	var abort_post_release := _track_facts(abort_track)
	_assert_true(abort_release.left_released, "Abort release frame routes through the same TrackSystem")
	_assert_equal(view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), abort_origin_endpoint, "Released abort endpoint may republish green")
	_assert_true(not abort_track.is_left_capture_active() and not abort_track.is_runtime_gesture_active(), "Abort release clears same-system latches")
	var abort_fresh_baseline_cells: Array = _record_cells(abort_post_release["records"])
	var abort_fresh_endpoint: Vector2i = abort_track.get_endpoint_cell()
	var abort_fresh_position := _logical_to_viewport(view, Vector2(abort_fresh_endpoint) * config.grid_cell_size_units + Vector2(config.grid_cell_size_units * 0.5, config.grid_cell_size_units * 0.5))
	var abort_fresh_next := abort_fresh_endpoint + Vector2i(1, 0)
	var abort_fresh_next_position := _logical_to_viewport(view, Vector2(abort_fresh_next) * config.grid_cell_size_units + Vector2(config.grid_cell_size_units * 0.5, config.grid_cell_size_units * 0.5))
	await _deliver(_button(abort_fresh_position, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(abort_fresh_next_position, MOUSE_BUTTON_MASK_LEFT))
	var abort_fresh_frame: TrackInputFrameScript = await _consume_view(shell, abort_track)
	var abort_fresh_state := _track_facts(abort_track)
	var abort_fresh_cells: Array = _record_cells(abort_fresh_state["records"])
	var abort_fresh_started: bool = abort_fresh_frame.left_pressed and abort_track.is_left_capture_active() \
		and abort_track.is_runtime_gesture_active() \
		and abort_fresh_state["records"].size() == abort_post_release["records"].size() + 1 \
		and abort_fresh_cells == abort_fresh_baseline_cells + [abort_fresh_next] \
		and abort_fresh_state["endpoint"] == abort_fresh_next
	_assert_true(abort_fresh_started, "Abort release and fresh press create a concrete new candidate")
	await _release_view(shell, abort_fresh_next_position)
	await _consume_view(shell, abort_track)

	var prep_track := TrackSystemScript.new(config)
	view.present(_track_snapshot(prep_track))
	var prep_origin := _track_facts(prep_track)
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(140.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var prep_frame: TrackInputFrameScript = await _consume_view(shell, prep_track)
	_assert_true(prep_frame.left_pressed, "Preparation fixture emits a real same-system left press")
	view.present(_track_snapshot(prep_track))
	var prep_active_before: bool = prep_track.is_runtime_gesture_active()
	var prep_candidate := _track_facts(prep_track)
	var prep_origin_cells: Array = _record_cells(prep_origin["records"])
	var prep_candidate_cells: Array = _record_cells(prep_candidate["records"])
	var prep_expected_cells: Array = prep_origin_cells.duplicate()
	prep_expected_cells.append(prep_origin["endpoint"] + Vector2i(1, 0))
	var prep_candidate_changed: bool = prep_candidate["records"].size() == prep_origin["records"].size() + 1 \
		and prep_candidate_cells == prep_expected_cells \
		and prep_candidate["endpoint"] == prep_origin["endpoint"] + Vector2i(1, 0) \
		and prep_candidate["available"] == prep_origin["available"] - 1
	var prep_candidate_records := _record_content_facts(prep_track.get_cell_records())
	var prep_candidate_geometry := _track_geometry_facts(prep_track)
	_assert_true(view._left_capture_active, "Preparation candidate has view capture before train preparation")
	_assert_true(prep_track.is_left_capture_active(), "Preparation candidate has facade capture before train preparation")
	var prep_result: bool = prep_track.prepare_for_train_sampling(0.0, 1.0)
	var prep_inactive: bool = prep_active_before and prep_result and not prep_track.is_runtime_gesture_active()
	view.present(_track_snapshot(prep_track))
	_assert_view_termination_clean(view, "Train preparation")
	_assert_true(not prep_track.is_left_capture_active(), "Train preparation clears facade capture")
	var prep_frozen_state := _track_facts(prep_track)
	var prep_metadata_stable := _preparation_metadata_transition_is_expected(prep_candidate, prep_frozen_state)
	var prep_frozen_records := _record_content_facts(prep_track.get_cell_records())
	var prep_frozen_geometry := _track_geometry_facts(prep_track)
	var prep_endpoint_after_prepare: Vector2i = prep_track.get_endpoint_cell()
	var prep_public_state_stable: bool = prep_frozen_state["available"] == prep_candidate["available"] \
		and prep_frozen_state["endpoint"] == prep_candidate["endpoint"] \
		and prep_frozen_state["contacts"] == prep_candidate["contacts"]
	var prep_endpoint_position := _logical_to_viewport(view, Vector2(prep_endpoint_after_prepare) * config.grid_cell_size_units + Vector2(config.grid_cell_size_units * 0.5, config.grid_cell_size_units * 0.5))
	await _deliver(_motion(prep_endpoint_position, MOUSE_BUTTON_MASK_LEFT))
	_assert_equal(view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), Vector2i(-1, -1), "Held preparation endpoint does not republish green")
	await _deliver(_motion(_logical_to_viewport(view, Vector2(180.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var frozen_frame: TrackInputFrameScript = await _consume_view(shell, prep_track)
	var held_motion_state := _track_facts(prep_track)
	var train_frozen: bool = prep_candidate_changed and prep_inactive \
		and prep_metadata_stable \
		and prep_public_state_stable \
		and prep_frozen_records == prep_candidate_records \
		and prep_frozen_geometry == prep_candidate_geometry \
		and prep_frozen_state["contacts"] == prep_candidate["contacts"] \
		and held_motion_state == prep_frozen_state \
		and frozen_frame.crossed_cells.is_empty() and not view._left_capture_active \
		and not prep_track.is_left_capture_active() \
		and view._previous_pointer_cell == Vector2i(-1, -1)
	_assert_true(train_frozen, "Endpoint reshape integration assertion failed train preparation freezes overlap")
	if train_frozen:
		print("PASS: Endpoint reshape integration train preparation freezes overlap")
	await _release_view(shell, prep_endpoint_position)
	var prep_release: TrackInputFrameScript = await _consume_view(shell, prep_track)
	var prep_post_release := _track_facts(prep_track)
	_assert_true(prep_release.left_released, "Preparation release frame routes through the same TrackSystem")
	_assert_equal(view.get_render_observation().get("hover_extend_cell", Vector2i(-1, -1)), prep_endpoint_after_prepare, "Released preparation endpoint may republish green")
	_assert_true(not prep_track.is_left_capture_active() and not prep_track.is_runtime_gesture_active(), "Preparation release clears same-system latches")
	var prep_fresh_baseline_cells: Array = _record_cells(prep_post_release["records"])
	var prep_fresh_endpoint: Vector2i = prep_track.get_endpoint_cell()
	var prep_fresh_position := _logical_to_viewport(view, Vector2(prep_fresh_endpoint) * config.grid_cell_size_units + Vector2(config.grid_cell_size_units * 0.5, config.grid_cell_size_units * 0.5))
	var prep_fresh_next := prep_fresh_endpoint + Vector2i(1, 0)
	var prep_fresh_next_position := _logical_to_viewport(view, Vector2(prep_fresh_next) * config.grid_cell_size_units + Vector2(config.grid_cell_size_units * 0.5, config.grid_cell_size_units * 0.5))
	await _deliver(_button(prep_fresh_position, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(prep_fresh_next_position, MOUSE_BUTTON_MASK_LEFT))
	var prep_fresh_frame: TrackInputFrameScript = await _consume_view(shell, prep_track)
	var prep_fresh_state := _track_facts(prep_track)
	var prep_fresh_cells: Array = _record_cells(prep_fresh_state["records"])
	var prep_fresh_started: bool = prep_fresh_frame.left_pressed and prep_track.is_left_capture_active() \
		and prep_track.is_runtime_gesture_active() \
		and prep_fresh_state["records"].size() == prep_post_release["records"].size() + 1 \
		and prep_fresh_cells == prep_fresh_baseline_cells + [prep_fresh_next] \
		and prep_fresh_state["endpoint"] == prep_fresh_next
	_assert_true(prep_fresh_started, "Preparation release and fresh press create a concrete new candidate")
	await _release_view(shell, prep_fresh_next_position)
	await _consume_view(shell, prep_track)

	var horizontal_track = TrackSystemScript.new(config)
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	var horizontal = await _consume(shell, horizontal_track)
	_assert_equal(horizontal.crossed_cells, [Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)], "Three horizontal cells")
	_assert_equal(horizontal_track.get_endpoint_cell(), Vector2i(5, 2), "Facade consumes horizontal order")
	await _release(shell, horizontal_track, _logical_to_viewport(view, Vector2(220.0, 100.0)))

	var l_track = TrackSystemScript.new(config)
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(180.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(180.0, 180.0)), MOUSE_BUTTON_MASK_LEFT))
	var l_frame = await _consume(shell, l_track)
	_assert_equal(
		l_frame.crossed_cells,
		[Vector2i(3, 2), Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4)],
		"Physical L events never shortcut diagonally"
	)
	await _release(shell, l_track, _logical_to_viewport(view, Vector2(180.0, 180.0)))

	var corner_track = TrackSystemScript.new(config)
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 140.0)), MOUSE_BUTTON_MASK_LEFT))
	var corner = await _consume(shell, corner_track)
	_assert_equal(
		corner.crossed_cells,
		[Vector2i(3, 2), Vector2i(4, 2), Vector2i(4, 3), Vector2i(5, 3)],
		"Fast corner uses dominant-axis ordering"
	)
	await _release(shell, corner_track, _logical_to_viewport(view, Vector2(220.0, 140.0)))

	var reflow_track = TrackSystemScript.new(config)
	await _deliver(_button(departure, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 100.0)), MOUSE_BUTTON_MASK_LEFT))
	await _consume(shell, reflow_track)
	await _deliver(_motion(_logical_to_viewport(view, Vector2(220.0, 180.0)), MOUSE_BUTTON_MASK_LEFT))
	var reflow_frame = await _consume(shell, reflow_track)
	_assert_equal(reflow_frame.crossed_cells, [Vector2i(5, 3), Vector2i(5, 4)], "Second frame emits only cells not consumed by the first frame")
	await _release(shell, reflow_track, _logical_to_viewport(view, Vector2(220.0, 180.0)))
	_assert_equal(reflow_track.advance_construction(5.0), 5.0, "Head completes without geometry locking")
	_assert_equal(reflow_track.get_geometry_pieces()[0].kind, TrackGeometryPieceScript.Kind.CURVE_3X3, "Completed head reflows as curve")
	var support_endpoint := reflow_track.get_endpoint_cell()
	reflow_track.apply_left_input(TrackInputFrameScript.new(
		[], support_endpoint, true, Vector2i(-1, -1), false,
		true, true, false, false, support_endpoint, true
	))
	var support_frame := TrackInputFrameScript.new(
		[support_endpoint, Vector2i(5, 5)], support_endpoint, true, Vector2i(-1, -1), false,
		false, true, false, false, Vector2i(5, 5), true
	)
	reflow_track.apply_left_input(support_frame)
	reflow_track.apply_left_input(TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, false, true, false, Vector2i(5, 5), true
	))
	_assert_equal(support_frame.crossed_cells, [support_endpoint, Vector2i(5, 5)], "Third frame appends G as exit support along F's direction")
	var g_viewport_position := _logical_to_viewport(view, Vector2(220.0, 220.0))
	_assert_true(not reflow_track._left_capture_active, "Releasing G clears left capture before the support right-click")
	var support_count := reflow_track.get_cell_records().size()
	_assert_equal(support_count, 6, "G support was actually appended")
	var support_record = reflow_track.get_cell_records()[-1]
	_assert_equal(support_record.cell, Vector2i(5, 5), "G support record is the active endpoint")
	var support_metadata_present := false
	for piece in reflow_track.get_geometry_pieces():
		if piece.exit_support_route_serial == support_record.route_serial:
			support_metadata_present = true
	_assert_true(support_metadata_present, "G is the active exit-support route serial")
	await _deliver(_button(g_viewport_position, MOUSE_BUTTON_RIGHT, true))
	await _consume(shell, reflow_track)
	_assert_equal(reflow_track.get_cell_records().size(), support_count, "Right-clicking exit support is a no-op")
	_assert_equal(reflow_track.get_endpoint_cell(), Vector2i(5, 5), "Exit support remains endpoint")

	await _deliver(_button(_logical_to_viewport(view, Vector2(180.0, 100.0)), MOUSE_BUTTON_RIGHT, true))
	var canceled = await _consume(shell, horizontal_track)
	_assert_equal(canceled.right_press_cell, Vector2i(4, 2), "Right press resolves one cell")
	_assert_equal(horizontal_track.get_endpoint_cell(), Vector2i(3, 2), "Right click cancels its ghost suffix")

	var before_invalid = horizontal_track.get_cell_records()
	var hud = shell.get_node("OuterMargin/MainColumn/TopHud") as Control
	await _deliver(_button(hud.get_global_rect().get_center(), MOUSE_BUTTON_LEFT, true))
	var hud_frame = await _consume(shell, horizontal_track)
	_assert_equal(hud_frame.crossed_cells, [], "HUD events emit no cells")
	_assert_equal(horizontal_track.get_cell_records().size(), before_invalid.size(), "HUD cannot change domain cells")
	await _deliver(_button(hud.get_global_rect().get_center(), MOUSE_BUTTON_LEFT, false))

	var content: Rect2 = view.get_logical_content_rect()
	var letterbox_local := Vector2(content.get_center().x, content.position.y * 0.5)
	var letterbox: Vector2 = view.get_global_transform_with_canvas() * letterbox_local
	await _deliver(_button(letterbox, MOUSE_BUTTON_LEFT, true))
	await _deliver(_motion(letterbox + Vector2(40.0, 0.0), MOUSE_BUTTON_MASK_LEFT))
	var outside = await _consume(shell, horizontal_track)
	_assert_true(not outside.left_press_inside_grid, "Letterbox press is outside grid")
	_assert_equal(outside.crossed_cells, [], "Letterbox motion emits no cells")
	await _deliver(_button(letterbox, MOUSE_BUTTON_LEFT, false))
	await _consume(shell, horizontal_track)

	var domain_before_resize = horizontal_track.get_cell_records()
	shell.size = Vector2(1100.0, 650.0)
	await process_frame
	await process_frame
	_assert_equal(horizontal_track.get_cell_records().size(), domain_before_resize.size(), "Resize does not change domain cells")
	await _finish(shell)


func _finish(shell) -> void:
	if shell != null:
		shell.queue_free()
		await process_frame
	if _failures.is_empty():
		print("PASS: track train input integration")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("FAIL: %d track train input assertion(s)" % _failures.size())
	quit(1)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, expected, actual])
