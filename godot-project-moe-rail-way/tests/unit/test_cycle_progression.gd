extends "res://tests/support/prototype_test.gd"

const CycleProgressionScript = preload("res://src/domain/run/cycle_progression.gd")
const TerminalRunResultScript = preload("res://src/domain/run/terminal_run_result.gd")
const RunStateScript = preload("res://src/domain/run/run_state.gd")
const RunControllerScript = preload("res://src/domain/run/prototype_run_controller.gd")
const CreditBalanceScript = preload("res://src/config/credit_survival_balance.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const ValidatorScript = preload("res://src/config/prototype_config_validator.gd")

const COMPANY_IDS := [&"company_01", &"company_02", &"company_03", &"company_04", &"company_05", &"company_06"]
const COMPANY_RATES := {&"company_01": 400, &"company_02": 500, &"company_03": 600, &"company_04": 700, &"company_05": 800, &"company_06": 900}


func run() -> PackedStringArray:
	assert_not_null(CycleProgressionScript, "CycleProgression exists")
	assert_not_null(TerminalRunResultScript, "TerminalRunResult exists")
	assert_equal(CycleProgressionScript.hazard_count_for_cycle(1, 3, 20, 2, 1), 3, "Cycle one retains base hazards")
	_test_difficulty_scaling_and_validation()
	_test_pending_cycle_selection_and_cancel()
	_test_recoverable_deficit_and_decline()
	_test_credit_exhausted_terminal_is_atomic()
	assert_equal(_terminal_signature(), _terminal_signature(), "Repeated bankruptcy runs produce identical canonical JSON")
	return finish()


func _test_difficulty_scaling_and_validation() -> void:
	assert_equal(CycleProgressionScript.hazard_count_for_cycle(3, 3, 20, 2, 1), 4, "Hazards grow at the configured interval")
	assert_equal(CycleProgressionScript.hazard_count_for_cycle(9223372036854775807, 3, 5, 2, 1), 5, "Hazard growth clamps before multiplication")
	assert_equal(CycleProgressionScript.hazard_count_for_cycle(9223372036854775807, 3, 5, 2, 0), 3, "Zero hazard increment stays at base")
	assert_equal(CycleProgressionScript.damage_for_cycle(1, 2.0, 1.0, 10.0), 2.0, "Cycle one retains base damage")
	assert_equal(CycleProgressionScript.damage_for_cycle(4, 2.0, 1.0, 10.0), 5.0, "Damage grows once per cycle")
	assert_equal(CycleProgressionScript.damage_for_cycle(9223372036854775807, 2.0, 1.0, 10.0), 10.0, "Damage caps before multiplication")
	assert_equal(CycleProgressionScript.damage_for_cycle(9223372036854775807, 2.0, 0.0, 10.0), 2.0, "Zero damage increment remains finite")
	var balance := PrototypeBalanceScript.new()
	balance.maximum_damage_per_cell = balance.durability_balance.damage_per_traveled_cell - 1.0
	assert_true(ValidatorScript.validate(balance).has("prototype_balance.maximum_damage_per_cell must be finite, bounded, and at least base damage"), "Maximum damage below Risk base rejects")


func _test_pending_cycle_selection_and_cancel() -> void:
	var state := RunStateScript.new(300, COMPANY_IDS, {}, 0, COMPANY_RATES)
	var controller := RunControllerScript.new(state, 0, CreditBalanceScript.new())
	var before := JSON.stringify(state.get_observation())
	assert_equal(controller.get_pending_cycle(), 1, "First pending cycle is derived")
	assert_true(controller.try_select_contract(_contract()), "Contract acceptance selects pending cycle")
	assert_equal(controller.get_selected_cycle(), 1, "Selected cycle is controller-owned")
	assert_equal(JSON.stringify(state.get_observation()), before, "Cycle selection does not mutate RunState")
	assert_true(controller.try_cancel_contract(), "Contract cancellation succeeds before session")
	assert_equal(controller.get_selected_cycle(), 0, "Cancellation discards selected cycle")
	assert_equal(controller.get_pending_cycle(), 1, "Pending cycle is derived again")
	var exhausted := RunStateScript.new(0, COMPANY_IDS, {}, 9223372036854775807, COMPANY_RATES)
	var exhausted_controller := RunControllerScript.new(exhausted, 0, CreditBalanceScript.new())
	assert_equal(exhausted_controller.get_pending_cycle(), 0, "Cycle exhaustion exposes no pending cycle")
	assert_false(exhausted_controller.try_select_contract(_contract()), "Cycle exhaustion rejects contract acceptance")


func _test_recoverable_deficit_and_decline() -> void:
	var state := RunStateScript.new(300, COMPANY_IDS, {&"company_02": 100, &"company_06": 1000}, 0, COMPANY_RATES)
	var controller := RunControllerScript.new(state, 50, CreditBalanceScript.new())
	_settle_negative(controller)
	assert_equal(controller.get_phase(), RunControllerScript.Phase.RESULTS, "Negative settlement remains in results")
	assert_true(controller.try_continue_to_operations(), "Recoverable deficit enters operations")
	assert_true(controller.is_recovery_mode(), "Recovery mode is explicit")
	assert_false(controller.try_select_contract(_contract()), "Recovery blocks contract selection")
	assert_false(controller.can_start_session(), "Recovery blocks session start")
	var recovery := controller.get_recovery_observation()
	assert_equal(recovery["deficit"], 160, "Recovery compares the exact deficit")
	assert_equal(recovery["comparison_capacity"], 160, "Comparison capacity caps at the deficit")
	assert_true(recovery["aggregate_remaining_credit_saturated"] >= 160, "Aggregate remaining credit is exposed")
	var state_before_decline := JSON.stringify(state.get_observation())
	assert_false(controller.try_decline_recovery(true), "Injected terminal staging failure rejects")
	assert_equal(JSON.stringify(state.get_observation()), state_before_decline, "Failed terminal staging preserves RunState")
	assert_true(controller.get_terminal_result() == null, "Failed terminal staging publishes no result")
	assert_true(controller.try_borrow(&"company_02", 60), "Recovery accepts the first valid company action")
	assert_true(controller.try_borrow(&"company_06", 100), "Recovery accepts a later company in arbitrary action order")
	assert_equal(state.get_cash(), 0, "Borrowing reaches nonnegative cash exactly")
	assert_false(controller.is_recovery_mode(), "Nonnegative cash exits recovery")
	assert_true(controller.try_select_contract(_contract()), "Contract selection reopens after recovery")

	var decline_state := RunStateScript.new(300, COMPANY_IDS, {&"company_06": 1000}, 0, COMPANY_RATES)
	var decline_controller := RunControllerScript.new(decline_state, 50, CreditBalanceScript.new())
	_settle_negative(decline_controller)
	decline_controller.try_continue_to_operations()
	assert_true(decline_controller.try_decline_recovery(), "Explicit recovery decline terminates")
	assert_equal(decline_controller.get_terminal_result().get_reason(), TerminalRunResultScript.Reason.RECOVERY_DECLINED, "Decline reason is exact")
	assert_false(decline_controller.try_decline_recovery(), "Terminal decline is one-shot")


func _test_credit_exhausted_terminal_is_atomic() -> void:
	var state := RunStateScript.new(300, COMPANY_IDS, {}, 0, COMPANY_RATES)
	var controller := RunControllerScript.new(state, 50, CreditBalanceScript.new())
	_settle_negative(controller)
	var before := JSON.stringify(state.get_observation())
	var phase_before := controller.get_phase()
	var settlement_before = controller.get_settlement_result()
	var selected_cycle_before := controller.get_selected_cycle()
	var identity_before := controller.get_active_settlement_identity()
	assert_false(controller.try_continue_to_operations(true), "Injected exhausted transition rejects")
	assert_equal(JSON.stringify(state.get_observation()), before, "Rejected exhausted transition preserves RunState")
	assert_equal(controller.get_phase(), phase_before, "Rejected exhausted transition preserves phase")
	assert_true(controller.get_settlement_result() == settlement_before, "Rejected exhausted transition preserves settlement result identity")
	assert_equal(controller.get_selected_cycle(), selected_cycle_before, "Rejected exhausted transition preserves selected cycle")
	assert_equal(controller.get_active_settlement_identity(), identity_before, "Rejected exhausted transition preserves settlement identity")
	assert_true(controller.get_terminal_result() == null, "Rejected exhausted transition publishes no result")
	assert_true(controller.try_continue_to_operations(), "Exhausted deficit terminates once")
	assert_equal(controller.get_phase(), RunControllerScript.Phase.TERMINAL, "Terminal phase is exact")
	assert_equal(controller.get_terminal_result().get_reason(), TerminalRunResultScript.Reason.CREDIT_EXHAUSTED, "Exhausted reason is exact")
	assert_false(controller.try_continue_to_operations(), "Terminal continuation is one-shot")
	var zero_state := RunStateScript.new(0, COMPANY_IDS, {}, 0, COMPANY_RATES)
	var zero_controller := RunControllerScript.new(zero_state, 0, CreditBalanceScript.new())
	assert_equal(zero_controller.get_recovery_observation()["aggregate_remaining_credit_saturated"], 0, "Zero aggregate remaining credit is explicit")


func _terminal_signature() -> String:
	var state := RunStateScript.new(300, COMPANY_IDS, {}, 0, COMPANY_RATES)
	var controller := RunControllerScript.new(state, 50, CreditBalanceScript.new())
	assert_true(controller.try_select_contract(_contract()), "First deterministic cycle selects contract")
	assert_not_null(controller.try_start_session(), "First deterministic cycle starts")
	assert_not_null(controller.try_settle_session(_positive_result()), "First deterministic cycle settles")
	assert_true(controller.try_continue_to_operations(), "First deterministic cycle returns to operations")
	assert_true(controller.try_select_contract(_contract()), "Second deterministic cycle selects contract")
	assert_not_null(controller.try_start_session(), "Second deterministic cycle starts")
	assert_not_null(controller.try_settle_session(_second_cycle_negative_result()), "Second deterministic cycle settles negative")
	controller.try_continue_to_operations()
	assert_equal(state.get_completed_cycle_count(), 2, "Deterministic bankruptcy fixture completes two cycles")
	return JSON.stringify(controller.get_terminal_result().get_observation())


func _settle_negative(controller) -> void:
	assert_true(controller.try_select_contract(_contract()), "Negative fixture selects contract")
	assert_not_null(controller.try_start_session(), "Negative fixture starts from positive cash")
	assert_not_null(controller.try_settle_session(_negative_result()), "Negative fixture settles")


func _contract() -> Dictionary:
	return {"company_id": &"company_01", "quota": 1, "maximum_shortfall_penalty": 100, "completion_bonus_at_quota": 0, "trust_per_excess_delivery_milli": 0}


func _negative_result():
	return SessionResultScript.new(SessionResultScript.Reason.TRACK_END_REACHED, 10, 10, 0, 0, 0, 100.0, 80.0, 20, 10, 290, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, &"company_01", 1, 0, 0, -100, 0, [])


func _positive_result():
	return SessionResultScript.new(SessionResultScript.Reason.REGULAR_TIME_EXPIRED, 10, 10, 0, 1, 0, 100.0, 100.0, 0, 300, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, &"company_01", 1, 1, 10000, 0, 0, [])


func _second_cycle_negative_result():
	return SessionResultScript.new(SessionResultScript.Reason.TRACK_END_REACHED, 10, 10, 0, 0, 0, 100.0, 80.0, 20, 10, 240, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, &"company_01", 1, 0, 0, -100, 0, [])
