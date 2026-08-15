extends SceneTree

const SUITES = [
    preload("res://tests/smoke/test_project_boot.gd"),
    preload("res://tests/unit/test_config_validator.gd"),
    preload("res://tests/unit/test_session_rng.gd"),
    preload("res://tests/unit/test_project_settings.gd"),
    preload("res://tests/unit/test_session_controller.gd"),
    preload("res://tests/unit/test_ui_layout_validator.gd"),
]


func _initialize() -> void:
    var failures := PackedStringArray()

    for suite_script in SUITES:
        var suite = suite_script.new()
        var suite_failures: PackedStringArray = suite.run()
        for failure in suite_failures:
            failures.append("%s: %s" % [suite_script.resource_path, failure])

    if failures.is_empty():
        print("PASS: %d prototype test suite(s)" % SUITES.size())
        quit(0)
        return

    for failure in failures:
        push_error(failure)
    print("FAIL: %d assertion(s)" % failures.size())
    quit(1)
