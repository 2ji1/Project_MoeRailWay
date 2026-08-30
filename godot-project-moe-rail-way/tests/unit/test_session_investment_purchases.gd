extends "res://tests/support/prototype_test.gd"

const CargoSystemScript = preload("res://src/domain/cargo/cargo_system.gd")
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const PrototypeConfigValidatorScript = preload("res://src/config/prototype_config_validator.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionEconomyScript = preload("res://src/domain/economy/session_economy.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")
const WarpPairSystemScript = preload("res://src/domain/warp/warp_pair_system.gd")

const CARGO_BALANCE_PATH := "res://src/config/cargo_investment_balance.gd"
const CARGO_BALANCE_DATA_PATH := "res://data/cargo_investment_balance.tres"
const INVESTMENT_INPUT_PATH := "res://src/domain/session/session_investment_input.gd"
const ACTION_DEMOLITION := &"paid_demolition"
const ACTION_TRACK := &"temporary_track_purchase"
const ACTION_CARGO := &"temporary_cargo_purchase"


func run() -> PackedStringArray:
	_test_balance_defaults_validation_and_detached_copy()
	_test_exact_track_and_cargo_increments_and_limits()
	_test_first_edge_arbitration_gesture_exclusion_and_no_queue()
	_test_unaffordable_and_limited_actions_are_byte_identical()
	_test_all_end_paths_revoke_authority_without_refund()
	return finish()


func _test_balance_defaults_validation_and_detached_copy() -> void:
	if not _require_task_five_scripts():
		return
	var balance := PrototypeBalanceScript.new()
	assert_true(_object_has_property(balance, &"cargo_investment_balance"), "Prototype balance owns cargo investment Resource")
	if not _object_has_property(balance, &"cargo_investment_balance"):
		return
	var track_balance = balance.track_investment_balance
	var cargo_balance = balance.cargo_investment_balance
	assert_not_null(cargo_balance, "Default cargo investment Resource is concrete")
	if cargo_balance == null:
		return
	assert_equal(track_balance.temporary_track_purchase_cost, 40, "Track purchase costs 40")
	assert_equal(track_balance.temporary_track_cells_per_purchase, 5, "Track purchase adds five cells")
	assert_equal(track_balance.maximum_temporary_track_purchases, 6, "Track purchases default to six")
	assert_equal(cargo_balance.temporary_cargo_purchase_cost, 80, "Cargo purchase costs 80")
	assert_equal(cargo_balance.temporary_cargo_slots_per_purchase, 1, "Cargo purchase adds one slot")
	assert_equal(cargo_balance.maximum_temporary_cargo_purchases, 4, "Cargo purchases default to four")
	assert_equal(PrototypeConfigValidatorScript.validate(balance), PackedStringArray(), "Default investment balance validates")
	var config = balance.create_session_start_config(501)
	for property_name in [
		&"temporary_track_purchase_cost",
		&"temporary_track_cells_per_purchase",
		&"maximum_temporary_track_purchases",
		&"temporary_cargo_purchase_cost",
		&"temporary_cargo_slots_per_purchase",
		&"maximum_temporary_cargo_purchases",
	]:
		assert_true(_object_has_property(config, property_name), "Session config copies %s" % property_name)
	assert_equal(config.temporary_track_purchase_cost, 40, "Runtime config receives track price")
	assert_equal(config.temporary_track_cells_per_purchase, 5, "Runtime config receives track increment")
	assert_equal(config.maximum_temporary_track_purchases, 6, "Runtime config receives track limit")
	assert_equal(config.temporary_cargo_purchase_cost, 80, "Runtime config receives cargo price")
	assert_equal(config.temporary_cargo_slots_per_purchase, 1, "Runtime config receives cargo increment")
	assert_equal(config.maximum_temporary_cargo_purchases, 4, "Runtime config receives cargo limit")
	track_balance.temporary_track_purchase_cost = 1
	cargo_balance.temporary_cargo_purchase_cost = 1
	assert_equal(config.temporary_track_purchase_cost, 40, "Track purchase config is detached from Resource mutation")
	assert_equal(config.temporary_cargo_purchase_cost, 80, "Cargo purchase config is detached from Resource mutation")
	assert_true(ResourceLoader.exists(CARGO_BALANCE_DATA_PATH), "Concrete cargo investment data Resource exists")


func _test_exact_track_and_cargo_increments_and_limits() -> void:
	if not _require_task_five_scripts():
		return
	var direct_config := _config(1000)
	var direct_track := TrackSystemScript.new(direct_config)
	assert_equal(direct_track._runtime.append_cells([Vector2i(1, 0)]), 1, "Track purchase fixture owns one active route record")
	var direct_records_before := _record_observation(direct_track)
	var direct_economy := SessionEconomyScript.new(1000)
	assert_true(direct_track.has_method("try_commit_temporary_track_purchase"), "Track exposes staged temporary capacity purchase")
	if not direct_track.has_method("try_commit_temporary_track_purchase"):
		return
	assert_true(
		direct_track.call(
			"try_commit_temporary_track_purchase",
			direct_config.temporary_track_cells_per_purchase,
			direct_config.temporary_track_purchase_cost,
			direct_economy
		),
		"Direct staged track purchase commits"
	)
	assert_equal(_record_observation(direct_track), direct_records_before, "Track purchase changes no active record, serial, construction, recovery, or geometry")
	assert_equal(direct_track.get_total_track_cells(), 25, "Track total increases by exactly five")
	assert_equal(direct_track.get_available_track_cells(), 24, "Track available inventory increases by exactly five")
	assert_equal(direct_economy.get_cash(), 960, "Track purchase charges exactly 40")

	var fixture := _fixture(1000)
	var controller = fixture.controller
	var track: TrackSystemScript = fixture.track
	var cargo: CargoSystemScript = fixture.cargo
	var economy: SessionEconomyScript = fixture.economy
	var train: TrainSystemScript = fixture.train
	var train_before := _train_observation(train, fixture.config)
	var initial_snapshot = controller.get_snapshot()
	assert_equal(initial_snapshot.get_maximum_temporary_track_purchases(), 6, "Snapshot exposes track purchase limit")
	assert_equal(initial_snapshot.get_temporary_track_purchase_cost(), 40, "Snapshot exposes track purchase cost")
	assert_equal(initial_snapshot.get_temporary_track_cells_per_purchase(), 5, "Snapshot exposes track purchase increment")
	assert_true(initial_snapshot.is_temporary_track_purchase_available(), "Track purchase begins available")
	assert_true(initial_snapshot.is_temporary_track_purchase_affordable(), "Track purchase begins affordable")
	assert_equal(initial_snapshot.get_maximum_temporary_cargo_purchases(), 4, "Snapshot exposes cargo purchase limit")
	assert_equal(initial_snapshot.get_temporary_cargo_purchase_cost(), 80, "Snapshot exposes cargo purchase cost")
	assert_equal(initial_snapshot.get_temporary_cargo_slots_per_purchase(), 1, "Snapshot exposes cargo purchase increment")
	assert_true(initial_snapshot.is_temporary_cargo_purchase_available(), "Cargo purchase begins available")
	assert_true(initial_snapshot.is_temporary_cargo_purchase_affordable(), "Cargo purchase begins affordable")
	controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_TRACK]))
	assert_equal(track.get_total_track_cells(), 25, "Controller track purchase applies exact increment")
	assert_equal(track.get_available_track_cells(), 25, "Empty route receives all five available cells")
	assert_equal(economy.get_cash(), 960, "Controller track purchase charges once")
	assert_equal(controller.get_snapshot().get_temporary_track_purchase_count(), 1, "Snapshot counts one track purchase")

	assert_equal(cargo.try_load(&"pair_a", 0), 0, "Cargo fixture fills slot zero")
	assert_equal(cargo.try_load(&"pair_b", 1), 1, "Cargo fixture fills slot one")
	controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_CARGO]))
	assert_equal(economy.get_cash(), 880, "Cargo purchase charges exactly 80")
	assert_equal(cargo.get_total_slot_count(), 3, "Cargo purchase appends exactly one slot")
	assert_equal(_slot_indices(cargo), [0, 1, 2], "Cargo slot indices append monotonically")
	assert_equal(cargo.try_load(&"pair_c", 2), 2, "Appended slot joins lowest-empty-slot loading")
	assert_equal(cargo.remove_pair(&"pair_a"), 0, "Original lower slot can reopen")
	assert_equal(cargo.try_load(&"pair_d", 3), 0, "Lowest original empty slot still wins after expansion")
	assert_equal(_train_observation(train, fixture.config), train_before, "Purchases change no train speed, durability, activity, distance, or recovery setting")

	for _index in range(5):
		controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_TRACK]))
	assert_equal(controller.get_snapshot().get_temporary_track_purchase_count(), 6, "Track purchase count reaches exact limit")
	assert_false(controller.get_snapshot().is_temporary_track_purchase_available(), "Track purchase becomes unavailable at its limit")
	assert_equal(track.get_total_track_cells(), 50, "Six track purchases add exactly thirty cells")
	var track_limit_before := _purchase_observation(fixture)
	controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_TRACK]))
	assert_equal(_purchase_observation(fixture), track_limit_before, "Seventh track purchase is a canonical no-op")

	for _index in range(3):
		controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_CARGO]))
	assert_equal(controller.get_snapshot().get_temporary_cargo_purchase_count(), 4, "Cargo purchase count reaches exact limit")
	assert_false(controller.get_snapshot().is_temporary_cargo_purchase_available(), "Cargo purchase becomes unavailable at its limit")
	assert_equal(cargo.get_total_slot_count(), 6, "Four cargo purchases append four total slots")
	var cargo_limit_before := _purchase_observation(fixture)
	controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_CARGO]))
	assert_equal(_purchase_observation(fixture), cargo_limit_before, "Fifth cargo purchase is a canonical no-op")


