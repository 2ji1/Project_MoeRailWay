extends "res://tests/support/prototype_test.gd"

const SessionEconomyScript = preload("res://src/domain/economy/session_economy.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const GridTrackRuntimeScript = preload("res://src/domain/track/grid_track_runtime.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")

const TRACK_INVESTMENT_BALANCE_PATH := "res://src/config/track_investment_balance.gd"


func run() -> PackedStringArray:
	_test_paid_demolition_surface_exists()
	_test_free_ghost_cancellation_never_spends()
	_test_front_suffix_demolition_is_atomic()
	_test_rear_prefix_and_unsafe_spans()
	_test_curve_exit_support_retirement_and_exact_evidence()
	_test_controller_consumes_one_paid_request_and_publishes_cash()
	return finish()


func _test_paid_demolition_surface_exists() -> void:
	assert_true(ResourceLoader.exists(TRACK_INVESTMENT_BALANCE_PATH), "Track investment balance exists")
	var track = TrackSystemScript.new(_config())
	for method_name in [
		&"take_paid_demolition_request",
		&"try_commit_paid_demolition",
	]:
		assert_true(track.has_method(method_name), "Track system exposes %s" % method_name)


func _test_free_ghost_cancellation_never_spends() -> void:
	var track = TrackSystemScript.new(_config())
	var economy = SessionEconomyScript.new(300)
	_append(track, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])
	assert_true(track.apply_right_input(_right_frame(Vector2i(2, 0))), "Ghost cancellation consumes right edge")
	assert_equal(track.get_endpoint_cell(), Vector2i(1, 0), "Ghost click removes its free suffix")
	assert_equal(track.get_available_track_cells(), 7, "Free suffix returns every removed cell")
	assert_equal(economy.get_cash(), 300, "Free suffix never spends cash")
	if track.has_method("take_paid_demolition_request"):
		assert_equal(track.call("take_paid_demolition_request"), -1, "Free suffix creates no paid request")


func _test_front_suffix_demolition_is_atomic() -> void:
	var track = TrackSystemScript.new(_config())
	var economy = SessionEconomyScript.new(300)
	_append(track, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0)])
	assert_equal(track.advance_construction(4.0), 4.0, "Front fixture builds every record")
	track.apply_right_input(_right_frame(Vector2i(4, 0)))
	if not track.has_method("take_paid_demolition_request") or not track.has_method("try_commit_paid_demolition"):
		return
	var request: int = track.call("take_paid_demolition_request")
	assert_true(request > 0, "Built click retains one exact route serial")
	var locked_before := _locked_ledger_observation(track)
	assert_true(track.call("try_commit_paid_demolition", request, 0.0, 50, economy), "Affordable front suffix commits")
	assert_equal(track.get_cell_records().map(func(record): return record.cell), [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], "Clicked front record through endpoint is removed")
	assert_equal(track.get_available_track_cells(), 5, "Paid suffix returns all removed inventory")
	assert_equal(economy.get_cash(), 250, "Paid suffix charges exactly once")
	assert_equal(_locked_ledger_observation(track), locked_before, "Front suffix preserves immutable locked history")
	assert_true(track._runtime.has_method("get_retired_exit_support_observation"), "Runtime exposes detached exact exit-support retirement evidence")
	if track._runtime.has_method("get_retired_exit_support_observation"):
		var retired_supports: Dictionary = track._runtime.call("get_retired_exit_support_observation")
		assert_equal(retired_supports.size(), 1, "Front suffix records exactly one retired exit support")
		var retired_by_serial: Dictionary = retired_supports.values()[0]
		assert_equal(retired_by_serial, {4: Vector2i(4, 0)}, "Retired evidence binds exact support serial to exact cell")
	assert_false(track.call("try_commit_paid_demolition", request, 0.0, 50, economy), "Consumed identity cannot spend twice")
	assert_equal(economy.get_cash(), 250, "Repeated request cannot charge twice")

	var building_track = TrackSystemScript.new(_config())
	var building_economy = SessionEconomyScript.new(300)
	_append(building_track, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0)])
	building_track.advance_construction(3.5)
	building_track.apply_right_input(_right_frame(Vector2i(4, 0)))
	var building_request: int = building_track.call("take_paid_demolition_request")
	assert_true(building_track.call("try_commit_paid_demolition", building_request, 0.0, 50, building_economy), "BUILDING front suffix uses the same paid path")
	assert_equal(building_track.get_cell_records().size(), 3, "BUILDING click removes itself and trailing ghosts")
	assert_equal(building_economy.get_cash(), 250, "BUILDING suffix charges once")


