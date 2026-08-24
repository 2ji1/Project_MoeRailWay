@tool
extends EditorPlugin

const GATE_FLAG := "--moerail-logical-field-editor-gate"
const FIELD_SCENE_PATH := "res://src/presentation/track/logical_track_field.tscn"
const APP_INTEGRATION_SCRIPT := "res://tests/integration/run_track_train_app_integration.gd"
const APP_INTEGRATION_PASS := "PASS: track train app integration"
const PASS_MARKER := "PASS: logical track field editor integration"

var _failures := PackedStringArray()
var _gate_started := false


func _enter_tree() -> void:
    if GATE_FLAG not in OS.get_cmdline_user_args():
        return
    if _gate_started:
        return
    _gate_started = true
    call_deferred("_run_gate")


func _run_gate() -> void:
    _assert_true(Engine.is_editor_hint(), "Editor integration must run with editor hint")
    var editor_filesystem := EditorInterface.get_resource_filesystem()
    _assert_true(editor_filesystem != null, "Editor filesystem must exist")
    if editor_filesystem != null:
        while editor_filesystem.is_scanning():
            await get_tree().process_frame
        await get_tree().process_frame

    var packed = load(FIELD_SCENE_PATH) as PackedScene
    _assert_true(packed != null, "Logical field scene must load in the editor")
    if packed != null:
        var field = packed.instantiate()
        var baseline: Array[Dictionary] = field.get_sorted_candidate_records()
        _assert_equal(baseline.size(), 8, "Editor gate requires eight authored candidates")
        var normalized: Array[Vector2] = []
        for record in baseline:
            normalized.append(record.position / Vector2(1200.0, 560.0))
        var cases := [
            [field.SizePreset.COMPACT, Vector2(900.0, 420.0), Vector2i(22, 10), Vector2(10.0, 10.0)],
            [field.SizePreset.STANDARD, Vector2(1200.0, 560.0), Vector2i(30, 14), Vector2.ZERO],
            [field.SizePreset.EXPANSIVE, Vector2(1500.0, 700.0), Vector2i(36, 16), Vector2(30.0, 30.0)],
        ]
        for case in cases:
            field.size_preset = case[0]
            _assert_equal(
                field.get_editor_boundary_rect(),
                Rect2(Vector2.ZERO, case[1]),
                "Preset boundary must update in editor"
            )
            _assert_normalized_positions(
                field.get_sorted_candidate_records(), normalized, case[1]
            )
            _assert_equal(field.get_grid_size(), case[2], "Preset grid size must be exact")
            _assert_equal(field.get_grid_rect().position, case[3], "Preset grid origin must be centered")
        field.size_preset = field.SizePreset.CUSTOM
        field.custom_width = 960.0
        field.custom_height = 480.0
        field.custom_grid_columns = 24
        field.custom_grid_rows = 12
        _assert_equal(
            field.get_editor_boundary_rect(),
            Rect2(Vector2.ZERO, Vector2(960.0, 480.0)),
            "CUSTOM boundary must update in editor"
        )
        _assert_normalized_positions(
            field.get_sorted_candidate_records(), normalized, Vector2(960.0, 480.0)
        )
        _assert_equal(field.get_grid_size(), Vector2i(24, 12), "CUSTOM grid size must be exact")
        _assert_equal(field.get_grid_rect().position, Vector2.ZERO, "Fitted CUSTOM grid origin")
        _assert_equal(field.validate_configuration(), PackedStringArray(), "Fitted CUSTOM grid must validate")
        field.custom_grid_columns = 25
        _assert_contains(
            field.validate_configuration(),
            "grid dimensions must fit within logical bounds",
            "Oversized CUSTOM columns must be rejected"
        )
        field.custom_grid_columns = 24
        field.custom_grid_rows = 13
        _assert_contains(
            field.validate_configuration(),
            "grid dimensions must fit within logical bounds",
            "Oversized CUSTOM rows must be rejected"
        )
        field.free()

    _verify_composition_snapping()

    _finish_gate()


func _finish_gate() -> void:
    if _failures.is_empty():
        print(PASS_MARKER)
    else:
        for failure in _failures:
            push_error(failure)
        print("FAIL: %d logical track field editor assertion(s)" % _failures.size())


func _assert_normalized_positions(
    records: Array[Dictionary],
    expected: Array[Vector2],
    logical_size: Vector2
) -> void:
    _assert_equal(records.size(), expected.size(), "Candidate count must remain stable")
    for index in range(min(records.size(), expected.size())):
        _assert_true(
            records[index].position.is_equal_approx(expected[index] * logical_size),
            "Editor resize must preserve normalized candidate positions"
        )


func _verify_composition_snapping() -> void:
    var output: Array[String] = []
    var arguments := PackedStringArray([
        "--headless",
        "--path",
        ProjectSettings.globalize_path("res://"),
        "--script",
        APP_INTEGRATION_SCRIPT,
    ])
    var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true)
    var combined_output := "\n".join(output)
    _assert_equal(exit_code, 0, "External app composition harness must exit successfully")
    _assert_true(
        APP_INTEGRATION_PASS in combined_output,
        "External app composition harness must publish its PASS marker"
    )
    for forbidden in ["SCRIPT ERROR", "Parse Error", "FAIL:"]:
        _assert_true(
            forbidden not in combined_output,
            "External app composition harness must not emit %s" % forbidden
        )


func _assert_contains(values: PackedStringArray, expected: String, message: String) -> void:
    if expected not in values:
        _failures.append("%s | missing=%s actual=%s" % [message, expected, values])


func _assert_true(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        _failures.append("%s | expected=%s actual=%s" % [message, expected, actual])
