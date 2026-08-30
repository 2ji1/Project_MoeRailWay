extends "res://tests/support/prototype_test.gd"

const RUN_STATE_PATH := "res://src/domain/run/run_state.gd"


func run() -> PackedStringArray:
	_verify_invalid_probes()
	assert_true(ResourceLoader.exists(RUN_STATE_PATH), "RunState exists")
	if not ResourceLoader.exists(RUN_STATE_PATH):
		return finish()
	var state_script: Script = load(RUN_STATE_PATH)
	var ids := [&"company_01", &"company_02", &"company_03", &"company_04", &"company_05", &"company_06"]
	var state: Variant = state_script.new(300, ids)
	for method_name in [&"get_cash", &"get_completed_cycle_count", &"get_company_trust_milli", &"get_observation", &"duplicate_state", &"replace_with"]:
		assert_true(state.has_method(method_name), "RunState exposes %s" % method_name)
	assert_equal(state.call("get_cash"), 300, "Run cash starts at configured value")
	assert_equal(state.call("get_completed_cycle_count"), 0, "Run cycles start at zero")
	for company_id in ids:
		assert_equal(state.call("get_company_trust_milli", company_id), 0, "Trust starts at zero")
	assert_equal(state.call("get_company_ids"), ids, "Company observation order is stable")
	assert_equal(state.call("get_observation")["company_trust_milli"].keys(), ["company_01", "company_02", "company_03", "company_04", "company_05", "company_06"], "Trust observation order is stable")

	var detached: Dictionary = state.call("get_observation")
	detached["cash"] = -999
	var detached_trust: Dictionary = detached["company_trust_milli"]
	detached_trust["company_01"] = 999
	assert_equal(state.call("get_cash"), 300, "Observation cannot mutate cash")
	assert_equal(state.call("get_company_trust_milli", &"company_01"), 0, "Observation cannot mutate trust")

	var candidate: Variant = state.call("duplicate_state")
	candidate.call("set_cash", -25)
	candidate.call("add_company_trust_milli", &"company_01", 125)
	candidate.call("increment_completed_cycle")
	assert_equal(state.call("get_cash"), 300, "Candidate cash is isolated")
	state.call("replace_with", candidate)
	assert_equal(state.call("get_cash"), -25, "Signed settlement cash installs")
	assert_equal(state.call("get_company_trust_milli", &"company_01"), 125, "Company trust installs")
	assert_equal(state.call("get_company_trust_milli", &"company_02"), 0, "Company trust remains isolated")
	assert_equal(state.call("get_completed_cycle_count"), 1, "Cycle increment installs once")
	candidate.call("set_cash", -1000000000000)
	assert_equal(candidate.call("get_cash"), -1000000000000, "Signed lower cash boundary is accepted")
	candidate.call("set_cash", 1000000000000)
	assert_equal(candidate.call("get_cash"), 1000000000000, "Signed upper cash boundary is accepted")
	return finish()


func _verify_invalid_probes() -> void:
	var cases := {
		"company_count": "RunState requires exactly six companies",
		"empty_id": "RunState company ID cannot be empty",
		"duplicate_id": "RunState company IDs must be unique",
		"cash_low": "Run cash exceeds the prototype bound",
		"cash_high": "Run cash exceeds the prototype bound",
		"trust_negative": "RunState trust exceeds the prototype bound",
		"trust_high": "RunState trust exceeds the prototype bound",
		"cycle_negative": "Completed cycle count cannot be negative",
		"set_cash_high": "Run cash exceeds the prototype bound",
		"add_trust_negative": "Trust increment cannot be negative",
		"add_trust_overflow": "RunState trust overflow",
		"cycle_overflow": "Completed cycle count overflow",
		"replace_ids": "Source RunState company IDs must match in stable order",
	}
	for case_name in cases:
		_run_invalid_probe(case_name, cases[case_name])


func _run_invalid_probe(case_name: String, expected_message: String) -> void:
	var output: Array = []
	var arguments := PackedStringArray([
		"--headless",
		"--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/run_all.gd",
		"--quit-after", "1",
		"--",
		"--run-state-invalid-probe=" + case_name,
	])
	OS.execute(OS.get_executable_path(), arguments, output, true)
	var captured_text := "\n".join(PackedStringArray(output))
	assert_true(captured_text.contains("RUN_STATE_INVALID_PROBE_BEGIN:" + case_name), "RunState invalid probe starts: " + case_name)
	assert_true(captured_text.contains(expected_message), "RunState invalid probe reports: " + expected_message)


func run_invalid_probe(case_name: String) -> void:
	var state_script: Script = load(RUN_STATE_PATH)
	var ids := [&"company_01", &"company_02", &"company_03", &"company_04", &"company_05", &"company_06"]
	if case_name == "company_count":
		state_script.new(0, [&"company_01"])
	elif case_name == "empty_id":
		ids[0] = &""
		state_script.new(0, ids)
	elif case_name == "duplicate_id":
		ids[1] = ids[0]
		state_script.new(0, ids)
	elif case_name == "cash_low":
		state_script.new(-1000000000001, ids)
	elif case_name == "cash_high":
		state_script.new(1000000000001, ids)
	elif case_name == "trust_negative":
		state_script.new(0, ids, {&"company_01": -1})
	elif case_name == "trust_high":
		state_script.new(0, ids, {&"company_01": 1000000000001})
	elif case_name == "cycle_negative":
		state_script.new(0, ids, {}, -1)
	elif case_name == "set_cash_high":
		state_script.new(0, ids).set_cash(1000000000001)
	elif case_name == "add_trust_negative":
		state_script.new(0, ids).add_company_trust_milli(&"company_01", -1)
	elif case_name == "add_trust_overflow":
		state_script.new(0, ids, {&"company_01": 1000000000000}).add_company_trust_milli(&"company_01", 1)
	elif case_name == "cycle_overflow":
		state_script.new(0, ids, {}, 9223372036854775807).increment_completed_cycle()
	elif case_name == "replace_ids":
		var other_ids := [&"other_01", &"other_02", &"other_03", &"other_04", &"other_05", &"other_06"]
		state_script.new(0, ids).replace_with(state_script.new(0, other_ids))
