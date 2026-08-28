extends "res://tests/support/prototype_test.gd"

const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")


func run() -> PackedStringArray:
	_test_valid_running_gesture_uses_literal_four_to_one_cadence()
	_test_departure_transition_moves_from_departure_center()
	_test_right_cancellation_wins_before_buffered_left_cells()
	_test_recovery_refund_is_not_spendable_until_next_tick()
	_test_regular_expiry_wins_a_same_tick_track_end_tie()
	_test_snapshot_recursively_detaches_grid_observations()
	_test_held_gesture_defers_work_until_train_termination()
	_test_active_gesture_controller_tick_preserves_train_sampling_order()
	return finish()


func _test_valid_running_gesture_uses_literal_four_to_one_cadence() -> void:
	var config := _config(20.0, 8, 8, 0.1)
	if not _object_has_property(config, &"planning_time_scale_percent"):
		assert_true(false, "Runtime config exposes planning time scale")
		return
	config.set("planning_time_scale_percent", 25)
	var track = TrackSystemScript.new(config)
	var controller = SessionControllerScript.new(config, track, TrainSystemScript.new(0.1))
	controller.start()
	controller.advance_tick(_left([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)], Vector2i(0, 0)))
	var endpoint := track.get_endpoint_cell()
	var press := _held_endpoint(endpoint)
	controller.advance_tick(press)
	var press_snapshot = controller.get_snapshot()
	assert_true(press_snapshot.call("is_planning_slowdown_active"), "Accepted press publishes active planning")
	assert_equal(press_snapshot.call("get_planning_time_scale_percent"), 25, "Accepted press publishes configured percentage")
	assert_true(press_snapshot.call("did_advance_simulation_tick"), "Accepted press remains a simulation tick")
	var elapsed_after_press := press_snapshot.get_elapsed_ticks()
	var distance_after_press := press_snapshot.get_train_route_distance_cells()
	var expected_did_advance := [false, false, false, true]
	var expected_elapsed := [elapsed_after_press, elapsed_after_press, elapsed_after_press, elapsed_after_press + 1]
	var expected_distance := [distance_after_press, distance_after_press, distance_after_press, distance_after_press + 0.1]
	for index in range(4):
		controller.advance_tick(_held_endpoint(endpoint))
		var snapshot = controller.get_snapshot()
		assert_equal(snapshot.call("did_advance_simulation_tick"), expected_did_advance[index], "Literal planning cadence step %d" % (index + 1))
		assert_equal(snapshot.get_elapsed_ticks(), expected_elapsed[index], "Elapsed cadence step %d" % (index + 1))
		assert_equal(snapshot.get_train_route_distance_cells(), expected_distance[index], "Train cadence step %d" % (index + 1))
	var due_snapshot = controller.get_snapshot()
	controller.advance_tick(_release_endpoint(endpoint))
	var released = controller.get_snapshot()
	assert_false(released.is_planning_slowdown_active(), "Release hides planning immediately")
	assert_false(released.did_advance_simulation_tick(), "Release consumes its slowed real tick without simulation")
	assert_equal(released.get_elapsed_ticks(), due_snapshot.get_elapsed_ticks(), "Release adds no catch-up simulation")
	controller.advance_tick()
	var resumed = controller.get_snapshot()
	assert_true(resumed.did_advance_simulation_tick(), "First post-release real tick resumes normal simulation")
	assert_equal(resumed.get_elapsed_ticks(), due_snapshot.get_elapsed_ticks() + 1, "Post-release cadence advances exactly once")
	assert_equal(resumed.get_train_route_distance_cells(), due_snapshot.get_train_route_distance_cells() + 0.1, "Post-release train movement advances exactly once")


func _object_has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if property.get("name", StringName()) == property_name:
			return true
	return false


