extends "res://tests/support/prototype_test.gd"

const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const ValidatorScript = preload("res://src/config/prototype_config_validator.gd")

const CASH_BALANCE_PATH := "res://src/config/session_cash_balance.gd"
const SESSION_ECONOMY_PATH := "res://src/domain/economy/session_economy.gd"


func run() -> PackedStringArray:
	_test_session_cash_resource_and_copy()
	_test_session_economy_atomic_spending()
	return finish()


func _test_session_cash_resource_and_copy() -> void:
	assert_true(ResourceLoader.exists(CASH_BALANCE_PATH), "Session cash balance script exists")
	var balance := PrototypeBalanceScript.new()
	if not _object_has_property(balance, &"session_cash_balance"):
		assert_true(false, "Prototype balance exposes session_cash_balance")
		return
	var cash_balance: Variant = balance.get("session_cash_balance")
	assert_not_null(cash_balance, "Default session cash balance is concrete")
	if cash_balance == null or not _object_has_property(cash_balance, &"starting_session_cash"):
		assert_true(false, "Session cash balance exposes starting_session_cash")
		return
	assert_equal(cash_balance.get("starting_session_cash"), 300, "Session cash defaults to 300")

	cash_balance.set("starting_session_cash", -1)
	_assert_contains(
		ValidatorScript.validate(balance),
		"prototype_balance.session_cash_balance.starting_session_cash"
	)
	cash_balance.set("starting_session_cash", 1000001)
	_assert_contains(
		ValidatorScript.validate(balance),
		"prototype_balance.session_cash_balance.starting_session_cash"
	)
	cash_balance.set("starting_session_cash", 417)
	assert_equal(ValidatorScript.validate(balance), PackedStringArray(), "Valid cash is accepted")

	var config: Variant = balance.create_session_start_config(901)
	if not _object_has_property(config, &"starting_session_cash"):
		assert_true(false, "Session start config copies starting_session_cash")
		return
	assert_equal(config.get("starting_session_cash"), 417, "Start config receives exact cash")
	cash_balance.set("starting_session_cash", 12)
	assert_equal(config.get("starting_session_cash"), 417, "Start config is detached from Resource")


func _test_session_economy_atomic_spending() -> void:
	assert_true(ResourceLoader.exists(SESSION_ECONOMY_PATH), "Session economy script exists")
	if not ResourceLoader.exists(SESSION_ECONOMY_PATH):
		return
	var economy_script: Script = load(SESSION_ECONOMY_PATH)
	var economy: Variant = economy_script.new(300)
	for method_name in [&"try_spend", &"get_cash", &"get_total_spent", &"get_observation"]:
		if not economy.has_method(method_name):
			assert_true(false, "Session economy exposes %s" % method_name)
			return

	assert_equal(economy.call("get_cash"), 300, "Economy starts from copied cash")
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
