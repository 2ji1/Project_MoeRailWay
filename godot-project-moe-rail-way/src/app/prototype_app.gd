extends Node

const ValidatorScript = preload("res://src/config/prototype_config_validator.gd")
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionInvestmentInputScript = preload("res://src/domain/session/session_investment_input.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")
const WarpPairSystemScript = preload("res://src/domain/warp/warp_pair_system.gd")
const CargoSystemScript = preload("res://src/domain/cargo/cargo_system.gd")
const HazardSystemScript = preload("res://src/domain/hazard/hazard_system.gd")
const SessionEconomyScript = preload("res://src/domain/economy/session_economy.gd")
const ContractSystemScript = preload("res://src/domain/contract/contract_system.gd")
const RunStateScript = preload("res://src/domain/run/run_state.gd")
const PrototypeRunControllerScript = preload("res://src/domain/run/prototype_run_controller.gd")
const CycleProgressionScript = preload("res://src/domain/run/cycle_progression.gd")
const SettlementResultScript = preload("res://src/domain/run/settlement_result.gd")
const OperationsScreenScript = preload("res://src/presentation/operations/operations_screen.gd")
const ContractResultPanelScript = preload("res://src/presentation/results/contract_result_panel.gd")
const SessionShellScript = preload("res://src/presentation/session/session_shell.gd")
const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")
const UILayoutValidatorScript = preload("res://src/presentation/layout/ui_layout_validator.gd")

signal session_result_presented(result: SessionResultScript)

@export var balance: PrototypeBalanceScript
@export var startup_seed := 1
@export var layout_profile: UILayoutProfileScript
@export var start_in_operations := false

var session_start_config: SessionStartConfigScript
var session_rng: SessionRngScript
var track_system: TrackSystemScript
var train_system: TrainSystemScript
var warp_pair_system: WarpPairSystemScript
var cargo_system: CargoSystemScript
var hazard_system: HazardSystemScript
var session_economy: SessionEconomyScript
var contract_system: ContractSystemScript
var run_state: RunStateScript
var run_controller: PrototypeRunControllerScript
var settlement_result: SettlementResultScript
var session_controller: SessionControllerScript

@onready var _session_shell: SessionShellScript = $SessionShell
@onready var _operations_screen: OperationsScreenScript = $OperationsScreen
@onready var _contract_result_panel: ContractResultPanelScript = $ContractResultPanel

var _session_result_was_presented := false
var _runs_as_project_main_scene := false


func _ready() -> void:
	set_physics_process(false)
	_runs_as_project_main_scene = get_tree().current_scene == self
	_operations_screen.company_selected.connect(_on_company_selected)
	_operations_screen.start_requested.connect(_on_start_requested)
	_contract_result_panel.continue_requested.connect(_on_continue_requested)
	var errors := compose_session_dependencies()
	if not errors.is_empty():
		for error_message in errors:
			push_error(error_message)
		if OS.is_debug_build():
			get_tree().quit(2)
		return

	if _starts_in_operations():
		_present_operations()
		return
	_activate_composed_session()