func _config(
	duration: float = 10.0,
	total_cells: int = 4,
	recovery_lag: int = 1,
	train_speed: float = 1.0
) -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		3, duration, 1,
		train_speed, total_cells, recovery_lag, 2.0, 10.0, 1,
		Vector2(320.0, 240.0), Vector2i(8, 6), 40.0, Vector2.ZERO,
		&"phase_departure", Vector2(20.0, 20.0), Vector2i(0, 0)
	)


func _left(cells: Array[Vector2i], press_cell: Vector2i) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		cells, press_cell, true, Vector2i(-1, -1), false,
		true, false, true, false, cells[-1], true
	)


func _held_endpoint(endpoint: Vector2i) -> TrackInputFrameScript:
	var empty: Array[Vector2i] = []
	return TrackInputFrameScript.new(
		empty, endpoint, true, Vector2i(-1, -1), false,
		true, true, false, false, endpoint, true
	)


func _held_route(cells: Array[Vector2i], press_cell: Vector2i) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		cells, press_cell, true, Vector2i(-1, -1), false,
		true, true, false, false, cells[-1], true
	)


func _release_endpoint(endpoint: Vector2i) -> TrackInputFrameScript:
	var empty: Array[Vector2i] = []
	return TrackInputFrameScript.new(
		empty, endpoint, true, Vector2i(-1, -1), false,
		false, false, true, false, endpoint, true
	)


func _test_departure_transition_moves_from_departure_center() -> void:
	var config = SessionStartConfigScript.new(
		3, 10.0, 60,
		1.0, 4, 1, 2.0, 60.0, 1,
		Vector2(320.0, 240.0), Vector2i(8, 6), 40.0, Vector2.ZERO,
		&"phase_departure", Vector2(20.0, 20.0), Vector2i(0, 0)
	)
	var track = TrackSystemScript.new(config)
	var controller = SessionControllerScript.new(config, track, TrainSystemScript.new(1.0))
	controller.start()
	var first_cell: Array[Vector2i] = [Vector2i(1, 0)]
	controller.advance_tick(_left(first_cell, Vector2i(0, 0)))
	var snapshot = controller.get_snapshot()
	assert_true(snapshot.is_train_active(), "Train departs after the required cell is built")
	assert_true(
		snapshot.get_train_position().is_equal_approx(Vector2(20.0 + 40.0 / 60.0, 20.0)),
		"First active snapshot advances continuously from the departure center"
	)


func _test_right_cancellation_wins_before_buffered_left_cells() -> void:
	var config := _config()
	var track = TrackSystemScript.new(config)
	var initial: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	track.apply_left_input(_left(initial, Vector2i(0, 0)))
	var controller = SessionControllerScript.new(config, track, TrainSystemScript.new(1.0))
	controller.start()
	var buffered: Array[Vector2i] = [Vector2i(3, 1)]
	controller.advance_tick(TrackInputFrameScript.new(
		buffered, Vector2i(3, 0), true, Vector2i(2, 0), true,
		true, false, true, true, Vector2i(3, 1), true
	))
	assert_equal(track.get_endpoint_cell(), Vector2i(1, 0), "Right cancellation wins before left buffer")
	assert_equal(track.get_cell_records().size(), 1, "Same-tick left cell was not accepted")


func _test_recovery_refund_is_not_spendable_until_next_tick() -> void:
	var config := _config(10.0, 2, 0, 1.0)
	var track = TrackSystemScript.new(config)
	var initial: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	track.apply_left_input(_left(initial, Vector2i(0, 0)))
	track.advance_construction(2.0)
	var controller = SessionControllerScript.new(config, track, TrainSystemScript.new(1.0))
	controller.start()
	var next_cell: Array[Vector2i] = [Vector2i(3, 0)]
	controller.advance_tick(_left(next_cell, Vector2i(2, 0)))
	assert_equal(track.get_endpoint_cell(), Vector2i(2, 0), "Refund cannot fund earlier input in the same tick")
	assert_equal(track.get_available_track_cells(), 1, "Recovery becomes visible after input phase")
	controller.advance_tick(_left(next_cell, Vector2i(2, 0)))
	assert_equal(track.get_endpoint_cell(), Vector2i(3, 0), "Refund funds input on the next tick")


