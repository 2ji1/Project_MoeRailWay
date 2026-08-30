extends "res://tests/support/prototype_test.gd"

const CargoSystemScript = preload("res://src/domain/cargo/cargo_system.gd")
const HazardSystemScript = preload("res://src/domain/hazard/hazard_system.gd")
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
const CROSSING_BASE_ROUTE: Array[Vector2i] = [
	Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
	Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2),
]
const CROSSING_PATH: Array[Vector2i] = [
	Vector2i(8, 2), Vector2i(9, 2), Vector2i(9, 3), Vector2i(9, 4),
	Vector2i(9, 5), Vector2i(9, 6), Vector2i(9, 7), Vector2i(8, 7),
	Vector2i(7, 7), Vector2i(6, 7), Vector2i(5, 7), Vector2i(4, 7),
	Vector2i(3, 7), Vector2i(2, 7), Vector2i(2, 6), Vector2i(2, 5),
	Vector2i(2, 4), Vector2i(2, 3), Vector2i(2, 2), Vector2i(2, 1),
]


func run() -> PackedStringArray:
	_test_balance_defaults_validation_and_detached_copy()
	_test_exact_track_and_cargo_increments_and_limits()
	_test_first_edge_arbitration_gesture_exclusion_and_no_queue()
	_test_action_class_totals_and_spend_conservation()
	_test_unaffordable_and_limited_actions_are_byte_identical()
	_test_all_end_paths_revoke_authority_without_refund()
	return finish()


