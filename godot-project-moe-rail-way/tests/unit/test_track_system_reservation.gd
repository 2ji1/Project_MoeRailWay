extends "res://tests/support/prototype_test.gd"

const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")


func run() -> PackedStringArray:
	_test_endpoint_reshape_track_input_frame_carries_final_pointer_facts()
	_verify_invalid_configuration_probes()
	_test_input_frame_owns_an_independent_cell_buffer()
	_test_facade_preserves_origin_and_exact_inventory()
	_test_endpoint_capture_appends_ordered_cells()
	_test_ordinary_held_path_replaces_visible_candidate()
	_test_invalid_candidates_stop_without_corrupting_ownership()
	_test_right_edge_consumes_the_frame_and_cancels_a_suffix()
	_test_right_edge_ends_left_capture_until_a_fresh_press()
	_test_fresh_capture_is_endpoint_only_and_legal()
	_test_active_right_abort_consumes_edge_before_cancellation()
	_test_facade_clears_capture_after_runtime_abort()
	_test_held_input_waits_for_release_and_fresh_press()
	_test_left_release_finalizes_once()
	_test_same_frame_press_routes_through_gesture_transaction()
	_test_current_pointer_selects_completed_head_template()
	_test_current_pointer_reselects_completed_head_template_while_held()
	_test_authoritative_pointer_wins_over_crossed_target()
	_test_reselection_keeps_suffix_after_selected_target()
	_test_left_press_latch_requires_release_after_rejection()
	_test_prepare_preserves_original_result_and_clears_capture()
	_test_prepare_termination_waits_for_release()
	_test_observation_getters_are_detached()
	return finish()


func _test_endpoint_reshape_track_input_frame_carries_final_pointer_facts() -> void:
	print("Endpoint reshape: TrackInputFrame carries final pointer facts")
	var frame_script = load("res://src/domain/track/track_input_frame.gd")
	var empty_cells: Array[Vector2i] = []
	var frame = frame_script.call(
		"new",
		empty_cells, Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, false, false, false, Vector2i(4, 5), true
	)
	assert_not_null(frame, "Pointer frame constructor accepts final facts")
	if frame == null:
		return
	assert_equal(frame.get("current_pointer_cell"), Vector2i(4, 5), "Frame stores current pointer cell")
	assert_true(frame.get("current_pointer_inside_grid"), "Frame stores current pointer grid fact")


func _verify_invalid_configuration_probes() -> void:
	_run_probe("origin_mismatch", "Grid origin must center within logical field")
	_run_probe("departure_mismatch", "Departure position must match departure cell center")


func _run_probe(case_name: String, expected_message: String) -> void:
	var output: Array = []
	var arguments := PackedStringArray([
		"--headless",
		"--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/run_all.gd",
		"--quit-after", "1",
		"--",
		"--track-invalid-probe=" + case_name,
	])
	OS.execute(OS.get_executable_path(), arguments, output, true)
	var output_lines := PackedStringArray()
	for chunk in output:
		output_lines.append(str(chunk))
	var captured_text := "\n".join(output_lines)
	assert_true(
		captured_text.contains("TRACK_INVALID_PROBE_BEGIN:" + case_name),
		"Track invalid probe starts for " + case_name
	)
	assert_true(
		captured_text.contains(expected_message),
		"Track invalid probe reports: " + expected_message
	)


func run_invalid_probe(case_name: String) -> void:
	var config := _config()
	if case_name == "origin_mismatch":
		config.grid_origin_units = Vector2.ZERO
		TrackSystemScript.new(config)
		return
	if case_name == "departure_mismatch":
		config.departure_position = Vector2(20.0, 20.0)
		TrackSystemScript.new(config)


func _config(total_cells: int = 8) -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		1, 20.0, 1,
		1.0, total_cells, 2, 2.0, 1.0, 1,
		Vector2(420.0, 260.0), Vector2i(10, 6), 40.0, Vector2(10.0, 10.0),
		&"departure", Vector2(30.0, 30.0), Vector2i(0, 0)
	)


func _left_frame(
	cells: Array[Vector2i],
	pressed: bool = false,
	held: bool = true,
	released: bool = false,
	press_cell: Vector2i = Vector2i(0, 0),
	inside: bool = true,
	current_pointer_cell: Vector2i = Vector2i(-1, -1),
	current_pointer_inside_grid: bool = false
) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		cells, press_cell, inside, Vector2i(-1, -1), false,
		pressed, held, released, false,
		current_pointer_cell, current_pointer_inside_grid
	)


func _right_frame(
	cell: Vector2i,
	inside: bool = true,
	left_released: bool = false
) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, cell, inside,
		false, false, left_released, true
	)