func _test_first_edge_arbitration_gesture_exclusion_and_no_queue() -> void:
	if not _require_task_five_scripts():
		return
	var fixture := _fixture(1000)
	var track: TrackSystemScript = fixture.track
	var cargo: CargoSystemScript = fixture.cargo
	var economy: SessionEconomyScript = fixture.economy
	assert_equal(track._runtime.append_cells([Vector2i(1, 0), Vector2i(2, 0)]), 2, "Arbitration fixture appends demolition target")
	track.advance_construction(2.0)
	var built_before := _record_observation(track)
	fixture.controller.advance_tick(
		_right_click(Vector2i(2, 0)),
		_investment([ACTION_TRACK, ACTION_DEMOLITION, ACTION_CARGO])
	)
	assert_equal(track.get_total_track_cells(), 25, "Chronologically first track edge wins")
	assert_equal(cargo.get_total_slot_count(), 2, "Later cargo edge is ignored")
	assert_equal(_record_observation(track), built_before, "Later demolition edge is ignored")
	assert_equal(economy.get_cash(), 960, "Only the winning track edge charges")

	fixture.controller.advance_tick(
		_right_click(Vector2i(2, 0)),
		_investment([ACTION_DEMOLITION, ACTION_CARGO])
	)
	assert_equal(track.get_cell_records().size(), 1, "Chronologically first demolition edge wins")
	assert_equal(cargo.get_total_slot_count(), 2, "Later cargo edge remains ignored after demolition")
	assert_equal(economy.get_cash(), 910, "Demolition charges the shared cost once")
	var after_demolition := _purchase_observation(fixture)
	fixture.controller.advance_tick(TrackInputFrameScript.empty(), _investment([]))
	assert_equal(_purchase_observation(fixture), after_demolition, "No priced action survives into the next tick")

	var cargo_first := _fixture(1000)
	cargo_first.controller.advance_tick(
		TrackInputFrameScript.empty(),
		_investment([ACTION_CARGO, ACTION_TRACK])
	)
	assert_equal(cargo_first.cargo.get_total_slot_count(), 3, "Chronologically first cargo edge wins")
	assert_equal(cargo_first.track.get_total_track_cells(), 20, "Later track edge is ignored")
	assert_equal(cargo_first.economy.get_cash(), 920, "Only cargo price is spent")

	var repeated := _fixture(1000)
	var repeated_input = _investment([ACTION_TRACK])
	repeated.controller.advance_tick(TrackInputFrameScript.empty(), repeated_input)
	var repeated_after_first := _capacity_purchase_observation(repeated)
	repeated.controller.advance_tick(TrackInputFrameScript.empty(), repeated_input)
	assert_equal(_capacity_purchase_observation(repeated), repeated_after_first, "Reusing one consumed input frame cannot synthesize a second purchase")

	var active_fixture := _fixture(1000)
	active_fixture.track.apply_left_input(_held_endpoint(active_fixture.track.get_endpoint_cell()))
	assert_true(active_fixture.track.is_runtime_gesture_active(), "Gesture-exclusion fixture begins planning")
	var active_before := _purchase_observation(active_fixture)
	active_fixture.controller.advance_tick(
		TrackInputFrameScript.empty(),
		_investment([ACTION_TRACK, ACTION_CARGO])
	)
	assert_equal(_purchase_observation(active_fixture), active_before, "Active gesture disables and consumes purchase edges")
	assert_true(active_fixture.track.is_runtime_gesture_active(), "Disabled purchase leaves the gesture active")
	assert_false(active_fixture.controller.get_snapshot().is_temporary_track_purchase_available(), "Active gesture disables track purchase affordance")
	assert_false(active_fixture.controller.get_snapshot().is_temporary_cargo_purchase_available(), "Active gesture disables cargo purchase affordance")

	var skipped := _running_planning_fixture()
	var skipped_before := _purchase_observation(skipped)
	skipped.controller.advance_tick(
		TrackInputFrameScript.empty(),
		_investment([ACTION_TRACK])
	)
	assert_false(skipped.controller.get_snapshot().did_advance_simulation_tick(), "Planning tick is deterministically skipped")
	assert_equal(_purchase_observation(skipped), skipped_before, "Skipped planning tick accepts and retains no purchase")
	skipped.controller.advance_tick(_right_click(skipped.track.get_endpoint_cell()), _investment([]))
	assert_false(skipped.track.is_runtime_gesture_active(), "Immediate right abort ends the skipped-tick gesture")
	var after_abort := _capacity_purchase_observation(skipped)
	skipped.controller.advance_tick(TrackInputFrameScript.empty(), _investment([]))
	assert_equal(_capacity_purchase_observation(skipped), after_abort, "Dropped skipped-tick purchase never reappears")


