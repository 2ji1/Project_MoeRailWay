@tool
extends EditorPlugin

const GATE_FLAG := "--moerail-logical-field-editor-gate"
const FIELD_SCENE_PATH := "res://src/presentation/track/logical_track_field.tscn"
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
            [field.SizePreset.COMPACT, Vector2(900.0, 420.0)],
            [field.SizePreset.STANDARD, Vector2(1200.0, 560.0)],
            [field.SizePreset.EXPANSIVE, Vector2(1500.0, 700.0)],
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
        field.size_preset = field.SizePreset.CUSTOM
        field.custom_width = 960.0
        field.custom_height = 480.0
        _assert_equal(
            field.get_editor_boundary_rect(),
            Rect2(Vector2.ZERO, Vector2(960.0, 480.0)),
            "CUSTOM boundary must update in editor"
        )
        _assert_normalized_positions(
            field.get_sorted_candidate_records(), normalized, Vector2(960.0, 480.0)
        )
        field.free()

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


func _assert_true(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
    if actual != expected:
        _failures.append("%s | expected=%s actual=%s" % [message, expected, actual])