func _test_input_frame_owns_an_independent_cell_buffer() -> void:
	var empty_frame = TrackInputFrameScript.empty()
	assert_not_null(empty_frame.get("live_gesture_path"), "Empty frame exposes the live gesture path")
	if empty_frame.get("live_gesture_path") == null:
		return
	var source: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	var source_path: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1)]
	var frame_script = load("res://src/domain/track/track_input_frame.gd")
	var frame = frame_script.call(
		"new",
		source, Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, false, false, false, Vector2i(-1, -1), false, source_path
	)
	assert_not_null(frame, "Frame constructor accepts an explicit live gesture path")
	if frame == null:
		return
	source[0] = Vector2i(9, 9)
	source_path[0] = Vector2i(9, 9)
	assert_equal(frame.crossed_cells, [Vector2i(1, 0), Vector2i(2, 0)], "Frame copies cells")
	assert_not_null(frame.get("live_gesture_path"), "Frame exposes the live gesture path")
	assert_equal(frame.live_gesture_path, [Vector2i(1, 0), Vector2i(1, 1)], "Frame copies live gesture path")
	var legacy = TrackInputFrameScript.new(source)
	assert_not_null(legacy.get("live_gesture_path"), "Legacy frame exposes the live gesture path")
	assert_equal(legacy.live_gesture_path, [Vector2i(9, 9), Vector2i(2, 0)], "Legacy constructor copies crossed cells into live gesture path")
	var first = TrackInputFrameScript.empty()
	var second = TrackInputFrameScript.empty()
	first.crossed_cells.append(Vector2i(1, 0))
	assert_equal(second.crossed_cells, [], "Empty frames never share their cell arrays")


func _test_facade_preserves_origin_and_exact_inventory() -> void:
	var track = TrackSystemScript.new(_config())
	assert_equal(track.get_endpoint_cell(), Vector2i(0, 0), "Departure is the initial endpoint")
	assert_equal(track.get_cell_records(), [], "The departure anchor is free")
	assert_equal(track.get_available_track_cells(), 8, "All inventory starts available")
	assert_equal(track.get_total_track_cells(), 8, "Total inventory is exact")
	assert_equal(track.get_grid_origin_units(), Vector2(10.0, 10.0), "Origin is copied exactly")


func _test_endpoint_capture_appends_ordered_cells() -> void:
	var track = TrackSystemScript.new(_config())
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	track.apply_left_input(_left_frame(cells, true))
	var records = track.get_cell_records()
	assert_equal(records.size(), 3, "Three crossed cells are owned")
	for index in range(records.size()):
		assert_equal(records[index].cell, cells[index], "Physical crossing order is retained")
	assert_equal(track.get_endpoint_cell(), Vector2i(3, 0), "Endpoint advances to the last cell")
	assert_equal(track.get_available_track_cells(), 5, "Each unique cell charges exactly once")
	var release_cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(3, 1)]
	track.apply_left_input(_left_frame(release_cells, false, false, true))
	assert_equal(track.get_endpoint_cell(), Vector2i(3, 1), "Release crossings process before capture clears")
	var after_release: Array[Vector2i] = [Vector2i(3, 2)]
	track.apply_left_input(_left_frame(after_release))
	assert_equal(track.get_endpoint_cell(), Vector2i(3, 1), "Held input after release has no capture")


func _test_ordinary_held_path_replaces_visible_candidate() -> void:
	print("Live gesture path: ordinary held candidate reflows before release")
	var track = TrackSystemScript.new(_config(10))
	var first_path: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	track.apply_left_input(TrackInputFrameScript.new(
		first_path, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		true, true, false, false, Vector2i(3, 0), true, first_path
	))
	var first_serials := track.get_cell_records().map(func(record): return record.route_serial)
	var replacement: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
	track.apply_left_input(TrackInputFrameScript.new(
		replacement, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		false, true, false, false, Vector2i(1, 2), true, replacement
	))
	assert_equal(track.get_cell_records().map(func(record): return record.cell), replacement, "Held replacement removes the superseded ordinary suffix")
	assert_equal(track.get_available_track_cells(), 7, "Equal-length replacement preserves exact inventory")
	assert_equal(track.get_cell_records()[0].route_serial, first_serials[0], "Common path prefix retains identity")
	assert_true(track.get_cell_records()[1].route_serial > first_serials[-1], "New branch never reuses a removed serial")
	assert_true(track.is_left_capture_active() and track.is_runtime_gesture_active(), "Replacement remains held")
	var empty_path: Array[Vector2i] = []
	track.apply_left_input(TrackInputFrameScript.new(
		empty_path, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		false, true, false, false, Vector2i(0, 0), true, empty_path
	))
	assert_equal(track.get_cell_records(), [], "Empty authoritative path restores the departure origin")
	assert_equal(track.get_available_track_cells(), 10, "Empty authoritative path refunds the full candidate")
	var new_path: Array[Vector2i] = [Vector2i(1, 0)]
	track.apply_left_input(TrackInputFrameScript.new(
		new_path, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		false, true, false, false, Vector2i(1, 0), true, new_path
	))
	assert_equal(track.get_cell_records().map(func(record): return record.cell), new_path, "Held gesture accepts a new path after clearing")
	assert_true(track.get_cell_records()[0].route_serial > first_serials[-1], "New path serial remains above every retired candidate")


func _test_invalid_candidates_stop_without_corrupting_ownership() -> void:
	var track = TrackSystemScript.new(_config())
	var wrong_start: Array[Vector2i] = [Vector2i(1, 0)]
	track.apply_left_input(_left_frame(wrong_start, true, true, false, Vector2i(4, 4)))
	assert_equal(track.get_cell_records(), [], "A press away from the endpoint discards its buffer")
	track.apply_left_input(_left_frame([], false, false, true, Vector2i(4, 4)))
	var invalid_buffer: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 0), Vector2i(2, 1),
	]
	track.apply_left_input(_left_frame(invalid_buffer.slice(0, 2), true))
	track.apply_left_input(_left_frame(invalid_buffer, false, true, false, Vector2i(2, 0)))
	assert_equal(track.get_cell_records().size(), 2, "Candidates after the first invalid cell are ignored")
	assert_equal(track.get_endpoint_cell(), Vector2i(2, 0), "Invalid suffix cannot move the endpoint")
	assert_equal(track.get_available_track_cells(), 6, "Rejected cells never charge inventory")