func _test_unaffordable_and_limited_actions_are_byte_identical() -> void:
	if not _require_task_five_scripts():
		return
	var poor_track := _fixture(39)
	assert_false(poor_track.controller.get_snapshot().is_temporary_track_purchase_affordable(), "Snapshot marks a 39-cash track purchase unaffordable")
	assert_false(poor_track.controller.get_snapshot().is_temporary_cargo_purchase_affordable(), "Snapshot marks a 39-cash cargo purchase unaffordable")
	var poor_before := _purchase_observation(poor_track)
	poor_track.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_TRACK, ACTION_CARGO]))
	assert_equal(_purchase_observation(poor_track), poor_before, "Unaffordable first track edge preserves all gameplay and cash bytes")
	poor_track.controller.advance_tick(TrackInputFrameScript.empty(), _investment([]))
	assert_equal(_purchase_observation(poor_track), poor_before, "Unaffordable edge is consumed without a queue")

	var poor_cargo := _fixture(79)
	var cargo_before := _purchase_observation(poor_cargo)
	poor_cargo.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_CARGO]))
	assert_equal(_purchase_observation(poor_cargo), cargo_before, "Unaffordable cargo edge preserves all gameplay and cash bytes")

	var limited_config := _config(1000)
	limited_config.maximum_temporary_track_purchases = 0
	limited_config.maximum_temporary_cargo_purchases = 0
	var limited := _fixture_from_config(limited_config)
	var limited_before := _purchase_observation(limited)
	limited.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_TRACK, ACTION_CARGO]))
	assert_equal(_purchase_observation(limited), limited_before, "Reached zero track limit consumes the first edge and leaves state byte-identical")
	limited.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_CARGO]))
	assert_equal(_purchase_observation(limited), limited_before, "Reached zero cargo limit leaves state byte-identical")


