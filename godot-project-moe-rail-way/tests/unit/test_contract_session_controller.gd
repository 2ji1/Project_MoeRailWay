extends "res://tests/support/prototype_test.gd"

const ECONOMY_PATH := "res://src/domain/economy/session_economy.gd"
const SNAPSHOT_PATH := "res://src/domain/session/session_snapshot.gd"
const RESULT_PATH := "res://src/domain/session/session_result.gd"
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")
const WarpPairSystemScript = preload("res://src/domain/warp/warp_pair_system.gd")
const CargoSystemScript = preload("res://src/domain/cargo/cargo_system.gd")
const ContractSystemScript = preload("res://src/domain/contract/contract_system.gd")
const SessionEconomyScript = preload("res://src/domain/economy/session_economy.gd")


func run() -> PackedStringArray:
	_test_company_fees_ignore_legacy_reward_capacity()
	_verify_capacity_probe(
		"credit_capacity",
		"Session maximum delivery fees must fit checked session cash"
	)
	_verify_capacity_probe(
		"count_capacity",
		"Session maximum deliveries must fit contract count and trust"
	)
	_verify_capacity_probe(
		"trust_capacity",
		"Session maximum deliveries must fit contract count and trust"
	)
	var economy_script: Script = load(ECONOMY_PATH)
	var economy: Variant = economy_script.new(300)
	assert_true(economy.has_method("try_credit"), "SessionEconomy exposes checked credit")
	if economy.has_method("try_credit"):
		assert_true(economy.try_credit(75), "Valid fee credit succeeds")
		assert_equal(economy.get_cash(), 375, "Fee is immediately spendable")
		assert_true(economy.try_spend(350), "New fee can fund a later purchase")
		assert_equal(economy.get_cash(), 25, "Credit and spend conserve cash")
		var before_invalid := JSON.stringify(economy.get_observation())
		assert_false(economy.try_credit(-1), "Negative credit rejects")
		assert_equal(JSON.stringify(economy.get_observation()), before_invalid, "Rejected credit is byte-identical")

	var snapshot: Variant = load(SNAPSHOT_PATH).new(1, 0, 1, 1)
	for method_name in [&"get_selected_contract_company_id", &"get_contract_quota", &"get_contracted_delivery_count", &"get_contract_attainment_basis_points", &"get_cash_contract_adjustment", &"get_contract_trust_gain_milli", &"get_contract_delivery_facts"]:
		assert_true(snapshot.has_method(method_name), "Snapshot exposes %s" % method_name)
	var result: Variant = load(RESULT_PATH).new(0, 1, 1, 0)
	for method_name in [&"get_selected_contract_company_id", &"get_contract_quota", &"get_contracted_delivery_count", &"get_contract_attainment_basis_points", &"get_cash_contract_adjustment", &"get_contract_trust_gain_milli", &"get_contract_delivery_facts"]:
		assert_true(result.has_method(method_name), "Result exposes %s" % method_name)
	return finish()


func _test_company_fees_ignore_legacy_reward_capacity() -> void:
	var config := SessionStartConfigScript.new(
		2, 10000000000000.0, 1,
		1.0, 8, 1, 2.0, 10.0, 1,
		Vector2(240.0, 160.0), Vector2i(6, 4), 40.0, Vector2.ZERO,
		&"company_departure", Vector2(20.0, 20.0), Vector2i(0, 0),
		0, 1, 5, 5, 2, 1, 1000000, 100, 0
	)
	for index in range(6):
		config.company_definitions.append({
			"company_id": StringName("company_%02d" % (index + 1)),
			"generation_weight": 1,
			"base_delivery_fee": 0,
		})
	var contract := ContractSystemScript.new({
		"company_id": &"company_01",
		"quota": 1,
		"maximum_shortfall_penalty": 0,
		"completion_bonus_at_quota": 0,
		"trust_per_excess_delivery_milli": 0,
	})
	var controller := SessionControllerScript.new(
		config,
		TrackSystemScript.new(config),
		TrainSystemScript.new(config.train_speed_cells_per_second),
		WarpPairSystemScript.new(config, SessionRngScript.new(config.seed)),
		CargoSystemScript.new(config.cargo_base_slot_count),
		null,
		SessionEconomyScript.new(config.starting_session_cash),
		contract
	)
	assert_not_null(controller, "Six-company fee capacity ignores retired legacy reward")


func _verify_capacity_probe(case_name: String, expected_assertion: String) -> void:
	var output: Array = []
	var arguments := PackedStringArray([
		"--headless",
		"--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/run_all.gd",
		"--",
		"--contract-controller-invalid-probe=" + case_name,
	])
	OS.execute(OS.get_executable_path(), arguments, output, true)
	var captured_text := ""
	for chunk in output:
		captured_text += str(chunk)
	assert_true(
		captured_text.contains("CONTRACT_CONTROLLER_INVALID_PROBE_BEGIN:" + case_name),
		"%s probe starts" % case_name
	)
	assert_true(
		captured_text.contains(expected_assertion),
		"%s probe rejects before session state mutation" % case_name
	)


func run_invalid_probe(case_name: String) -> void:
	if case_name not in ["credit_capacity", "count_capacity", "trust_capacity"]:
		return
	var duration := 10000000000000.0
	var delivery_fee := 1000000
	var trust_per_excess_delivery_milli := 0
	if case_name == "count_capacity":
		duration = 1000000000000000.0
		delivery_fee = 0
	elif case_name == "trust_capacity":
		delivery_fee = 0
		trust_per_excess_delivery_milli = 1000000
	var config := SessionStartConfigScript.new(
		1, duration, 1,
		1.0, 8, 1, 2.0, 10.0, 1,
		Vector2(240.0, 160.0), Vector2i(6, 4), 40.0, Vector2.ZERO,
		&"contract_departure", Vector2(20.0, 20.0), Vector2i(0, 0),
		0, 1, 5, 5, 2, 1, delivery_fee, 100, 0
	)
	var contract := ContractSystemScript.new({
		"company_id": &"legacy",
		"quota": 1,
		"maximum_shortfall_penalty": 0,
		"completion_bonus_at_quota": 0,
		"trust_per_excess_delivery_milli": trust_per_excess_delivery_milli,
	})
	SessionControllerScript.new(
		config,
		TrackSystemScript.new(config),
		TrainSystemScript.new(config.train_speed_cells_per_second),
		WarpPairSystemScript.new(config, SessionRngScript.new(config.seed)),
		CargoSystemScript.new(config.cargo_base_slot_count, config.cargo_base_delivery_reward),
		null,
		SessionEconomyScript.new(config.starting_session_cash),
		contract
	)