func _test_right_edge_consumes_the_frame_and_cancels_a_suffix() -> void:
	var track = TrackSystemScript.new(_config())
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	track.apply_left_input(_left_frame(cells, true))
	track.apply_left_input(_left_frame(cells, false, false, true, Vector2i(3, 0)))
	assert_true(track.apply_right_input(_right_frame(Vector2i(2, 0))), "Right edge is consumed")
	assert_equal(track.get_endpoint_cell(), Vector2i(1, 0), "Clicked cell and its suffix cancel")
	assert_equal(track.get_available_track_cells(), 7, "Canceled ghosts refund once")
	assert_true(track.apply_right_input(_right_frame(Vector2i(9, 5))), "A miss still consumes its edge")
	assert_true(track.apply_right_input(_right_frame(Vector2i(-1, -1), false)), "Outside right edge is consumed")
	assert_equal(track.get_available_track_cells(), 7, "Misses never change ownership")
	assert_false(track.apply_right_input(TrackInputFrameScript.empty()), "No right edge is not consumed")


func _test_right_edge_ends_left_capture_until_a_fresh_press() -> void:
	var track = TrackSystemScript.new(_config())
	var initial: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	track.apply_left_input(_left_frame(initial, true, true))
	track.apply_left_input(_left_frame(initial, false, false, true, Vector2i(2, 0)))
	assert_true(track.apply_right_input(_right_frame(Vector2i(2, 0))), "Right edge cancels held drag")
	assert_equal(track.get_endpoint_cell(), Vector2i(1, 0), "Right edge cancels the selected suffix")
	var held_motion: Array[Vector2i] = [Vector2i(2, 0)]
	track.apply_left_input(_left_frame(held_motion, false, true, false, Vector2i(1, 0)))
	assert_equal(
		track.get_endpoint_cell(),
		Vector2i(1, 0),
		"Held-left motion after right cancellation stays ignored"
	)
	track.apply_left_input(_left_frame([], false, false, true, Vector2i(1, 0)))
	track.apply_left_input(_left_frame(held_motion, true, true, false, Vector2i(1, 0)))
	assert_equal(track.get_endpoint_cell(), Vector2i(2, 0), "Fresh valid press starts a new capture")


func _test_fresh_capture_is_endpoint_only_and_legal() -> void:
	print("Endpoint reshape: fresh capture is endpoint-only")
	var track = TrackSystemScript.new(_config())
	track.apply_left_input(_left_frame([Vector2i(1, 0)], true, true, false, Vector2i(4, 4)))
	assert_equal(track.get_cell_records(), [], "Nonendpoint press discards crossed cells")
	assert_false(track.is_left_capture_active(), "Nonendpoint press does not capture")
	track.apply_left_input(_left_frame([], false, false, true, Vector2i(4, 4)))
	assert_true(track.has_method("is_left_capture_active"), "Facade exposes capture state")
	assert_true(track.has_method("is_runtime_gesture_active"), "Facade exposes runtime active state")
	if track.has_method("is_left_capture_active"):
		assert_false(track.is_left_capture_active(), "Nonendpoint facade state is inactive")
	if track.has_method("is_runtime_gesture_active"):
		assert_false(track.is_runtime_gesture_active(), "Nonendpoint runtime state is inactive")
	track.apply_left_input(_left_frame([], true, true, false, Vector2i(0, 0)))
	assert_true(track.is_left_capture_active(), "Endpoint press captures")
	assert_true(track.is_runtime_gesture_active(), "Endpoint press begins runtime gesture")


