class_name WarpPairSystem
extends RefCounted

const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const WarpPairRecordScript = preload("res://src/domain/warp/warp_pair_record.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const CargoSystemScript = preload("res://src/domain/cargo/cargo_system.gd")

var _grid_size: Vector2i
var _forecast_ticks: int
var _generation_interval_ticks: int
var _lifetime_min_ticks: int
var _lifetime_max_ticks: int
var _max_live_pairs: int
var _session_rng: SessionRngScript
var _records: Array[WarpPairRecordScript] = []
var _tick_events: Array[Dictionary] = []
var _last_begin_tick := 0
var _last_expire_tick := 0
var _last_contact_tick := 0
var _last_generation_tick := 0
var _next_ordinal := 1
var _generation_pending := false
var _terminal := false


func _init(
    start_config: SessionStartConfigScript,
    session_rng: SessionRngScript
) -> void:
    _grid_size = start_config.grid_size
    _forecast_ticks = start_config.warp_forecast_ticks
    _generation_interval_ticks = start_config.warp_generation_interval_ticks
    _lifetime_min_ticks = start_config.warp_lifetime_min_ticks
    _lifetime_max_ticks = start_config.warp_lifetime_max_ticks
    _max_live_pairs = start_config.warp_max_live_pairs
    _session_rng = session_rng


static func cell_from_row_major_index(index: int, grid_size: Vector2i) -> Vector2i:
    if grid_size.x <= 0 or grid_size.y <= 0:
        return Vector2i(-1, -1)
    var cell_count := grid_size.x * grid_size.y
    if index < 0 or index >= cell_count:
        return Vector2i(-1, -1)
    return Vector2i(index % grid_size.x, index / grid_size.x)


func begin_running_tick(tick_index: int) -> void:
    if _terminal or tick_index <= _last_begin_tick:
        return
    _last_begin_tick = tick_index
    _tick_events.clear()

    for record in _records:
        if record.state != WarpPairRecordScript.State.FORECAST:
            continue
        if record.forecast_remaining_ticks > 0:
            record.forecast_remaining_ticks -= 1
        if record.forecast_remaining_ticks == 0:
            _activate(record, tick_index)

    var generation_due := (
        _last_generation_tick == 0
        or _generation_pending
        or tick_index - _last_generation_tick >= _generation_interval_ticks
    )
    if not generation_due:
        return
    if _get_live_pair_count() >= _max_live_pairs:
        _generation_pending = true
        return
    _generate_pair(tick_index)


func resolve_contact_hits(
    tick_index: int,
    hits: Array[Dictionary],
    cargo_system: CargoSystemScript
) -> void:
    if _terminal or cargo_system == null or tick_index <= _last_contact_tick:
        return
    _last_contact_tick = tick_index
    var ordered_hits: Array[Dictionary] = []
    var seen_anchor_ids := {}
    for hit in hits:
        var candidate := _contact_candidate(hit)
        if candidate.is_empty():
            continue
        var anchor_id: StringName = candidate["anchor_id"]
        if seen_anchor_ids.has(anchor_id):
            continue
        seen_anchor_ids[anchor_id] = true
        ordered_hits.append(candidate)
    ordered_hits.sort_custom(_contact_less)

    for hit in ordered_hits:
        var record: WarpPairRecordScript = hit["record"]
        var endpoint: StringName = hit["endpoint"]
        if endpoint == &"origin":
            if record.state != WarpPairRecordScript.State.ACTIVE_UNLOADED:
                continue
            var loaded_slot := cargo_system.try_load(record.pair_id, record.style_index)
            if loaded_slot < 0:
                continue
            record.state = WarpPairRecordScript.State.IN_TRANSIT
            _append_event(tick_index, &"LOADED", record.pair_id, loaded_slot)
        elif endpoint == &"destination":
            if record.state != WarpPairRecordScript.State.IN_TRANSIT:
                continue
            var delivery: Dictionary = cargo_system.try_deliver(record.pair_id)
            if not delivery["delivered"]:
                continue
            record.state = WarpPairRecordScript.State.DELIVERED
            _append_event(
                tick_index,
                &"DELIVERED",
                record.pair_id,
                delivery["slot_index"],
                delivery["amount"]
            )


func expire_after_contact(tick_index: int, cargo_system: CargoSystemScript) -> void:
    if _terminal or tick_index <= _last_expire_tick:
        return
    _last_expire_tick = tick_index
    for record in _records:
        if (
            record.state != WarpPairRecordScript.State.ACTIVE_UNLOADED
            and record.state != WarpPairRecordScript.State.IN_TRANSIT
        ):
            continue
        if record.lifetime_remaining_ticks > 0:
            record.lifetime_remaining_ticks -= 1
        if record.lifetime_remaining_ticks == 0:
            var cleared_slot := -1
            if (
                record.state == WarpPairRecordScript.State.IN_TRANSIT
                and cargo_system != null
            ):
                cleared_slot = cargo_system.remove_pair(record.pair_id)
            record.state = WarpPairRecordScript.State.EXPIRED
            _append_event(tick_index, &"EXPIRED", record.pair_id, cleared_slot)


func void_nonterminal(tick_index: int, cargo_system: CargoSystemScript) -> void:
    if _terminal:
        return
    _terminal = true
    for record in _records:
        if not _is_live_state(record.state):
            continue
        var cleared_slot := -1
        if record.state == WarpPairRecordScript.State.IN_TRANSIT and cargo_system != null:
            cleared_slot = cargo_system.remove_pair(record.pair_id)
        record.state = WarpPairRecordScript.State.VOIDED
        _append_event(tick_index, &"VOIDED", record.pair_id, cleared_slot)
    if cargo_system != null:
        cargo_system.clear_all()


func get_route_contact_anchors() -> Array[RouteContactAnchorScript]:
    var anchors: Array[RouteContactAnchorScript] = []
    for record in _records:
        if record.state == WarpPairRecordScript.State.ACTIVE_UNLOADED:
            anchors.append(
                RouteContactAnchorScript.new(
                    StringName("%s/origin" % record.pair_id),
                    record.origin_cell
                )
            )
            anchors.append(
                RouteContactAnchorScript.new(
                    StringName("%s/destination" % record.pair_id),
                    record.destination_cell
                )
            )
        elif record.state == WarpPairRecordScript.State.IN_TRANSIT:
            anchors.append(
                RouteContactAnchorScript.new(
                    StringName("%s/destination" % record.pair_id),
                    record.destination_cell
                )
            )
    return anchors


func get_pair_records() -> Array[WarpPairRecordScript]:
    var copies: Array[WarpPairRecordScript] = []
    for record in _records:
        copies.append(record.duplicate_record())
    return copies


func get_tick_events() -> Array[Dictionary]:
    var copies: Array[Dictionary] = []
    for event in _tick_events:
        copies.append(event.duplicate(true))
    return copies


func _generate_pair(tick_index: int) -> void:
    var cell_count := _grid_size.x * _grid_size.y
    if cell_count <= 0 or _session_rng == null:
        return
    var lifetime_range := _lifetime_max_ticks - _lifetime_min_ticks + 1
    if lifetime_range <= 0:
        return

    var record := WarpPairRecordScript.new()
    record.ordinal = _next_ordinal
    record.pair_id = StringName("warp_pair_%d" % record.ordinal)
    record.origin_cell = cell_from_row_major_index(
        _session_rng.next_index(cell_count),
        _grid_size
    )
    record.destination_cell = cell_from_row_major_index(
        _session_rng.next_index(cell_count),
        _grid_size
    )
    record.lifetime_total_ticks = (
        _lifetime_min_ticks + _session_rng.next_index(lifetime_range)
    )
    record.lifetime_remaining_ticks = record.lifetime_total_ticks
    record.forecast_remaining_ticks = _forecast_ticks
    record.style_index = _get_lowest_unused_style()
    record.state = WarpPairRecordScript.State.FORECAST
    _records.append(record)
    _next_ordinal += 1
    _last_generation_tick = tick_index
    _generation_pending = false
    _append_event(tick_index, &"FORECASTED", record.pair_id)
    if record.forecast_remaining_ticks == 0:
        _activate(record, tick_index)


func _activate(record: WarpPairRecordScript, tick_index: int) -> void:
    if record.state != WarpPairRecordScript.State.FORECAST:
        return
    record.forecast_remaining_ticks = 0
    record.lifetime_remaining_ticks = record.lifetime_total_ticks
    record.state = WarpPairRecordScript.State.ACTIVE_UNLOADED
    _append_event(tick_index, &"ACTIVATED", record.pair_id)


func _append_event(
    tick_index: int,
    type: StringName,
    pair_id: StringName,
    slot_index: int = -1,
    amount: int = 0
) -> void:
    _tick_events.append({
        "tick": tick_index,
        "type": type,
        "pair_id": pair_id,
        "slot_index": slot_index,
        "amount": amount,
    })


func _contact_candidate(hit: Dictionary) -> Dictionary:
    if (
        not hit.has("anchor_id")
        or not hit.has("cell")
        or not hit.has("contact_distance_cells")
        or typeof(hit["anchor_id"]) != TYPE_STRING_NAME
        or typeof(hit["cell"]) != TYPE_VECTOR2I
        or (
            typeof(hit["contact_distance_cells"]) != TYPE_FLOAT
            and typeof(hit["contact_distance_cells"]) != TYPE_INT
        )
    ):
        return {}
    var distance := float(hit["contact_distance_cells"])
    if not is_finite(distance):
        return {}
    var anchor_id: StringName = hit["anchor_id"]
    var cell: Vector2i = hit["cell"]
    for record in _records:
        if not _is_live_state(record.state):
            continue
        var origin_id := StringName("%s/origin" % record.pair_id)
        if (
            anchor_id == origin_id
            and record.state == WarpPairRecordScript.State.ACTIVE_UNLOADED
            and cell == record.origin_cell
        ):
            return {
                "anchor_id": anchor_id,
                "cell": cell,
                "contact_distance_cells": distance,
                "endpoint": &"origin",
                "record": record,
            }
        var destination_id := StringName("%s/destination" % record.pair_id)
        if anchor_id == destination_id and cell == record.destination_cell:
            return {
                "anchor_id": anchor_id,
                "cell": cell,
                "contact_distance_cells": distance,
                "endpoint": &"destination",
                "record": record,
            }
    return {}


func _contact_less(first: Dictionary, second: Dictionary) -> bool:
    var first_distance: float = first["contact_distance_cells"]
    var second_distance: float = second["contact_distance_cells"]
    if first_distance != second_distance:
        return first_distance < second_distance
    var first_record: WarpPairRecordScript = first["record"]
    var second_record: WarpPairRecordScript = second["record"]
    if (
        first_record.ordinal == second_record.ordinal
        and first["endpoint"] != second["endpoint"]
    ):
        return first["endpoint"] == &"origin"
    if first_record.ordinal != second_record.ordinal:
        return first_record.ordinal < second_record.ordinal
    return String(first["anchor_id"]) < String(second["anchor_id"])


func _get_live_pair_count() -> int:
    var count := 0
    for record in _records:
        if _is_live_state(record.state):
            count += 1
    return count


func _get_lowest_unused_style() -> int:
    var used_styles := {}
    for record in _records:
        if _is_live_state(record.state):
            used_styles[record.style_index] = true
    for style_index in range(6):
        if not used_styles.has(style_index):
            return style_index
    return -1


func _is_live_state(state: int) -> bool:
    return (
        state == WarpPairRecordScript.State.FORECAST
        or state == WarpPairRecordScript.State.ACTIVE_UNLOADED
        or state == WarpPairRecordScript.State.IN_TRANSIT
    )
