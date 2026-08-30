class_name SessionSnapshot
extends RefCounted

const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")
const CargoSlotRecordScript = preload("res://src/domain/cargo/cargo_slot_record.gd")

var _total_ticks: int
var _elapsed_ticks: int
var _remaining_ticks: int
var _ticks_per_second: int
var _has_track_train_data: bool
var _state: int
var _cell_records: Array[TrackCellRecordScript] = []
var _geometry_pieces: Array[TrackGeometryPieceScript] = []
var _contact_observations: Array[Dictionary] = []
var _built_end_distance_cells: float
var _available_track_cells: int
var _total_track_cells: int
var _grid_origin_units: Vector2
var _departure_built_cells: int
var _departure_required_cells: int
var _built_distance_ahead_cells: float
var _train_active: bool
var _train_route_distance_cells: float
var _train_position: Vector2
var _train_heading: Vector2
var _estimated_track_end_seconds: float
var _track_end_warning_urgent: bool
var _selected_departure_candidate_id: StringName
var _departure_cell: Vector2i
var _endpoint_gesture_eligible: bool
var _endpoint_gesture_active: bool
var _warp_pair_records: Array[WarpPairRecordScript] = []
var _cargo_slot_records: Array[CargoSlotRecordScript] = []
var _occupied_cargo_slots: int
var _total_cargo_slots: int
var _delivered_pair_count: int
var _base_delivery_reward_total: int
var _warp_cargo_events: Array[Dictionary] = []
var _planning_slowdown_active: bool
var _planning_time_scale_percent: int
var _did_advance_simulation_tick: bool
var _hazard_cells: Array[Vector2i] = []
var _maximum_durability: float
var _current_durability: float
var _repair_cost_basis: int
var _starting_session_cash: int
var _current_session_cash: int
var _total_session_cash_spent: int
var _pending_crossing_count: int
var _pending_crossing_total_cost: int
var _pending_crossing_affordable: bool
var _temporary_track_purchase_count: int
var _maximum_temporary_track_purchases: int
var _temporary_track_purchase_cost: int
var _temporary_track_cells_per_purchase: int
var _temporary_track_purchase_available: bool
var _temporary_track_purchase_affordable: bool
var _temporary_cargo_purchase_count: int
var _maximum_temporary_cargo_purchases: int
var _temporary_cargo_purchase_cost: int
var _temporary_cargo_slots_per_purchase: int
var _temporary_cargo_purchase_available: bool
var _temporary_cargo_purchase_affordable: bool
var _paid_demolition_count: int
var _paid_demolition_spent: int
var _grade_separated_crossing_count: int
var _grade_separated_crossing_spent: int
var _temporary_track_purchase_spent: int
var _temporary_cargo_purchase_spent: int