func _test_rear_prefix_and_unsafe_spans() -> void:
	var track = TrackSystemScript.new(_config())
	var economy = SessionEconomyScript.new(300)
	_append(track, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)])
	track.advance_construction(4.0)
	track.prepare_for_train_sampling(0.0, 3.0)
	var rear_locked_before := _locked_ledger_values(track)
	track.apply_right_input(_right_frame(Vector2i(1, 0)))
	if not track.has_method("take_paid_demolition_request") or not track.has_method("try_commit_paid_demolition"):
		return
	var rear_request: int = track.call("take_paid_demolition_request")
	assert_true(track.call("try_commit_paid_demolition", rear_request, 3.0, 50, economy), "Completed rear prefix commits")
	assert_equal(track.get_cell_records()[0].cell, Vector2i(2, 0), "Rear prefix removes through clicked record")
	assert_equal(track.get_available_track_cells(), 5, "Rear prefix returns one inventory cell")
	assert_equal(_locked_ledger_values(track), rear_locked_before.slice(1), "Rear prefix preserves every retained immutable locked piece byte-for-byte")

	track.apply_right_input(_right_frame(Vector2i(3, 0)))
	var containing_request: int = track.call("take_paid_demolition_request")
	var before_track := _track_observation(track)
	var before_cash := economy.get_observation()
	assert_false(track.call("try_commit_paid_demolition", containing_request, 2.5, 50, economy), "Train-containing record rejects")
	assert_equal(_track_observation(track), before_track, "Unsafe rejection leaves track byte-identical")
	assert_equal(economy.get_observation(), before_cash, "Unsafe rejection leaves economy byte-identical")

	var poor_track = TrackSystemScript.new(_config())
	var poor_economy = SessionEconomyScript.new(49)
	_append(poor_track, [Vector2i(1, 0), Vector2i(2, 0)])
	poor_track.advance_construction(2.0)
	poor_track.apply_right_input(_right_frame(Vector2i(2, 0)))
	var poor_request: int = poor_track.call("take_paid_demolition_request")
	var poor_before := _track_observation(poor_track)
	assert_false(poor_track.call("try_commit_paid_demolition", poor_request, 0.0, 50, poor_economy), "Insufficient cash rejects")
	assert_equal(_track_observation(poor_track), poor_before, "Unaffordable action leaves track byte-identical")
	assert_equal(poor_economy.get_cash(), 49, "Unaffordable action leaves cash unchanged")


