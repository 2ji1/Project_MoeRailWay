extends "res://tests/support/prototype_test.gd"

const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionEconomyScript = preload("res://src/domain/economy/session_economy.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")

const FIRST_ROUTE: Array[Vector2i] = [
	Vector2i(1, 2),
	Vector2i(2, 2),
	Vector2i(3, 2),
	Vector2i(4, 2),
	Vector2i(5, 2),
	Vector2i(6, 2),
	Vector2i(7, 2),
]
const CROSSING_APPROACH: Array[Vector2i] = [
	Vector2i(8, 2),
	Vector2i(9, 2),
	Vector2i(9, 3),
	Vector2i(9, 4),
	Vector2i(9, 5),
	Vector2i(9, 6),
	Vector2i(9, 7),
	Vector2i(8, 7),
	Vector2i(7, 7),
	Vector2i(6, 7),
	Vector2i(5, 7),
	Vector2i(4, 7),
	Vector2i(3, 7),
	Vector2i(2, 7),
	Vector2i(2, 6),
	Vector2i(2, 5),
	Vector2i(2, 4),
	Vector2i(2, 3),
]
const COMPLETE_CROSSING: Array[Vector2i] = [
	Vector2i(8, 2),
	Vector2i(9, 2),
	Vector2i(9, 3),
	Vector2i(9, 4),
	Vector2i(9, 5),
	Vector2i(9, 6),
	Vector2i(9, 7),
	Vector2i(8, 7),
	Vector2i(7, 7),
	Vector2i(6, 7),
	Vector2i(5, 7),
	Vector2i(4, 7),
	Vector2i(3, 7),
	Vector2i(2, 7),
	Vector2i(2, 6),
	Vector2i(2, 5),
	Vector2i(2, 4),
	Vector2i(2, 3),
	Vector2i(2, 2),
	Vector2i(2, 1),
]
const MULTI_BASE_ROUTE: Array[Vector2i] = [
	Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
	Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2),
	Vector2i(9, 2), Vector2i(9, 3), Vector2i(9, 4), Vector2i(9, 5),
	Vector2i(8, 5), Vector2i(7, 5), Vector2i(6, 5), Vector2i(5, 5),
	Vector2i(4, 5), Vector2i(3, 5),
]
const MULTI_CROSSING_PATH: Array[Vector2i] = [
	Vector2i(2, 5), Vector2i(1, 5), Vector2i(1, 6), Vector2i(1, 7),
	Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4, 8),
	Vector2i(4, 7), Vector2i(4, 6), Vector2i(4, 5), Vector2i(4, 4),
	Vector2i(4, 3), Vector2i(4, 2), Vector2i(4, 1),
]


func run() -> PackedStringArray:
	_test_complete_perpendicular_crossing_creates_a_second_ordered_occurrence()
	_test_endpoint_eligibility_recognizes_an_immediate_crossing()
	_test_incomplete_and_branch_like_reentry_preserve_last_valid_preview()
	_test_crossing_finalize_charges_once_and_abort_is_free()
	_test_unaffordable_finalize_is_byte_identical_and_backtracking_is_free()
	_test_crossing_occurrences_sample_contact_and_damage_independently()
	_test_recovery_preserves_the_remaining_crossing_occurrence()
	_test_pointer_selection_targets_one_crossing_occurrence()
	_test_multiple_crossings_charge_once_per_occurrence()
	return finish()