func compose_session_dependencies() -> PackedStringArray:
	session_start_config = null
	session_rng = null
	track_system = null
	train_system = null
	warp_pair_system = null
	cargo_system = null
	hazard_system = null
	session_economy = null
	contract_system = null
	run_state = null
	run_controller = null
	settlement_result = null
	session_controller = null
	_session_result_was_presented = false

	var errors := PackedStringArray()
	var shell = get_node_or_null("SessionShell") as SessionShellScript
	var track_field_view = null
	var logical_track_field = null
	if shell == null:
		errors.append("prototype_app.SessionShell must exist")
	else:
		track_field_view = shell.get_track_field_view()
		if track_field_view == null:
			errors.append("session_shell.TrackFieldView must exist")
		else:
			logical_track_field = track_field_view.get_logical_track_field()
			if logical_track_field == null:
				errors.append("track_field_view.LogicalTrackField must exist")
	errors.append_array(ValidatorScript.validate(balance))
	errors.append_array(UILayoutValidatorScript.validate(layout_profile))
	if logical_track_field != null:
		for field_error in logical_track_field.validate_configuration():
			errors.append("logical_track_field." + field_error)
	if not errors.is_empty():
		return errors

	var base_config = balance.create_session_start_config(startup_seed)
	var records: Array[Dictionary] = logical_track_field.get_sorted_candidate_records()
	var departure_rng := SessionRngScript.new(base_config.seed)
	var selected_index := departure_rng.peek_index(records.size())
	if selected_index < 0:
		errors.append("logical_track_field.DepartureCandidates must select one candidate")
		session_rng = null
		return errors
	var selected_record: Dictionary = records[selected_index]
	var selected_cell: Vector2i = logical_track_field.logical_to_grid_cell(
		selected_record.position
	)
	if selected_cell == Vector2i(-1, -1):
		var grid_size: Vector2i = logical_track_field.get_grid_size()
		var grid_rect: Rect2 = logical_track_field.get_grid_rect()
		var cell_size: float = logical_track_field.get_grid_cell_size_units()
		var local_position: Vector2 = selected_record.position - grid_rect.position
		selected_cell = Vector2i(
			clampi(int(floor(local_position.x / cell_size)), 0, grid_size.x - 1),
			clampi(int(floor(local_position.y / cell_size)), 0, grid_size.y - 1)
		)
	var selected_position: Vector2 = logical_track_field.grid_cell_center(selected_cell)
	session_start_config = balance.complete_session_start_config(
		base_config,
		logical_track_field.get_logical_size(),
		selected_record.candidate_id,
		selected_position,
		logical_track_field.get_grid_cell_size_units(),
		logical_track_field.get_grid_size(),
		logical_track_field.get_grid_rect().position,
		selected_cell
	)
	var selected_company = balance.contract_economy_balance.companies[0]
	session_start_config.selected_contract = {
		"company_id": selected_company.company_id,
		"quota": selected_company.quota,
		"maximum_shortfall_penalty": selected_company.maximum_shortfall_penalty,
		"completion_bonus_at_quota": selected_company.completion_bonus_at_quota,
		"trust_per_excess_delivery_milli": selected_company.trust_per_excess_delivery_milli,
	}
	var company_ids: Array[StringName] = []
	for company in balance.contract_economy_balance.companies:
		company_ids.append(company.company_id)
	run_state = RunStateScript.new(
		balance.contract_economy_balance.initial_run_cash,
		company_ids,
		{},
		0,
		balance.credit_survival_balance.get_rate_table(company_ids)
	)
	run_controller = PrototypeRunControllerScript.new(
		run_state,
		balance.contract_economy_balance.base_operating_cost,
		balance.credit_survival_balance,
		CycleProgressionScript.new(balance.hazard_growth_interval_cycles, balance.hazard_cells_per_step, balance.damage_per_cell_per_cycle, balance.maximum_damage_per_cell)
	)
	if not _starts_in_operations():
		assert(
			run_controller.try_select_contract(session_start_config.selected_contract),
			"Default prototype contract must select"
		)
	session_start_config.starting_session_cash = run_state.get_cash()
	errors.append_array(ValidatorScript.validate_completed_session_start_config(session_start_config))
	if not errors.is_empty():
		return errors
	if _starts_in_operations():
		return errors
	errors.append_array(_compose_transient_session())
	return errors


func _compose_transient_session() -> PackedStringArray:
	var errors := PackedStringArray()
	var selected_contract := run_controller.get_selected_contract()
	if selected_contract.is_empty():
		errors.append("prototype_run_controller requires one selected contract")
		return errors
	session_start_config.selected_contract = selected_contract
	session_start_config.starting_session_cash = run_state.get_cash()
	var eligible_cells := session_start_config.grid_size.x * session_start_config.grid_size.y - 1
	var difficulty := run_controller.get_cycle_difficulty(balance.hazard_generation_balance.hazard_cell_count, eligible_cells, balance.durability_balance.damage_per_traveled_cell)
	if difficulty.is_empty():
		errors.append("prototype_run_controller requires one valid cycle difficulty")
		return errors
	session_start_config.hazard_cell_count = int(difficulty["hazard_cell_count"])
	session_start_config.damage_per_traveled_cell = float(difficulty["damage_per_traveled_cell"])
	errors.append_array(ValidatorScript.validate_completed_session_start_config(session_start_config))
	if not errors.is_empty():
		return errors
	session_rng = SessionRngScript.new(session_start_config.seed)
	track_system = TrackSystemScript.new(session_start_config)
	train_system = TrainSystemScript.new(
		session_start_config.train_speed_cells_per_second,
		session_start_config.maximum_durability
	)
	hazard_system = HazardSystemScript.new(session_start_config)
	session_economy = run_controller.try_start_session()
	if session_economy == null:
		errors.append("prototype_run_controller must start from nonnegative RunState cash")
		return errors
	contract_system = ContractSystemScript.new(session_start_config.selected_contract)
	warp_pair_system = WarpPairSystemScript.new(session_start_config, session_rng)
	cargo_system = CargoSystemScript.new(session_start_config.cargo_base_slot_count)
	session_controller = SessionControllerScript.new(
		session_start_config,
		track_system,
		train_system,
		warp_pair_system,
		cargo_system,
		hazard_system,
		session_economy,
		contract_system
	)
	return errors


