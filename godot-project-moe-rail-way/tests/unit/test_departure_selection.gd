extends "res://tests/support/prototype_test.gd"

const FIELD_SCENE_PATH := "res://src/presentation/track/logical_track_field.tscn"
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")


func run() -> PackedStringArray:
	var packed = load(FIELD_SCENE_PATH) as PackedScene
	assert_not_null(packed, "Logical field scene must load")
	if packed == null:
		return finish()
	var field = packed.instantiate()
	assert_equal(field.get_logical_size(), Vector2(1200.0, 560.0), "STANDARD must be default")
	assert_equal(field.get_editor_boundary_rect(), Rect2(Vector2.ZERO, Vector2(1200.0, 560.0)), "Editor boundary must match logical size")
	var records: Array[Dictionary] = field.get_sorted_candidate_records()
	assert_equal(records.size(), 8, "Default field must contain eight candidates")
	var expected_standard_positions := [
		Vector2(216.0, 123.2), Vector2(600.0, 100.8),
		Vector2(984.0, 123.2), Vector2(264.0, 280.0),
		Vector2(936.0, 280.0), Vector2(216.0, 436.8),
		Vector2(600.0, 459.2), Vector2(984.0, 436.8),
	]
	for index in range(records.size()):
		assert_equal(
			records[index].candidate_id,
			StringName("departure_%02d" % (index + 1)),
			"Candidate records must sort by stable ID"
		)
		_assert_vector_close(
			records[index].position,
			expected_standard_positions[index],
			"Candidate STANDARD position must match its approved normalized default"
		)
	var first_id := _select_id(records, 9123)
	assert_equal(_select_id(records, 9123), first_id, "Equal seed and set must select equal ID")
	var moved_records := records.duplicate(true)
	moved_records[0].position += Vector2(20.0, 10.0)
	assert_equal(_select_id(moved_records, 9123), first_id, "Moving positions must not change selected ID")

	var peek_rng = SessionRngScript.new(9123)
	var consuming_rng = SessionRngScript.new(9123)
	var untouched_rng = SessionRngScript.new(9123)
	assert_equal(
		peek_rng.peek_index(records.size()),
		consuming_rng.next_index(records.size()),
		"Peek must return the same bounded sample as one consuming draw"
	)
	for sample_index in range(3):
		assert_equal(
			peek_rng.next_u32(),
			untouched_rng.next_u32(),
			"Peek must preserve the public RNG sequence at sample %d" % sample_index
		)

	for invalid_bound in [0, -3]:
		var invalid_next_rng = SessionRngScript.new(9123)
		var invalid_next_baseline = SessionRngScript.new(9123)
		assert_equal(invalid_next_rng.next_index(invalid_bound), -1, "Invalid next bound must reject")
		assert_equal(invalid_next_rng.next_u32(), invalid_next_baseline.next_u32(), "Rejected next bound must not consume RNG")
		var invalid_peek_rng = SessionRngScript.new(9123)
		var invalid_peek_baseline = SessionRngScript.new(9123)
		assert_equal(invalid_peek_rng.peek_index(invalid_bound), -1, "Invalid peek bound must reject")
		assert_equal(invalid_peek_rng.next_u32(), invalid_peek_baseline.next_u32(), "Rejected peek bound must not consume RNG")

	for edge_position in [
		Vector2(0.0, 280.0), Vector2(1200.0, 280.0),
		Vector2(600.0, 0.0), Vector2(600.0, 560.0),
	]:
		field.get_node("DepartureCandidates").get_child(0).position = edge_position
		assert_equal(field.validate_configuration().size(), 0, "Every logical boundary edge must be inclusive")
	for outside_position in [
		Vector2(-0.1, 280.0), Vector2(1200.1, 280.0),
		Vector2(600.0, -0.1), Vector2(600.0, 560.1),
	]:
		field.get_node("DepartureCandidates").get_child(0).position = outside_position
		_assert_contains(field.validate_configuration(), "position", "Coordinates beyond any logical edge must be rejected")
	field.get_node("DepartureCandidates").get_child(0).position = Vector2(216.0, 123.2)

	var before_positions := PackedVector2Array()
	for record in records:
		before_positions.append(record.position / Vector2(1200.0, 560.0))
	field.size_preset = field.SizePreset.EXPANSIVE
	var expanded: Array[Dictionary] = field.get_sorted_candidate_records()
	for index in range(expanded.size()):
		_assert_vector_close(
			expanded[index].position / Vector2(1500.0, 700.0),
			before_positions[index],
			"Preset change must preserve normalized candidate position"
		)

	field.size_preset = field.SizePreset.CUSTOM
	field.custom_width = 639.0
	field.custom_height = 319.0
	var custom_errors: PackedStringArray = field.validate_configuration()
	_assert_contains(custom_errors, "custom_width", "CUSTOM width below 640 must be rejected")
	_assert_contains(custom_errors, "custom_height", "CUSTOM height below 320 must be rejected")
	field.custom_width = 4001.0
	field.custom_height = 560.0
	custom_errors = field.validate_configuration()
	_assert_contains(custom_errors, "custom_width", "CUSTOM width above 4000 must be rejected")
	field.custom_width = 1200.0
	field.custom_height = 2161.0
	custom_errors = field.validate_configuration()
	_assert_contains(custom_errors, "custom_height", "CUSTOM height above 2160 must be rejected")
	field.custom_width = 1200.0
	field.custom_height = 560.0

	var candidate_parent = field.get_node("DepartureCandidates")
	candidate_parent.get_child(1).candidate_id = candidate_parent.get_child(0).candidate_id
	_assert_contains(field.validate_configuration(), "candidate_id", "Duplicate ID must be rejected")
	candidate_parent.get_child(1).candidate_id = &"departure_02"
	candidate_parent.get_child(1).position = Vector2(-1.0, 10.0)
	_assert_contains(field.validate_configuration(), "position", "Out-of-bounds position must be rejected")
	candidate_parent.get_child(1).position = Vector2(600.0, 100.8)
	candidate_parent.get_child(1).candidate_id = StringName()
	_assert_contains(field.validate_configuration(), "candidate_id", "Empty ID must be rejected")

	var plain_node_field = packed.instantiate()
	var plain_parent = plain_node_field.get_node("DepartureCandidates")
	for child in plain_parent.get_children():
		plain_parent.remove_child(child)
		child.free()
	var plain_node = Node.new()
	plain_parent.add_child(plain_node)
	_assert_contains(
		plain_node_field.validate_configuration(),
		"DepartureCandidates",
		"DepartureCandidates with only a plain Node child must be rejected"
	)
	plain_node_field.free()

	var empty_field = packed.instantiate()
	var empty_parent = empty_field.get_node("DepartureCandidates")
	for child in empty_parent.get_children():
		empty_parent.remove_child(child)
		child.free()
	_assert_contains(
		empty_field.validate_configuration(),
		"DepartureCandidates",
		"A field with zero candidates must be rejected"
	)
	empty_field.free()
	field.free()
	return finish()


func _select_id(records: Array[Dictionary], seed_value: int) -> StringName:
	var rng = SessionRngScript.new(seed_value)
	return records[rng.peek_index(records.size())].candidate_id


func _assert_contains(errors: PackedStringArray, fragment: String, message: String) -> void:
	var found := false
	for error_message in errors:
		found = found or error_message.contains(fragment)
	assert_true(found, message)


func _assert_vector_close(actual: Vector2, expected: Vector2, message: String) -> void:
	assert_true(actual.is_equal_approx(expected), message)