func _test_active_right_abort_consumes_edge_before_cancellation() -> void:
	print("Endpoint reshape: active right abort consumes edge")
	var track = TrackSystemScript.new(_config())
	track.apply_left_input(_left_frame([Vector2i(1, 0), Vector2i(2, 0)], true, true))
	track.apply_left_input(_left_frame([Vector2i(1, 0), Vector2i(2, 0)], false, false, true, Vector2i(2, 0)))
	track.apply_left_input(_left_frame([], true, true, false, Vector2i(2, 0)))
	track.apply_left_input(_left_frame([Vector2i(3, 0)], false, true, false, Vector2i(2, 0)))
	assert_equal(track.get_endpoint_cell(), Vector2i(3, 0), "Active gesture publishes its candidate")
	assert_true(track.apply_right_input(_right_frame(Vector2i(1, 0))), "Active right edge is consumed")
	assert_equal(track.get_endpoint_cell(), Vector2i(2, 0), "Abort restores the exact gesture origin")
	assert_equal(track.get_cell_records().size(), 2, "Abort skips ordinary suffix cancellation")
	assert_false(track.is_left_capture_active(), "Abort clears facade capture")
	assert_false(track.is_runtime_gesture_active(), "Abort clears runtime active state")

	var simultaneous = TrackSystemScript.new(_config())
	simultaneous.apply_left_input(_left_frame([Vector2i(1, 0), Vector2i(2, 0)], true, true))
	simultaneous.apply_left_input(_left_frame([Vector2i(1, 0), Vector2i(2, 0)], false, false, true, Vector2i(2, 0)))
	simultaneous.apply_left_input(_left_frame([], true, true, false, Vector2i(2, 0)))
	simultaneous.apply_left_input(_left_frame([Vector2i(3, 0)], false, true, false, Vector2i(2, 0)))
	assert_true(
		simultaneous.apply_right_input(_right_frame(Vector2i(1, 0), true, true)),
		"Simultaneous right abort and left release consumes the right edge"
	)
	assert_equal(simultaneous.get_endpoint_cell(), Vector2i(2, 0), "Simultaneous abort restores origin")
	assert_equal(simultaneous.get_cell_records().size(), 2, "Simultaneous abort skips left mutation")
	assert_false(simultaneous.is_left_capture_active(), "Simultaneous abort clears facade capture")
	assert_false(simultaneous.is_runtime_gesture_active(), "Simultaneous abort does not finalize")
	simultaneous.apply_left_input(_left_frame([], true, true, false, Vector2i(2, 0)))
	assert_true(
		simultaneous.is_left_capture_active(),
		"Simultaneous release permits an immediate fresh press"
	)


func _test_facade_clears_capture_after_runtime_abort() -> void:
	print("Endpoint reshape: facade clears capture after runtime abort")
	var track = TrackSystemScript.new(_config())
	track.apply_left_input(_left_frame([], true, true, false, Vector2i(0, 0)))
	assert_true(track.is_left_capture_active(), "Facade captures before public runtime abort")
	assert_true(track.apply_right_input(_right_frame(Vector2i(9, 5))), "Public right edge aborts the runtime gesture")
	track.apply_left_input(_left_frame([Vector2i(1, 0)], false, true, false, Vector2i(0, 0)))
	assert_false(track.is_left_capture_active(), "Facade clears stale capture after runtime abort")
	assert_false(track.is_runtime_gesture_active(), "Runtime remains inactive after abort")


func _test_held_input_waits_for_release_and_fresh_press() -> void:
	print("Endpoint reshape: held input waits for release and fresh press")
	var track = TrackSystemScript.new(_config())
	track.apply_left_input(_left_frame([], true, true, false, Vector2i(0, 0)))
	track.apply_left_input(_left_frame([Vector2i(1, 0)], false, true, false, Vector2i(0, 0)))
	track.apply_left_input(_left_frame([Vector2i(1, 0)], false, false, true, Vector2i(1, 0)))
	var completed_endpoint := track.get_endpoint_cell()
	track.apply_left_input(_left_frame([Vector2i(2, 0)], false, true, false, completed_endpoint))
	assert_equal(track.get_endpoint_cell(), completed_endpoint, "Held motion after completion is ignored")
	track.apply_left_input(_left_frame([], true, true, false, completed_endpoint))
	assert_true(track.is_left_capture_active(), "Fresh press after release captures")
	track.apply_right_input(_right_frame(Vector2i(9, 5)))
	track.apply_left_input(_left_frame([Vector2i(2, 0)], false, true, false, completed_endpoint))
	assert_false(track.is_left_capture_active(), "Held motion after abort remains ignored")
	track.apply_left_input(_left_frame([], false, false, true, completed_endpoint))
	track.apply_left_input(_left_frame([], true, true, false, completed_endpoint))
	assert_true(track.is_left_capture_active(), "Abort requires release and a fresh press")
	var exhausted = TrackSystemScript.new(_config(1))
	exhausted.apply_left_input(_left_frame([Vector2i(1, 0)], true, true))
	exhausted.apply_left_input(_left_frame([], false, false, true, Vector2i(1, 0)))
	exhausted.apply_left_input(_left_frame([Vector2i(2, 0)], true, true, false, Vector2i(1, 0)))
	assert_false(exhausted.is_left_capture_active(), "Rejected fresh press does not capture without a legal operation")


func _test_left_release_finalizes_once() -> void:
	print("Endpoint reshape: left release finalizes")
	var track = TrackSystemScript.new(_config())
	track.apply_left_input(
		_left_frame(
			[Vector2i(1, 0)], true, true, false, Vector2i(0, 0), true,
			Vector2i(-1, -1), false
		)
	)
	assert_true(track.is_runtime_gesture_active(), "Held left input keeps runtime gesture active")
	assert_equal(track.advance_construction(1.0), 0.0, "Active gesture defers construction")
	assert_true(track.is_runtime_gesture_active(), "Construction cannot finalize the active gesture")
	track.apply_left_input(_left_frame([Vector2i(1, 0)], false, false, true, Vector2i(1, 0), true, Vector2i(1, 0), true))
	assert_false(track.is_left_capture_active(), "Release clears facade capture")
	assert_false(track.is_runtime_gesture_active(), "Release finalizes runtime gesture")
	var endpoint_after_release := track.get_endpoint_cell()
	assert_equal(track.advance_construction(1.0), 1.0, "Construction proceeds after release")
	track.apply_left_input(_left_frame([Vector2i(2, 0)], false, false, true, Vector2i(1, 0)))
	assert_equal(track.get_endpoint_cell(), endpoint_after_release, "Second release does not finalize twice")