func _test_complete_perpendicular_crossing_creates_a_second_ordered_occurrence() -> void:
	var track := _built_horizontal_track()
	var locked_before := _locked_geometry_observation(track)
	assert_true(_begin_gesture(track), "Crossing fixture begins at the current endpoint")
	var approach_accepted := _update_gesture(track, CROSSING_APPROACH)
	assert_true(approach_accepted, "A non-overlapping approach remains valid")
	var accepted := _update_gesture(track, COMPLETE_CROSSING)
	assert_true(accepted, "A complete perpendicular opposite-side traversal is accepted")
	if not accepted:
		return

	var records := track.get_cell_records()
	var crossing_records := records.filter(func(record): return record.cell == Vector2i(2, 2))
	assert_equal(crossing_records.size(), 2, "The occupied crossing cell owns two ordered occurrences")
	assert_equal(records.size(), FIRST_ROUTE.size() + COMPLETE_CROSSING.size(), "The crossing consumes one inventory cell per new route occurrence")
	assert_equal(track.get_available_track_cells(), 50 - records.size(), "Crossing inventory follows route occurrence count")
	assert_equal(_locked_geometry_observation(track), locked_before, "The earlier locked centerline remains byte-identical")
	for index in range(records.size()):
		assert_equal(records[index].route_serial, index + 1, "Route serials remain strictly monotonic")
		assert_equal(records[index].route_distance_start_cells, float(index), "Nominal route distance remains ordered")
	if crossing_records.size() == 2:
		assert_false(bool(crossing_records[0].get("grade_separated_crossing")), "The earlier occurrence remains ordinary")
		assert_true(bool(crossing_records[1].get("grade_separated_crossing")), "Only the later occurrence owns crossing identity")


func _test_endpoint_eligibility_recognizes_an_immediate_crossing() -> void:
	var track := _built_horizontal_track()
	_append_and_release(track, CROSSING_APPROACH)
	track.advance_construction(100.0)
	assert_true(
		track.prepare_for_train_sampling(0.0, track.get_built_end_distance_cells()),
		"Immediate-crossing fixture locks the approach"
	)
	var endpoint := track.get_endpoint_cell()
	assert_equal(endpoint, Vector2i(2, 3), "Immediate-crossing fixture ends beside the occupied cell")
	var ordinary_candidate = track._runtime._sequence.duplicate_sequence()
	assert_equal(
		ordinary_candidate.try_append_candidate(Vector2i(2, 2)),
		null,
		"The occupied crossing cell is not an ordinary append"
	)
	assert_equal(
		track._runtime._crossing_partner_for_candidate(
			track._runtime._sequence,
			Vector2i(2, 2),
			Vector2i(2, 1)
		),
		2,
		"The complete opposite-side traversal resolves the exact earlier partner"
	)
	assert_true(track.is_endpoint_gesture_eligible(), "Endpoint eligibility includes an immediate legal crossing")


func _test_incomplete_and_branch_like_reentry_preserve_last_valid_preview() -> void:
	var stop_track := _built_horizontal_track()
	assert_true(_begin_gesture(stop_track), "Stop-on-cell fixture begins")
	assert_true(_update_gesture(stop_track, CROSSING_APPROACH), "Stop-on-cell fixture publishes its approach")
	var stop_before := _track_observation(stop_track)
	var stop_path := CROSSING_APPROACH.duplicate()
	stop_path.append(Vector2i(2, 2))
	assert_false(_update_gesture(stop_track, stop_path), "Stopping on an occupied cell does not infer a crossing")
	assert_equal(_track_observation(stop_track), stop_before, "Rejected stop-on-cell preserves the last valid preview")

	var branch_track := _built_horizontal_track()
	assert_true(_begin_gesture(branch_track), "Branch-like fixture begins")
	assert_true(_update_gesture(branch_track, CROSSING_APPROACH), "Branch-like fixture publishes its approach")
	var branch_before := _track_observation(branch_track)
	var branch_path := CROSSING_APPROACH.duplicate()
	branch_path.append_array([Vector2i(2, 2), Vector2i(3, 2)])
	assert_false(_update_gesture(branch_track, branch_path), "A turn through occupied track does not create a branch-like crossing")
	assert_equal(_track_observation(branch_track), branch_before, "Rejected branch-like reentry preserves the last valid preview")

	var uturn_track := _built_horizontal_track()
	assert_true(_begin_gesture(uturn_track), "U-turn fixture begins")
	assert_true(_update_gesture(uturn_track, CROSSING_APPROACH), "U-turn fixture publishes its approach")
	var uturn_before := _track_observation(uturn_track)
	var uturn_path := CROSSING_APPROACH.duplicate()
	uturn_path.append_array([Vector2i(2, 2), Vector2i(2, 3)])
	assert_false(_update_gesture(uturn_track, uturn_path), "Entering and leaving through the same side rejects as a U-turn")
	assert_equal(_track_observation(uturn_track), uturn_before, "Rejected U-turn preserves the last valid preview")

	var diagonal_track := _built_horizontal_track()
	assert_true(_begin_gesture(diagonal_track), "Diagonal fixture begins")
	var diagonal_approach: Array[Vector2i] = [
		Vector2i(8, 2), Vector2i(9, 2), Vector2i(9, 3), Vector2i(9, 4),
		Vector2i(9, 5), Vector2i(9, 6), Vector2i(9, 7), Vector2i(8, 7),
		Vector2i(7, 7), Vector2i(6, 7), Vector2i(5, 7), Vector2i(4, 7),
		Vector2i(3, 7), Vector2i(3, 6), Vector2i(3, 5), Vector2i(3, 4),
		Vector2i(3, 3),
	]
	assert_true(_update_gesture(diagonal_track, diagonal_approach), "Diagonal fixture publishes its non-overlapping approach")
	var diagonal_before := _track_observation(diagonal_track)
	var diagonal_path := diagonal_approach.duplicate()
	diagonal_path.append_array([Vector2i(2, 2), Vector2i(2, 1)])
	assert_false(_update_gesture(diagonal_track, diagonal_path), "A diagonal entry into occupied track rejects")
	assert_equal(_track_observation(diagonal_track), diagonal_before, "Rejected diagonal entry preserves the last valid preview")


