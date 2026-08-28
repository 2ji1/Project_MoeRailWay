extends SceneTree

const SUITES = [
    preload("res://tests/smoke/test_project_boot.gd"),
    preload("res://tests/unit/test_config_validator.gd"),
    preload("res://tests/unit/test_session_rng.gd"),
    preload("res://tests/unit/test_project_settings.gd"),
    preload("res://tests/unit/test_session_controller.gd"),
    preload("res://tests/unit/test_ui_layout_validator.gd"),
    preload("res://tests/unit/test_track_train_config_validator.gd"),
    preload("res://tests/unit/test_departure_selection.gd"),
    preload("res://tests/unit/test_track_system_reservation.gd"),
    preload("res://tests/unit/test_track_system_construction_recovery.gd"),
    preload("res://tests/unit/test_train_system.gd"),
    preload("res://tests/unit/test_track_field_view_input.gd"),
    preload("res://tests/unit/test_track_train_session_controller.gd"),
    preload("res://tests/smoke/test_track_train_app_composition.gd"),
    preload("res://tests/unit/test_track_cell_sequence.gd"),
    preload("res://tests/unit/test_track_geometry_resolver.gd"),
    preload("res://tests/unit/test_grid_track_runtime.gd"),
    preload("res://tests/unit/test_nominal_train_motion.gd"),
    preload("res://tests/unit/test_grid_pointer_rasterizer.gd"),
    preload("res://tests/unit/test_warp_pair_system.gd"),
    preload("res://tests/unit/test_cargo_system.gd"),
]

const GridTrackRuntimeSuiteScript = preload("res://tests/unit/test_grid_track_runtime.gd")


func _initialize() -> void:
    call_deferred("_run_suites")


func _run_suites() -> void:
    var probe_prefix := "--track-invalid-probe="
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with(probe_prefix):
            var probe_case := argument.trim_prefix(probe_prefix)
            print("TRACK_INVALID_PROBE_BEGIN:" + probe_case)
            SUITES[8].new().run_invalid_probe(probe_case)
            quit(0)
            return

    for argument in OS.get_cmdline_user_args():
        if argument == "--reflow-unprepared-pose-probe":
            print("REFLOW_UNPREPARED_POSE_PROBE_BEGIN")
            if not GridTrackRuntimeSuiteScript.new().run_unprepared_pose_probe():
                quit(1)
                return
            quit(0)
            return

    var requested_suite := ""
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--suite="):
            requested_suite = argument.trim_prefix("--suite=")
    var selected_suites := SUITES
    if not requested_suite.is_empty():
        selected_suites = []
        for suite_script in SUITES:
            if suite_script.resource_path.get_file() == requested_suite:
                selected_suites.append(suite_script)
        if selected_suites.is_empty():
            push_error("Unknown prototype suite: " + requested_suite)
            quit(1)
            return
    var failures := PackedStringArray()
    for suite_script in selected_suites:
        var suite = suite_script.new()
        var suite_failures: PackedStringArray = suite.run()
        for failure in suite_failures:
            failures.append("%s: %s" % [suite_script.resource_path, failure])

    if failures.is_empty():
        print("PASS: %d prototype test suite(s)" % selected_suites.size())
        quit(0)
        return

    for failure in failures:
        push_error(failure)
    print("FAIL: %d assertion(s)" % failures.size())
    quit(1)