func _test_same_frame_press_routes_through_gesture_transaction() -> void:
	print("Endpoint reshape: same-frame press routes through gesture transaction")
	var track = TrackSystemScript.new(_config())
	var origin_cells: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(3, 1), Vector2i(3, 2),
	]
	track.apply_left_input(_left_frame(origin_cells, true, true, false, Vector2i(0, 0)))
	track.apply_left_input(_left_frame(origin_cells, false, false, true, Vector2i(3, 2)))
	var origin_records = _record_values(track.get_cell_records())
	var origin_pieces = _piece_values(track.get_geometry_pieces())
	var endpoint := track.get_endpoint_cell()
	var selected_target := Vector2i(5, 0)
	var control_cell := Vector2i(4, 1)
	track.apply_left_input(
		_left_frame(
			[control_cell, selected_target], true, true, false, endpoint, true,
			selected_target, true
		)
	)
	assert_true(track.is_left_capture_active(), "Same-frame motion keeps facade capture active")
	assert_true(track.is_runtime_gesture_active(), "Same-frame motion keeps runtime gesture active")
	assert_equal(track.get_endpoint_cell(), selected_target, "Same-frame motion publishes the candidate")
	assert_false(
		track.get_cell_records().any(func(record): return record.cell == control_cell),
		"Cells before the template target remain control input"
	)
	assert_true(track.apply_right_input(_right_frame(origin_cells[0])), "Right edge aborts same-frame gesture")
	assert_equal(_record_values(track.get_cell_records()), origin_records, "Abort restores the exact same-frame gesture origin records")
	assert_equal(_piece_values(track.get_geometry_pieces()), origin_pieces, "Abort restores the exact same-frame gesture origin pieces")
	assert_equal(track.get_endpoint_cell(), endpoint, "Abort restores the exact same-frame gesture origin endpoint")
	assert_false(track.is_left_capture_active(), "Abort clears facade capture after same-frame motion")
	assert_false(track.is_runtime_gesture_active(), "Abort clears runtime gesture after same-frame motion")
	track.apply_left_input(_left_frame([], true, true, false, endpoint))
	assert_false(track.is_left_capture_active(), "Held repeated press cannot restart before release")
	track.apply_left_input(_left_frame([], false, false, true, endpoint))
	track.apply_left_input(_left_frame([], true, true, false, endpoint))
	assert_true(track.is_left_capture_active(), "Fresh press after release starts a new gesture")


func _test_current_pointer_selects_completed_head_template() -> void:
	print("Endpoint interaction fix: current pointer selects completed head template")
	var config = SessionStartConfigScript.new(
		1, 20.0, 1,
		1.0, 8, 2, 2.0, 1.0, 1,
		Vector2(420.0, 260.0), Vector2i(10, 6), 40.0, Vector2(10.0, 10.0),
		&"departure", Vector2(30.0, 110.0), Vector2i(0, 2)
	)
	var track = TrackSystemScript.new(config)
	var right_curve: Array[Vector2i] = [
		Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
		Vector2i(3, 3), Vector2i(3, 4),
	]
	track.apply_left_input(_left_frame(right_curve, true, true, false, Vector2i(0, 2)))
	track.apply_left_input(_left_frame(right_curve, false, false, true, Vector2i(3, 4)))
	var curve_endpoint := track.get_endpoint_cell()
	var left_target := Vector2i(3, 0)
	var straight_target := Vector2i(5, 2)
	track.apply_left_input(
		_left_frame([], true, true, false, curve_endpoint, true, curve_endpoint, true)
	)
	track.apply_left_input(
		_left_frame([], false, true, false, curve_endpoint, true, left_target, true)
	)
	assert_equal(
		track.get_endpoint_cell(),
		left_target,
		"The authoritative current pointer selects the opposite curve without a new crossed cell"
	)
	assert_equal(
		track.get_cell_records().map(func(record): return record.cell),
		[Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0)],
		"Current-pointer selection atomically replaces the completed curve direction"
	)
	track.apply_left_input(_left_frame([], false, false, true, left_target, true, left_target, true))
	track.apply_left_input(_left_frame([], true, true, false, left_target, true, left_target, true))
	track.apply_left_input(_left_frame([], false, true, false, left_target, true, straight_target, true))
	assert_equal(track.get_endpoint_cell(), straight_target, "A later pointer-only gesture selects straight")
	assert_equal(
		track.get_cell_records().map(func(record): return record.cell),
		[Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)],
		"Pointer-only template changes remain atomic across separate gestures"
	)


