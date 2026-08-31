class_name ContractResultPanel
extends Control

signal continue_requested

@onready var _reason: Label = %Reason
@onready var _title: Label = %Title
@onready var _contract_summary: Label = %ContractSummary
@onready var _line_rows: VBoxContainer = %LineRows
@onready var _cycle: Label = %Cycle
@onready var _blocked_notice: Label = %BlockedNotice
@onready var _continue_button: Button = %ContinueButton

var _settlement_observation: Dictionary = {}
var _continue_consumed := false
var _terminal_observation: Dictionary = {}


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)


func present(settlement) -> void:
	if settlement == null:
		return
	_settlement_observation = settlement.get_observation()
	_terminal_observation = {}
	_title.text = "CONTRACT SETTLEMENT"
	_continue_consumed = false
	_continue_button.show()
	_continue_button.disabled = false
	_rebuild_lines(settlement.get_ordered_line_items())
	_reason.text = _reason_text(settlement.get_completion_reason())
	_contract_summary.text = "COMPANY %s | DELIVERIES %d / %d | ATTAINMENT %.2f%%" % [
		String(settlement.get_selected_company_id()),
		settlement.get_contracted_delivery_count(),
		settlement.get_contract_quota(),
		float(settlement.get_contract_attainment_basis_points()) / 100.0,
	]
	_cycle.text = "COMPLETED CYCLE %d" % settlement.get_completed_cycle_count()
	_blocked_notice.visible = settlement.get_closing_cash() < 0
	_blocked_notice.text = "CREDIT SURVIVAL REQUIRED" if _blocked_notice.visible else ""
	show()


func present_terminal(terminal_result) -> void:
	if terminal_result == null: return
	_terminal_observation = terminal_result.get_observation()
	_title.text = "RUN ENDED"
	var reason: int = terminal_result.get_reason()
	_reason.text = "BANKRUPTCY: CREDIT EXHAUSTED" if reason == 0 else "BANKRUPTCY: RECOVERY DECLINED"
	_contract_summary.text = "FINAL CASH %d" % int(_terminal_observation.get("run_state", {}).get("cash", 0))
	_cycle.text = "COMPLETED CYCLES %d" % int(_terminal_observation.get("run_state", {}).get("completed_cycle_count", 0))
	_blocked_notice.visible = true
	_blocked_notice.text = "NO FURTHER SESSION CAN START"
	_rebuild_lines([])
	_continue_button.hide()
	_continue_button.disabled = true
	show()


func get_presentation_observation() -> Dictionary:
	var rows: Array[Dictionary] = []
	for child in _line_rows.get_children():
		if child is Label:
			rows.append({
				"id": StringName(child.get_meta("line_id", StringName())),
				"text": child.text,
				"informational": bool(child.get_meta("informational", false)),
				"mouse_filter": child.mouse_filter,
			})
	return {
		"visible": visible,
		"reason_text": _reason.text,
		"contract_text": _contract_summary.text,
		"cycle_text": _cycle.text,
		"blocked_text": _blocked_notice.text,
		"rows": rows,
		"continue_disabled": _continue_button.disabled,
		"continue_mouse_filter": _continue_button.mouse_filter,
		"settlement": _settlement_observation.duplicate(true),
		"terminal": _terminal_observation.duplicate(true),
	}.duplicate(true)


func _rebuild_lines(line_items: Array) -> void:
	for child in _line_rows.get_children():
		child.free()
	for item in line_items:
		var row := Label.new()
		var line_id := StringName(item.get("id", StringName()))
		var informational := bool(item.get("informational", false))
		row.set_meta("line_id", line_id)
		row.set_meta("informational", informational)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.text = "%s%s: %d" % [
			"INFO " if informational else "",
			String(line_id).to_upper().replace("_", " "),
			int(item.get("amount", 0)),
		]
		_line_rows.add_child(row)


func _on_continue_pressed() -> void:
	if _continue_consumed or _continue_button.disabled:
		return
	_continue_consumed = true
	_continue_button.disabled = true
	continue_requested.emit()


func _reason_text(reason: int) -> String:
	match reason:
		0:
			return "REGULAR TIME EXPIRED"
		1:
			return "TRACK END REACHED"
		2:
			return "DURABILITY DEPLETED"
	return "UNKNOWN"
