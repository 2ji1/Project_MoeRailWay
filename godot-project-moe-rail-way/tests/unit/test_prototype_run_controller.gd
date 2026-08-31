extends "res://tests/support/prototype_test.gd"

const RUN_CONTROLLER_PATH := "res://src/domain/run/prototype_run_controller.gd"
const SETTLEMENT_RESULT_PATH := "res://src/domain/run/settlement_result.gd"
const RunStateScript = preload("res://src/domain/run/run_state.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")

const COMPANY_IDS := [
	&"company_01", &"company_02", &"company_03",
	&"company_04", &"company_05", &"company_06",
]


func run() -> PackedStringArray:
	assert_true(ResourceLoader.exists(RUN_CONTROLLER_PATH), "PrototypeRunController exists")
	assert_true(ResourceLoader.exists(SETTLEMENT_RESULT_PATH), "SettlementResult exists")
	if not ResourceLoader.exists(RUN_CONTROLLER_PATH) or not ResourceLoader.exists(SETTLEMENT_RESULT_PATH):
		return finish()
	_test_ordered_one_shot_settlement()
	_test_all_end_reasons_share_order()
	_test_negative_cash_blocks_next_session()
	_test_high_settlement_cash_carries_to_next_session()
	_test_rejected_settlement_is_byte_identical()
	return finish()


func _test_ordered_one_shot_settlement() -> void:
	var state := RunStateScript.new(300, COMPANY_IDS)
	var controller: Variant = load(RUN_CONTROLLER_PATH).new(state, 50)
	assert_true(controller.try_select_contract(_contract()), "Operations selects one valid contract")
	var economy: Variant = controller.try_start_session()
	assert_not_null(economy, "Nonnegative run cash starts one session")
	assert_equal(economy.get_cash(), 300, "Session economy copies current RunState cash")
	var result: Variant = _session_result(SessionResultScript.Reason.REGULAR_TIME_EXPIRED, 425, 200, 75, 60, 125, 25)
	var settlement: Variant = controller.try_settle_session(result)
	assert_not_null(settlement, "First immutable session result settles")
	assert_equal(state.get_cash(), 410, "Opening cash, contract, repair, and operating cost settle in order")
	assert_equal(state.get_company_trust_milli(&"company_01"), 125, "Trust applies only to selected company")
	assert_equal(state.get_company_trust_milli(&"company_02"), 0, "Other company trust is unchanged")
	assert_equal(state.get_completed_cycle_count(), 1, "Settlement increments cycle once")
	assert_equal(settlement.get_ordered_line_items(), [
		{"id": &"session_starting_cash", "amount": 300, "informational": false},
		{"id": &"delivery_fee_total", "amount": 200, "informational": true},
		{"id": &"session_spending", "amount": 75, "informational": true},
		{"id": &"settlement_opening_cash", "amount": 425, "informational": false},
		{"id": &"contract_adjustment", "amount": 60, "informational": false},
		{"id": &"trust_gain_milli", "amount": 125, "informational": false},
		{"id": &"repair_cost", "amount": 25, "informational": false},
		{"id": &"operating_cost", "amount": 50, "informational": false},
		{"id": &"closing_cash", "amount": 410, "informational": false},
	], "Settlement line order is canonical and reconciliation rows are non-additive")
	assert_true(settlement.does_next_session_start_at_full_durability(), "Settlement restores next-session durability basis")
	assert_true(settlement.are_session_only_increases_cleared(), "Temporary capacities never enter persistent state")
	var observation: Dictionary = settlement.get_credit_survival_observation()
	assert_equal(observation["selected_company_id"], &"company_01", "Credit observation identifies the selected company")
	assert_equal(observation["contracted_delivery_count"], 5, "Credit observation carries contracted deliveries")
	assert_equal(observation["contract_quota"], 4, "Credit observation carries quota")
	assert_equal(observation["contract_attainment_basis_points"], 12500, "Credit observation carries attainment")
	assert_equal(observation["closing_cash"], 410, "Credit observation names signed closing cash")
	observation["cash"] = 999
	var trust: Dictionary = observation["company_trust_milli"]
	trust["company_01"] = 999
	assert_equal(settlement.get_credit_survival_observation()["cash"], 410, "Credit observation cash is detached")
	assert_equal(settlement.get_credit_survival_observation()["company_trust_milli"]["company_01"], 125, "Credit observation trust is detached")
	var before_repeat := JSON.stringify(state.get_observation())
	assert_true(controller.try_settle_session(result) == null, "Repeated settlement rejects")
	assert_equal(JSON.stringify(state.get_observation()), before_repeat, "Repeated settlement leaves RunState byte-identical")


func _test_all_end_reasons_share_order() -> void:
	var signatures: Array = []
	for reason in [SessionResultScript.Reason.REGULAR_TIME_EXPIRED, SessionResultScript.Reason.TRACK_END_REACHED, SessionResultScript.Reason.DURABILITY_DEPLETED]:
		var state := RunStateScript.new(300, COMPANY_IDS)
		var controller: Variant = load(RUN_CONTROLLER_PATH).new(state, 50)
		controller.try_select_contract(_contract())
		controller.try_start_session()
		var settlement: Variant = controller.try_settle_session(_session_result(reason, 425, 200, 75, 60, 125, 25))
		signatures.append({
			"reason": settlement.get_completion_reason(),
			"lines": settlement.get_ordered_line_items(),
			"state": state.get_observation(),
		})
	assert_equal(signatures[0]["lines"], signatures[1]["lines"], "Track end uses identical settlement order")
	assert_equal(signatures[0]["lines"], signatures[2]["lines"], "Durability end uses identical settlement order")
	assert_equal(signatures[0]["state"], signatures[1]["state"], "Track end produces identical persistent facts")
	assert_equal(signatures[0]["state"], signatures[2]["state"], "Durability end produces identical persistent facts")


