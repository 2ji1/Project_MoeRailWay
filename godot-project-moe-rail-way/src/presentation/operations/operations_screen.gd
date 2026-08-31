class_name OperationsScreen
extends Control

signal company_selected(company_id: StringName)
signal start_requested

@onready var _status: Label = %RunStatus
@onready var _company_rows: VBoxContainer = %CompanyRows
@onready var _blocked_notice: Label = %BlockedNotice
@onready var _start_button: Button = %StartButton

var _companies: Array = []
var _run_observation: Dictionary = {}
var _selected_company_id := StringName()


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)


func present(companies: Array, run_observation: Dictionary, selected_company_id: StringName) -> void:
	_companies = companies.duplicate()
	_run_observation = run_observation.duplicate(true)
	_selected_company_id = selected_company_id
	_rebuild_company_rows()
	var cash := int(_run_observation.get("cash", 0))
	_status.text = "CASH %d | CYCLE %d" % [cash, int(_run_observation.get("completed_cycle_count", 0))]
	_blocked_notice.visible = cash < 0
	_blocked_notice.text = "CREDIT SURVIVAL REQUIRED" if cash < 0 else ""
	_start_button.disabled = _selected_company_id.is_empty() or cash < 0


func get_presentation_observation() -> Dictionary:
	var rows: Array[Dictionary] = []
	for child in _company_rows.get_children():
		if child is Button:
			rows.append({
				"company_id": StringName(child.get_meta("company_id", StringName())),
				"text": child.text,
				"selected": child.button_pressed,
				"mouse_filter": child.mouse_filter,
				"rect": child.get_global_rect(),
			})
	return {
		"visible": visible,
		"status_text": _status.text,
		"blocked_text": _blocked_notice.text,
		"rows": rows,
		"start_disabled": _start_button.disabled,
		"start_mouse_filter": _start_button.mouse_filter,
		"panel_rect": %Panel.get_global_rect(),
	}.duplicate(true)


func _rebuild_company_rows() -> void:
	var trust_by_company: Dictionary = _run_observation.get("company_trust_milli", {})
	if _company_rows.get_child_count() == _companies.size():
		for index in range(_companies.size()):
			var existing: Button = _company_rows.get_child(index)
			var existing_company = _companies[index]
			existing.button_pressed = existing_company.company_id == _selected_company_id
			existing.text = _row_text(existing_company, index, trust_by_company)
		return
	for child in _company_rows.get_children():
		child.free()
	for index in range(_companies.size()):
		var company = _companies[index]
		var company_id := StringName(company.company_id)
		var row := Button.new()
		row.set_meta("company_id", company_id)
		row.toggle_mode = true
		row.button_pressed = company_id == _selected_company_id
		row.text = _row_text(company, index, trust_by_company)
		row.pressed.connect(_on_company_pressed.bind(company_id))
		_company_rows.add_child(row)


func _row_text(company, index: int, trust_by_company: Dictionary) -> String:
	return "[%d] %s | TRUST %.3f | FEE %d | QUOTA %d | PENALTY %d | BONUS %d" % [
		index + 1,
		company.display_name,
		float(int(trust_by_company.get(String(company.company_id), 0))) / 1000.0,
		company.base_delivery_fee,
		company.quota,
		company.maximum_shortfall_penalty,
		company.completion_bonus_at_quota,
	]


func _on_company_pressed(company_id: StringName) -> void:
	company_selected.emit(company_id)


func _on_start_pressed() -> void:
	if _start_button.disabled:
		return
	start_requested.emit()