func _test_regular_expiry_wins_a_same_tick_track_end_tie() -> void:
	var config := _config(1.0, 1, 0, 1.0)
	var track = TrackSystemScript.new(config)
	var one: Array[Vector2i] = [Vector2i(1, 0)]
	track.apply_left_input(_left(one, Vector2i(0, 0)))
	track.advance_construction(1.0)
	var controller = SessionControllerScript.new(config, track, TrainSystemScript.new(1.0))
	var reasons: Array[int] = []
	controller.session_completed.connect(func(result): reasons.append(result.get_reason()))
	controller.start()
	controller.advance_tick()
	assert_equal(reasons, [SessionResultScript.Reason.REGULAR_TIME_EXPIRED], "Regular expiry has tie priority")


func _test_snapshot_recursively_detaches_grid_observations() -> void:
	print("Endpoint reshape: train session snapshot detaches endpoint gesture facts")
	var record = TrackCellRecordScript.new(1, Vector2i(1, 0), 0.0)
	var piece = TrackGeometryPieceScript.new()
	piece.group_id = 4
	piece.first_route_serial = 1
	piece.last_route_serial = 1
	piece.nominal_length_cells = 1
	var footprint: Array[Vector2i] = [Vector2i(1, 0)]
	piece.footprint_cells = footprint
	piece.centerline = PackedVector2Array([Vector2(30.0, 30.0), Vector2(70.0, 30.0)])
	var records: Array[TrackCellRecordScript] = [record]
	var pieces: Array[TrackGeometryPieceScript] = [piece]
	var contacts: Array[Dictionary] = [{"anchor_id": &"d", "nested": [[Vector2i(1, 0)]]}]
	var eligible_source := true
	var active_source := true
	var snapshot = SessionSnapshotScript.new(
		10, 2, 8, 1, true, int(SessionControllerScript.State.RUNNING),
		records, pieces, contacts, 1.0, 3, 4, Vector2(10.0, 10.0),
		1, 1, 0.5, true, 0.5, Vector2(50.0, 30.0), Vector2.RIGHT,
		0.5, true, &"d", Vector2i(0, 0), eligible_source, active_source
	)
	eligible_source = false
	active_source = false
	record.cell = Vector2i(9, 9)
	piece.footprint_cells[0] = Vector2i(9, 9)
	piece.centerline[0] = Vector2(999.0, 999.0)
	contacts[0]["nested"][0][0] = Vector2i(9, 9)
	var observed_records = snapshot.get_cell_records()
	var observed_pieces = snapshot.get_geometry_pieces()
	var observed_contacts = snapshot.get_contact_observations()
	assert_equal(observed_records[0].cell, Vector2i(1, 0), "Constructor detaches records")
	assert_equal(observed_pieces[0].footprint_cells[0], Vector2i(1, 0), "Footprints detach")
	assert_equal(observed_pieces[0].centerline[0], Vector2(30.0, 30.0), "Centerlines detach")
	assert_equal(observed_contacts[0]["nested"][0][0], Vector2i(1, 0), "Nested contacts detach")
	observed_records[0].cell = Vector2i(8, 8)
	observed_pieces[0].centerline[0] = Vector2(888.0, 888.0)
	observed_contacts[0]["nested"][0][0] = Vector2i(8, 8)
	assert_equal(snapshot.get_cell_records()[0].cell, Vector2i(1, 0), "Record getter detaches")
	assert_equal(snapshot.get_geometry_pieces()[0].centerline[0], Vector2(30.0, 30.0), "Piece getter detaches")
	assert_equal(snapshot.get_contact_observations()[0]["nested"][0][0], Vector2i(1, 0), "Contact getter detaches")
	assert_equal(snapshot.get_grid_origin_units(), Vector2(10.0, 10.0), "Origin exposed")
	assert_equal(snapshot.get_departure_cell(), Vector2i(0, 0), "Departure cell exposed")
	assert_equal(snapshot.get_available_track_cells(), 3, "Integer inventory exposed")
	assert_equal(snapshot.get_train_route_distance_cells(), 0.5, "Nominal distance exposed")
	assert_true(snapshot.has_method("is_endpoint_gesture_eligible"), "Train snapshot exposes endpoint eligibility getter")
	assert_true(snapshot.has_method("is_endpoint_gesture_active"), "Train snapshot exposes endpoint active getter")
	if snapshot.has_method("is_endpoint_gesture_eligible"):
		assert_true(snapshot.call("is_endpoint_gesture_eligible"), "Train snapshot detaches endpoint eligibility")
	if snapshot.has_method("is_endpoint_gesture_active"):
		assert_true(snapshot.call("is_endpoint_gesture_active"), "Train snapshot detaches endpoint active state")


