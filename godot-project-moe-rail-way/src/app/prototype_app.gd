extends Node

const ValidatorScript = preload("res://src/config/prototype_config_validator.gd")
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionShellScript = preload("res://src/presentation/session/session_shell.gd")
const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")
const UILayoutValidatorScript = preload("res://src/presentation/layout/ui_layout_validator.gd")

signal session_result_presented(result: SessionResultScript)

@export var balance: PrototypeBalanceScript
@export var startup_seed := 1
@export var layout_profile: UILayoutProfileScript

var session_start_config: SessionStartConfigScript
var session_rng: SessionRngScript
var session_controller: SessionControllerScript

@onready var _session_shell: SessionShellScript = $SessionShell

var _session_result_was_presented := false


func _ready() -> void:
    set_physics_process(false)
    var errors := compose_session_dependencies()
    if not errors.is_empty():
        for error_message in errors:
            push_error(error_message)
        if OS.is_debug_build():
            get_tree().quit(2)
        return

    Engine.physics_ticks_per_second = session_start_config.simulation_ticks_per_second
    session_controller.snapshot_published.connect(_on_snapshot_published)
    session_controller.session_completed.connect(_on_session_completed)
    _session_shell.configure(layout_profile, session_controller.get_snapshot())
    session_controller.start()
    set_physics_process(true)
    print(
        "Moe Rail Way session shell ready | duration=%d ticks=%d"
        % [
            int(session_start_config.session_duration_seconds),
            session_start_config.simulation_ticks_per_second,
        ]
    )


func compose_session_dependencies() -> PackedStringArray:
    session_start_config = null
    session_rng = null
    session_controller = null
    _session_result_was_presented = false

    var errors := PackedStringArray()
    errors.append_array(ValidatorScript.validate(balance))
    errors.append_array(UILayoutValidatorScript.validate(layout_profile))
    if not errors.is_empty():
        return errors

    session_start_config = balance.create_session_start_config(startup_seed)
    session_rng = SessionRngScript.new(session_start_config.seed)
    session_controller = SessionControllerScript.new(session_start_config)
    return errors


func _physics_process(_delta: float) -> void:
    if session_controller == null:
        return
    if session_controller.get_state() != SessionControllerScript.State.RUNNING:
        return
    session_controller.advance_tick()


func present_session_result(result: SessionResultScript) -> void:
    if _session_result_was_presented or result == null:
        return
    _session_result_was_presented = true
    set_physics_process(false)
    _session_shell.show_result(result)
    session_result_presented.emit(result)
    var reason_name: String = SessionResultScript.Reason.keys()[result.get_reason()]
    print(
        "Moe Rail Way session complete | reason=%s elapsed_ticks=%d total_ticks=%d"
        % [reason_name, result.get_elapsed_ticks(), result.get_total_ticks()]
    )


func is_showing_result() -> bool:
    if not _session_result_was_presented or _session_shell == null:
        return false
    return _session_shell.is_showing_result()


func _on_snapshot_published(snapshot: SessionSnapshotScript) -> void:
    _session_shell.present(snapshot)


func _on_session_completed(result: SessionResultScript) -> void:
    present_session_result(result)
