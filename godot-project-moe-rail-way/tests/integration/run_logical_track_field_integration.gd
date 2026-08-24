extends SceneTree

const FIELD_SCENE_PATH := "res://src/presentation/track/logical_track_field.tscn"
const TrackFieldViewScript = preload("res://src/presentation/track/track_field_view.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed = load(FIELD_SCENE_PATH) as PackedScene
	_assert_true(packed != null, "Logical field scene must load for runtime integration")
	if packed != null:
		var view = TrackFieldViewScript.new()
		view.size = Vector2(1000.0, 700.0)
		var field = packed.instantiate()
		view.add_child(field)
		root.add_child(view)
		await process_frame

		var expected_sizes := {
			field.SizePreset.COMPACT: Vector2(900.0, 420.0),
			field.SizePreset.STANDARD: Vector2(1200.0, 560.0),
			field.SizePreset.EXPANSIVE: Vector2(1500.0, 700.0),
			field.SizePreset.CUSTOM: Vector2(800.0, 400.0),
		}
		field.custom_width = 800.0
		field.custom_height = 400.0
		for preset in expected_sizes:
			field.size_preset = preset
			_assert_equal(field.get_logical_size(), expected_sizes[preset], "Every logical field preset must expose its approved size")

		field.size_preset = field.SizePreset.STANDARD
		var content_rect := view.get_logical_content_rect()
		_assert_vector_close(content_rect.size, Vector2(1000.0, 466.66666), "Mapping must use uniform scale")
		_assert_vector_close(content_rect.position, Vector2(0.0, 116.66667), "Mapping must center the uniform content")
		_assert_equal(view.try_viewport_to_logical(Vector2(500.0, 50.0)), null, "Letterbox points must reject")
		_assert_vector_close(view.try_viewport_to_logical(content_rect.get_center()), Vector2(600.0, 280.0), "Content center must map to logical center")

		var config = SessionStartConfigScript.new(1, 180.0, 60)
		config.logical_field_size = Vector2(1200.0, 560.0)
		config.departure_candidate_id = &"departure_03"
		config.departure_position = Vector2(984.0, 123.2)
		config.route_hit_radius_units = 16.0
		config.urgent_warning_seconds = 3.0
		view.configure_session(config)
		var configured_rect := view.get_logical_content_rect()
		var tl_before: Variant = view.try_viewport_to_logical(configured_rect.position)
		var br_before: Variant = view.try_viewport_to_logical(configured_rect.position + configured_rect.size)
		_assert_equal(tl_before, Vector2.ZERO, "Configured top-left must map to logical origin")
		_assert_equal(br_before, Vector2(1200.0, 560.0), "Configured bottom-right must map to logical size")
		_assert_vector_close(view.try_viewport_to_logical(configured_rect.get_center()), Vector2(600.0, 280.0), "Configured center must map to logical center")
		_assert_equal(view.try_viewport_to_logical(Vector2(500.0, 50.0)), null, "Letterbox must still reject after configure")
		field.size_preset = field.SizePreset.EXPANSIVE
		field.size_preset = field.SizePreset.CUSTOM
		field.custom_width = 640.0
		field.custom_height = 320.0
		var mutated_rect := view.get_logical_content_rect()
		_assert_equal(mutated_rect, configured_rect, "Configured content rect must not change with authored resize")
		_assert_equal(view.try_viewport_to_logical(mutated_rect.position), Vector2.ZERO, "Mutated top-left must still map to logical origin")
		_assert_equal(view.try_viewport_to_logical(mutated_rect.position + mutated_rect.size), Vector2(1200.0, 560.0), "Mutated bottom-right must still map to logical size")
		_assert_vector_close(view.try_viewport_to_logical(mutated_rect.get_center()), Vector2(600.0, 280.0), "Mutated center must still map to logical center")
		_assert_equal(view.try_viewport_to_logical(Vector2(500.0, 50.0)), null, "Letterbox must still reject after authored resize")
		view.queue_free()
		await process_frame

	if _failures.is_empty():
		print("PASS: logical track field runtime integration")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("FAIL: %d logical track field runtime assertion(s)" % _failures.size())
	quit(1)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s | expected=%s actual=%s" % [message, expected, actual])


func _assert_vector_close(actual: Variant, expected: Vector2, message: String) -> void:
	_assert_true(actual is Vector2 and actual.is_equal_approx(expected), message)