func _test_controller_consumes_one_paid_request_and_publishes_cash() -> void:
	var config := _config()
	config.departure_required_built_cells = 8
	config.major_track_action_cost = 50
	config.planning_time_scale_percent = 25
	var track = TrackSystemScript.new(config)
	_append(track, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0)])
	track.advance_construction(4.0)
	var economy = SessionEconomyScript.new(300)
	var train = TrainSystemScript.new(1.0, 100.0)
	var controller = SessionControllerScript.new(
		config, track, train, null, null, null, economy
	)
	controller.start()
	controller.advance_tick(_right_frame(Vector2i(4, 0)))
	assert_equal(economy.get_cash(), 250, "Due controller tick charges one same-tick paid edge")
	assert_equal(track.get_cell_records().size(), 3, "Due controller tick installs one staged demolition")
	var snapshot = controller.get_snapshot()
	assert_equal(snapshot.get_starting_session_cash(), 300, "Snapshot exposes starting provisional cash")
	assert_equal(snapshot.get_current_session_cash(), 250, "Snapshot exposes current provisional cash")
	assert_equal(snapshot.get_total_session_cash_spent(), 50, "Snapshot exposes exact spending")
	controller.advance_tick(_right_frame(Vector2i(4, 0)))
	assert_equal(economy.get_cash(), 250, "Repeated frame cannot charge an already consumed route identity")
	assert_equal(track.get_cell_records().size(), 3, "Repeated frame cannot duplicate demolition")

	var cadence_track = TrackSystemScript.new(config)
	_append(cadence_track, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0)])
	cadence_track.advance_construction(4.0)
	var cadence_economy = SessionEconomyScript.new(300)
	var cadence_controller = SessionControllerScript.new(
		config, cadence_track, TrainSystemScript.new(1.0, 100.0),
		null, null, null, cadence_economy
	)
	cadence_controller.start()
	cadence_controller._state = SessionControllerScript.State.RUNNING
	var endpoint := cadence_track.get_endpoint_cell()
	cadence_track.apply_left_input(TrackInputFrameScript.new(
		[], endpoint, true, Vector2i(-1, -1), false,
		true, true, false, false, endpoint, true
	))
	assert_true(cadence_track.is_runtime_gesture_active(), "Public field input starts the slowdown fixture gesture")
	cadence_controller.advance_tick(TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, false, true, false, endpoint, true
	))
	assert_false(cadence_controller.get_snapshot().did_advance_simulation_tick(), "Public release consumes only its current skipped planning tick")
	assert_false(cadence_track.is_runtime_gesture_active(), "Public release ends the gesture on that skipped tick")
	cadence_controller.advance_tick(_right_frame(Vector2i(4, 0)))
	assert_true(cadence_controller.get_snapshot().did_advance_simulation_tick(), "First post-release real tick restores normal cadence")
	assert_equal(cadence_track.get_cell_records().size(), 3, "Post-release paid edge commits on that same due tick")
	assert_equal(cadence_economy.get_cash(), 250, "Post-release paid edge charges exactly once on that due tick")


func _test_curve_exit_support_retirement_and_exact_evidence() -> void:
	var curve = GridTrackRuntimeScript.new(
		Vector2i(-1, 0), 18, Vector2.ZERO, Vector2i(8, 8), 40.0
	)
	assert_equal(curve.append_cells([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3),
	]), 6, "Curve support fixture appends its route")
	assert_equal(curve.advance_construction(6.0), 6.0, "Curve support fixture builds its route")
	var ledger_before := JSON.stringify(_locked_ledger_values_from_runtime(curve))
	var support_identities_before: Dictionary = curve._exit_support_cells_by_piece.duplicate(true)
	assert_equal(support_identities_before.values()[0], {6: Vector2i(2, 3)}, "Locked curve captures its exact active support identity")
	assert_true(curve.try_paid_demolition(6, 0.0), "Exact locked-curve exit support can be retired")
	assert_equal(curve.get_available_track_cells(), 13, "Curve support demolition returns one inventory cell")
	assert_equal(JSON.stringify(_locked_ledger_values_from_runtime(curve)), ledger_before, "Curve support retirement preserves locked ledger bytes")
	assert_equal(curve._exit_support_cells_by_piece, support_identities_before, "Support retirement preserves the captured immutable identity")
	var retired: Dictionary = curve.get_retired_exit_support_observation()
	assert_equal(retired.values()[0], {6: Vector2i(2, 3)}, "Curve evidence retains exact support serial and cell")
	assert_equal(curve.append_cells([Vector2i(2, 3)]), 1, "Retired support terrain can be reused by later geometry")

	var invalid = curve.duplicate_runtime()
	invalid._sequence.remove_suffix_from_serial(7)
	invalid._exit_support_cells_by_piece.clear()
	var resolution = invalid._resolve_candidate(
		invalid._sequence,
		invalid._locked_ledger,
		invalid._anchors,
		invalid._recovered_cells_by_piece
	)
	assert_true(resolution.is_valid, "Negative fixture resolves before exact support validation")
	if resolution.is_valid:
		invalid._assign_unique_unlocked_group_ids(resolution.pieces, invalid._locked_ledger)
		invalid._sequence.apply_resolved_geometry(resolution.pieces)
		assert_false(invalid._validate_candidate(
			invalid._sequence,
			invalid._locked_ledger,
			resolution,
			invalid._recovered_cells_by_piece,
			invalid._exit_support_cells_by_piece,
			invalid._recovered_end_distance_cells
		), "A recovered support cell without its captured serial identity cannot validate")


