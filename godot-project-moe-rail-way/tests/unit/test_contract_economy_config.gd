extends "res://tests/support/prototype_test.gd"

const COMPANY_BALANCE_PATH := "res://src/config/company_contract_balance.gd"
const CONTRACT_BALANCE_PATH := "res://src/config/contract_economy_balance.gd"
const PROTOTYPE_BALANCE_PATH := "res://src/config/prototype_balance.gd"
const VALIDATOR_PATH := "res://src/config/prototype_config_validator.gd"


func run() -> PackedStringArray:
	_test_exact_defaults_and_single_cash_authority()
	_test_company_validation()
	return finish()


func _test_exact_defaults_and_single_cash_authority() -> void:
	assert_true(ResourceLoader.exists(COMPANY_BALANCE_PATH), "Company contract balance exists")
	assert_true(ResourceLoader.exists(CONTRACT_BALANCE_PATH), "Contract economy balance exists")
	if not ResourceLoader.exists(CONTRACT_BALANCE_PATH):
		return
	var contract_script: Script = load(CONTRACT_BALANCE_PATH)
	var contract_balance: Variant = contract_script.new()
	assert_equal(contract_balance.get("initial_run_cash"), 300, "Initial run cash defaults to 300")
	assert_equal(contract_balance.get("base_operating_cost"), 50, "Operating cost defaults to 50")
	var companies: Array = contract_balance.get("companies")
	assert_equal(companies.size(), 6, "Exactly six company balances are present")
	for index in range(companies.size()):
		var company: Variant = companies[index]
		assert_not_null(company, "Company %d is concrete" % (index + 1))
		if company == null:
			continue
		assert_equal(company.get("company_id"), StringName("company_%02d" % (index + 1)), "Company ID is stable")
		assert_equal(company.get("display_name"), "Company %d" % (index + 1), "Company label is stable")
		assert_equal(company.get("generation_weight"), 1, "Company weight defaults to one")
		assert_equal(company.get("base_delivery_fee"), 100, "Company fee defaults to 100")
		assert_equal(company.get("quota"), 3, "Company quota defaults to three")
		assert_equal(company.get("maximum_shortfall_penalty"), 100, "Company penalty defaults to 100")
		assert_equal(company.get("completion_bonus_at_quota"), 150, "Company bonus defaults to 150")
		assert_equal(company.get("trust_per_excess_delivery_milli"), 100, "Company trust defaults to 100 milli")

	var prototype_script: Script = load(PROTOTYPE_BALANCE_PATH)
	var prototype: Variant = prototype_script.new()
	assert_false(_object_has_property(prototype, &"session_cash_balance"), "Renewable session cash Inspector authority is retired")
	assert_true(_object_has_property(prototype, &"contract_economy_balance"), "Prototype exposes contract economy balance")
	var second_prototype: Variant = prototype_script.new()
	prototype.get("contract_economy_balance").get("companies")[0].set("base_delivery_fee", 777)
	assert_equal(second_prototype.get("contract_economy_balance").get("companies")[0].get("base_delivery_fee"), 100, "Default nested company Resources are instance-local")


func _test_company_validation() -> void:
	if not ResourceLoader.exists(CONTRACT_BALANCE_PATH):
		return
	var prototype_script: Script = load(PROTOTYPE_BALANCE_PATH)
	var validator_script: Script = load(VALIDATOR_PATH)
	var valid: Variant = prototype_script.new()
	assert_equal(validator_script.validate(valid), PackedStringArray(), "Default contract economy configuration is valid")

	var missing_nested: Variant = prototype_script.new()
	missing_nested.set("contract_economy_balance", null)
	_assert_contains(validator_script.validate(missing_nested), "contract_economy_balance.resource")

	var invalid_cash: Variant = prototype_script.new()
	invalid_cash.get("contract_economy_balance").set("initial_run_cash", -1)
	_assert_contains(validator_script.validate(invalid_cash), "initial_run_cash")
	invalid_cash.get("contract_economy_balance").set("initial_run_cash", 300)
	invalid_cash.get("contract_economy_balance").set("base_operating_cost", 1000001)
	_assert_contains(validator_script.validate(invalid_cash), "base_operating_cost")

	var invalid_count: Variant = prototype_script.new()
	var empty_companies: Array = invalid_count.get("contract_economy_balance").get("companies")
	empty_companies.clear()
	_assert_contains(validator_script.validate(invalid_count), "companies must contain exactly 6")

	var duplicate_id: Variant = prototype_script.new()
	var duplicate_companies: Array = duplicate_id.get("contract_economy_balance").get("companies")
	duplicate_companies[1].set("company_id", duplicate_companies[0].get("company_id"))
	_assert_contains(validator_script.validate(duplicate_id), "company_id must be unique")

	var null_company: Variant = prototype_script.new()
	null_company.get("contract_economy_balance").get("companies")[0] = null
	_assert_contains(validator_script.validate(null_company), "companies[0].resource")

	var empty_id: Variant = prototype_script.new()
	empty_id.get("contract_economy_balance").get("companies")[0].set("company_id", &"")
	_assert_contains(validator_script.validate(empty_id), "company_id must not be empty")

	var invalid_fields: Variant = prototype_script.new()
	var company: Variant = invalid_fields.get("contract_economy_balance").get("companies")[0]
	company.set("display_name", "")
	company.set("generation_weight", 0)
	company.set("quota", 0)
	company.set("base_delivery_fee", -1)
	company.set("maximum_shortfall_penalty", -1)
	company.set("completion_bonus_at_quota", -1)
	company.set("trust_per_excess_delivery_milli", -1)
	var errors: PackedStringArray = validator_script.validate(invalid_fields)
	for fragment in ["display_name", "generation_weight", "quota", "base_delivery_fee", "maximum_shortfall_penalty", "completion_bonus_at_quota", "trust_per_excess_delivery_milli"]:
		_assert_contains(errors, fragment)

	for field_name in ["base_delivery_fee", "maximum_shortfall_penalty", "completion_bonus_at_quota", "trust_per_excess_delivery_milli"]:
		var upper_bound: Variant = prototype_script.new()
		upper_bound.get("contract_economy_balance").get("companies")[0].set(field_name, 1000001)
		_assert_contains(validator_script.validate(upper_bound), field_name)
	var upper_weight: Variant = prototype_script.new()
	upper_weight.get("contract_economy_balance").get("companies")[0].set("generation_weight", 1000001)
	_assert_contains(validator_script.validate(upper_weight), "generation_weight")
	var upper_quota: Variant = prototype_script.new()
	upper_quota.get("contract_economy_balance").get("companies")[0].set("quota", 1000001)
	_assert_contains(validator_script.validate(upper_quota), "quota")

	var overflow_candidate: Variant = prototype_script.new()
	var overflow_company: Variant = overflow_candidate.get("contract_economy_balance").get("companies")[0]
	overflow_company.set("quota", 9223372036854775807)
	overflow_company.set("maximum_shortfall_penalty", 9223372036854775807)
	overflow_company.set("completion_bonus_at_quota", 9223372036854775807)
	_assert_contains(validator_script.validate(overflow_candidate), "cash curve must not overflow")


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
