extends "res://tests/support/prototype_test.gd"

const SessionRngScript = preload("res://src/domain/random/session_rng.gd")


func run() -> PackedStringArray:
	var first = SessionRngScript.new(4242)
	var second = SessionRngScript.new(4242)

	for index in range(16):
		assert_equal(
			first.next_u32(),
			second.next_u32(),
			"Matching seeds must match at integer sample %d" % index
		)

	var first_float = SessionRngScript.new(9001)
	var second_float = SessionRngScript.new(9001)
	for index in range(16):
		assert_equal(
			first_float.next_unit_float(),
			second_float.next_unit_float(),
			"Matching seeds must match at float sample %d" % index
		)

	var baseline_sequence := []
	var alternate_sequence := []
	var baseline_rng = SessionRngScript.new(4242)
	var alternate_rng = SessionRngScript.new(4243)
	for index in range(16):
		baseline_sequence.append(baseline_rng.next_u32())
		alternate_sequence.append(alternate_rng.next_u32())
	assert_false(
		baseline_sequence == alternate_sequence,
        "Different seeds must produce different integer sequences"
	)

	return finish()