func _append(track, cells: Array[Vector2i]) -> void:
	track.apply_left_input(TrackInputFrameScript.new(
		cells, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		true, true, false, false, cells[-1], true, cells
	))
	track.apply_left_input(TrackInputFrameScript.new(
		cells, Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, false, true, false, cells[-1], true, cells
	))


func _right_frame(cell: Vector2i) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, cell, true,
		false, false, false, true
	)


func _track_observation(track) -> String:
	return JSON.stringify({
		"records": track.get_cell_records().map(func(record): return {
		"serial": record.route_serial,
		"cell": record.cell,
		"state": record.state,
		"progress": record.build_progress,
		"group": record.geometry_group_id,
		"locked": record.geometry_locked,
		}),
		"pieces": track.get_geometry_pieces().map(func(piece): return {
			"group": piece.group_id,
			"first": piece.first_route_serial,
			"last": piece.last_route_serial,
			"locked": piece.locked,
			"active_start": piece.active_local_start_cells,
			"active_end": piece.active_local_end_cells,
			"centerline": piece.centerline,
		}),
		"contacts": track.get_contact_observations(),
		"anchors": track._runtime._anchors.map(func(anchor): return {
			"id": anchor.anchor_id,
			"cell": anchor.cell,
			"mode": anchor.contact_mode,
		}),
		"recovered": track._runtime._recovered_cells_by_piece,
		"recovered_end": track._runtime._recovered_end_distance_cells,
		"exit_support_identities": track._runtime._exit_support_cells_by_piece,
		"retired_supports": track._runtime.get_retired_exit_support_observation(),
		"next_serial": track._runtime._sequence._next_route_serial,
		"next_distance": track._runtime._sequence._next_nominal_start_cells,
		"predecessor": track._runtime._sequence._active_predecessor_cell,
		"left_capture": track._left_capture_active,
		"left_latched": track._left_press_latched,
		"paid_request": track._paid_demolition_request_serial,
		"available": track.get_available_track_cells(),
		"total": track.get_total_track_cells(),
		"ledger": _locked_ledger_observation(track),
	})


func _locked_ledger_observation(track) -> String:
	return JSON.stringify(_locked_ledger_values(track))


func _locked_ledger_values(track) -> Array:
	return _locked_ledger_values_from_runtime(track._runtime)


func _locked_ledger_values_from_runtime(runtime) -> Array:
	return runtime._locked_ledger.map(func(piece): return {
		"group": piece.group_id,
		"first": piece.first_route_serial,
		"last": piece.last_route_serial,
		"support": piece.exit_support_route_serial,
		"footprint": piece.footprint_cells,
		"centerline": piece.centerline,
		"active_start": piece.active_local_start_cells,
		"active_end": piece.active_local_end_cells,
	})


func _config() -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		1, 20.0, 1,
		1.0, 8, 2, 2.0, 1.0, 1,
		Vector2(420.0, 260.0), Vector2i(10, 6), 40.0, Vector2(10.0, 10.0),
		&"departure", Vector2(30.0, 30.0), Vector2i(0, 0)
	)
