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
	_test_departure_transition_moves_from_departure_center()
	_test_right_cancellation_wins_before_buffered_left_cells()
	_test_recovery_refund_is_not_spendable_until_next_tick()
	_test_regular_expiry_wins_a_same_tick_track_end_tie()
	_test_snapshot_recursively_detaches_grid_observations()
	return finish()


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
	var snapshot = SessionSnapshotScript.new(
		10, 2, 8, 1, true, int(SessionControllerScript.State.RUNNING),
		records, pieces, contacts, 1.0, 3, 4, Vector2(10.0, 10.0),
		1, 1, 0.5, true, 0.5, Vector2(50.0, 30.0), Vector2.RIGHT,
		0.5, true, &"d", Vector2i(0, 0)
	)
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
