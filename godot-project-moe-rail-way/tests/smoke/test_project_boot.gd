extends "res://tests/support/prototype_test.gd"

const PrototypeAppScript = preload("res://src/app/prototype_app.gd")
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")


class OffsetSeedBalance extends PrototypeBalanceScript:
	func create_session_start_config(seed_value: int) -> SessionStartConfigScript:
		return SessionStartConfigScript.new(
			seed_value + 1,
			session_duration_seconds,
			simulation_ticks_per_second
		)


func run() -> PackedStringArray:
	_verify_typed_resource_property("balance", "PrototypeBalance")
	_verify_typed_resource_property("layout_profile", "UILayoutProfile")
	var layout_property_exists := not _find_script_property("layout_profile").is_empty()

	var contract_probe = PrototypeAppScript.new()
	var compose_method_exists := contract_probe.has_method("compose_session_dependencies")
	contract_probe.free()
	assert_true(
		compose_method_exists,
        "PrototypeApp must expose compose_session_dependencies"
	)

	var packed_scene := load("res://src/app/prototype_app.tscn") as PackedScene
	assert_not_null(packed_scene, "PrototypeApp scene must load")

	if packed_scene != null:
		var instance := packed_scene.instantiate()
		assert_not_null(instance, "PrototypeApp scene must instantiate")
		if instance != null:
			assert_not_null(
				instance.get("balance"),
                "PrototypeApp must receive the default balance Resource"
			)
			if layout_property_exists and compose_method_exists:
				_verify_valid_composition(instance)
			instance.free()

	if layout_property_exists and compose_method_exists:
		_verify_invalid_composition()

	return finish()


func _verify_valid_composition(instance) -> void:
	instance.set("balance", OffsetSeedBalance.new())
	instance.set("layout_profile", UILayoutProfileScript.new())
	instance.set("startup_seed", 4242)
	var composition_errors = instance.call("compose_session_dependencies")
	assert_equal(composition_errors.size(), 0, "Valid app composition must report no errors")

	var start_config = instance.get("session_start_config")
	var app_rng = instance.get("session_rng")
	var controller = instance.get("session_controller")
	assert_not_null(start_config, "PrototypeApp must compose SessionStartConfig during startup")
	assert_not_null(app_rng, "PrototypeApp must compose SessionRng during startup")
	assert_not_null(controller, "PrototypeApp must compose SessionController during startup")
	if start_config == null or app_rng == null or controller == null:
		return

	assert_equal(start_config.seed, 4243, "PrototypeApp must retain the factory-produced session seed")
	var expected_rng = SessionRngScript.new(start_config.seed)
	for index in range(8):
		assert_equal(
			app_rng.next_u32(),
			expected_rng.next_u32(),
			"PrototypeApp must seed SessionRng from SessionStartConfig at sample %d" % index
		)
	assert_equal(
		controller.get_snapshot().get_total_ticks(),
		int(ceil(start_config.session_duration_seconds * start_config.simulation_ticks_per_second)),
        "PrototypeApp must build SessionController from the factory config"
	)
	assert_equal(
		controller.get_state(),
		SessionControllerScript.State.READY,
        "Out-of-tree composition must not start the controller"
	)


func _verify_invalid_composition() -> void:
	var invalid_instance = PrototypeAppScript.new()
	invalid_instance.set("balance", PrototypeBalanceScript.new())
	var invalid_layout = UILayoutProfileScript.new()
	invalid_layout.outer_padding_x = -1.0
	invalid_instance.set("layout_profile", invalid_layout)
	var invalid_errors = invalid_instance.call("compose_session_dependencies")
	_assert_contains_error(
		invalid_errors,
		"ui_layout_profile.outer_padding_x",
        "Invalid layout composition must report the exact field"
	)
	assert_equal(
		invalid_instance.get("session_controller"),
		null,
        "Invalid layout composition must not create or start a controller"
	)
	invalid_instance.free()


func _verify_typed_resource_property(property_name: StringName, expected_type: String) -> void:
	var property := _find_script_property(property_name)
	assert_false(property.is_empty(), "PrototypeApp must export %s" % property_name)
	if property.is_empty():
		return
	assert_equal(property.get("type"), TYPE_OBJECT, "%s must be an object property" % property_name)
	assert_equal(
		property.get("hint"),
		PROPERTY_HINT_RESOURCE_TYPE,
		"%s must use a resource-type Inspector hint" % property_name
	)
	assert_equal(
		property.get("hint_string"),
		expected_type,
		"%s Inspector type must remain specific" % property_name
	)


func _assert_contains_error(errors: PackedStringArray, fragment: String, message: String) -> void:
	var found := false
	for error_message in errors:
		if error_message.contains(fragment):
			found = true
			break
	assert_true(found, message)


func _find_script_property(property_name: StringName) -> Dictionary:
	var app = PrototypeAppScript.new()
	var properties := app.get_property_list()
	app.free()
	for property in properties:
		if property.get("name") == property_name:
			return property
	return {}
