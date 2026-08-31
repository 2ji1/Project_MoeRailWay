class_name OperationsScreen
extends Control

signal company_selected(company_id: StringName)
signal start_requested
signal borrow_requested(company_id: StringName, amount: int)
signal decline_recovery_requested

@onready var _status: Label = %RunStatus
@onready var _recovery_status: Label = %RecoveryStatus
@onready var _company_rows: VBoxContainer = %CompanyRows
@onready var _blocked_notice: Label = %BlockedNotice
@onready var _start_button: Button = %StartButton
@onready var _schedule: Label = %CreditSchedule
@onready var _costs: Label = %ProjectedCosts
@onready var _borrow_amount: Label = %BorrowAmount
@onready var _borrow_button: Button = %BorrowButton
@onready var _decline_button: Button = %DeclineButton

var _companies: Array = []
var _run_observation: Dictionary = {}
var _selected_company_id := StringName()
var _borrow_value := 1


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	%MinusTen.pressed.connect(_adjust_borrow.bind(-10))
	%MinusOne.pressed.connect(_adjust_borrow.bind(-1))
	%PlusOne.pressed.connect(_adjust_borrow.bind(1))
	%PlusTen.pressed.connect(_adjust_borrow.bind(10))
	%Maximum.pressed.connect(_set_maximum_borrow)
	_borrow_button.pressed.connect(_on_borrow_pressed)
	_decline_button.pressed.connect(_on_decline_pressed)


func present(companies: Array, run_observation: Dictionary, selected_company_id: StringName) -> void:
	_companies = companies.duplicate()
	_run_observation = run_observation.duplicate(true)
	_selected_company_id = selected_company_id
	_borrow_value = maxi(_borrow_value, 1)
	_rebuild_company_rows()
	var cash := int(_run_observation.get("cash", 0))
	var recovery_mode := bool(_run_observation.get("recovery_mode", false))
	var cycle := int(_run_observation.get("selected_cycle", 0))
	if cycle <= 0: cycle = int(_run_observation.get("pending_cycle", 0))
	if cycle <= 0: cycle = int(_run_observation.get("completed_cycle_count", 0))
	_status.text = "CASH %d | CYCLE %d" % [cash, cycle]
	_recovery_status.text = "RECOVERY ACTIVE" if recovery_mode else "OPERATIONS READY"
	_blocked_notice.visible = cash < 0
	_blocked_notice.text = "CREDIT SURVIVAL REQUIRED" if cash < 0 else ""
	_start_button.disabled = not bool(_run_observation.get("contract_selected", not _selected_company_id.is_empty())) or cash < 0
	_decline_button.visible = recovery_mode and cash < 0
	_costs.text = "PROJECTED: OPERATING %d | DEBT %d + %d | REPAIR UNKNOWN" % [
		int(_run_observation.get("projected_operating_cost", 0)),
		int(_run_observation.get("projected_debt_principal", 0)),
		int(_run_observation.get("projected_debt_interest", 0)),
	]
	_refresh_credit_controls()


func set_credit_observation(run_observation: Dictionary) -> void:
	present(_companies, run_observation, _selected_company_id)


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
		"recovery_text": _recovery_status.text,
		"blocked_text": _blocked_notice.text,
		"rows": rows,
		"start_disabled": _start_button.disabled,
		"start_mouse_filter": _start_button.mouse_filter,
		"schedule_text": _schedule.text,
		"cost_text": _costs.text,
		"borrow_amount": _borrow_value,
		"borrow_disabled": _borrow_button.disabled,
		"borrow_disabled_reason": String(_borrow_button.tooltip_text),
		"decline_visible": _decline_button.visible,
		"borrow_mouse_filter": _borrow_button.mouse_filter,
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
	var credit := _credit_for(StringName(company.company_id))
	var threshold := "CAP" if int(credit.get("next_limit_trust_milli", -1)) < 0 else "NEXT %.3f" % (float(int(credit.get("next_limit_trust_milli", 0))) / 1000.0)
	return "[%d] %s | TRUST %.3f %s | LIMIT %d PRINCIPAL %d LEFT %d | RATE %.2f%% NEXT %d+%d | FEE %d Q%d PEN %d BONUS %d" % [
		index + 1,
		company.display_name,
		float(int(trust_by_company.get(String(company.company_id), 0))) / 1000.0,
		threshold,
		int(credit.get("credit_limit", 0)),
		int(credit.get("outstanding_principal", 0)),
		int(credit.get("remaining_credit", 0)),
		float(int(credit.get("rate_basis_points", 0))) / 100.0,
		int(credit.get("next_principal", 0)),
		int(credit.get("next_interest", 0)),
		company.base_delivery_fee,
		company.quota,
		company.maximum_shortfall_penalty,
		company.completion_bonus_at_quota,
	]


func _credit_for(company_id: StringName) -> Dictionary:
	for entry in _run_observation.get("company_credit", []):
		if StringName(entry.get("company_id", StringName())) == company_id:
			return entry
	return {}


func _refresh_credit_controls() -> void:
	var credit := _credit_for(_selected_company_id)
	var remaining := int(credit.get("remaining_credit", 0))
	var capacity := int(credit.get("borrow_capacity", remaining))
	var disabled_reason := String(credit.get("borrow_disabled_reason", ""))
	if capacity > 0:
		_borrow_value = clampi(_borrow_value, 1, capacity)
	else:
		_borrow_value = 0
	_borrow_amount.text = "BORROW %d" % _borrow_value
	_borrow_button.disabled = _selected_company_id.is_empty() or capacity <= 0 or _borrow_value <= 0
	_borrow_button.tooltip_text = "SELECT A COMPANY" if _selected_company_id.is_empty() else disabled_reason
	var schedule: Array = credit.get("schedule", [])
	var parts: PackedStringArray = []
	for item in schedule:
		parts.append("#%d P%d I%d -> %d" % [int(item.get("loan_id", 0)), int(item.get("principal", 0)), int(item.get("interest", 0)), int(item.get("post_principal", 0))])
	_schedule.text = "SELECTED SCHEDULE: NONE" if parts.is_empty() else "SELECTED SCHEDULE: " + " | ".join(parts)


func _adjust_borrow(delta: int) -> void:
	var credit := _credit_for(_selected_company_id)
	var capacity := int(credit.get("borrow_capacity", credit.get("remaining_credit", 0)))
	if capacity <= 0: return
	_borrow_value = clampi(_borrow_value + delta, 1, capacity)
	_refresh_credit_controls()


func _set_maximum_borrow() -> void:
	var credit := _credit_for(_selected_company_id)
	var capacity := int(credit.get("borrow_capacity", credit.get("remaining_credit", 0)))
	if capacity <= 0: return
	_borrow_value = capacity
	_refresh_credit_controls()


func _on_borrow_pressed() -> void:
	if _borrow_button.disabled: return
	borrow_requested.emit(_selected_company_id, _borrow_value)


func _on_decline_pressed() -> void:
	if not _decline_button.visible: return
	decline_recovery_requested.emit()


func _on_company_pressed(company_id: StringName) -> void:
	company_selected.emit(company_id)


func _on_start_pressed() -> void:
	if _start_button.disabled:
		return
	start_requested.emit()
