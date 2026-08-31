class_name TerminalRunResult
extends RefCounted

enum Reason { CREDIT_EXHAUSTED, RECOVERY_DECLINED }

var _reason: Reason
var _run_state: Dictionary
var _settlement: Dictionary
var _recovery: Dictionary


func _init(reason_value: Reason, run_state_value: Dictionary, settlement_value: Dictionary, recovery_value: Dictionary) -> void:
	assert(reason_value in [Reason.CREDIT_EXHAUSTED, Reason.RECOVERY_DECLINED], "Terminal reason is invalid")
	_reason = reason_value
	_run_state = run_state_value.duplicate(true)
	_settlement = settlement_value.duplicate(true)
	_recovery = recovery_value.duplicate(true)


func get_reason() -> Reason: return _reason
func get_observation() -> Dictionary:
	return {"reason": _reason, "run_state": _run_state, "settlement": _settlement, "recovery": _recovery}.duplicate(true)