func _init(
	total_ticks_value: int,
	elapsed_ticks_value: int,
	remaining_ticks_value: int,
	ticks_per_second_value: int,
	has_track_train_data_value: bool = false,
	state_value: int = 0,
	cell_records_value: Array[TrackCellRecordScript] = [],
	geometry_pieces_value: Array[TrackGeometryPieceScript] = [],
	contact_observations_value: Array[Dictionary] = [],
	built_end_distance_cells_value: float = 0.0,
	available_track_cells_value: int = 0,
	total_track_cells_value: int = 0,
	grid_origin_units_value: Vector2 = Vector2.ZERO,
	departure_built_cells_value: int = 0,
	departure_required_cells_value: int = 0,
	built_distance_ahead_cells_value: float = 0.0,
	train_active_value: bool = false,
	train_route_distance_cells_value: float = 0.0,
	train_position_value: Vector2 = Vector2.ZERO,
	train_heading_value: Vector2 = Vector2.RIGHT,
	estimated_track_end_seconds_value: float = 0.0,
	track_end_warning_urgent_value: bool = false,
	selected_departure_candidate_id_value: StringName = StringName(),
	departure_cell_value: Vector2i = Vector2i(-1, -1),
	endpoint_gesture_eligible_value: bool = false,
	endpoint_gesture_active_value: bool = false,
	warp_pair_records_value: Array[WarpPairRecordScript] = [],
	cargo_slot_records_value: Array[CargoSlotRecordScript] = [],
	occupied_cargo_slots_value: int = 0,
	total_cargo_slots_value: int = 0,
	delivered_pair_count_value: int = 0,
	base_delivery_reward_total_value: int = 0,
	warp_cargo_events_value: Array[Dictionary] = [],
	planning_slowdown_active_value: bool = false,
	planning_time_scale_percent_value: int = 100,
	did_advance_simulation_tick_value: bool = true,
	hazard_cells_value: Array[Vector2i] = [],
	maximum_durability_value: float = 0.0,
	current_durability_value: float = 0.0,
	repair_cost_basis_value: int = 0,
	starting_session_cash_value: int = 0,
	current_session_cash_value: int = 0,
	total_session_cash_spent_value: int = 0,
	pending_crossing_count_value: int = 0,
	pending_crossing_total_cost_value: int = 0,
	pending_crossing_affordable_value: bool = true,
	temporary_track_purchase_count_value: int = 0,
	maximum_temporary_track_purchases_value: int = 0,
	temporary_track_purchase_cost_value: int = 0,
	temporary_track_cells_per_purchase_value: int = 0,
	temporary_track_purchase_available_value: bool = false,
	temporary_track_purchase_affordable_value: bool = false,
	temporary_cargo_purchase_count_value: int = 0,
	maximum_temporary_cargo_purchases_value: int = 0,
	temporary_cargo_purchase_cost_value: int = 0,
	temporary_cargo_slots_per_purchase_value: int = 0,
	temporary_cargo_purchase_available_value: bool = false,
	temporary_cargo_purchase_affordable_value: bool = false,
	paid_demolition_count_value: int = 0,
	paid_demolition_spent_value: int = 0,
	grade_separated_crossing_count_value: int = 0,
	grade_separated_crossing_spent_value: int = 0,
	temporary_track_purchase_spent_value: int = 0,
	temporary_cargo_purchase_spent_value: int = 0
) -> void:
	_total_ticks = total_ticks_value
	_elapsed_ticks = elapsed_ticks_value
	_remaining_ticks = remaining_ticks_value
	_ticks_per_second = ticks_per_second_value
	_has_track_train_data = has_track_train_data_value
	_state = state_value
	_cell_records = _duplicate_records(cell_records_value)
	_geometry_pieces = _duplicate_pieces(geometry_pieces_value)
	_contact_observations = contact_observations_value.duplicate(true)
	_built_end_distance_cells = built_end_distance_cells_value
	_available_track_cells = available_track_cells_value
	_total_track_cells = total_track_cells_value
	_grid_origin_units = Vector2(grid_origin_units_value)
	_departure_built_cells = departure_built_cells_value
	_departure_required_cells = departure_required_cells_value
	_built_distance_ahead_cells = built_distance_ahead_cells_value
	_train_active = train_active_value
	_train_route_distance_cells = train_route_distance_cells_value
	_train_position = Vector2(train_position_value)
	_train_heading = Vector2(train_heading_value)
	_estimated_track_end_seconds = estimated_track_end_seconds_value
	_track_end_warning_urgent = track_end_warning_urgent_value
	_selected_departure_candidate_id = StringName(selected_departure_candidate_id_value)
	_departure_cell = Vector2i(departure_cell_value)
	_endpoint_gesture_eligible = endpoint_gesture_eligible_value
	_endpoint_gesture_active = endpoint_gesture_active_value
	_warp_pair_records = _duplicate_warp_pairs(warp_pair_records_value)
	_cargo_slot_records = _duplicate_cargo_slots(cargo_slot_records_value)
	_occupied_cargo_slots = occupied_cargo_slots_value
	_total_cargo_slots = total_cargo_slots_value
	_delivered_pair_count = delivered_pair_count_value
	_base_delivery_reward_total = base_delivery_reward_total_value
	_warp_cargo_events = warp_cargo_events_value.duplicate(true)
	_planning_slowdown_active = planning_slowdown_active_value
	_planning_time_scale_percent = planning_time_scale_percent_value
	_did_advance_simulation_tick = did_advance_simulation_tick_value
	_hazard_cells = hazard_cells_value.duplicate()
	_maximum_durability = maximum_durability_value
	_current_durability = current_durability_value
	_repair_cost_basis = repair_cost_basis_value
	_starting_session_cash = starting_session_cash_value
	_current_session_cash = current_session_cash_value
	_total_session_cash_spent = total_session_cash_spent_value
	_pending_crossing_count = pending_crossing_count_value
	_pending_crossing_total_cost = pending_crossing_total_cost_value
	_pending_crossing_affordable = pending_crossing_affordable_value
	_temporary_track_purchase_count = temporary_track_purchase_count_value
	_maximum_temporary_track_purchases = maximum_temporary_track_purchases_value
	_temporary_track_purchase_cost = temporary_track_purchase_cost_value
	_temporary_track_cells_per_purchase = temporary_track_cells_per_purchase_value
	_temporary_track_purchase_available = temporary_track_purchase_available_value
	_temporary_track_purchase_affordable = temporary_track_purchase_affordable_value
	_temporary_cargo_purchase_count = temporary_cargo_purchase_count_value
	_maximum_temporary_cargo_purchases = maximum_temporary_cargo_purchases_value
	_temporary_cargo_purchase_cost = temporary_cargo_purchase_cost_value
	_temporary_cargo_slots_per_purchase = temporary_cargo_slots_per_purchase_value
	_temporary_cargo_purchase_available = temporary_cargo_purchase_available_value
	_temporary_cargo_purchase_affordable = temporary_cargo_purchase_affordable_value
	_paid_demolition_count = paid_demolition_count_value
	_paid_demolition_spent = paid_demolition_spent_value
	_grade_separated_crossing_count = grade_separated_crossing_count_value
	_grade_separated_crossing_spent = grade_separated_crossing_spent_value
	_temporary_track_purchase_spent = temporary_track_purchase_spent_value
	_temporary_cargo_purchase_spent = temporary_cargo_purchase_spent_value