func _test_negative_cash_blocks_next_session() -> void:
	var state := RunStateScript.new(300, COMPANY_IDS)
	var controller: Variant = load(RUN_CONTROLLER_PATH).new(state, 50)
	controller.try_select_contract(_contract())
	controller.try_start_session()
	var settlement: Variant = controller.try_settle_session(
		_session_result(
			SessionResultScript.Reason.TRACK_END_REACHED,
			10,
			0,
			290,
			-100,
			0,
			20,
			0
		)
	)
	assert_equal(settlement.get_closing_cash(), -160, "Settlement retains negative cash without floor or skipped cost")
	assert_equal(state.get_cash(), -160, "RunState retains signed closing cash")
	assert_true(settlement.get_credit_survival_observation()["session_start_blocked"], "Credit observation reports the negative-cash start gate")
	assert_true(controller.try_continue_to_operations(), "Results continue returns once")
	assert_false(controller.try_continue_to_operations(), "Repeated continue is inert")
	assert_true(controller.try_select_contract(_contract()), "Negative-cash operations remains readable and selectable")
	assert_false(controller.can_start_session(), "Negative cash blocks the next session")
	assert_true(controller.try_start_session() == null, "Negative cash creates no renewable session budget")


func _test_high_settlement_cash_carries_to_next_session() -> void:
	var state := RunStateScript.new(1000000, COMPANY_IDS)
	var controller: Variant = load(RUN_CONTROLLER_PATH).new(state, 0)
	assert_true(controller.try_select_contract(_contract()), "High-cash cycle selects a contract")
	assert_equal(controller.try_start_session().get_cash(), 1000000, "First high-cash session starts at the RunState boundary")
	var settlement: Variant = controller.try_settle_session(
		_session_result(
			SessionResultScript.Reason.REGULAR_TIME_EXPIRED,
			1000100,
			100,
			0,
			60,
			125,
			0
		)
	)
	assert_equal(settlement.get_closing_cash(), 1000160, "Settlement may grow RunState cash above the old session cap")
	assert_true(controller.try_continue_to_operations(), "High-cash results continue to operations")
	assert_true(controller.try_select_contract(_contract()), "Next high-cash cycle selects a contract")
	var next_economy: Variant = controller.try_start_session()
	assert_not_null(next_economy, "Nonnegative high RunState cash starts the next session")
	assert_equal(next_economy.get_starting_cash(), 1000160, "Next session copies the exact high RunState cash")
	assert_equal(next_economy.get_total_credited(), 0, "Carried RunState cash is not misreported as a delivery fee")


func _test_rejected_settlement_is_byte_identical() -> void:
	var state := RunStateScript.new(300, COMPANY_IDS)
	var controller: Variant = load(RUN_CONTROLLER_PATH).new(state, 50)
	controller.try_select_contract(_contract())
	controller.try_start_session()
	var before := JSON.stringify(state.get_observation())
	var mismatch: Variant = _session_result(SessionResultScript.Reason.REGULAR_TIME_EXPIRED, 426, 200, 75, 60, 125, 25)
	assert_true(controller.try_settle_session(mismatch) == null, "Broken cash reconciliation rejects")
	assert_equal(JSON.stringify(state.get_observation()), before, "Rejected reconciliation leaves live state byte-identical")
	var forged_adjustment: Variant = _session_result(SessionResultScript.Reason.REGULAR_TIME_EXPIRED, 425, 200, 75, 61, 125, 25)
	assert_true(controller.try_settle_session(forged_adjustment) == null, "Forged contract aggregate rejects")
	assert_equal(JSON.stringify(state.get_observation()), before, "Rejected contract aggregate leaves live state byte-identical")
	var invalid_reason: Variant = _session_result(999, 425, 200, 75, 60, 125, 25)
	assert_true(controller.try_settle_session(invalid_reason) == null, "Unknown completion reason rejects")
	assert_equal(JSON.stringify(state.get_observation()), before, "Rejected completion reason leaves live state byte-identical")
	var overflow: Variant = _session_result(SessionResultScript.Reason.REGULAR_TIME_EXPIRED, 1000000000001, 1000000000001, 300, 0, 0, 0)
	assert_true(controller.try_settle_session(overflow) == null, "Out-of-bound settlement candidate rejects")
	assert_equal(JSON.stringify(state.get_observation()), before, "Rejected bound leaves live state byte-identical")


func _contract() -> Dictionary:
	return {
		"company_id": &"company_01",
		"quota": 4,
		"maximum_shortfall_penalty": 100,
		"completion_bonus_at_quota": 60,
		"trust_per_excess_delivery_milli": 125,
	}


func _session_result(
	reason: int,
	final_cash: int,
	fee_total: int,
	spending: int,
	adjustment: int,
	trust_gain: int,
	repair_cost: int,
	delivery_count: int = 5
):
	return SessionResultScript.new(
		reason, 10, 10, 0,
		5, fee_total, 100.0, 75.0, repair_cost,
		final_cash, spending,
		2, 1, 18, 3,
		1, 40, 1, 40, 40, 80,
		&"company_01", 4, delivery_count, delivery_count * 10000 / 4, adjustment, trust_gain,
		[]
	)