func _test_all_end_paths_revoke_authority_without_refund() -> void:
	if not _require_task_five_scripts():
		return
	for reason in [
		SessionResultScript.Reason.REGULAR_TIME_EXPIRED,
		SessionResultScript.Reason.TRACK_END_REACHED,
		SessionResultScript.Reason.DURABILITY_DEPLETED,
	]:
		var fixture := _fixture(1000)
		var results: Array = []
		fixture.controller.session_completed.connect(func(result): results.append(result))
		fixture.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_TRACK]))
		fixture.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_CARGO]))
		fixture.cargo.try_load(&"terminal_pair", 0)
		fixture.controller._complete(reason)
		assert_equal(results.size(), 1, "End reason %d emits one result" % reason)
		assert_equal(fixture.economy.get_cash(), 880, "End reason %d refunds no purchase cost" % reason)
		assert_equal(fixture.cargo.get_occupied_slot_count(), 0, "End reason %d voids remaining cargo" % reason)
		var terminal = fixture.controller.get_snapshot()
		assert_equal(terminal.get_total_track_cells(), 25, "Terminal snapshot retains detached final track capacity")
		assert_equal(terminal.get_total_cargo_slots(), 3, "Terminal snapshot retains detached final cargo capacity")
		assert_equal(terminal.get_temporary_track_purchase_count(), 1, "Terminal snapshot retains track purchase evidence")
		assert_equal(terminal.get_temporary_cargo_purchase_count(), 1, "Terminal snapshot retains cargo purchase evidence")
		if results.size() == 1:
			var result = results[0]
			assert_equal(result.get_final_session_cash(), 880, "Result retains final cash without settlement")
			assert_equal(result.get_total_session_cash_spent(), 120, "Result retains exact total spend")
			assert_equal(result.get_temporary_track_purchase_count(), 1, "Result retains track purchase count")
			assert_equal(result.get_temporary_cargo_purchase_count(), 1, "Result retains cargo purchase count")
			assert_equal(result.get_final_total_track_cells(), 25, "Result retains final track capacity")
			assert_equal(result.get_final_total_cargo_slots(), 3, "Result retains final cargo capacity")
		var terminal_before := _purchase_observation(fixture)
		fixture.controller.advance_tick(
			TrackInputFrameScript.empty(),
			_investment([ACTION_TRACK, ACTION_CARGO])
		)
		assert_equal(_purchase_observation(fixture), terminal_before, "Completed reason %d revokes later purchase authority" % reason)
		var fresh := _fixture(1000)
		assert_equal(fresh.track.get_total_track_cells(), 20, "Fresh session after reason %d returns to base track capacity" % reason)
		assert_equal(fresh.cargo.get_total_slot_count(), 2, "Fresh session after reason %d returns to base cargo capacity" % reason)
		assert_equal(fresh.economy.get_cash(), 1000, "Fresh session after reason %d starts with configured cash" % reason)
		assert_equal(fresh.controller.get_snapshot().get_temporary_track_purchase_count(), 0, "Fresh session carries no track purchases")
		assert_equal(fresh.controller.get_snapshot().get_temporary_cargo_purchase_count(), 0, "Fresh session carries no cargo purchases")