func _test_action_class_totals_and_spend_conservation() -> void:
	var probe := _fixture(1000)
	var snapshot_methods := [
		&"get_paid_demolition_count",
		&"get_paid_demolition_spent",
		&"get_grade_separated_crossing_count",
		&"get_grade_separated_crossing_spent",
		&"get_temporary_track_purchase_spent",
		&"get_temporary_cargo_purchase_spent",
	]
	var result_methods := snapshot_methods.duplicate()
	var ready := true
	for method_name in snapshot_methods:
		if not probe.controller.get_snapshot().has_method(method_name):
			assert_true(false, "Snapshot exposes action-class total %s" % method_name)
			ready = false
	for method_name in result_methods:
		if not _script_has_method(SessionResultScript, method_name):
			assert_true(false, "Result exposes action-class total %s" % method_name)
			ready = false
	if not ready:
		return

	var fixture := _fixture(1000)
	fixture.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_TRACK]))
	fixture.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_CARGO]))
	var demolition_cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	fixture.track._runtime.append_cells(demolition_cells)
	fixture.track.advance_construction(2.0)
	fixture.controller.advance_tick(_right_click(Vector2i(2, 0)), _investment([ACTION_DEMOLITION]))
	var action_snapshot = fixture.controller.get_snapshot()
	assert_equal(action_snapshot.call("get_paid_demolition_count"), 1, "Snapshot counts one successful demolition")
	assert_equal(action_snapshot.call("get_paid_demolition_spent"), 50, "Snapshot assigns 50 spend to demolition")
	assert_equal(action_snapshot.call("get_grade_separated_crossing_count"), 0, "Snapshot starts with zero crossing actions")
	assert_equal(action_snapshot.call("get_grade_separated_crossing_spent"), 0, "Snapshot starts with zero crossing spend")
	assert_equal(action_snapshot.call("get_temporary_track_purchase_spent"), 40, "Snapshot assigns 40 spend to track purchase")
	assert_equal(action_snapshot.call("get_temporary_cargo_purchase_spent"), 80, "Snapshot assigns 80 spend to cargo purchase")
	assert_equal(_snapshot_action_spent(action_snapshot), fixture.economy.get_total_spent(), "Snapshot action-class spend conserves total spend")
	fixture.controller._complete(SessionResultScript.Reason.REGULAR_TIME_EXPIRED)
	assert_equal(fixture.results.size(), 1, "Action-total fixture emits one result")
	if fixture.results.size() == 1:
		var result = fixture.results[0]
		assert_equal(result.call("get_paid_demolition_count"), 1, "Result retains demolition count")
		assert_equal(result.call("get_paid_demolition_spent"), 50, "Result retains demolition spend")
		assert_equal(result.call("get_temporary_track_purchase_spent"), 40, "Result retains track purchase spend")
		assert_equal(result.call("get_temporary_cargo_purchase_spent"), 80, "Result retains cargo purchase spend")
		assert_equal(_result_action_spent(result), result.get_total_session_cash_spent(), "Result action-class spend conserves total spend")

	var crossing_config := _crossing_config()
	var crossing_track := TrackSystemScript.new(crossing_config)
	_append_and_release(crossing_track, CROSSING_BASE_ROUTE)
	crossing_track.advance_construction(float(CROSSING_BASE_ROUTE.size()))
	crossing_track.prepare_for_train_sampling(0.0, float(CROSSING_BASE_ROUTE.size()))
	var crossing_economy := SessionEconomyScript.new(300)
	var crossing_controller := SessionControllerScript.new(
		crossing_config,
		crossing_track,
		TrainSystemScript.new(1.0, 100.0),
		null, null, null, crossing_economy
	)
	var crossing_results: Array = []
	crossing_controller.session_completed.connect(func(result): crossing_results.append(result))
	crossing_controller.start()
	crossing_controller.advance_tick(_held_path_frame(crossing_track.get_endpoint_cell(), CROSSING_PATH))
	crossing_controller.advance_tick(_release_path_frame(CROSSING_PATH))
	var crossing_snapshot = crossing_controller.get_snapshot()
	assert_equal(crossing_snapshot.call("get_grade_separated_crossing_count"), 1, "Snapshot counts one paid crossing occurrence")
	assert_equal(crossing_snapshot.call("get_grade_separated_crossing_spent"), 50, "Snapshot assigns shared cost to crossing")
	assert_equal(_snapshot_action_spent(crossing_snapshot), crossing_economy.get_total_spent(), "Crossing spend conserves total spend")
	crossing_controller._complete(SessionResultScript.Reason.REGULAR_TIME_EXPIRED)
	assert_equal(crossing_results.size(), 1, "Crossing action fixture emits one result")
	if crossing_results.size() == 1:
		assert_equal(crossing_results[0].call("get_grade_separated_crossing_count"), 1, "Result retains crossing count")
		assert_equal(crossing_results[0].call("get_grade_separated_crossing_spent"), 50, "Result retains crossing spend")
		assert_equal(_result_action_spent(crossing_results[0]), crossing_results[0].get_total_session_cash_spent(), "Crossing result action-class spend conserves total spend")


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
	var direct_noncapacity_before := _track_noncapacity_observation(direct_track)
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
	assert_equal(_track_noncapacity_observation(direct_track), direct_noncapacity_before, "Track purchase changes no route identity, construction, recovery, geometry, ledger, anchor, or gesture state")
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
	var poor_before := _canonical_observation(poor_track)
	poor_track.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_TRACK, ACTION_CARGO]))
	assert_equal(_canonical_observation(poor_track), poor_before, "Unaffordable first track edge preserves the canonical authoritative boundary")
	poor_track.controller.advance_tick(TrackInputFrameScript.empty(), _investment([]))
	assert_equal(_canonical_observation(poor_track), poor_before, "Unaffordable edge is consumed without a canonical queue")

	var poor_cargo := _fixture(79)
	var cargo_before := _canonical_observation(poor_cargo)
	poor_cargo.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_CARGO]))
	assert_equal(_canonical_observation(poor_cargo), cargo_before, "Unaffordable cargo edge preserves the canonical authoritative boundary")

	var limited_config := _config(1000)
	limited_config.maximum_temporary_track_purchases = 0
	limited_config.maximum_temporary_cargo_purchases = 0
	var limited := _fixture_from_config(limited_config)
	var limited_before := _canonical_observation(limited)
	limited.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_TRACK, ACTION_CARGO]))
	assert_equal(_canonical_observation(limited), limited_before, "Reached zero track limit consumes the first edge and leaves the canonical boundary byte-identical")
	limited.controller.advance_tick(TrackInputFrameScript.empty(), _investment([ACTION_CARGO]))
	assert_equal(_canonical_observation(limited), limited_before, "Reached zero cargo limit leaves the canonical boundary byte-identical")


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
	var hazard := HazardSystemScript.new(config)
	var economy := SessionEconomyScript.new(config.starting_session_cash)
	var controller := SessionControllerScript.new(config, track, train, warp, cargo, hazard, economy)
	var results: Array = []
	controller.session_completed.connect(func(result): results.append(result))
	controller.start()
	return {
		"config": config,
		"track": track,
		"train": train,
		"cargo": cargo,
		"warp": warp,
		"hazard": hazard,
		"economy": economy,
		"controller": controller,
		"results": results,
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
		starting_cash, 2, 100.0, 0.0, 1.0, 50
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
	return JSON.stringify(_record_values(track.get_cell_records()))


func _record_values(records: Array) -> Array:
	return records.map(func(record): return {
		"serial": record.route_serial,
		"cell": record.cell,
		"distance": record.route_distance_start_cells,
		"state": record.state,
		"progress": record.build_progress,
		"group": record.geometry_group_id,
		"locked": record.geometry_locked,
		"crossing": record.grade_separated_crossing,
		"partner": record.crossing_partner_route_serial,
	})


func _piece_values(pieces: Array) -> Array:
	return pieces.map(func(piece): return {
		"group": piece.group_id,
		"kind": piece.kind,
		"first_serial": piece.first_route_serial,
		"last_serial": piece.last_route_serial,
		"nominal_length": piece.nominal_length_cells,
		"absolute_start": piece.absolute_start_distance_cells,
		"footprint": piece.footprint_cells,
		"centerline": piece.centerline,
		"locked": piece.locked,
		"exit_support_serial": piece.exit_support_route_serial,
		"active_start": piece.active_local_start_cells,
		"active_end": piece.active_local_end_cells,
		"entry_heading": piece.entry_heading_override,
		"exit_heading": piece.exit_heading_override,
	})


func _anchor_values(anchors: Array) -> Array:
	return anchors.map(func(anchor): return {
		"id": String(anchor.anchor_id),
		"cell": anchor.cell,
		"mode": anchor.contact_mode,
	})


func _track_noncapacity_observation(track: TrackSystemScript) -> String:
	var runtime = track._runtime
	var sequence = runtime._sequence
	return JSON.stringify({
		"records": _record_values(track.get_cell_records()),
		"active_cells": sequence._active_cells,
		"next_route_serial": sequence._next_route_serial,
		"next_nominal_start": sequence._next_nominal_start_cells,
		"active_predecessor": sequence._active_predecessor_cell,
		"pieces": _piece_values(track.get_geometry_pieces()),
		"locked_ledger": _piece_values(runtime._locked_ledger),
		"anchors": _anchor_values(runtime._anchors),
		"contacts": runtime.get_contact_observations(),
		"recovered_cells": runtime._recovered_cells_by_piece,
		"exit_support_cells": runtime._exit_support_cells_by_piece,
		"recovered_end": runtime._recovered_end_distance_cells,
		"gesture_active": runtime._gesture_active,
		"last_gesture_rejection": runtime._last_gesture_rejection,
		"last_stage_rejection": String(runtime._last_stage_rejection_reason),
		"left_capture": track._left_capture_active,
		"left_latched": track._left_press_latched,
		"paid_demolition_request": track._paid_demolition_request_serial,
	})


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


func _canonical_observation(fixture: Dictionary) -> String:
	var controller = fixture.controller
	var train = fixture.train
	return JSON.stringify({
		"economy": fixture.economy.get_observation(),
		"track_noncapacity": _track_noncapacity_observation(fixture.track),
		"track_capacity": {
			"total": fixture.track.get_total_track_cells(),
			"available": fixture.track.get_available_track_cells(),
		},
		"train": {
			"active": train._motion._active,
			"distance": train._motion._route_distance_cells,
			"speed": train._motion._speed_cells_per_second,
			"maximum_durability": train._maximum_durability,
			"current_durability": train._current_durability,
		},
		"hazard": {
			"cells": fixture.hazard.get_hazard_cells(),
			"damage_per_cell": fixture.hazard._damage_per_traveled_cell,
		},
		"warp": _warp_checkpoint_values(fixture.warp.create_running_tick_checkpoint()),
		"cargo": {
			"slots": fixture.cargo.get_slot_records().map(func(slot): return {
				"index": slot.slot_index,
				"pair": String(slot.pair_id),
				"style": slot.style_index,
				"company": String(slot.company_id),
				"fee": slot.base_delivery_fee,
			}),
			"base_reward": fixture.cargo._base_delivery_reward,
			"delivered": fixture.cargo.get_delivered_pair_count(),
			"reward_total": fixture.cargo.get_base_delivery_reward_total(),
		},
		"session": {
			"state": controller.get_state(),
			"total_ticks": controller._total_ticks,
			"elapsed_ticks": controller._elapsed_ticks,
			"remaining_ticks": controller._remaining_ticks,
			"running_tick_index": controller._running_tick_index,
			"planning_accumulator": controller._planning_accumulator_percent,
			"did_advance": controller._did_advance_simulation_tick,
			"cached_pose": controller._cached_tick_pose,
			"paid_actions_enabled": controller._paid_track_actions_enabled,
			"track_purchase_count": controller._temporary_track_purchase_count,
			"cargo_purchase_count": controller._temporary_cargo_purchase_count,
			"paid_demolition_count": _property_or_null(controller, &"_paid_demolition_count"),
			"paid_demolition_spent": _property_or_null(controller, &"_paid_demolition_spent"),
			"crossing_count": _property_or_null(controller, &"_grade_separated_crossing_count"),
			"crossing_spent": _property_or_null(controller, &"_grade_separated_crossing_spent"),
			"track_purchase_spent": _property_or_null(controller, &"_temporary_track_purchase_spent"),
			"cargo_purchase_spent": _property_or_null(controller, &"_temporary_cargo_purchase_spent"),
		},
		"snapshot": _snapshot_values(controller.get_snapshot()),
		"results": fixture.results.map(func(result): return _result_values(result)),
	})


func _warp_checkpoint_values(checkpoint: Dictionary) -> Dictionary:
	return {
		"records": checkpoint.records.map(func(record): return {
			"pair": String(record.pair_id),
			"ordinal": record.ordinal,
			"origin": record.origin_cell,
			"destination": record.destination_cell,
			"state": record.state,
			"forecast": record.forecast_remaining_ticks,
			"lifetime_total": record.lifetime_total_ticks,
			"lifetime_remaining": record.lifetime_remaining_ticks,
			"style": record.style_index,
			"company": String(record.company_id),
			"fee": record.base_delivery_fee,
		}),
		"events": checkpoint.tick_events,
		"last_begin_tick": checkpoint.last_begin_tick,
		"last_expire_tick": checkpoint.last_expire_tick,
		"last_contact_tick": checkpoint.last_contact_tick,
		"last_generation_tick": checkpoint.last_generation_tick,
		"next_ordinal": checkpoint.next_ordinal,
		"generation_pending": checkpoint.generation_pending,
		"terminal": checkpoint.terminal,
		"rng_state": checkpoint.rng_state,
		"company_rng_state": checkpoint.company_rng_state,
	}


func _snapshot_values(snapshot) -> Dictionary:
	return {
		"total_ticks": snapshot.get_total_ticks(),
		"elapsed_ticks": snapshot.get_elapsed_ticks(),
		"remaining_ticks": snapshot.get_remaining_ticks(),
		"ticks_per_second": snapshot.get_ticks_per_second(),
		"display_seconds": snapshot.get_display_seconds(),
		"state": snapshot.get_state(),
		"records": _record_values(snapshot.get_cell_records()),
		"pieces": _piece_values(snapshot.get_geometry_pieces()),
		"contacts": snapshot.get_contact_observations(),
		"built_end": snapshot.get_built_end_distance_cells(),
		"available_track": snapshot.get_available_track_cells(),
		"total_track": snapshot.get_total_track_cells(),
		"grid_origin": snapshot.get_grid_origin_units(),
		"departure_built": snapshot.get_departure_built_cells(),
		"departure_required": snapshot.get_departure_required_cells(),
		"built_ahead": snapshot.get_built_distance_ahead_cells(),
		"train_active": snapshot.is_train_active(),
		"train_distance": snapshot.get_train_route_distance_cells(),
		"train_position": snapshot.get_train_position(),
		"train_heading": snapshot.get_train_heading(),
		"track_end_seconds": snapshot.get_estimated_track_end_seconds(),
		"track_end_urgent": snapshot.is_track_end_warning_urgent(),
		"departure_id": String(snapshot.get_selected_departure_candidate_id()),
		"departure_cell": snapshot.get_departure_cell(),
		"gesture_eligible": snapshot.is_endpoint_gesture_eligible(),
		"gesture_active": snapshot.is_endpoint_gesture_active(),
		"warp_pairs": snapshot.get_warp_pair_records().map(func(record): return {
			"pair": String(record.pair_id),
			"ordinal": record.ordinal,
			"origin": record.origin_cell,
			"destination": record.destination_cell,
			"state": record.state,
			"forecast": record.forecast_remaining_ticks,
			"lifetime_total": record.lifetime_total_ticks,
			"lifetime_remaining": record.lifetime_remaining_ticks,
			"style": record.style_index,
		}),
		"cargo_slots": snapshot.get_cargo_slot_records().map(func(slot): return {
			"index": slot.slot_index,
			"pair": String(slot.pair_id),
			"style": slot.style_index,
		}),
		"occupied_cargo": snapshot.get_occupied_cargo_slots(),
		"total_cargo": snapshot.get_total_cargo_slots(),
		"delivered": snapshot.get_delivered_pair_count(),
		"base_reward": snapshot.get_base_delivery_reward_total(),
		"warp_events": snapshot.get_warp_cargo_events(),
		"planning_slowdown": snapshot.is_planning_slowdown_active(),
		"planning_percent": snapshot.get_planning_time_scale_percent(),
		"did_advance": snapshot.did_advance_simulation_tick(),
		"hazards": snapshot.get_hazard_cells(),
		"maximum_durability": snapshot.get_maximum_durability(),
		"current_durability": snapshot.get_current_durability(),
		"repair_basis": snapshot.get_repair_cost_basis(),
		"starting_cash": snapshot.get_starting_session_cash(),
		"current_cash": snapshot.get_current_session_cash(),
		"total_spent": snapshot.get_total_session_cash_spent(),
		"pending_crossings": snapshot.get_pending_crossing_count(),
		"pending_crossing_cost": snapshot.get_pending_crossing_total_cost(),
		"pending_crossing_affordable": snapshot.is_pending_crossing_affordable(),
		"track_purchase_count": snapshot.get_temporary_track_purchase_count(),
		"track_purchase_max": snapshot.get_maximum_temporary_track_purchases(),
		"track_purchase_cost": snapshot.get_temporary_track_purchase_cost(),
		"track_purchase_increment": snapshot.get_temporary_track_cells_per_purchase(),
		"track_purchase_available": snapshot.is_temporary_track_purchase_available(),
		"track_purchase_affordable": snapshot.is_temporary_track_purchase_affordable(),
		"cargo_purchase_count": snapshot.get_temporary_cargo_purchase_count(),
		"cargo_purchase_max": snapshot.get_maximum_temporary_cargo_purchases(),
		"cargo_purchase_cost": snapshot.get_temporary_cargo_purchase_cost(),
		"cargo_purchase_increment": snapshot.get_temporary_cargo_slots_per_purchase(),
		"cargo_purchase_available": snapshot.is_temporary_cargo_purchase_available(),
		"cargo_purchase_affordable": snapshot.is_temporary_cargo_purchase_affordable(),
		"paid_demolition_count": _call_or_null(snapshot, &"get_paid_demolition_count"),
		"paid_demolition_spent": _call_or_null(snapshot, &"get_paid_demolition_spent"),
		"crossing_count": _call_or_null(snapshot, &"get_grade_separated_crossing_count"),
		"crossing_spent": _call_or_null(snapshot, &"get_grade_separated_crossing_spent"),
		"track_purchase_spent": _call_or_null(snapshot, &"get_temporary_track_purchase_spent"),
		"cargo_purchase_spent": _call_or_null(snapshot, &"get_temporary_cargo_purchase_spent"),
	}


func _result_values(result) -> Dictionary:
	return {
		"reason": result.get_reason(),
		"total_ticks": result.get_total_ticks(),
		"elapsed_ticks": result.get_elapsed_ticks(),
		"remaining_ticks": result.get_remaining_ticks(),
		"delivered": result.get_delivered_pair_count(),
		"base_reward": result.get_base_delivery_reward_total(),
		"maximum_durability": result.get_maximum_durability(),
		"current_durability": result.get_current_durability(),
		"durability_loss": result.get_durability_loss(),
		"repair_basis": result.get_repair_cost_basis(),
		"final_cash": result.get_final_session_cash(),
		"total_spent": result.get_total_session_cash_spent(),
		"track_purchase_count": result.get_temporary_track_purchase_count(),
		"cargo_purchase_count": result.get_temporary_cargo_purchase_count(),
		"track_capacity": result.get_final_total_track_cells(),
		"cargo_capacity": result.get_final_total_cargo_slots(),
		"paid_demolition_count": _call_or_null(result, &"get_paid_demolition_count"),
		"paid_demolition_spent": _call_or_null(result, &"get_paid_demolition_spent"),
		"crossing_count": _call_or_null(result, &"get_grade_separated_crossing_count"),
		"crossing_spent": _call_or_null(result, &"get_grade_separated_crossing_spent"),
		"track_purchase_spent": _call_or_null(result, &"get_temporary_track_purchase_spent"),
		"cargo_purchase_spent": _call_or_null(result, &"get_temporary_cargo_purchase_spent"),
	}


func _snapshot_action_spent(snapshot) -> int:
	return (
		int(snapshot.call("get_paid_demolition_spent"))
		+ int(snapshot.call("get_grade_separated_crossing_spent"))
		+ int(snapshot.call("get_temporary_track_purchase_spent"))
		+ int(snapshot.call("get_temporary_cargo_purchase_spent"))
	)


func _result_action_spent(result) -> int:
	return (
		int(result.call("get_paid_demolition_spent"))
		+ int(result.call("get_grade_separated_crossing_spent"))
		+ int(result.call("get_temporary_track_purchase_spent"))
		+ int(result.call("get_temporary_cargo_purchase_spent"))
	)


func _property_or_null(object: Object, property_name: StringName):
	return object.get(property_name) if _object_has_property(object, property_name) else null


func _call_or_null(object: Object, method_name: StringName):
	return object.call(method_name) if object.has_method(method_name) else null


func _script_has_method(script: Script, method_name: StringName) -> bool:
	for method in script.get_script_method_list():
		if method.get("name", StringName()) == method_name:
			return true
	return false


func _crossing_config() -> SessionStartConfigScript:
	var config := SessionStartConfigScript.new(
		41, 30.0, 1,
		1.0, 50, 2, 2.0, 1.0, 99,
		Vector2(480.0, 400.0), Vector2i(12, 10), 40.0, Vector2.ZERO,
		&"crossing_departure", Vector2(20.0, 100.0), Vector2i(0, 2)
	)
	config.major_track_action_cost = 50
	return config


func _append_and_release(track: TrackSystemScript, cells: Array[Vector2i]) -> void:
	track.apply_left_input(_held_path_frame(track.get_endpoint_cell(), cells))
	track.apply_left_input(_release_path_frame(cells))


func _held_path_frame(endpoint: Vector2i, path: Array[Vector2i]) -> TrackInputFrameScript:
	var pointer := endpoint if path.is_empty() else path[-1]
	return TrackInputFrameScript.new(
		path, endpoint, true, Vector2i(-1, -1), false,
		true, true, false, false, pointer, true, path
	)


func _release_path_frame(path: Array[Vector2i]) -> TrackInputFrameScript:
	var pointer := Vector2i(-1, -1) if path.is_empty() else path[-1]
	return TrackInputFrameScript.new(
		path, Vector2i(-1, -1), false, Vector2i(-1, -1), false,
		false, false, true, false, pointer, not path.is_empty(), path, path,
		pointer, not path.is_empty()
	)


func _object_has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if property.get("name", StringName()) == property_name:
			return true
	return false
