extends "res://tests/support/prototype_test.gd"

const CREDIT_BALANCE_PATH := "res://src/config/credit_survival_balance.gd"
const PROTOTYPE_BALANCE_PATH := "res://src/config/prototype_balance.gd"
const VALIDATOR_PATH := "res://src/config/prototype_config_validator.gd"
const RUN_STATE_PATH := "res://src/domain/run/run_state.gd"


func run() -> PackedStringArray:
	_verify_invalid_probes()
	assert_true(ResourceLoader.exists(CREDIT_BALANCE_PATH), "Credit balance exists")
	if not ResourceLoader.exists(CREDIT_BALANCE_PATH):
		return finish()
	var credit_script: Script = load(CREDIT_BALANCE_PATH)
	var credit: Variant = credit_script.new()
	var expected_rates := [400, 500, 600, 700, 800, 900]
	var expected_terms := [4, 4, 5, 5, 6, 6]
	assert_equal(credit.companies.size(), 6, "Credit balance covers six companies")
	for index in range(credit.companies.size()):
		var company = credit.companies[index]
		assert_equal(company.company_id, StringName("company_%02d" % (index + 1)), "Credit company order is canonical")
		assert_equal(company.rate_basis_points, expected_rates[index], "Company rate matches activated balance")
		assert_equal(company.term_cycles, expected_terms[index], "Company term matches activated balance")
		assert_equal(credit.get_credit_limit(company.company_id, 0), 0, "Zero trust has zero credit")
	assert_equal(credit.get_credit_limit(&"company_01", 100), 100, "Knot limit is exact")
	assert_equal(credit.get_credit_limit(&"company_01", 200), 175, "Interpolation floors deterministically")
	assert_equal(credit.get_credit_limit(&"company_01", 999999), 800, "Limit caps at final knot")
	assert_equal(credit.get_next_limit_trust(&"company_01", 0), 1, "Next increase query returns first integer trust")
	assert_equal(credit.get_next_limit_trust(&"company_01", 1000), -1, "Cap query returns sentinel")
	credit.companies[0].trust_limit_knots = _knots([Vector2i(0, 0), Vector2i(100, 0), Vector2i(200, 100)])
	assert_equal(credit.get_next_limit_trust(&"company_01", 0), 101, "Next increase skips a flat segment without linear scanning")
	assert_equal(credit.get_credit_limit(&"unknown", 0), -1, "Unknown company rejects")
	assert_equal(credit.get_credit_limit(&"company_01", -1), -1, "Negative trust rejects")

	var prototype_script: Script = load(PROTOTYPE_BALANCE_PATH)
	var validator_script: Script = load(VALIDATOR_PATH)
	var prototype: Variant = prototype_script.new()
	assert_equal(validator_script.validate(prototype), PackedStringArray(), "Default Credit configuration is valid")
	var original_contract_fee: int = prototype.contract_economy_balance.companies[0].base_delivery_fee
	prototype.credit_survival_balance.companies[0].company_id = prototype.credit_survival_balance.companies[1].company_id
	_assert_contains(validator_script.validate(prototype), "credit_survival_balance.companies[0].company_id must match contract company order")
	assert_equal(prototype.contract_economy_balance.companies[0].base_delivery_fee, original_contract_fee, "Credit validation cannot mutate Contract configuration")

	var missing_company: Variant = prototype_script.new()
	missing_company.credit_survival_balance.companies.remove_at(5)
	_assert_contains(validator_script.validate(missing_company), "credit_survival_balance.companies must contain exactly 6")
	var null_company: Variant = prototype_script.new()
	null_company.credit_survival_balance.companies[0] = null
	_assert_contains(validator_script.validate(null_company), "credit_survival_balance.companies[0].resource is required")
	var invalid_first: Variant = prototype_script.new()
	invalid_first.credit_survival_balance.companies[0].trust_limit_knots = _knots([Vector2i(1, 0), Vector2i(100, 100)])
	_assert_contains(validator_script.validate(invalid_first), "must begin at (0, 0)")
	var too_few_knots: Variant = prototype_script.new()
	too_few_knots.credit_survival_balance.companies[0].trust_limit_knots = _knots([Vector2i(0, 0)])
	_assert_contains(validator_script.validate(too_few_knots), "must contain at least 2 entries")
	var negative_knot: Variant = prototype_script.new()
	negative_knot.credit_survival_balance.companies[0].trust_limit_knots = _knots([Vector2i(0, 0), Vector2i(100, -1)])
	_assert_contains(validator_script.validate(negative_knot), "trust_limit_knots must be nonnegative")
	var duplicate_trust: Variant = prototype_script.new()
	duplicate_trust.credit_survival_balance.companies[0].trust_limit_knots = _knots([Vector2i(0, 0), Vector2i(100, 100), Vector2i(100, 200)])
	_assert_contains(validator_script.validate(duplicate_trust), "trust coordinates must be strictly increasing")
	var decreasing_limit: Variant = prototype_script.new()
	decreasing_limit.credit_survival_balance.companies[0].trust_limit_knots = _knots([Vector2i(0, 0), Vector2i(100, 100), Vector2i(200, 99)])
	_assert_contains(validator_script.validate(decreasing_limit), "credit limits must be nondecreasing")
	var invalid_rate_low: Variant = prototype_script.new()
	invalid_rate_low.credit_survival_balance.companies[0].rate_basis_points = -1
	_assert_contains(validator_script.validate(invalid_rate_low), "rate_basis_points")
	var invalid_rate_high: Variant = prototype_script.new()
	invalid_rate_high.credit_survival_balance.companies[0].rate_basis_points = 10001
	_assert_contains(validator_script.validate(invalid_rate_high), "rate_basis_points")
	var invalid_term_low: Variant = prototype_script.new()
	invalid_term_low.credit_survival_balance.companies[0].term_cycles = 0
	_assert_contains(validator_script.validate(invalid_term_low), "term_cycles")
	var invalid_term_high: Variant = prototype_script.new()
	invalid_term_high.credit_survival_balance.companies[0].term_cycles = 1001
	_assert_contains(validator_script.validate(invalid_term_high), "term_cycles")
	var maximum_safe_knots: Variant = prototype_script.new()
	maximum_safe_knots.credit_survival_balance.companies[0].trust_limit_knots = _knots([Vector2i(0, 0), Vector2i(2147483647, 2147483647)])
	assert_equal(validator_script.validate(maximum_safe_knots), PackedStringArray(), "Vector2i knot bounds keep interpolation products inside signed 64-bit")
	assert_equal(maximum_safe_knots.credit_survival_balance.get_credit_limit(&"company_01", 2147483646), 2147483646, "Maximum Vector2i interpolation remains exact")
	assert_equal(maximum_safe_knots.credit_survival_balance.get_next_limit_trust(&"company_01", 2147483646), 2147483647, "Maximum Vector2i next threshold remains exact")

	var run_script: Script = load(RUN_STATE_PATH)
	var ids: Array[StringName] = [&"company_01", &"company_02", &"company_03", &"company_04", &"company_05", &"company_06"]
	var rates: Dictionary = credit.get_rate_table(ids)
	var state: Variant = run_script.new(300, ids, {}, 0, rates)
	assert_equal(state.get_company_rate_basis_points(&"company_06"), 900, "Run copies company rates")
	credit.companies[5].rate_basis_points = 1
	assert_equal(state.get_company_rate_basis_points(&"company_06"), 900, "Live balance edits do not change run rates")
	return finish()