func _require_task_five_scripts() -> bool:
	var ready := true
	for path in [CARGO_BALANCE_PATH, CARGO_BALANCE_DATA_PATH, INVESTMENT_INPUT_PATH]:
		if not ResourceLoader.exists(path):
			assert_true(false, "Task 5 resource exists: %s" % path)
			ready = false
	return ready


func _investment(actions: Array[StringName]):
	var script: Script = load(INVESTMENT_INPUT_PATH)
	return script.new(actions)


func _fixture(starting_cash: int) -> Dictionary:
	return _fixture_from_config(_config(starting_cash))


func _fixture_from_config(config: SessionStartConfigScript) -> Dictionary:
	var track := TrackSystemScript.new(config)
	var train := TrainSystemScript.new(config.train_speed_cells_per_second, config.maximum_durability)
	var cargo := CargoSystemScript.new(config.cargo_base_slot_count, config.cargo_base_delivery_reward)
	var warp := WarpPairSystemScript.new(config, SessionRngScript.new(config.seed))
	var economy := SessionEconomyScript.new(config.starting_session_cash)
	var controller := SessionControllerScript.new(config, track, train, warp, cargo, null, economy)
	controller.start()
	return {
		"config": config,
		"track": track,
		"train": train,
		"cargo": cargo,
		"warp": warp,
		"economy": economy,
		"controller": controller,
	}