func _test_current_pointer_reselects_completed_head_template_while_held() -> void:
	print("Endpoint interaction fix: held pointer reselects completed head template")
	var config = SessionStartConfigScript.new(
		1, 20.0, 1,
		1.0, 8, 2, 2.0, 1.0, 1,
		Vector2(420.0, 260.0), Vector2i(10, 6), 40.0, Vector2(10.0, 10.0),
		&"departure", Vector2(30.0, 110.0), Vector2i(0, 2)
	)
	var track = TrackSystemScript.new(config)
	var right_curve: Array[Vector2i] = [
		Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
		Vector2i(3, 3), Vector2i(3, 4),
	]
	track.apply_left_input(_left_frame(right_curve, true, true, false, Vector2i(0, 2)))
	track.apply_left_input(_left_frame(right_curve, false, false, true, Vector2i(3, 4)))
	var endpoint := track.get_endpoint_cell()
	var available := track.get_available_track_cells()
	track.apply_left_input(_left_frame([], true, true, false, endpoint, true, endpoint, true))
	assert_true(track.is_left_capture_active(), "Held reselection starts with active facade capture")
	assert_true(track.is_runtime_gesture_active(), "Held reselection starts with active runtime gesture")

	var left_near := Vector2i(3, 1)
	var left_frame := _left_frame([], false, true, false, endpoint, true, left_near, true)
	assert_true(left_frame.left_held and not left_frame.left_released, "Left near frame stays held")
	track.apply_left_input(left_frame)
	assert_equal(
		track.get_cell_records().map(func(record): return record.cell),
		[
			Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
			Vector2i(3, 1), Vector2i(3, 0),
		],
		"Held pointer near the left target selects the left template"
	)
	assert_true(track.is_left_capture_active(), "Left reselection keeps facade capture active")
	assert_true(track.is_runtime_gesture_active(), "Left reselection keeps runtime gesture active")
	assert_equal(track.get_available_track_cells(), available, "Equal-length left replacement preserves inventory")

	var straight_near := Vector2i(5, 1)
	var straight_frame := _left_frame([], false, true, false, endpoint, true, straight_near, true)
	assert_true(straight_frame.left_held and not straight_frame.left_released, "Straight near frame stays held")
	track.apply_left_input(straight_frame)
	assert_equal(
		track.get_cell_records().map(func(record): return record.cell),
		[
			Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
			Vector2i(4, 2), Vector2i(5, 2),
		],
		"Held pointer near the straight target selects the straight template"
	)
	assert_true(track.is_left_capture_active(), "Straight reselection keeps facade capture active")
	assert_true(track.is_runtime_gesture_active(), "Straight reselection keeps runtime gesture active")
	assert_equal(track.get_available_track_cells(), available, "Equal-length straight replacement preserves inventory")

	var right_near := Vector2i(3, 3)
	var right_frame := _left_frame([], false, true, false, endpoint, true, right_near, true)
	assert_true(right_frame.left_held and not right_frame.left_released, "Right near frame stays held")
	track.apply_left_input(right_frame)
	assert_equal(
		track.get_cell_records().map(func(record): return record.cell),
		right_curve,
		"Held pointer near the right target reselects the right template"
	)
	assert_true(track.is_left_capture_active(), "Right reselection keeps facade capture active")
	assert_true(track.is_runtime_gesture_active(), "Right reselection keeps runtime gesture active")
	assert_equal(track.get_available_track_cells(), available, "Equal-length right replacement preserves inventory")


func _test_authoritative_pointer_wins_over_crossed_target() -> void:
	print("Endpoint interaction fix: authoritative pointer wins over crossed target")
	var config = SessionStartConfigScript.new(
		1, 20.0, 1,
		1.0, 18, 2, 2.0, 1.0, 1,
		Vector2(420.0, 260.0), Vector2i(10, 6), 40.0, Vector2(10.0, 10.0),
		&"departure", Vector2(30.0, 110.0), Vector2i(0, 2)
	)
	var runtime = GridTrackRuntimeScript.new(
		config.departure_cell,
		config.total_track_cells,
		config.grid_origin_units,
		config.grid_size,
		config.grid_cell_size_units
	)
	var right_curve: Array[Vector2i] = [
		Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
		Vector2i(3, 3), Vector2i(3, 4),
	]
	assert_equal(runtime.append_cells(right_curve), right_curve.size(), "Right curve fixture is appended")
	assert_true(runtime.gesture_begin(Vector2i(3, 4)).size() > 0, "Held gesture begins at right endpoint")
	var selected_right_target := Vector2i(3, 4)
	var straight_target := Vector2i(5, 2)
	var right_near := Vector2i(3, 3)
	var crossed_cells: Array[Vector2i] = [
		selected_right_target,
		Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5),
		Vector2i(5, 4), Vector2i(5, 3), straight_target,
	]
	runtime.gesture_update(crossed_cells, right_near)
	assert_true(runtime.gesture_is_active(), "Crossed-target frame keeps the gesture held")
	var expected_route := right_curve.duplicate()
	expected_route.append_array(crossed_cells.slice(1))
	assert_equal(
		runtime.get_cell_records().map(func(record): return record.cell),
		expected_route,
		"Authoritative right target reset is not hidden by a later straight target"
	)