func get_total_ticks() -> int:
	return _total_ticks


func get_elapsed_ticks() -> int:
	return _elapsed_ticks


func get_remaining_ticks() -> int:
	return _remaining_ticks


func get_ticks_per_second() -> int:
	return _ticks_per_second


func get_display_seconds() -> int:
	if _remaining_ticks <= 0:
		return 0
	return int(ceil(float(_remaining_ticks) / float(_ticks_per_second)))


func has_track_train_data() -> bool:
	return _has_track_train_data


func get_state() -> int:
	return _state


func get_cell_records() -> Array[TrackCellRecordScript]:
	return _duplicate_records(_cell_records)


func get_geometry_pieces() -> Array[TrackGeometryPieceScript]:
	return _duplicate_pieces(_geometry_pieces)


func get_contact_observations() -> Array[Dictionary]:
	return _contact_observations.duplicate(true)


func get_built_end_distance_cells() -> float:
	return _built_end_distance_cells


func get_available_track_cells() -> int:
	return _available_track_cells


func get_total_track_cells() -> int:
	return _total_track_cells


func get_grid_origin_units() -> Vector2:
	return _grid_origin_units


func get_departure_built_cells() -> int:
	return _departure_built_cells


func get_departure_required_cells() -> int:
	return _departure_required_cells


func get_built_distance_ahead_cells() -> float:
	return _built_distance_ahead_cells


func is_train_active() -> bool:
	return _train_active


func get_train_route_distance_cells() -> float:
	return _train_route_distance_cells


func get_train_position() -> Vector2:
	return _train_position


func get_train_heading() -> Vector2:
	return _train_heading


func get_estimated_track_end_seconds() -> float:
	return _estimated_track_end_seconds


func is_track_end_warning_urgent() -> bool:
	return _track_end_warning_urgent


func get_selected_departure_candidate_id() -> StringName:
	return _selected_departure_candidate_id


func get_departure_cell() -> Vector2i:
	return _departure_cell


func is_endpoint_gesture_eligible() -> bool:
	return _endpoint_gesture_eligible


func is_endpoint_gesture_active() -> bool:
	return _endpoint_gesture_active


func get_warp_pair_records() -> Array[WarpPairRecordScript]:
	return _duplicate_warp_pairs(_warp_pair_records)


func get_cargo_slot_records() -> Array[CargoSlotRecordScript]:
	return _duplicate_cargo_slots(_cargo_slot_records)