func _test_crossing_finalize_charges_once_and_abort_is_free() -> void:
	var config := _config()
	config.departure_required_built_cells = 99
	config.major_track_action_cost = 50
	var track := TrackSystemScript.new(config)
	_append_and_release(track, FIRST_ROUTE)
	assert_equal(track.advance_construction(float(FIRST_ROUTE.size())), float(FIRST_ROUTE.size()), "Transactional fixture locks the first route")
	assert_true(track.prepare_for_train_sampling(0.0, float(FIRST_ROUTE.size())), "Transactional fixture freezes the earlier geometry")
	var economy := SessionEconomyScript.new(300)
	var controller := SessionControllerScript.new(
		config,
		track,
		TrainSystemScript.new(1.0, 100.0),
		null,
		null,
		null,
		economy
	)
	controller.start()
	controller.advance_tick(_held_frame(track.get_endpoint_cell(), COMPLETE_CROSSING))
	assert_equal(economy.get_cash(), 300, "A pending crossing preview does not charge")
	controller.advance_tick(_release_frame(COMPLETE_CROSSING))
	assert_equal(economy.get_cash(), 250, "Finalizing one crossing charges the shared major-track-action cost once")
	assert_equal(track.get_cell_records().size(), FIRST_ROUTE.size() + COMPLETE_CROSSING.size(), "Affordable finalize commits the entire ordered candidate")

	var abort_track := TrackSystemScript.new(config)
	_append_and_release(abort_track, FIRST_ROUTE)
	abort_track.advance_construction(float(FIRST_ROUTE.size()))
	abort_track.prepare_for_train_sampling(0.0, float(FIRST_ROUTE.size()))
	var abort_economy := SessionEconomyScript.new(300)
	var abort_controller := SessionControllerScript.new(
		config,
		abort_track,
		TrainSystemScript.new(1.0, 100.0),
		null,
		null,
		null,
		abort_economy
	)
	abort_controller.start()
	var abort_origin := _track_observation(abort_track)
	abort_controller.advance_tick(_held_frame(abort_track.get_endpoint_cell(), COMPLETE_CROSSING))
	abort_controller.advance_tick(_right_frame(Vector2i(2, 2)))
	assert_equal(_track_observation(abort_track), abort_origin, "Right-click abort restores the exact gesture origin")
	assert_equal(abort_economy.get_cash(), 300, "Right-click abort never charges a pending crossing")