func _activate_composed_session() -> void:
	Engine.physics_ticks_per_second = session_start_config.simulation_ticks_per_second
	session_controller.snapshot_published.connect(_on_snapshot_published)
	session_controller.session_completed.connect(_on_session_completed)
	_session_shell.reset_for_session()
	_session_shell.configure(layout_profile, session_controller.get_snapshot(), session_start_config)
	_operations_screen.hide()
	_contract_result_panel.hide()
	_session_shell.show()
	_session_result_was_presented = false
	settlement_result = null
	session_controller.start()
	set_physics_process(true)
	print(
		"Moe Rail Way session shell ready | duration=%d ticks=%d"
		% [int(session_start_config.session_duration_seconds), session_start_config.simulation_ticks_per_second]
	)


func _physics_process(_delta: float) -> void:
	if session_controller == null:
		return
	if session_controller.get_state() not in [
		SessionControllerScript.State.PREPARING_DEPARTURE,
		SessionControllerScript.State.RUNNING,
	]:
		return
	var input_frame = _session_shell.consume_track_input_frame()
	var investment_input = _session_shell.consume_investment_input()
	session_controller.advance_tick(input_frame, investment_input)


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
	settlement_result = run_controller.try_settle_session(result)
	if settlement_result == null:
		push_error("Prototype run settlement must accept the completed session result")
		return
	present_session_result(result)
	_contract_result_panel.present(settlement_result)


func _on_company_selected(company_id: StringName) -> void:
	var contract := _contract_for_company(company_id)
	if contract.is_empty() or not run_controller.try_select_contract(contract):
		return
	_present_operations()


func _on_start_requested() -> void:
	if not run_controller.can_start_session():
		_present_operations()
		return
	var errors := _compose_transient_session()
	if not errors.is_empty():
		for error_message in errors:
			push_error(error_message)
		return
	_activate_composed_session()


func _on_continue_requested() -> void:
	if not run_controller.try_continue_to_operations():
		return
	if run_controller.get_phase() == PrototypeRunControllerScript.Phase.TERMINAL:
		_present_terminal()
		return
	_present_operations()


func _present_terminal() -> void:
	set_physics_process(false)
	_session_shell.hide()
	_operations_screen.hide()
	_contract_result_panel.show()
	print("Credit Survival terminal reason=%d" % run_controller.get_terminal_result().get_reason())


func _present_operations() -> void:
	set_physics_process(false)
	_session_shell.set_contract_presentation_enabled(true)
	_session_shell.hide()
	_contract_result_panel.hide()
	_operations_screen.show()
	_operations_screen.present(
		balance.contract_economy_balance.companies,
		run_controller.get_run_state_observation(),
		StringName(run_controller.get_selected_contract().get("company_id", StringName()))
	)


func _contract_for_company(company_id: StringName) -> Dictionary:
	for company in balance.contract_economy_balance.companies:
		if company.company_id == company_id:
			return {
				"company_id": company.company_id,
				"quota": company.quota,
				"maximum_shortfall_penalty": company.maximum_shortfall_penalty,
				"completion_bonus_at_quota": company.completion_bonus_at_quota,
				"trust_per_excess_delivery_milli": company.trust_per_excess_delivery_milli,
			}
	return {}


func _starts_in_operations() -> bool:
	return start_in_operations or _runs_as_project_main_scene