func _running_planning_fixture() -> Dictionary:
	var config := _config(1000)
	config.departure_required_built_cells = 1
	config.train_speed_cells_per_second = 0.1
	var fixture := _fixture_from_config(config)
	var running_route: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
	]
	assert_equal(fixture.track._runtime.append_cells(running_route), 4, "Skipped-tick fixture appends a running route")
	fixture.track.advance_construction(4.0)
	fixture.controller.advance_tick(TrackInputFrameScript.empty(), _investment([]))
	assert_equal(fixture.controller.get_state(), SessionControllerScript.State.RUNNING, "Skipped-tick fixture reaches running state")
	fixture.track.apply_left_input(_held_endpoint(fixture.track.get_endpoint_cell()))
	assert_true(fixture.track.is_runtime_gesture_active(), "Skipped-tick fixture starts a running gesture")
	return fixture


func _config(starting_cash: int) -> SessionStartConfigScript:
	var config := SessionStartConfigScript.new(
		501, 100.0, 1,
		0.1, 20, 2, 2.0, 10.0, 99,
		Vector2(480.0, 400.0), Vector2i(12, 10), 40.0, Vector2.ZERO,
		&"investment_departure", Vector2(20.0, 20.0), Vector2i(0, 0),
		0, 100, 100, 100, 1, 2, 37, 25,
		starting_cash, 0, 100.0, 0.0, 1.0, 50
	)
	config.set("temporary_track_purchase_cost", 40)
	config.set("temporary_track_cells_per_purchase", 5)
	config.set("maximum_temporary_track_purchases", 6)
	config.set("temporary_cargo_purchase_cost", 80)
	config.set("temporary_cargo_slots_per_purchase", 1)
	config.set("maximum_temporary_cargo_purchases", 4)
	return config


func _right_click(cell: Vector2i) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		[], Vector2i(-1, -1), false, cell, true,
		false, false, false, true
	)


func _held_endpoint(endpoint: Vector2i) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		[], endpoint, true, Vector2i(-1, -1), false,
		true, true, false, false, endpoint, true
	)


func _record_observation(track: TrackSystemScript) -> String:
	return JSON.stringify(track.get_cell_records().map(func(record): return {
		"serial": record.route_serial,
		"cell": record.cell,
		"state": record.state,
		"progress": record.build_progress,
		"group": record.geometry_group_id,
		"locked": record.geometry_locked,
		"crossing": record.grade_separated_crossing,
		"partner": record.crossing_partner_route_serial,
	}))


func _slot_indices(cargo: CargoSystemScript) -> Array:
	return cargo.get_slot_records().map(func(slot): return slot.slot_index)


func _train_observation(train: TrainSystemScript, config: SessionStartConfigScript) -> String:
	return JSON.stringify({
		"active": train.is_active(),
		"distance": train.get_route_distance_cells(),
		"maximum_durability": train.get_maximum_durability(),
		"current_durability": train.get_current_durability(),
		"speed": train._motion._speed_cells_per_second,
		"recovery_lag": config.recovery_lag_cells,
	})


func _purchase_observation(fixture: Dictionary) -> String:
	var snapshot = fixture.controller.get_snapshot()
	return JSON.stringify({
		"cash": fixture.economy.get_observation(),
		"track_records": _record_observation(fixture.track),
		"track_total": fixture.track.get_total_track_cells(),
		"track_available": fixture.track.get_available_track_cells(),
		"cargo_slots": fixture.cargo.get_slot_records().map(func(slot): return {
			"index": slot.slot_index,
			"pair": String(slot.pair_id),
			"style": slot.style_index,
		}),
		"delivered": fixture.cargo.get_delivered_pair_count(),
		"reward": fixture.cargo.get_base_delivery_reward_total(),
		"track_purchases": snapshot.get_temporary_track_purchase_count(),
		"cargo_purchases": snapshot.get_temporary_cargo_purchase_count(),
		"train": _train_observation(fixture.train, fixture.config),
	})


func _capacity_purchase_observation(fixture: Dictionary) -> String:
	var snapshot = fixture.controller.get_snapshot()
	return JSON.stringify({
		"cash": fixture.economy.get_observation(),
		"track_total": fixture.track.get_total_track_cells(),
		"track_available": fixture.track.get_available_track_cells(),
		"cargo_total": fixture.cargo.get_total_slot_count(),
		"track_purchases": snapshot.get_temporary_track_purchase_count(),
		"cargo_purchases": snapshot.get_temporary_cargo_purchase_count(),
	})


func _object_has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if property.get("name", StringName()) == property_name:
			return true
	return false