func _verify_invalid_probes() -> void:
	var cases := {
		"rate_empty": "RunState rate table must cover every company",
		"rate_missing": "RunState rate table must cover every company",
		"replace_rates": "Source RunState company rates must match",
	}
	for case_name in cases:
		var output: Array = []
		var arguments := PackedStringArray([
			"--headless",
			"--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://tests/run_all.gd",
			"--",
			"--credit-limit-invalid-probe=" + case_name,
		])
		var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true)
		var captured_text := "\n".join(PackedStringArray(output))
		assert_true(captured_text.contains("CREDIT_LIMIT_INVALID_PROBE_BEGIN:" + case_name), "Credit invalid probe starts: " + case_name)
		assert_true(captured_text.contains(cases[case_name]), "Credit invalid probe reports: " + cases[case_name])
		assert_true(exit_code != 0, "Credit invalid probe exits unsuccessfully: " + case_name)


func run_invalid_probe(case_name: String) -> void:
	var run_script: Script = load(RUN_STATE_PATH)
	var ids: Array[StringName] = [&"company_01", &"company_02", &"company_03", &"company_04", &"company_05", &"company_06"]
	var rates := {&"company_01": 400, &"company_02": 500, &"company_03": 600, &"company_04": 700, &"company_05": 800, &"company_06": 900}
	if case_name == "rate_empty":
		run_script.new(0, ids)
	elif case_name == "rate_missing":
		run_script.new(0, ids, {}, 0, {&"company_01": 400})
	elif case_name == "replace_rates":
		var state = run_script.new(0, ids, {}, 0, rates)
		var changed_rates: Dictionary = rates.duplicate(true)
		changed_rates[&"company_06"] = 1
		state.replace_with(run_script.new(0, ids, {}, 0, changed_rates))


func _assert_contains(errors: PackedStringArray, fragment: String) -> void:
	var found := false
	for error_message in errors:
		found = found or error_message.contains(fragment)
	assert_true(found, "Expected error containing %s" % fragment)


func _knots(values: Array) -> Array[Vector2i]:
	var typed: Array[Vector2i] = []
	for value in values:
		typed.append(value)
	return typed