func _test_unaffordable_finalize_is_byte_identical_and_backtracking_is_free() -> void:
	var poor_fixture := _controller_fixture(49)
	var poor_track: TrackSystemScript = poor_fixture.track
	var poor_controller: SessionControllerScript = poor_fixture.controller
	var poor_economy: SessionEconomyScript = poor_fixture.economy
	var poor_before := _track_observation(poor_track)
	var poor_cash_before := poor_economy.get_observation()
	poor_controller.advance_tick(_held_frame(poor_track.get_endpoint_cell(), COMPLETE_CROSSING))
	assert_equal(poor_track._runtime.get_pending_crossing_count(), 1, "Affordable validation publishes one pending crossing before release")
	var poor_snapshot = poor_controller.get_snapshot()
	assert_equal(poor_snapshot.get_pending_crossing_count(), 1, "Snapshot publishes pending crossing count")
	assert_equal(poor_snapshot.get_pending_crossing_total_cost(), 50, "Snapshot publishes pending shared action cost")
	assert_false(poor_snapshot.is_pending_crossing_affordable(), "Snapshot marks the pending candidate unaffordable")
	poor_controller.advance_tick(_release_frame(COMPLETE_CROSSING))
	assert_equal(_track_observation(poor_track), poor_before, "Unaffordable finalize restores byte-identical track state")
	assert_equal(poor_economy.get_observation(), poor_cash_before, "Unaffordable finalize preserves every cash byte")

	var backtrack_fixture := _controller_fixture(300)
	var backtrack_track: TrackSystemScript = backtrack_fixture.track
	var backtrack_controller: SessionControllerScript = backtrack_fixture.controller
	var backtrack_economy: SessionEconomyScript = backtrack_fixture.economy
	backtrack_controller.advance_tick(_held_frame(backtrack_track.get_endpoint_cell(), COMPLETE_CROSSING))
	assert_equal(backtrack_track._runtime.get_pending_crossing_count(), 1, "Complete preview owns one pending crossing")
	backtrack_controller.advance_tick(_motion_frame(CROSSING_APPROACH))
	assert_equal(backtrack_track._runtime.get_pending_crossing_count(), 0, "Backtracking before release removes the pending crossing")
	backtrack_controller.advance_tick(_release_frame(CROSSING_APPROACH))
	assert_equal(backtrack_economy.get_cash(), 300, "Backtracked crossing never charges")
	assert_equal(backtrack_track.get_endpoint_cell(), CROSSING_APPROACH[-1], "Backtracking finalizes only the remaining ordinary suffix")


func _test_crossing_occurrences_sample_contact_and_damage_independently() -> void:
	var fixture := _controller_fixture(300)
	var track: TrackSystemScript = fixture.track
	var controller: SessionControllerScript = fixture.controller
	controller.advance_tick(_held_frame(track.get_endpoint_cell(), COMPLETE_CROSSING))
	controller.advance_tick(_release_frame(COMPLETE_CROSSING))
	track.advance_construction(100.0)
	var built_end := track.get_built_end_distance_cells()
	assert_equal(built_end, float(track.get_cell_records().size()), "Sampling fixture builds the complete crossing route")
	assert_true(track.prepare_for_train_sampling(0.0, built_end), "Sampling fixture locks both crossing occurrences")
	track.set_contact_anchors([
		RouteContactAnchorScript.new(
			&"crossing_exact",
			Vector2i(2, 2),
			RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER
		),
	])
	var observations := track.get_contact_observations()
	assert_equal(observations.size(), 1, "Crossing exact anchor publishes one compatibility observation")
	if observations.is_empty():
		return
	var distances: Array = observations[0].get("contact_distances_cells", [])
	assert_equal(distances.size(), 2, "Exact contact retains both ordered crossing distances")
	if distances.size() != 2:
		return
	assert_equal(observations[0].contact_distance_cells, distances[0], "Legacy scalar retains the earliest exact contact")
	assert_true(float(distances[1]) > float(distances[0]), "Crossing contact distances preserve route order")
	var center := Vector2(100.0, 100.0)
	var first_pose := track.get_pose_sample_at_distance(float(distances[0]))
	var second_pose := track.get_pose_sample_at_distance(float(distances[1]))
	assert_true(first_pose.position.distance_to(center) <= 0.001, "Earlier occurrence samples the cell center")
	assert_true(second_pose.position.distance_to(center) <= 0.001, "Later occurrence samples the same cell center")
	assert_true(absf(first_pose.heading.normalized().dot(second_pose.heading.normalized())) <= 0.001, "Ordered crossing headings remain perpendicular")
	var later_hits := track.get_contact_hits_between(
		float(distances[0]) + 0.1,
		float(distances[1]) + 0.1
	)
	assert_equal(later_hits.size(), 1, "A traveled earlier occurrence cannot hide the later exact contact")
	if later_hits.size() == 1:
		assert_equal(later_hits[0].contact_distance_cells, distances[1], "Later sweep emits the later route distance")
	var hazard_distance := track.get_traveled_hazard_distance_cells(
		[Vector2i(2, 2)],
		0.0,
		built_end
	)
	assert_true(absf(hazard_distance - 2.0) <= 0.001, "Hazard terrain applies once per actual crossing pass")