func _test_held_gesture_defers_work_until_train_termination() -> void:
	print("Endpoint reshape: origin construction and recovery lifecycle")
	var config := _config(5.0, 4, 1, 1.0)
	var track = TrackSystemScript.new(config)
	track.apply_left_input(_held_route([Vector2i(1, 0), Vector2i(2, 0)], Vector2i(0, 0)))
	track.apply_left_input(_release_endpoint(Vector2i(2, 0)))
	assert_equal(track.advance_construction(1.5), 1.5, "Held-gesture fixture leaves a recoverable unfinished route")
	var endpoint := track.get_endpoint_cell()
	track.apply_left_input(_held_endpoint(endpoint))
	assert_true(track.is_runtime_gesture_active(), "Held-gesture fixture remains active without release")
	assert_equal(track.advance_construction(0.5), 0.5, "Origin-owned construction advances while the gesture is held")
	assert_equal(track.get_cell_records()[-1].build_progress, 1.0, "Held gesture completes the shared origin serial")
	assert_equal(track.recover_behind(1.0), 1, "Recovery advances transactionally while the gesture is held")
	var controller = SessionControllerScript.new(config, track, TrainSystemScript.new(config.train_speed_cells_per_second))
	controller.start()
	controller.advance_tick()
	assert_false(track.is_runtime_gesture_active(), "Overlapping train preparation terminates the held gesture")
	assert_equal(track.advance_construction(0.5), 0.0, "No construction budget remains after the origin frontier completes")
	assert_equal(track.recover_behind(1.0), 0, "Train termination does not repeat already committed recovery")


func _test_active_gesture_controller_tick_preserves_train_sampling_order() -> void:
	print("Active gesture construction: train controller advances origin before sampling")
	var config := _config(5.0, 4, 1, 1.0)
	var track := TrackSystemScript.new(config)
	track.apply_left_input(_held_route([Vector2i(1, 0), Vector2i(2, 0)], Vector2i(0, 0)))
	track.apply_left_input(_release_endpoint(Vector2i(2, 0)))
	assert_equal(track.advance_construction(1.5), 1.5, "Train causal fixture creates partial origin progress")
	var endpoint := track.get_endpoint_cell()
	var held_path: Array[Vector2i] = [Vector2i(3, 0)]
	var held_frame := TrackInputFrameScript.new(
		held_path, endpoint, true, Vector2i(-1, -1), false,
		true, true, false, false, held_path[-1], true, held_path
	)
	var controller := SessionControllerScript.new(config, track, TrainSystemScript.new(config.train_speed_cells_per_second))
	controller.start()
	controller.advance_tick(held_frame)
	var records := track.get_cell_records()
	assert_equal(records[1].state, TrackCellRecordScript.State.BUILT, "Train controller completes the shared origin serial")
	assert_equal(records[-1].state, TrackCellRecordScript.State.RESERVED_GHOST, "Train controller leaves suffix ghost-only")
	assert_false(track.is_runtime_gesture_active(), "Overlapping train sampling terminates the gesture safely")