func get_occupied_cargo_slots() -> int:
	return _occupied_cargo_slots


func get_total_cargo_slots() -> int:
	return _total_cargo_slots


func get_delivered_pair_count() -> int:
	return _delivered_pair_count


func get_base_delivery_reward_total() -> int:
	return _base_delivery_reward_total


func get_warp_cargo_events() -> Array[Dictionary]:
	return _warp_cargo_events.duplicate(true)


func is_planning_slowdown_active() -> bool:
	return _planning_slowdown_active


func get_planning_time_scale_percent() -> int:
	return _planning_time_scale_percent


func did_advance_simulation_tick() -> bool:
	return _did_advance_simulation_tick


func get_hazard_cells() -> Array[Vector2i]:
	return _hazard_cells.duplicate()


func get_maximum_durability() -> float:
	return _maximum_durability


func get_current_durability() -> float:
	return _current_durability


func get_repair_cost_basis() -> int:
	return _repair_cost_basis


func get_starting_session_cash() -> int:
	return _starting_session_cash


func get_current_session_cash() -> int:
	return _current_session_cash


func get_total_session_cash_spent() -> int:
	return _total_session_cash_spent


func get_pending_crossing_count() -> int:
	return _pending_crossing_count


func get_pending_crossing_total_cost() -> int:
	return _pending_crossing_total_cost


func is_pending_crossing_affordable() -> bool:
	return _pending_crossing_affordable


func get_temporary_track_purchase_count() -> int:
	return _temporary_track_purchase_count


func get_maximum_temporary_track_purchases() -> int:
	return _maximum_temporary_track_purchases


func get_temporary_track_purchase_cost() -> int:
	return _temporary_track_purchase_cost


func get_temporary_track_cells_per_purchase() -> int:
	return _temporary_track_cells_per_purchase


func is_temporary_track_purchase_available() -> bool:
	return _temporary_track_purchase_available


func is_temporary_track_purchase_affordable() -> bool:
	return _temporary_track_purchase_affordable


func get_temporary_cargo_purchase_count() -> int:
	return _temporary_cargo_purchase_count


func get_maximum_temporary_cargo_purchases() -> int:
	return _maximum_temporary_cargo_purchases


func get_temporary_cargo_purchase_cost() -> int:
	return _temporary_cargo_purchase_cost


func get_temporary_cargo_slots_per_purchase() -> int:
	return _temporary_cargo_slots_per_purchase


func is_temporary_cargo_purchase_available() -> bool:
	return _temporary_cargo_purchase_available


func is_temporary_cargo_purchase_affordable() -> bool:
	return _temporary_cargo_purchase_affordable


func get_paid_demolition_count() -> int:
	return _paid_demolition_count


func get_paid_demolition_spent() -> int:
	return _paid_demolition_spent


func get_grade_separated_crossing_count() -> int:
	return _grade_separated_crossing_count


func get_grade_separated_crossing_spent() -> int:
	return _grade_separated_crossing_spent


func get_temporary_track_purchase_spent() -> int:
	return _temporary_track_purchase_spent


func get_temporary_cargo_purchase_spent() -> int:
	return _temporary_cargo_purchase_spent


func _duplicate_records(source: Array[TrackCellRecordScript]) -> Array[TrackCellRecordScript]:
	var copies: Array[TrackCellRecordScript] = []
	for record in source:
		copies.append(record.duplicate_record())
	return copies


func _duplicate_pieces(source: Array[TrackGeometryPieceScript]) -> Array[TrackGeometryPieceScript]:
	var copies: Array[TrackGeometryPieceScript] = []
	for piece in source:
		copies.append(piece.duplicate_piece())
	return copies


func _duplicate_warp_pairs(
	source: Array[WarpPairRecordScript]
) -> Array[WarpPairRecordScript]:
	var copies: Array[WarpPairRecordScript] = []
	for record in source:
		copies.append(record.duplicate_record())
	return copies


func _duplicate_cargo_slots(
	source: Array[CargoSlotRecordScript]
) -> Array[CargoSlotRecordScript]:
	var copies: Array[CargoSlotRecordScript] = []
	for record in source:
		copies.append(record.duplicate_record())
	return copies