func _test_recovery_preserves_the_remaining_crossing_occurrence() -> void:
	var fixture := _controller_fixture(300)
	var track: TrackSystemScript = fixture.track
	var controller: SessionControllerScript = fixture.controller
	controller.advance_tick(_held_frame(track.get_endpoint_cell(), COMPLETE_CROSSING))
	controller.advance_tick(_release_frame(COMPLETE_CROSSING))
	track.advance_construction(100.0)
	var built_end := track.get_built_end_distance_cells()
	assert_true(track.prepare_for_train_sampling(0.0, built_end), "Recovery fixture locks the complete crossing route")
	assert_equal(track.recover_behind(2.0), 2, "Recovery removes the earlier crossing occurrence and its prefix")
	var crossing_records := track.get_cell_records().filter(func(record): return record.cell == Vector2i(2, 2))
	assert_equal(crossing_records.size(), 1, "The later crossing occurrence remains active after its partner recovers")
	if crossing_records.size() != 1:
		return
	assert_true(crossing_records[0].grade_separated_crossing, "The surviving occurrence retains crossing identity")
	assert_equal(crossing_records[0].crossing_partner_route_serial, 2, "The surviving occurrence retains its historical partner serial")
	track.set_contact_anchors([
		RouteContactAnchorScript.new(
			&"recovered_crossing_exact",
			Vector2i(2, 2),
			RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER
		),
	])
	var observations := track.get_contact_observations()
	assert_equal(observations.size(), 1, "The surviving crossing occurrence remains contact-addressable")
	if observations.size() != 1:
		return
	var distances: Array = observations[0].get("contact_distances_cells", [])
	assert_equal(distances.size(), 1, "Recovered crossing contact publishes only the active later distance")
	if distances.size() == 1:
		assert_true(float(distances[0]) > 2.0, "The surviving contact keeps its absolute later route distance")


