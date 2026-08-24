extends "res://tests/support/prototype_test.gd"

const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")


func run() -> PackedStringArray:
	_verify_invalid_configuration_probes()
	_test_input_frame_owns_an_independent_cell_buffer()
	_test_facade_preserves_origin_and_exact_inventory()
	_test_endpoint_capture_appends_ordered_cells()
	_test_invalid_candidates_stop_without_corrupting_ownership()
	_test_right_edge_consumes_the_frame_and_cancels_a_suffix()
	_test_right_edge_ends_left_capture_until_a_fresh_press()
	_test_observation_getters_are_detached()
	return finish()


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
	inside: bool = true
) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		cells, press_cell, inside, Vector2i(-1, -1), false,
		pressed, held, released, false
	)


func _right_frame(cell: Vector2i, inside: bool = true) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, cell, inside,
		false, false, false, true
	)


func _test_input_frame_owns_an_independent_cell_buffer() -> void:
	var source: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	var frame = TrackInputFrameScript.new(source)
	source[0] = Vector2i(9, 9)
	assert_equal(frame.crossed_cells, [Vector2i(1, 0), Vector2i(2, 0)], "Frame copies cells")
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
	var release_cells: Array[Vector2i] = [Vector2i(3, 1)]
	track.apply_left_input(_left_frame(release_cells, false, false, true))
	assert_equal(track.get_endpoint_cell(), Vector2i(3, 1), "Release crossings process before capture clears")
	var after_release: Array[Vector2i] = [Vector2i(3, 2)]
	track.apply_left_input(_left_frame(after_release))
	assert_equal(track.get_endpoint_cell(), Vector2i(3, 1), "Held input after release has no capture")


func _test_invalid_candidates_stop_without_corrupting_ownership() -> void:
	var track = TrackSystemScript.new(_config())
	var wrong_start: Array[Vector2i] = [Vector2i(1, 0)]
	track.apply_left_input(_left_frame(wrong_start, true, true, false, Vector2i(4, 4)))
	assert_equal(track.get_cell_records(), [], "A press away from the endpoint discards its buffer")
	var invalid_buffer: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 0), Vector2i(2, 1),
	]
	track.apply_left_input(_left_frame(invalid_buffer, true))
	assert_equal(track.get_cell_records().size(), 2, "Candidates after the first invalid cell are ignored")
	assert_equal(track.get_endpoint_cell(), Vector2i(2, 0), "Invalid suffix cannot move the endpoint")
	assert_equal(track.get_available_track_cells(), 6, "Rejected cells never charge inventory")


func _test_right_edge_consumes_the_frame_and_cancels_a_suffix() -> void:
	var track = TrackSystemScript.new(_config())
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	track.apply_left_input(_left_frame(cells, true))
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
