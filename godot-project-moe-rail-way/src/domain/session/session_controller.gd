class_name SessionController
extends RefCounted

const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")

signal snapshot_published(snapshot: SessionSnapshotScript)
signal session_completed(result: SessionResultScript)

enum State {
    READY,
    RUNNING,
    COMPLETED,
}

var _state: State = State.READY
var _total_ticks: int
var _elapsed_ticks := 0
var _remaining_ticks: int
var _ticks_per_second: int
var _snapshot: SessionSnapshotScript


func _init(start_config: SessionStartConfigScript) -> void:
    _ticks_per_second = start_config.simulation_ticks_per_second
    _total_ticks = max(
        1,
        int(ceil(start_config.session_duration_seconds * float(_ticks_per_second)))
    )
    _remaining_ticks = _total_ticks
    _snapshot = _create_snapshot()


func start() -> void:
    if _state != State.READY:
        return
    _state = State.RUNNING
    _publish_snapshot()


func advance_tick() -> void:
    if _state != State.RUNNING:
        return

    _elapsed_ticks += 1
    _remaining_ticks = max(0, _remaining_ticks - 1)
    var completed_this_tick := _remaining_ticks == 0
    if completed_this_tick:
        _state = State.COMPLETED
    _publish_snapshot()

    if not completed_this_tick:
        return

    var result = SessionResultScript.new(
        SessionResultScript.Reason.REGULAR_TIME_EXPIRED,
        _total_ticks,
        _elapsed_ticks,
        _remaining_ticks
    )
    session_completed.emit(result)


func get_snapshot() -> SessionSnapshotScript:
    return _snapshot


func get_state() -> State:
    return _state


func _publish_snapshot() -> void:
    _snapshot = _create_snapshot()
    snapshot_published.emit(_snapshot)


func _create_snapshot() -> SessionSnapshotScript:
    return SessionSnapshotScript.new(
        _total_ticks,
        _elapsed_ticks,
        _remaining_ticks,
        _ticks_per_second
    )