func _test_pointer_selection_targets_one_crossing_occurrence() -> void:
	var fixture := _controller_fixture(300)
	var track: TrackSystemScript = fixture.track
	var controller: SessionControllerScript = fixture.controller
	controller.advance_tick(_held_frame(track.get_endpoint_cell(), COMPLETE_CROSSING))
	controller.advance_tick(_release_frame(COMPLETE_CROSSING))
	var crossing_records := track.get_cell_records().filter(func(record): return record.cell == Vector2i(2, 2))
	assert_equal(crossing_records.size(), 2, "Pointer fixture owns two selectable occurrences")
	if crossing_records.size() != 2:
		return
	var earlier_serial: int = crossing_records[0].route_serial
	var later_serial: int = crossing_records[1].route_serial
	var center := Vector2(100.0, 100.0)
	assert_equal(
		track._runtime.select_route_serial_at_position(Vector2i(2, 2), center, true),
		-1,
		"An exact pointer-distance tie is a no-op"
	)
	assert_equal(
		track._runtime.select_route_serial_at_position(Vector2i(2, 2), center + Vector2(0.2, 0.0), true),
		-1,
		"A pointer-distance difference within 0.01 cell remains a no-op"
	)
	assert_equal(
		track._runtime.select_route_serial_at_position(Vector2i(2, 2), center + Vector2(12.0, 2.0), true),
		earlier_serial,
		"The pointer closer to the horizontal centerline selects the earlier occurrence"
	)
	assert_equal(
		track._runtime.select_route_serial_at_position(Vector2i(2, 2), center + Vector2(2.0, 12.0), true),
		later_serial,
		"The pointer closer to the vertical centerline selects the later occurrence"
	)

	var before_tie := _track_observation(track)
	track.apply_right_input(_right_frame_at(Vector2i(2, 2), center))
	assert_equal(_track_observation(track), before_tie, "A tied right-click changes neither occurrence")
	assert_equal(track.take_paid_demolition_request(), -1, "A tied right-click creates no paid request")

	var ghost_cash: int = fixture.economy.get_cash()
	track.apply_right_input(_right_frame_at(Vector2i(2, 2), center + Vector2(2.0, 12.0)))
	assert_equal(track.get_endpoint_cell(), Vector2i(2, 3), "Selected later ghost cancellation removes the crossing suffix")
	assert_equal(fixture.economy.get_cash(), ghost_cash, "Selected crossing ghost cancellation is free")
	assert_equal(track.take_paid_demolition_request(), -1, "Selected ghost cancellation creates no paid demolition")

	var built_fixture := _controller_fixture(300)
	var built_track: TrackSystemScript = built_fixture.track
	var built_controller: SessionControllerScript = built_fixture.controller
	var built_economy: SessionEconomyScript = built_fixture.economy
	built_controller.advance_tick(_held_frame(built_track.get_endpoint_cell(), COMPLETE_CROSSING))
	built_controller.advance_tick(_release_frame(COMPLETE_CROSSING))
	built_track.advance_construction(100.0)
	built_track.apply_right_input(_right_frame_at(Vector2i(2, 2), center + Vector2(2.0, 12.0)))
	var selected_built_serial := built_track.take_paid_demolition_request()
	assert_equal(selected_built_serial, later_serial, "Selected built crossing retains its exact later route identity")
	assert_true(built_track.try_commit_paid_demolition(selected_built_serial, 0.0, 50, built_economy), "Selected built crossing suffix demolishes through the staged paid path")
	assert_equal(built_economy.get_cash(), 200, "Crossing construction and demolition each charge the shared cost once")
	assert_equal(built_track.get_endpoint_cell(), Vector2i(2, 3), "Paid crossing demolition removes the selected occurrence and its suffix")


func _test_multiple_crossings_charge_once_per_occurrence() -> void:
	var config := _config()
	config.departure_required_built_cells = 99
	config.major_track_action_cost = 50
	var track := TrackSystemScript.new(config)
	_append_and_release(track, MULTI_BASE_ROUTE)
	assert_equal(track.get_cell_records().size(), MULTI_BASE_ROUTE.size(), "Multi-crossing fixture publishes its ordinary base route")
	track.advance_construction(100.0)
	assert_true(track.prepare_for_train_sampling(0.0, float(MULTI_BASE_ROUTE.size())), "Multi-crossing fixture freezes both earlier traversals")
	var economy := SessionEconomyScript.new(300)
	var controller := SessionControllerScript.new(
		config, track, TrainSystemScript.new(1.0, 100.0),
		null, null, null, economy
	)
	controller.start()
	controller.advance_tick(_held_frame(track.get_endpoint_cell(), MULTI_CROSSING_PATH))
	assert_equal(track._runtime.get_pending_crossing_count(), 2, "One gesture stages two independent crossing occurrences")
	controller.advance_tick(_release_frame(MULTI_CROSSING_PATH))
	assert_equal(economy.get_cash(), 200, "Finalizing two crossings charges the shared cost twice in one atomic spend")
	var crossing_records := track.get_cell_records().filter(func(record): return record.grade_separated_crossing)
	assert_equal(crossing_records.size(), 2, "The ordered route retains two fresh crossing identities")


func _built_horizontal_track() -> TrackSystemScript:
	var track := TrackSystemScript.new(_config())
	track._runtime.set_gesture_rejection_diagnostics_enabled(true)
	_append_and_release(track, FIRST_ROUTE)
	assert_equal(track.advance_construction(float(FIRST_ROUTE.size())), float(FIRST_ROUTE.size()), "Crossing fixture builds the first route")
	assert_true(track.prepare_for_train_sampling(0.0, float(FIRST_ROUTE.size())), "Crossing fixture freezes the earlier geometry")
	return track


