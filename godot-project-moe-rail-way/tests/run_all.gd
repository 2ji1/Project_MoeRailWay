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
    preload("res://tests/unit/test_warp_cargo_session_controller.gd"),
    preload("res://tests/unit/test_warp_cargo_presentation.gd"),
    preload("res://tests/unit/test_warp_cargo_control_feel_presentation.gd"),
    preload("res://tests/unit/test_session_economy.gd"),
    preload("res://tests/unit/test_hazard_system.gd"),
    preload("res://tests/unit/test_risk_session_controller.gd"),
    preload("res://tests/unit/test_track_system_demolition.gd"),
    preload("res://tests/unit/test_track_system_crossing.gd"),
    preload("res://tests/unit/test_session_investment_purchases.gd"),
    preload("res://tests/unit/test_risk_investment_presentation.gd"),
    preload("res://tests/unit/test_contract_economy_config.gd"),
    preload("res://tests/unit/test_run_state.gd"),
    preload("res://tests/unit/test_contract_system.gd"),
    preload("res://tests/unit/test_contract_session_controller.gd"),
    preload("res://tests/unit/test_prototype_run_controller.gd"),
    preload("res://tests/unit/test_contract_economy_presentation.gd"),
    preload("res://tests/unit/test_credit_limit.gd"),
    preload("res://tests/unit/test_credit_system.gd"),
]

const GridTrackRuntimeSuiteScript = preload("res://tests/unit/test_grid_track_runtime.gd")
const WarpPairSystemSuiteScript = preload("res://tests/unit/test_warp_pair_system.gd")
const CargoSystemSuiteScript = preload("res://tests/unit/test_cargo_system.gd")
const WarpCargoSessionControllerSuiteScript = preload(
    "res://tests/unit/test_warp_cargo_session_controller.gd"
)
const RunStateSuiteScript = preload("res://tests/unit/test_run_state.gd")
const ContractSessionControllerSuiteScript = preload(
    "res://tests/unit/test_contract_session_controller.gd"
)
const CreditLimitSuiteScript = preload("res://tests/unit/test_credit_limit.gd")


func _initialize() -> void:
    call_deferred("_run_suites")


func _run_suites() -> void:
    var credit_limit_probe_prefix := "--credit-limit-invalid-probe="
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with(credit_limit_probe_prefix):
            var probe_case := argument.trim_prefix(credit_limit_probe_prefix)
            print("CREDIT_LIMIT_INVALID_PROBE_BEGIN:" + probe_case)
            CreditLimitSuiteScript.new().run_invalid_probe(probe_case)
            quit(1)
            return
    var contract_controller_probe_prefix := "--contract-controller-invalid-probe="
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with(contract_controller_probe_prefix):
            var probe_case := argument.trim_prefix(contract_controller_probe_prefix)
            print("CONTRACT_CONTROLLER_INVALID_PROBE_BEGIN:" + probe_case)
            ContractSessionControllerSuiteScript.new().run_invalid_probe(probe_case)
            quit(0)
            return
    var run_state_probe_prefix := "--run-state-invalid-probe="
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with(run_state_probe_prefix):
            var probe_case := argument.trim_prefix(run_state_probe_prefix)
            print("RUN_STATE_INVALID_PROBE_BEGIN:" + probe_case)
            RunStateSuiteScript.new().run_invalid_probe(probe_case)
            quit(0)
            return
    var controller_probe_prefix := "--warp-cargo-controller-invalid-probe="
    var warp_probe_prefix := "--warp-pair-invalid-probe="
    var cargo_probe_prefix := "--cargo-invalid-probe="
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with(controller_probe_prefix):
            var probe_case := argument.trim_prefix(controller_probe_prefix)
            print("WARP_CARGO_CONTROLLER_INVALID_PROBE_BEGIN:" + probe_case)
            WarpCargoSessionControllerSuiteScript.new().run_invalid_probe(probe_case)
            quit(0)
            return
        if argument.begins_with(warp_probe_prefix):
            var probe_case := argument.trim_prefix(warp_probe_prefix)
            print("WARP_PAIR_INVALID_PROBE_BEGIN:" + probe_case)
            WarpPairSystemSuiteScript.new().run_invalid_probe(probe_case)
            quit(0)
            return
        if argument.begins_with(cargo_probe_prefix):
            var probe_case := argument.trim_prefix(cargo_probe_prefix)
            print("CARGO_INVALID_PROBE_BEGIN:" + probe_case)
            CargoSystemSuiteScript.new().run_invalid_probe(probe_case)
            quit(0)
            return

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
