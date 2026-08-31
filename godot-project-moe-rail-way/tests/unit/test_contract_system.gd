extends "res://tests/support/prototype_test.gd"

const CONTRACT_SYSTEM_PATH := "res://src/domain/contract/contract_system.gd"


func run() -> PackedStringArray:
	assert_true(ResourceLoader.exists(CONTRACT_SYSTEM_PATH), "ContractSystem exists")
	if not ResourceLoader.exists(CONTRACT_SYSTEM_PATH):
		return finish()
	var script: Script = load(CONTRACT_SYSTEM_PATH)
	var contract := {
		"company_id": &"company_02",
		"quota": 4,
		"maximum_shortfall_penalty": 100,
		"completion_bonus_at_quota": 60,
		"trust_per_excess_delivery_milli": 125,
	}
	var system: Variant = script.new(contract)
	assert_equal(system.get_selected_company_id(), &"company_02", "Selected company is immutable")
	assert_equal(system.get_quota(), 4, "Selected quota is immutable")

	for index in range(6):
		var company_id := &"company_02" if index != 1 else &"company_01"
		assert_true(system.try_record_delivery({"pair_id": StringName("pair_%d" % index), "company_id": company_id, "base_delivery_fee": 20}), "Unique delivery fact records")
	assert_equal(system.get_contracted_delivery_count(), 5, "Only selected-company deliveries count")
	assert_equal(system.get_attainment_basis_points(), 12500, "Attainment may exceed 100 percent")
	assert_equal(system.get_cash_contract_adjustment(), 60, "Cash adjustment caps at quota bonus")
	assert_equal(system.get_trust_gain_milli(), 125, "Only one excess delivery creates trust")
	var recorded_facts: Array[Dictionary] = system.get_delivery_facts()
	assert_true(recorded_facts[0]["is_selected_contract"], "Selected delivery fact records contract match")
	assert_equal(recorded_facts[0]["contracted_delivery_count_after_event"], 1, "Selected fact records post-event count")
	assert_false(recorded_facts[1]["is_selected_contract"], "Unselected delivery fact records contract mismatch")
	assert_equal(recorded_facts[1]["contracted_delivery_count_after_event"], 1, "Unselected fact preserves prior selected count")
	var before_duplicate := JSON.stringify(system.get_observation())
	assert_false(system.try_record_delivery({"pair_id": &"pair_0", "company_id": &"company_02", "base_delivery_fee": 20}), "Repeated delivery rejects")
	assert_equal(JSON.stringify(system.get_observation()), before_duplicate, "Repeated delivery leaves contract byte-identical")
	assert_false(system.try_record_delivery({"pair_id": &"invalid", "company_id": StringName(), "base_delivery_fee": 20}), "Malformed delivery rejects")
	assert_equal(JSON.stringify(system.get_observation()), before_duplicate, "Malformed delivery leaves contract byte-identical")
	var detached_facts: Array[Dictionary] = system.get_delivery_facts()
	detached_facts[0]["company_id"] = &"mutated"
	assert_equal(system.get_delivery_facts()[0]["company_id"], &"company_02", "Delivery facts are recursively detached")

	var expected_adjustments := [-100, -60, -20, 20, 60]
	for delivered in range(5):
		var curve_system: Variant = script.new(contract)
		for index in range(delivered):
			curve_system.try_record_delivery({"pair_id": StringName("curve_%d" % index), "company_id": &"company_02", "base_delivery_fee": 1})
		assert_equal(curve_system.get_cash_contract_adjustment(), expected_adjustments[delivered], "Integer cash curve resolves delivery %d" % delivered)

	var negative_tie: Variant = script.new({"company_id": &"company_01", "quota": 2, "maximum_shortfall_penalty": 1, "completion_bonus_at_quota": 0, "trust_per_excess_delivery_milli": 0})
	negative_tie.try_record_delivery({"pair_id": &"negative_tie", "company_id": &"company_01", "base_delivery_fee": 0})
	assert_equal(negative_tie.get_cash_contract_adjustment(), -1, "Negative half rounds away from zero")
	var positive_tie: Variant = script.new({"company_id": &"company_01", "quota": 2, "maximum_shortfall_penalty": 0, "completion_bonus_at_quota": 1, "trust_per_excess_delivery_milli": 0})
	positive_tie.try_record_delivery({"pair_id": &"tie", "company_id": &"company_01", "base_delivery_fee": 0})
	assert_equal(positive_tie.get_cash_contract_adjustment(), 1, "Positive half rounds away from zero")
	return finish()