func _test_reselection_keeps_suffix_after_selected_target() -> void:
	print("Endpoint interaction fix: reselection keeps suffix after selected target")
	var config = SessionStartConfigScript.new(
		1, 20.0, 1,
		1.0, 8, 2, 2.0, 1.0, 1,
		Vector2(420.0, 260.0), Vector2i(10, 6), 40.0, Vector2(10.0, 10.0),
		&"departure", Vector2(30.0, 110.0), Vector2i(0, 2)
	)
	var track = TrackSystemScript.new(config)
	var right_curve: Array[Vector2i] = [
		Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
		Vector2i(3, 3), Vector2i(3, 4),
	]
	track.apply_left_input(_left_frame(right_curve, true, true, false, Vector2i(0, 2)))
	track.apply_left_input(_left_frame(right_curve, false, false, true, Vector2i(3, 4)))
	var endpoint := track.get_endpoint_cell()
	var available := track.get_available_track_cells()
	track.apply_left_input(_left_frame([], true, true, false, endpoint, true, endpoint, true))
	var straight_target := Vector2i(5, 2)
	var suffix_cell := Vector2i(6, 2)
	var frame := _left_frame(
		[straight_target, suffix_cell], false, true, false,
		endpoint, true, suffix_cell, true
	)
	assert_true(frame.left_held and not frame.left_released, "Reselection suffix frame stays held")
	track.apply_left_input(frame)
	assert_equal(
		track.get_cell_records().map(func(record): return record.cell),
		[
			Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
			Vector2i(4, 2), straight_target, suffix_cell,
		],
		"Reselection keeps valid suffix cells after the selected target"
	)
	assert_true(track.is_left_capture_active(), "Reselection suffix frame keeps facade capture active")
	assert_true(track.is_runtime_gesture_active(), "Reselection suffix frame keeps runtime gesture active")
	assert_equal(track.get_available_track_cells(), available - 1, "Reselection suffix charges one new record")


func _test_left_press_latch_requires_release_after_rejection() -> void:
	print("Endpoint reshape: left press latch requires release")
	var rejected = TrackSystemScript.new(_config())
	rejected.apply_left_input(_left_frame([Vector2i(1, 0)], true, true, false, Vector2i(4, 4)))
	rejected.apply_left_input(_left_frame([], true, true, false, Vector2i(0, 0)))
	assert_false(rejected.is_left_capture_active(), "Rejected press latches until release")
	rejected.apply_left_input(_left_frame([], false, false, true, Vector2i(0, 0)))
	rejected.apply_left_input(_left_frame([], true, true, false, Vector2i(0, 0)))
	assert_true(rejected.is_left_capture_active(), "Release clears a rejected press latch")


func _test_prepare_preserves_original_result_and_clears_capture() -> void:
	print("Endpoint reshape: prepare true returns true and clears capture")
	var config := _config()
	var successful = TrackSystemScript.new(config)
	successful.apply_left_input(_left_frame([Vector2i(1, 0)], true, true))
	assert_true(successful.has_method("prepare_for_train_sampling"), "Facade exposes train preparation")
	if not successful.has_method("prepare_for_train_sampling"):
		return
	var reference = GridTrackRuntimeScript.new(
		config.departure_cell,
		config.total_track_cells,
		config.grid_origin_units,
		config.grid_size,
		config.grid_cell_size_units
	)
	reference.append_cells([Vector2i(1, 0)])
	reference.gesture_begin(Vector2i(1, 0))
	var expected_result := bool(reference.call("prepare_for_train_sampling", 0.0, 1.0))
	var expected_active_after := bool(reference.call("gesture_is_active"))
	var was_active := successful.is_left_capture_active()
	var original_result := bool(successful.call("prepare_for_train_sampling", 0.0, 1.0))
	var active_after := successful.is_runtime_gesture_active()
	assert_true(was_active, "True overlap fixture starts with active facade capture")
	assert_equal(original_result, expected_result, "Facade returns the public runtime result unchanged")
	assert_equal(active_after, expected_active_after, "Facade observes the public runtime active state")
	assert_false(active_after, "Successful overlapping preparation ends runtime capture")
	assert_false(successful.is_left_capture_active(), "Successful overlapping preparation clears facade capture")
	assert_equal(successful.is_left_capture_active(), was_active and active_after, "Successful capture clearing follows was_active and active_after")

	var false_overlap_config := _config()
	var false_overlap = TrackSystemScript.new(false_overlap_config)
	false_overlap.apply_left_input(_left_frame([Vector2i(1, 0)], true, true))
	var false_overlap_reference = GridTrackRuntimeScript.new(
		false_overlap_config.departure_cell,
		false_overlap_config.total_track_cells,
		false_overlap_config.grid_origin_units,
		false_overlap_config.grid_size,
		false_overlap_config.grid_cell_size_units
	)
	false_overlap_reference.append_cells([Vector2i(1, 0)])
	false_overlap_reference.gesture_begin(Vector2i(1, 0))
	var expected_false_overlap_result := bool(false_overlap_reference.call("prepare_for_train_sampling", 0.0, 2.0))
	var expected_false_overlap_active := bool(false_overlap_reference.call("gesture_is_active"))
	var false_overlap_was_active := false_overlap.is_left_capture_active()
	print("Endpoint reshape: prepare false returns false and clears capture")
	var false_overlap_result := bool(false_overlap.call("prepare_for_train_sampling", 0.0, 2.0))
	var false_overlap_active_after := false_overlap.is_runtime_gesture_active()
	assert_false(expected_false_overlap_result, "False overlap reference returns false after its through owner is missing")
	assert_false(expected_false_overlap_active, "False overlap reference terminates its active gesture")
	assert_false(false_overlap_result, "False overlap facade returns the original false result")
	assert_equal(false_overlap_result, expected_false_overlap_result, "Facade preserves the false overlap runtime result")
	assert_equal(false_overlap_active_after, expected_false_overlap_active, "Facade observes false overlap active state")
	assert_equal(false_overlap.is_left_capture_active(), false_overlap_was_active and false_overlap_active_after, "False overlap clears capture iff active became false")

	var ordered_nonoverlap_config := _config()
	var ordered_nonoverlap = TrackSystemScript.new(ordered_nonoverlap_config)
	ordered_nonoverlap.apply_left_input(_left_frame([Vector2i(1, 0)], true, true))
	var ordered_nonoverlap_reference = GridTrackRuntimeScript.new(
		ordered_nonoverlap_config.departure_cell,
		ordered_nonoverlap_config.total_track_cells,
		ordered_nonoverlap_config.grid_origin_units,
		ordered_nonoverlap_config.grid_size,
		ordered_nonoverlap_config.grid_cell_size_units
	)
	ordered_nonoverlap_reference.append_cells([Vector2i(1, 0)])
	ordered_nonoverlap_reference.gesture_begin(Vector2i(1, 0))
	var expected_ordered_nonoverlap_result := bool(ordered_nonoverlap_reference.call("prepare_for_train_sampling", 2.0, 3.0))
	var expected_ordered_nonoverlap_active := bool(ordered_nonoverlap_reference.call("gesture_is_active"))
	var ordered_nonoverlap_was_active := ordered_nonoverlap.is_left_capture_active()
	var ordered_nonoverlap_result := bool(ordered_nonoverlap.call("prepare_for_train_sampling", 2.0, 3.0))
	var ordered_nonoverlap_active_after := ordered_nonoverlap.is_runtime_gesture_active()
	assert_false(expected_ordered_nonoverlap_result, "Ordered out-of-route reference returns false")
	assert_true(expected_ordered_nonoverlap_active, "Ordered out-of-route reference keeps its active gesture")
	assert_false(ordered_nonoverlap_result, "Ordered out-of-route facade returns false")
	assert_equal(ordered_nonoverlap_result, expected_ordered_nonoverlap_result, "Facade preserves ordered nonoverlap runtime result")
	assert_equal(ordered_nonoverlap_active_after, expected_ordered_nonoverlap_active, "Facade observes ordered nonoverlap active state")
	assert_equal(ordered_nonoverlap.is_left_capture_active(), ordered_nonoverlap_was_active and ordered_nonoverlap_active_after, "Ordered nonoverlap preserves capture while active")