func _controller_fixture(starting_cash: int) -> Dictionary:
	var config := _config()
	config.departure_required_built_cells = 99
	config.major_track_action_cost = 50
	var track := TrackSystemScript.new(config)
	_append_and_release(track, FIRST_ROUTE)
	track.advance_construction(float(FIRST_ROUTE.size()))
	track.prepare_for_train_sampling(0.0, float(FIRST_ROUTE.size()))
	var economy := SessionEconomyScript.new(starting_cash)
	var controller := SessionControllerScript.new(
		config,
		track,
		TrainSystemScript.new(1.0, 100.0),
		null,
		null,
		null,
		economy
	)
	controller.start()
	return {
		"config": config,
		"track": track,
		"economy": economy,
		"controller": controller,
	}


func _append_and_release(track: TrackSystemScript, cells: Array[Vector2i]) -> void:
	track.apply_left_input(_held_frame(track.get_endpoint_cell(), cells))
	track.apply_left_input(_release_frame(cells))


func _begin_gesture(track: TrackSystemScript) -> bool:
	var endpoint := track.get_endpoint_cell()
	track.apply_left_input(_held_frame(endpoint, []))
	return track.is_runtime_gesture_active()


func _update_gesture(track: TrackSystemScript, path: Array[Vector2i]) -> bool:
	return bool(track._runtime.gesture_update(path, path[-1]))


func _held_frame(endpoint: Vector2i, path: Array[Vector2i]) -> TrackInputFrameScript:
	var pointer := endpoint if path.is_empty() else path[-1]
	return TrackInputFrameScript.new(
		path, endpoint, true, Vector2i(-1, -1), false,
		true, true, false, false, pointer, true, path
	)


func _release_frame(path: Array[Vector2i]) -> TrackInputFrameScript:
	var pointer := Vector2i(-1, -1) if path.is_empty() else path[-1]
	return TrackInputFrameScript.new(
		path, Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, false, true, false, pointer, not path.is_empty(), path, path,
		pointer, not path.is_empty()
	)


func _motion_frame(path: Array[Vector2i]) -> TrackInputFrameScript:
	var pointer := Vector2i(-1, -1) if path.is_empty() else path[-1]
	return TrackInputFrameScript.new(
		path, Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, true, false, false, pointer, not path.is_empty(), path
	)


func _right_frame(cell: Vector2i) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, cell, true,
		false, false, false, true
	)


func _right_frame_at(cell: Vector2i, logical_position: Vector2) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, cell, true,
		false, false, false, true,
		Vector2i(-1, -1), false,
		null, null,
		Vector2i(-1, -1), false,
		false,
		logical_position, true
	)


func _track_observation(track: TrackSystemScript) -> String:
	return JSON.stringify({
		"records": track.get_cell_records().map(func(record): return {
			"serial": record.route_serial,
			"cell": record.cell,
			"state": record.state,
			"progress": record.build_progress,
			"group": record.geometry_group_id,
			"locked": record.geometry_locked,
			"crossing": record.grade_separated_crossing,
			"partner": record.crossing_partner_route_serial,
		}),
		"pieces": track.get_geometry_pieces().map(func(piece): return {
			"group": piece.group_id,
			"first": piece.first_route_serial,
			"last": piece.last_route_serial,
			"kind": piece.kind,
			"locked": piece.locked,
			"centerline": piece.centerline,
		}),
		"available": track.get_available_track_cells(),
		"contacts": track.get_contact_observations(),
		"next_serial": track._runtime._sequence._next_route_serial,
		"next_distance": track._runtime._sequence._next_nominal_start_cells,
		"gesture_active": track.is_runtime_gesture_active(),
	})


func _locked_geometry_observation(track: TrackSystemScript) -> String:
	return JSON.stringify(track._runtime._locked_ledger.map(func(piece): return {
		"group": piece.group_id,
		"first": piece.first_route_serial,
		"last": piece.last_route_serial,
		"kind": piece.kind,
		"support": piece.exit_support_route_serial,
		"footprint": piece.footprint_cells,
		"centerline": piece.centerline,
	}))


func _config() -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		41, 30.0, 1,
		1.0, 50, 2, 2.0, 1.0, 1,
		Vector2(480.0, 400.0), Vector2i(12, 10), 40.0, Vector2.ZERO,
		&"departure", Vector2(20.0, 100.0), Vector2i(0, 2)
	)
