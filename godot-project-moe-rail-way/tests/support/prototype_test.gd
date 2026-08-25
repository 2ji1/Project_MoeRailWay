extends RefCounted

var _failures := PackedStringArray()


func assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)


func assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append(
			"%s | expected=%s actual=%s" % [message, str(expected), str(actual)]
		)


func assert_not_null(value: Variant, message: String) -> void:
	assert_true(value != null, message)


func finish() -> PackedStringArray:
	return _failures.duplicate()