func _test_prepare_termination_waits_for_release() -> void:
	print("Endpoint reshape: held motion waits for release after termination")
	var track = TrackSystemScript.new(_config())
	track.apply_left_input(_left_frame([Vector2i(1, 0)], true, true))
	assert_true(track.call("prepare_for_train_sampling", 0.0, 1.0), "Overlapping preparation succeeds before held-motion check")
	var endpoint_after_prepare := track.get_endpoint_cell()
	track.apply_left_input(_left_frame([Vector2i(2, 0)], false, true, false, endpoint_after_prepare))
	assert_equal(track.get_endpoint_cell(), endpoint_after_prepare, "Held motion after preparation termination is ignored")
	track.apply_left_input(_left_frame([], false, false, true, endpoint_after_prepare))
	track.apply_left_input(_left_frame([Vector2i(2, 0)], true, true, false, endpoint_after_prepare))
	assert_true(track.is_left_capture_active(), "Fresh press after release starts a new capture")

func _record_values(records: Array) -> Array:
	var values: Array = []
	for record in records:
		values.append({
			"route_serial": record.route_serial,
			"cell": record.cell,
			"route_distance_start_cells": record.route_distance_start_cells,
			"state": record.state,
			"build_progress": record.build_progress,
			"geometry_group_id": record.geometry_group_id,
			"geometry_locked": record.geometry_locked,
		})
	return values


func _piece_values(pieces: Array) -> Array:
	var values: Array = []
	for piece in pieces:
		values.append({
			"group_id": piece.group_id,
			"kind": piece.kind,
			"first_route_serial": piece.first_route_serial,
			"last_route_serial": piece.last_route_serial,
			"nominal_length_cells": piece.nominal_length_cells,
			"absolute_start_distance_cells": piece.absolute_start_distance_cells,
			"footprint_cells": piece.footprint_cells,
			"centerline": piece.centerline,
			"locked": piece.locked,
			"exit_support_route_serial": piece.exit_support_route_serial,
			"active_local_start_cells": piece.active_local_start_cells,
			"active_local_end_cells": piece.active_local_end_cells,
		})
	return values


func _test_observation_getters_are_detached() -> void:
	var track = TrackSystemScript.new(_config())
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	track.apply_left_input(_left_frame(cells, true))
	var records = track.get_cell_records()
	var pieces = track.get_geometry_pieces()
	var contacts = track.get_contact_observations()
	records[0].cell = Vector2i(9, 9)
	pieces[0].centerline[0] = Vector2(999.0, 999.0)
	contacts.append({"nested": [Vector2i(9, 9)]})
	assert_equal(track.get_cell_records()[0].cell, Vector2i(1, 0), "Cell records are detached")
	assert_false(
		track.get_geometry_pieces()[0].centerline[0].is_equal_approx(Vector2(999.0, 999.0)),
		"Piece centerlines are detached"
	)
	assert_equal(track.get_contact_observations(), [], "Contact observations are detached")
