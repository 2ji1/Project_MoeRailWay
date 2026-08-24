class_name PrototypeBalance
extends Resource

const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionBalanceScript = preload("res://src/config/session_balance.gd")
const TrainBalanceScript = preload("res://src/config/train_balance.gd")
const TrackInventoryBalanceScript = preload("res://src/config/track_inventory_balance.gd")
const TrackConstructionBalanceScript = preload("res://src/config/track_construction_balance.gd")
const DepartureBalanceScript = preload("res://src/config/departure_balance.gd")

@export var session_balance: SessionBalanceScript = SessionBalanceScript.new()
@export var train_balance: TrainBalanceScript = TrainBalanceScript.new()
@export var track_inventory_balance: TrackInventoryBalanceScript = TrackInventoryBalanceScript.new()
@export var track_construction_balance: TrackConstructionBalanceScript = TrackConstructionBalanceScript.new()
@export var departure_balance: DepartureBalanceScript = DepartureBalanceScript.new()

var session_duration_seconds: float:
    get:
        return session_balance.session_duration_seconds
    set(value):
        session_balance.session_duration_seconds = value

var simulation_ticks_per_second: int:
    get:
        return session_balance.simulation_ticks_per_second
    set(value):
        session_balance.simulation_ticks_per_second = value


func create_session_start_config(seed_value: int) -> SessionStartConfigScript:
    return SessionStartConfigScript.new(
        seed_value,
        session_duration_seconds,
        simulation_ticks_per_second
    )


func complete_session_start_config(
    base_config: SessionStartConfigScript,
    logical_field_size: Vector2,
    candidate_id: StringName,
    departure_position: Vector2,
    grid_cell_size_value: float = 0.0,
    grid_size_value: Vector2i = Vector2i.ZERO,
    grid_origin_value: Vector2 = Vector2.ZERO,
    departure_cell_value: Vector2i = Vector2i(-1, -1)
) -> SessionStartConfigScript:
    return SessionStartConfigScript.new(
        base_config.seed,
        base_config.session_duration_seconds,
        base_config.simulation_ticks_per_second,
        train_balance.speed_cells_per_second,
        track_inventory_balance.total_track_cells,
        track_inventory_balance.recovery_lag_cells,
        track_inventory_balance.urgent_warning_seconds,
        track_construction_balance.build_cells_per_second,
        departure_balance.required_built_cells,
        logical_field_size,
        grid_size_value,
        grid_cell_size_value,
        grid_origin_value,
        candidate_id,
        departure_position,
        departure_cell_value
    )
