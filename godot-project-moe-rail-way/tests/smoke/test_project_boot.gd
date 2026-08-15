extends "res://tests/support/prototype_test.gd"

const PrototypeAppScript = preload("res://src/app/prototype_app.gd")
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")


class OffsetSeedBalance extends PrototypeBalanceScript:
    func create_session_start_config(seed_value: int) -> SessionStartConfigScript:
        return SessionStartConfigScript.new(
            seed_value + 1,
            session_duration_seconds,
            simulation_ticks_per_second
        )


func run() -> PackedStringArray:
    var balance_property := _find_script_property("balance")
    assert_false(
        balance_property.is_empty(),
        "PrototypeApp must export the balance property"
    )
    if not balance_property.is_empty():
        assert_equal(
            balance_property.get("type"),
            TYPE_OBJECT,
            "PrototypeApp balance must be an object property"
        )
        assert_equal(
            balance_property.get("hint"),
            PROPERTY_HINT_RESOURCE_TYPE,
            "PrototypeApp balance must use a resource-type Inspector hint"
        )
        assert_equal(
            balance_property.get("hint_string"),
            "PrototypeBalance",
            "PrototypeApp balance Inspector must accept only PrototypeBalance"
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
            instance.set("balance", OffsetSeedBalance.new())
            instance.set("startup_seed", 4242)
            instance.call("_ready")

            var start_config = instance.get("session_start_config")
            var app_rng = instance.get("session_rng")
            assert_not_null(
                start_config,
                "PrototypeApp must compose SessionStartConfig during startup"
            )
            assert_not_null(
                app_rng,
                "PrototypeApp must compose SessionRng during startup"
            )
            if start_config != null and app_rng != null:
                assert_equal(
                    start_config.seed,
                    4243,
                    "PrototypeApp must retain the factory-produced session seed"
                )
                var expected_rng = SessionRngScript.new(start_config.seed)
                for index in range(8):
                    assert_equal(
                        app_rng.next_u32(),
                        expected_rng.next_u32(),
                        "PrototypeApp must seed SessionRng from SessionStartConfig at sample %d" % index
                    )
            instance.free()

    return finish()


func _find_script_property(property_name: StringName) -> Dictionary:
    var app = PrototypeAppScript.new()
    var properties := app.get_property_list()
    app.free()
    for property in properties:
        if property.get("name") == property_name:
            return property
    return {}
