extends "res://tests/support/prototype_test.gd"

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const ValidatorScript = preload("res://src/config/prototype_config_validator.gd")

const CONTRACT_BALANCE_PATH := "res://src/config/contract_economy_balance.gd"
const SESSION_ECONOMY_PATH := "res://src/domain/economy/session_economy.gd"


func run() -> PackedStringArray:
	_test_session_cash_resource_and_copy()
	_test_session_economy_atomic_spending()
	return finish()


func _test_session_cash_resource_and_copy() -> void:
	assert_true(ResourceLoader.exists(CONTRACT_BALANCE_PATH), "Contract economy balance script exists")
	var balance := PrototypeBalanceScript.new()
	assert_false(_object_has_property(balance, &"session_cash_balance"), "Prototype balance retires session_cash_balance")
	if not _object_has_property(balance, &"contract_economy_balance"):
		assert_true(false, "Prototype balance exposes contract_economy_balance")
		return
	var contract_balance: Variant = balance.get("contract_economy_balance")
	assert_not_null(contract_balance, "Default contract economy balance is concrete")
	if contract_balance == null or not _object_has_property(contract_balance, &"initial_run_cash"):
		assert_true(false, "Contract economy balance exposes initial_run_cash")
		return
	assert_equal(contract_balance.get("initial_run_cash"), 300, "Run cash defaults to 300")

	contract_balance.set("initial_run_cash", -1)
	_assert_contains(
		ValidatorScript.validate(balance),
		"prototype_balance.contract_economy_balance.initial_run_cash"
	)
	contract_balance.set("initial_run_cash", 1000001)
	_assert_contains(
		ValidatorScript.validate(balance),
		"prototype_balance.contract_economy_balance.initial_run_cash"
	)
	contract_balance.set("initial_run_cash", 417)
	assert_equal(ValidatorScript.validate(balance), PackedStringArray(), "Valid cash is accepted")

	var config: Variant = balance.create_session_start_config(901)
	if not _object_has_property(config, &"starting_session_cash"):
		assert_true(false, "Session start config copies starting_session_cash")
		return
	assert_equal(config.get("starting_session_cash"), 417, "Start config receives exact cash")
	contract_balance.set("initial_run_cash", 12)
	assert_equal(config.get("starting_session_cash"), 417, "Start config is detached from Resource")


func _test_session_economy_atomic_spending() -> void:
	assert_true(ResourceLoader.exists(SESSION_ECONOMY_PATH), "Session economy script exists")
	if not ResourceLoader.exists(SESSION_ECONOMY_PATH):
		return
	var economy_script: Script = load(SESSION_ECONOMY_PATH)
	var economy: Variant = economy_script.new(300)
	for method_name in [&"try_spend", &"try_credit", &"get_cash", &"get_total_spent", &"get_total_credited", &"get_observation"]:
		if not economy.has_method(method_name):
			assert_true(false, "Session economy exposes %s" % method_name)
			return

	assert_equal(economy.call("get_cash"), 300, "Economy starts from copied cash")
	var high_cash_economy: Variant = economy_script.new(1000000000000)
	assert_equal(high_cash_economy.call("get_starting_cash"), 1000000000000, "Economy accepts the complete RunState cash range")
	assert_equal(high_cash_economy.call("get_cash"), 1000000000000, "High RunState cash copies without synthetic credit")
	assert_equal(economy.call("get_total_spent"), 0, "Economy starts with zero spending")
	var before_rejection := JSON.stringify(economy.call("get_observation"))
	assert_false(economy.call("try_spend", 301), "Insufficient spend rejects")
	assert_equal(
		JSON.stringify(economy.call("get_observation")),
		before_rejection,
		"Insufficient spend leaves economy byte-identical"
	)
	assert_false(economy.call("try_spend", -1), "Negative spend rejects")
	assert_equal(
		JSON.stringify(economy.call("get_observation")),
		before_rejection,
		"Invalid spend leaves economy byte-identical"
	)
	assert_true(economy.call("try_spend", 50), "Affordable spend succeeds")
	assert_equal(economy.call("get_cash"), 250, "Affordable spend subtracts exactly once")
	assert_equal(economy.call("get_total_spent"), 50, "Affordable spend records exact total")
	var detached: Dictionary = economy.call("get_observation")
	detached["cash"] = 999
	assert_equal(economy.call("get_cash"), 250, "Economy observation is detached")
	assert_true(economy.has_method("duplicate_economy"), "Economy exposes concrete staged copy")
	assert_true(economy.has_method("replace_with"), "Economy exposes non-rejecting staged install")
	if economy.has_method("duplicate_economy") and economy.has_method("replace_with"):
		var candidate: Variant = economy.call("duplicate_economy")
		assert_true(candidate.call("try_spend", 50), "Staged economy can precompute a spend")
		assert_equal(economy.call("get_cash"), 250, "Staged spend does not mutate authority")
		economy.call("replace_with", candidate)
		assert_equal(economy.call("get_cash"), 200, "Validated staged economy installs exactly")
		assert_equal(economy.call("get_total_spent"), 100, "Staged install preserves exact spending total")

	var credit_economy: Variant = economy_script.new(300)
	assert_true(credit_economy.call("try_credit", 75), "Checked credit succeeds")
	assert_equal(credit_economy.call("get_cash"), 375, "Credit is immediately spendable")
	assert_equal(credit_economy.call("get_total_credited"), 75, "Credit total records exact fees")
	var before_invalid_credit := JSON.stringify(credit_economy.call("get_observation"))
	assert_false(credit_economy.call("try_credit", -1), "Negative credit rejects")
	assert_equal(JSON.stringify(credit_economy.call("get_observation")), before_invalid_credit, "Invalid credit is byte-identical")
	var overflow_economy: Variant = economy_script.new(300)
	assert_true(overflow_economy.call("try_credit", 9223372036854775507), "Largest safe cash credit succeeds")
	var before_overflow := JSON.stringify(overflow_economy.call("get_observation"))
	assert_false(overflow_economy.call("try_credit", 1), "Cash overflow credit rejects")
	assert_equal(JSON.stringify(overflow_economy.call("get_observation")), before_overflow, "Overflow rejection is byte-identical")


func _assert_contains(errors: PackedStringArray, fragment: String) -> void:
	var found := false
	for error_message in errors:
		found = found or error_message.contains(fragment)
	assert_true(found, "Expected error containing %s" % fragment)


func _object_has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if property.get("name", StringName()) == property_name:
			return true
	return false
