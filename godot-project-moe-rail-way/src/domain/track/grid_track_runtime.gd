class_name GridTrackRuntime
extends RefCounted

const TrackCellSequenceScript = preload("res://src/domain/track/track_cell_sequence.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackGeometryResolverScript = preload("res://src/domain/track/track_geometry_resolver.gd")
const TrackGeometryResolutionScript = preload("res://src/domain/track/track_geometry_resolution.gd")

const NOMINAL_BOUNDARY_EPSILON := 0.0001
const CONTACT_SAMPLES_PER_CELL := 8
const EXACT_CONTACT_POSITION_EPSILON_UNITS := 0.0001

var _departure_cell: Vector2i
var _grid_origin_units: Vector2
var _grid_size: Vector2i
var _cell_size_units: float
var _sequence: TrackCellSequenceScript
var _resolver: TrackGeometryResolverScript = TrackGeometryResolverScript.new()
var _pieces: Array[TrackGeometryPieceScript] = []
var _locked_ledger: Array[TrackGeometryPieceScript] = []
var _anchors: Array[RouteContactAnchorScript] = []
var _contact_observations: Array[Dictionary] = []
var _recovered_cells_by_piece: Dictionary = {}
var _recovered_end_distance_cells := 0.0
var _gesture_active := false
var _gesture_origin_sequence: TrackCellSequenceScript
var _gesture_origin_pieces: Array[TrackGeometryPieceScript] = []
var _gesture_origin_locked_ledger: Array[TrackGeometryPieceScript] = []
var _gesture_origin_anchors: Array[RouteContactAnchorScript] = []
var _gesture_origin_recovered_cells_by_piece: Dictionary = {}
var _gesture_origin_recovered_end_distance_cells := 0.0
var _gesture_origin_contacts: Array[Dictionary] = []
var _gesture_editable_span: Dictionary = {}
var _gesture_target_endpoints: Dictionary = {}
var _gesture_selected_template_index := -1
var _gesture_suffix_input_facts: Array[Dictionary] = []
var _gesture_ordinary_input_facts: Array[Dictionary] = []
var _gesture_template_selection_signature_valid := false
var _gesture_template_selection_signature_path: Array[Vector2i] = []
var _gesture_template_selection_signature_pointer := Vector2i(-1, -1)
var _gesture_live_warp_latches: Array[Dictionary] = []
var _gesture_latched_suffix_input_facts: Array[Dictionary] = []
var _gesture_preexisting_nonendpoint_anchor_ids: Dictionary = {}
var _gesture_press_anchor_ids: Dictionary = {}
var _gesture_rejection_diagnostics_enabled := false
var _last_gesture_rejection: Dictionary = {}
var _last_stage_rejection_reason := StringName()


func _init(
    departure_cell: Vector2i,
    total_track_cells: int,
    grid_origin_units: Vector2,
    grid_size: Vector2i,
    cell_size_units: float
) -> void:
    _departure_cell = departure_cell
    _grid_origin_units = grid_origin_units
    _grid_size = grid_size
    _cell_size_units = cell_size_units
    _sequence = TrackCellSequenceScript.new(departure_cell, total_track_cells)


func gesture_is_active() -> bool:
    return _gesture_active


func get_last_gesture_rejection() -> Dictionary:
    return _last_gesture_rejection.duplicate(true)


func set_gesture_rejection_diagnostics_enabled(enabled: bool) -> void:
    _gesture_rejection_diagnostics_enabled = enabled
    if not enabled:
        _last_gesture_rejection.clear()


func gesture_has_legal_operation(endpoint: Vector2i = Vector2i(-1, -1)) -> bool:
    var requested_endpoint := get_endpoint_cell() if endpoint == Vector2i(-1, -1) else endpoint
    if requested_endpoint != get_endpoint_cell():
        return false
    if _gesture_active:
        return true
    var editable_span := _discover_editable_span()
    if _has_legal_template_alternative(editable_span):
        return true
    if _sequence.get_available_track_cells() <= 0:
        return false
    for offset in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
        var cell: Vector2i = requested_endpoint + offset
        if not _cell_in_grid(cell):
            continue
        var candidate_sequence = _sequence.duplicate_sequence()
        if candidate_sequence.try_append_candidate(cell) == null:
            continue
        var candidate_ledger = _duplicate_pieces(_locked_ledger)
        var candidate_anchors = _duplicate_anchors(_anchors)
        var resolution = _stage_stable_retirement(
            candidate_sequence,
            candidate_ledger,
            candidate_anchors,
            _recovered_cells_by_piece
        )
        if not resolution.is_valid:
            continue
        _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
        candidate_sequence.apply_resolved_geometry(resolution.pieces)
        if _validate_candidate(candidate_sequence, candidate_ledger, resolution):
            return true
    return false


func gesture_begin(endpoint: Vector2i) -> Dictionary:
    if _gesture_active or endpoint != get_endpoint_cell() or not gesture_has_legal_operation(endpoint):
        return {}
    _gesture_origin_sequence = _sequence.duplicate_sequence()
    _gesture_origin_pieces = _duplicate_pieces(_pieces)
    _gesture_origin_locked_ledger = _duplicate_pieces(_locked_ledger)
    _gesture_origin_anchors = _duplicate_anchors(_anchors)
    _gesture_origin_recovered_cells_by_piece = _recovered_cells_by_piece.duplicate(true)
    _gesture_origin_recovered_end_distance_cells = _recovered_end_distance_cells
    _gesture_origin_contacts = _contact_observations.duplicate(true)
    _gesture_editable_span = _discover_editable_span()
    _gesture_target_endpoints = _calculate_target_endpoints(_gesture_editable_span)
    _gesture_selected_template_index = _matching_template_index(_gesture_editable_span)
    _gesture_suffix_input_facts.clear()
    _gesture_ordinary_input_facts.clear()
    _gesture_template_selection_signature_valid = false
    _gesture_template_selection_signature_path.clear()
    _gesture_template_selection_signature_pointer = Vector2i(-1, -1)
    _gesture_live_warp_latches.clear()
    _gesture_latched_suffix_input_facts.clear()
    _gesture_preexisting_nonendpoint_anchor_ids.clear()
    _gesture_press_anchor_ids.clear()
    for anchor in _gesture_origin_anchors:
        _gesture_press_anchor_ids[anchor.anchor_id] = true
    _last_gesture_rejection.clear()
    _gesture_active = true
    _capture_press_endpoint_warp_latches()
    return _gesture_origin_observation()


func gesture_finalize() -> bool:
    if not _gesture_active:
        return false
    var candidate_sequence = _sequence.duplicate_sequence()
    var candidate_ledger = _duplicate_pieces(_locked_ledger)
    var candidate_anchors = _duplicate_anchors(_anchors)
    var resolution = _stage_stable_retirement(
        candidate_sequence,
        candidate_ledger,
        candidate_anchors,
        _recovered_cells_by_piece
    )
    if not resolution.is_valid or not _pieces_are_continuous(resolution.pieces):
        _clear_gesture_state()
        return false
    _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
    candidate_sequence.apply_resolved_geometry(resolution.pieces)
    if not _validate_candidate(
        candidate_sequence,
        candidate_ledger,
        resolution,
        _recovered_cells_by_piece,
        _recovered_end_distance_cells
    ):
        _clear_gesture_state()
        return false
    var candidate_contacts := _build_contact_observations(
        resolution.pieces,
        candidate_anchors,
        _recovered_cells_by_piece,
        candidate_sequence.get_records()
    )
    _commit_candidate(candidate_sequence, candidate_ledger, resolution)
    _contact_observations = candidate_contacts.duplicate(true)
    _clear_gesture_state()
    return true


func gesture_abort() -> bool:
    if not _gesture_active or _gesture_origin_sequence == null:
        return false
    _sequence.replace_with(_gesture_origin_sequence)
    _locked_ledger = _duplicate_pieces(_gesture_origin_locked_ledger)
    _pieces = _duplicate_pieces(_gesture_origin_pieces)
    _sequence.apply_resolved_geometry(_pieces)
    _anchors = _duplicate_anchors(_gesture_origin_anchors)
    _recovered_cells_by_piece = _gesture_origin_recovered_cells_by_piece.duplicate(true)
    _recovered_end_distance_cells = _gesture_origin_recovered_end_distance_cells
    _contact_observations = _gesture_origin_contacts.duplicate(true)
    _clear_gesture_state()
    return true


func gesture_update(
    live_path: Array[Vector2i],
    current_pointer_cell: Vector2i = Vector2i(-1, -1),
    allows_bounded_reentry_connection: bool = false
) -> bool:
    if not _gesture_active:
        return false
    if not _gesture_live_warp_latches.is_empty():
        return _gesture_update_from_live_warp_latch(
            live_path, current_pointer_cell, allows_bounded_reentry_connection
        )
    var frame_template_index := -1
    var frame_target_indices: Array[int] = [-1, -1, -1]
    for cell_index in range(live_path.size()):
        var cell: Vector2i = live_path[cell_index]
        for index in range([&"straight", &"left", &"right"].size()):
            var template_name: StringName = [&"straight", &"left", &"right"][index]
            if _gesture_target_endpoints.get(template_name, Vector2i(-1, -1)) == cell:
                frame_template_index = index
                frame_target_indices[index] = cell_index
    var templates := _template_cells(_gesture_editable_span)
    var previous_template_index := _gesture_selected_template_index
    var next_template_index := previous_template_index
    var next_suffix_input_facts: Array[Dictionary] = _gesture_suffix_input_facts.duplicate(true)
    var next_ordinary_input_facts: Array[Dictionary] = _gesture_ordinary_input_facts.duplicate(true)
    var current_ordinary_cells: Array[Vector2i] = []
    var current_suffix_cells: Array[Vector2i] = []
    var existing_suffix_input_facts: Array[Dictionary] = []
    var pointer_template_index := _template_index_from_pointer(current_pointer_cell, templates)
    if pointer_template_index >= 0:
        next_template_index = pointer_template_index
        next_ordinary_input_facts.clear()
    elif frame_template_index >= 0 and frame_template_index < templates.size():
        next_template_index = frame_template_index
        next_ordinary_input_facts.clear()
    elif _gesture_selected_template_index >= 0:
        next_ordinary_input_facts.clear()
    elif not _gesture_editable_span.is_empty() and not templates.is_empty():
        _record_gesture_rejection(
            &"template_selection", &"no_selected_template",
            live_path, current_pointer_cell, next_template_index
        )
        return false
    else:
        current_ordinary_cells = live_path.duplicate()

    var template_changed := next_template_index != previous_template_index
    if next_template_index >= 0:
        var selected_target_index := -1
        if next_template_index < frame_target_indices.size():
            selected_target_index = frame_target_indices[next_template_index]
        if selected_target_index >= 0:
            for index in range(selected_target_index + 1, live_path.size()):
                current_suffix_cells.append(live_path[index])
        elif (
            _gesture_origin_sequence != null
            and next_template_index == previous_template_index
            and next_template_index < [&"straight", &"left", &"right"].size()
            and _gesture_target_endpoints.get(
                [&"straight", &"left", &"right"][next_template_index],
                Vector2i(-1, -1)
            ) == _gesture_origin_sequence.get_endpoint_cell()
        ):
            var is_selection_replay := _gesture_template_selection_signature_valid \
                and _gesture_template_selection_signature_pointer == current_pointer_cell \
                and _gesture_template_selection_signature_path == live_path
            if not is_selection_replay:
                for cell in live_path:
                    current_suffix_cells.append(cell)
        if next_template_index == previous_template_index:
            existing_suffix_input_facts = _gesture_suffix_input_facts
        if template_changed:
            existing_suffix_input_facts = []
    var candidate_sequence = _gesture_origin_sequence.duplicate_sequence()
    if next_template_index >= 0:
        var template_cells: Array[Vector2i] = []
        for cell in templates[next_template_index]:
            template_cells.append(cell)
        if not _gesture_template_mutation_is_safe():
            _record_gesture_rejection(
                &"template_mutation", &"unsafe_template_mutation",
                live_path, current_pointer_cell, next_template_index,
                candidate_sequence
            )
            return false
        if not candidate_sequence.replace_span_in_place(
            _gesture_editable_span["first_route_serial"],
            _gesture_editable_span["last_route_serial"],
            template_cells
        ):
            _record_gesture_rejection(
                &"candidate_sequence", &"replace_span_rejected",
                live_path, current_pointer_cell, next_template_index,
                candidate_sequence
            )
            return false
        var expanded_suffix: Variant = _expand_bounded_reentry_path(
            candidate_sequence,
            current_suffix_cells,
            allows_bounded_reentry_connection
        )
        if expanded_suffix == null:
            _record_gesture_rejection(
                &"candidate_sequence", &"bounded_reentry_connection_rejected",
                live_path, current_pointer_cell, next_template_index,
                candidate_sequence
            )
            return false
        next_suffix_input_facts = _reconcile_gesture_input_facts(
            existing_suffix_input_facts,
            expanded_suffix
        )
        if not _append_gesture_input_facts(candidate_sequence, next_suffix_input_facts):
            _record_gesture_rejection(
                &"candidate_sequence", &"append_suffix_rejected",
                live_path, current_pointer_cell, next_template_index,
                candidate_sequence
            )
            return false
    else:
        var expanded_ordinary: Variant = _expand_bounded_reentry_path(
            candidate_sequence,
            current_ordinary_cells,
            allows_bounded_reentry_connection
        )
        if expanded_ordinary == null:
            _record_gesture_rejection(
                &"candidate_sequence", &"bounded_reentry_connection_rejected",
                live_path, current_pointer_cell, next_template_index,
                candidate_sequence
            )
            return false
        next_ordinary_input_facts = _reconcile_gesture_input_facts(
            _gesture_ordinary_input_facts,
            expanded_ordinary
        )
        if not _append_gesture_input_facts(candidate_sequence, next_ordinary_input_facts):
            _record_gesture_rejection(
                &"candidate_sequence", &"append_path_rejected",
                live_path, current_pointer_cell, next_template_index,
                candidate_sequence
            )
            return false
    var candidate_ledger = _duplicate_pieces(_gesture_origin_locked_ledger)
    var candidate_anchors = _duplicate_anchors(_gesture_origin_anchors)
    var resolution = _resolve_candidate(
        candidate_sequence,
        candidate_ledger,
        candidate_anchors,
        _gesture_origin_recovered_cells_by_piece
    )
    if not resolution.is_valid:
        _record_gesture_rejection(
            &"candidate_resolution", resolution.reason,
            live_path, current_pointer_cell, next_template_index,
            candidate_sequence, candidate_ledger, candidate_anchors
        )
        return false
    if not _pieces_are_continuous(resolution.pieces):
        _record_gesture_rejection(
            &"candidate_continuity", &"piece_discontinuity",
            live_path, current_pointer_cell, next_template_index,
            candidate_sequence, candidate_ledger, candidate_anchors
        )
        return false
    _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
    candidate_sequence.apply_resolved_geometry(resolution.pieces)
    if not _validate_candidate(candidate_sequence, candidate_ledger, resolution):
        _record_gesture_rejection(
            &"candidate_validation", &"candidate_invariant",
            live_path, current_pointer_cell, next_template_index,
            candidate_sequence, candidate_ledger, candidate_anchors
        )
        return false
    if not _gesture_candidate_can_finalize(candidate_sequence, candidate_ledger, candidate_anchors):
        var final_reason := _last_stage_rejection_reason
        if final_reason == StringName():
            final_reason = &"candidate_cannot_finalize"
        _record_gesture_rejection(
            &"candidate_finalization", final_reason,
            live_path, current_pointer_cell, next_template_index,
            candidate_sequence, candidate_ledger, candidate_anchors
        )
        return false
    var candidate_contacts := _build_contact_observations(
        resolution.pieces,
        candidate_anchors,
        _gesture_origin_recovered_cells_by_piece,
        candidate_sequence.get_records()
    )
    _commit_candidate(candidate_sequence, candidate_ledger, resolution)
    _advance_gesture_serial_watermark(candidate_sequence)
    _gesture_selected_template_index = next_template_index
    _gesture_suffix_input_facts = next_suffix_input_facts
    _gesture_ordinary_input_facts = next_ordinary_input_facts
    if template_changed:
        _gesture_template_selection_signature_valid = false
        _gesture_template_selection_signature_path.clear()
        _gesture_template_selection_signature_pointer = Vector2i(-1, -1)
        var selected_template_name := StringName()
        if next_template_index >= 0 and next_template_index < 3:
            selected_template_name = [&"straight", &"left", &"right"][next_template_index]
        var selected_target: Vector2i = Vector2i(
            _gesture_target_endpoints.get(selected_template_name, Vector2i(-1, -1))
        )
        var selected_target_in_frame := next_template_index >= 0 \
            and next_template_index < frame_target_indices.size() \
            and frame_target_indices[next_template_index] >= 0
        if (
            next_template_index >= 0
            and not selected_target_in_frame
            and _gesture_origin_sequence != null
            and selected_target == _gesture_origin_sequence.get_endpoint_cell()
        ):
            _gesture_template_selection_signature_valid = true
            _gesture_template_selection_signature_path = live_path.duplicate()
            _gesture_template_selection_signature_pointer = current_pointer_cell
    _contact_observations = candidate_contacts.duplicate(true)
    _capture_candidate_warp_latches(
        candidate_sequence, candidate_anchors, candidate_contacts
    )
    _last_gesture_rejection.clear()
    return true


func _capture_press_endpoint_warp_latches() -> void:
    if _gesture_origin_sequence == null:
        return
    var endpoint := _gesture_origin_sequence.get_endpoint_cell()
    for observation in _gesture_origin_contacts:
        if (
            not observation.get("contact_possible", false)
            or observation.get("contact_mode", -1) \
                != RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER
        ):
            continue
        var anchor_id: StringName = observation.get("anchor_id", StringName())
        var cell: Vector2i = observation.get("cell", Vector2i(-1, -1))
        if cell == endpoint:
            _remember_gesture_warp_latch(
                anchor_id, cell, _route_occurrence_for_cell(_gesture_origin_sequence, cell)
            )
        else:
            var occurrence := _route_occurrence_for_cell(_gesture_origin_sequence, cell)
            if not occurrence.is_empty():
                _gesture_preexisting_nonendpoint_anchor_ids[anchor_id] = {
                    "route_serial": occurrence["route_serial"],
                    "cell": cell,
                }


func _capture_candidate_warp_latches(
    candidate_sequence: TrackCellSequenceScript,
    candidate_anchors: Array[RouteContactAnchorScript],
    candidate_contacts: Array[Dictionary]
) -> void:
    var exact_ids: Dictionary = {}
    for anchor in candidate_anchors:
        if anchor.contact_mode == RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER:
            exact_ids[anchor.anchor_id] = true
    var pending: Array[Dictionary] = []
    for observation in candidate_contacts:
        var anchor_id: StringName = observation.get("anchor_id", StringName())
        if (
            not exact_ids.has(anchor_id)
            or not observation.get("contact_possible", false)
            or _gesture_has_warp_latch(anchor_id)
        ):
            continue
        var cell: Vector2i = observation.get("cell", Vector2i(-1, -1))
        var occurrence := _route_occurrence_for_cell(candidate_sequence, cell)
        if occurrence.is_empty():
            continue
        var preexisting: Dictionary = _gesture_preexisting_nonendpoint_anchor_ids.get(
            anchor_id, {}
        )
        if (
            not preexisting.is_empty()
            and int(preexisting["route_serial"]) == int(occurrence["route_serial"])
            and Vector2i(preexisting["cell"]) == cell
        ):
            continue
        if (
            int(occurrence["route_serial"]) >= 0
            and _gesture_origin_occurrence_is_unchanged(
                int(occurrence["route_serial"]), cell
            )
            and cell != _gesture_origin_sequence.get_endpoint_cell()
            and not _gesture_press_anchor_ids.has(anchor_id)
        ):
            continue
        pending.append({
            "anchor_id": anchor_id,
            "cell": cell,
            "route_serial": occurrence["route_serial"],
            "route_index": occurrence["route_index"],
        })
    pending.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
        if first["route_index"] != second["route_index"]:
            return first["route_index"] < second["route_index"]
        return String(first["anchor_id"]) < String(second["anchor_id"])
    )
    for fact in pending:
        _remember_gesture_warp_latch(
            fact["anchor_id"], fact["cell"], fact
        )


func _remember_gesture_warp_latch(
    anchor_id: StringName,
    cell: Vector2i,
    occurrence: Dictionary
) -> void:
    if anchor_id == StringName() or occurrence.is_empty() or _gesture_has_warp_latch(anchor_id):
        return
    _gesture_live_warp_latches.append({
        "anchor_id": anchor_id,
        "cell": cell,
        "route_serial": int(occurrence["route_serial"]),
    })
    _gesture_latched_suffix_input_facts.clear()


func _gesture_has_warp_latch(anchor_id: StringName) -> bool:
    for latch in _gesture_live_warp_latches:
        if latch["anchor_id"] == anchor_id:
            return true
    return false


func _route_occurrence_for_cell(
    sequence: TrackCellSequenceScript,
    cell: Vector2i
) -> Dictionary:
    var records := sequence.get_records()
    for index in range(records.size()):
        if records[index].cell == cell:
            return {
                "route_serial": records[index].route_serial,
                "route_index": index,
            }
    if records.is_empty() and cell == sequence.get_endpoint_cell():
        return {"route_serial": -1, "route_index": -1}
    return {}


func _gesture_origin_occurrence_is_unchanged(
    route_serial: int,
    cell: Vector2i
) -> bool:
    if _gesture_origin_sequence == null:
        return false
    for record in _gesture_origin_sequence.get_records():
        if record.route_serial == route_serial:
            return record.cell == cell
    return false


func _latest_gesture_warp_latch() -> Dictionary:
    var latest: Dictionary = {}
    var latest_index := -2
    var records := _sequence.get_records()
    for latch in _gesture_live_warp_latches:
        var route_index := -1
        if int(latch["route_serial"]) >= 0:
            route_index = -2
            for index in range(records.size()):
                if records[index].route_serial == int(latch["route_serial"]):
                    route_index = index
                    break
            if route_index < 0:
                continue
        if route_index >= latest_index:
            latest = latch
            latest_index = route_index
    return latest


func _sequence_prefix_through_latch(
    source: TrackCellSequenceScript,
    route_serial: int
):
    if source == null:
        return null
    var prefix = source.duplicate_sequence()
    if route_serial < 0:
        if _gesture_origin_sequence != null and _gesture_origin_sequence.get_records().is_empty():
            return _gesture_origin_sequence.duplicate_sequence()
        if prefix.get_records().is_empty():
            return prefix
        return null
    var records := prefix.get_records()
    var anchor_index := -1
    for index in range(records.size()):
        if records[index].route_serial == route_serial:
            anchor_index = index
            break
    if anchor_index < 0:
        return null
    if anchor_index + 1 >= records.size():
        return prefix
    for index in range(anchor_index + 1, prefix._records.size()):
        var record = prefix._records[index]
        if record.state != TrackCellRecordScript.State.RESERVED_GHOST:
            return null
        for locked in _gesture_origin_locked_ledger:
            if locked.contains_serial(record.route_serial):
                return null
        record.geometry_locked = false
    var expected_removed := records.size() - anchor_index - 1
    var removed := prefix.cancel_ghost_suffix(records[anchor_index + 1].cell)
    if removed != expected_removed:
        return null
    return prefix


func _release_inactive_gesture_warp_latches(
    candidate_anchors: Array[RouteContactAnchorScript]
) -> void:
    var active_ids: Dictionary = {}
    for anchor in candidate_anchors:
        if anchor.contact_mode == RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER:
            active_ids[anchor.anchor_id] = true
    var retained: Array[Dictionary] = []
    for latch in _gesture_live_warp_latches:
        if active_ids.has(latch["anchor_id"]):
            retained.append(latch)
    if retained.size() != _gesture_live_warp_latches.size():
        _gesture_live_warp_latches = retained
        _gesture_latched_suffix_input_facts.clear()


func _gesture_update_from_live_warp_latch(
    live_path: Array[Vector2i],
    current_pointer_cell: Vector2i,
    allows_bounded_reentry_connection: bool
) -> bool:
    var latch := _latest_gesture_warp_latch()
    if latch.is_empty():
        _gesture_live_warp_latches.clear()
        _gesture_latched_suffix_input_facts.clear()
        return gesture_update(
            live_path, current_pointer_cell, allows_bounded_reentry_connection
        )
    var candidate_sequence = _sequence_prefix_through_latch(
        _sequence, int(latch["route_serial"])
    )
    if candidate_sequence == null:
        _record_gesture_rejection(
            &"template_mutation", &"immutable_suffix_after_warp_latch",
            live_path, current_pointer_cell, -1, _sequence
        )
        return false
    var candidate_ledger = _locked_ledger_retained_by_sequence(candidate_sequence)
    var suffix_cells: Array[Vector2i] = []
    var anchor_path_index := live_path.rfind(Vector2i(latch["cell"]))
    if anchor_path_index >= 0:
        for index in range(anchor_path_index + 1, live_path.size()):
            suffix_cells.append(live_path[index])
    else:
        suffix_cells = live_path.duplicate()
    var expanded_suffix: Variant = _expand_live_warp_latched_suffix(
        candidate_sequence,
        suffix_cells,
        allows_bounded_reentry_connection
    )
    if expanded_suffix == null:
        _record_gesture_rejection(
            &"candidate_sequence", &"bounded_reentry_connection_rejected",
            live_path, current_pointer_cell, -1, candidate_sequence
        )
        return false
    var next_suffix_facts := _reconcile_gesture_input_facts(
        _gesture_latched_suffix_input_facts,
        expanded_suffix
    )
    if not _append_gesture_input_facts(candidate_sequence, next_suffix_facts):
        _record_gesture_rejection(
            &"candidate_sequence", &"append_latched_suffix_rejected",
            live_path, current_pointer_cell, -1, candidate_sequence
        )
        return false
    var candidate_anchors = _duplicate_anchors(_gesture_origin_anchors)
    var resolution = _resolve_candidate(
        candidate_sequence,
        candidate_ledger,
        candidate_anchors,
        _gesture_origin_recovered_cells_by_piece
    )
    if not resolution.is_valid:
        _record_gesture_rejection(
            &"candidate_resolution", resolution.reason,
            live_path, current_pointer_cell, -1,
            candidate_sequence, candidate_ledger, candidate_anchors
        )
        return false
    if not _pieces_are_continuous(resolution.pieces):
        _record_gesture_rejection(
            &"candidate_continuity", &"piece_discontinuity",
            live_path, current_pointer_cell, -1,
            candidate_sequence, candidate_ledger, candidate_anchors
        )
        return false
    _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
    candidate_sequence.apply_resolved_geometry(resolution.pieces)
    if not _validate_candidate(candidate_sequence, candidate_ledger, resolution):
        _record_gesture_rejection(
            &"candidate_validation", &"candidate_invariant",
            live_path, current_pointer_cell, -1,
            candidate_sequence, candidate_ledger, candidate_anchors
        )
        return false
    if not _gesture_candidate_can_finalize(candidate_sequence, candidate_ledger, candidate_anchors):
        var final_reason := _last_stage_rejection_reason
        if final_reason == StringName():
            final_reason = &"candidate_cannot_finalize"
        _record_gesture_rejection(
            &"candidate_finalization", final_reason,
            live_path, current_pointer_cell, -1,
            candidate_sequence, candidate_ledger, candidate_anchors
        )
        return false
    var candidate_contacts := _build_contact_observations(
        resolution.pieces,
        candidate_anchors,
        _gesture_origin_recovered_cells_by_piece,
        candidate_sequence.get_records()
    )
    _commit_candidate(candidate_sequence, candidate_ledger, resolution)
    _advance_gesture_serial_watermark(candidate_sequence)
    _gesture_latched_suffix_input_facts = next_suffix_facts
    _contact_observations = candidate_contacts.duplicate(true)
    _capture_candidate_warp_latches(
        candidate_sequence, candidate_anchors, candidate_contacts
    )
    _last_gesture_rejection.clear()
    return true


func _expand_live_warp_latched_suffix(
    base_sequence: TrackCellSequenceScript,
    cells: Array[Vector2i],
    authorized: bool
) -> Variant:
    var occupied: Dictionary = {}
    for record in base_sequence.get_records():
        occupied[record.cell] = true
    var free_waypoints: Array[Vector2i] = []
    for cell in cells:
        if not occupied.has(cell):
            free_waypoints.append(cell)
    if not authorized:
        return free_waypoints
    return _expand_bounded_reentry_path(base_sequence, free_waypoints, true)


func _locked_ledger_retained_by_sequence(
    candidate_sequence: TrackCellSequenceScript
) -> Array[TrackGeometryPieceScript]:
    var retained_serials: Dictionary = {}
    for record in candidate_sequence.get_records():
        retained_serials[record.route_serial] = true
    var retained := _duplicate_pieces(_gesture_origin_locked_ledger)
    for piece in _locked_ledger:
        var belongs_to_origin := false
        for origin_piece in _gesture_origin_locked_ledger:
            if (
                piece.first_route_serial == origin_piece.first_route_serial
                and piece.last_route_serial == origin_piece.last_route_serial
                and piece.exit_support_route_serial == origin_piece.exit_support_route_serial
            ):
                belongs_to_origin = true
                break
        if belongs_to_origin:
            continue
        if (
            not retained_serials.has(piece.first_route_serial)
            or not retained_serials.has(piece.last_route_serial)
            or (
                piece.exit_support_route_serial >= 0
                and not retained_serials.has(piece.exit_support_route_serial)
            )
        ):
            continue
        retained.append(piece.duplicate_piece())
    return retained


func _record_gesture_rejection(
    stage: StringName,
    reason: StringName,
    live_path: Array[Vector2i],
    pointer_cell: Vector2i,
    attempted_template_index: int,
    candidate_sequence = null,
    candidate_ledger: Array = [],
    candidate_anchors: Array = []
) -> void:
    if not _gesture_rejection_diagnostics_enabled:
        return
    var candidate_records: Array[Dictionary] = []
    if candidate_sequence != null:
        for record in candidate_sequence.get_records():
            candidate_records.append({
                "serial": record.route_serial,
                "cell": record.cell,
                "distance": record.route_distance_start_cells,
                "state": record.state,
                "group": record.geometry_group_id,
                "locked": record.geometry_locked,
            })
    var locked_pieces: Array[Dictionary] = []
    for piece in candidate_ledger:
        locked_pieces.append({
            "group": piece.group_id,
            "kind": piece.kind,
            "first_serial": piece.first_route_serial,
            "last_serial": piece.last_route_serial,
            "footprint": piece.footprint_cells.duplicate(),
        })
    var anchor_facts: Array[Dictionary] = []
    for anchor in candidate_anchors:
        anchor_facts.append({
            "id": anchor.anchor_id,
            "cell": anchor.cell,
            "mode": anchor.contact_mode,
        })
    _last_gesture_rejection = {
        "stage": stage,
        "reason": reason,
        "live_path": live_path.duplicate(),
        "pointer_cell": pointer_cell,
        "accepted_endpoint": get_endpoint_cell(),
        "selected_template_index": _gesture_selected_template_index,
        "attempted_template_index": attempted_template_index,
        "editable_span": _gesture_editable_span.duplicate(true),
        "targets": _gesture_target_endpoints.duplicate(true),
        "candidate_records": candidate_records,
        "locked_pieces": locked_pieces,
        "anchors": anchor_facts,
    }


func _reconcile_gesture_input_facts(
    existing: Array[Dictionary],
    cells: Array[Vector2i]
) -> Array[Dictionary]:
    var common_count := 0
    while (
        common_count < existing.size()
        and common_count < cells.size()
        and Vector2i(existing[common_count]["cell"]) == cells[common_count]
    ):
        common_count += 1
    var reconciled: Array[Dictionary] = existing.slice(0, common_count).duplicate(true)
    for index in range(common_count, cells.size()):
        reconciled = _append_new_gesture_input_fact(reconciled, cells[index])
    return reconciled


func _expand_bounded_reentry_path(
    base_sequence: TrackCellSequenceScript,
    cells: Array[Vector2i],
    authorized: bool
) -> Variant:
    if not authorized or not _path_has_nonadjacent_edge(base_sequence, cells):
        return cells.duplicate()
    var working := base_sequence.duplicate_sequence()
    var expanded: Array[Vector2i] = []
    for cell_index in range(cells.size()):
        var cell: Vector2i = cells[cell_index]
        var endpoint: Vector2i = working.get_endpoint_cell()
        var distance := absi(cell.x - endpoint.x) + absi(cell.y - endpoint.y)
        var steps: Array[Vector2i] = []
        if distance == 1:
            steps.append(cell)
        else:
            var reserved_waypoints: Dictionary = {}
            for later_index in range(cell_index + 1, cells.size()):
                reserved_waypoints[cells[later_index]] = true
            steps = _find_bounded_reentry_connector(
                working,
                cell,
                reserved_waypoints
            )
            if steps.is_empty():
                return null
        for step in steps:
            if working.try_append_candidate(step) == null:
                return null
            expanded.append(step)
    return expanded


func _path_has_nonadjacent_edge(
    base_sequence: TrackCellSequenceScript,
    cells: Array[Vector2i]
) -> bool:
    var previous := base_sequence.get_endpoint_cell()
    for cell in cells:
        if absi(cell.x - previous.x) + absi(cell.y - previous.y) != 1:
            return true
        previous = cell
    return false


func _find_bounded_reentry_connector(
    sequence: TrackCellSequenceScript,
    target: Vector2i,
    reserved_waypoints: Dictionary = {}
) -> Array[Vector2i]:
    var empty: Array[Vector2i] = []
    if not _cell_in_grid(target):
        return empty
    var available := sequence.get_available_track_cells()
    var start := sequence.get_endpoint_cell()
    var minimum_distance := absi(target.x - start.x) + absi(target.y - start.y)
    if minimum_distance <= 0 or minimum_distance > available:
        return empty
    var blocked: Dictionary = {}
    for record in sequence.get_records():
        blocked[record.cell] = true
    for waypoint in reserved_waypoints:
        blocked[waypoint] = true
    if sequence.get_active_predecessor_cell() == _departure_cell:
        blocked[_departure_cell] = true
    if blocked.has(target):
        return empty
    var predecessors: Dictionary = {start: start}
    var depths: Dictionary = {start: 0}
    var queue: Array[Vector2i] = [start]
    var read_index := 0
    var directions: Array[Vector2i] = [
        Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP,
    ]
    while read_index < queue.size():
        var current: Vector2i = queue[read_index]
        read_index += 1
        var depth: int = depths[current]
        if depth >= available:
            continue
        for direction in directions:
            var neighbor := current + direction
            if not _cell_in_grid(neighbor) or blocked.has(neighbor) or predecessors.has(neighbor):
                continue
            predecessors[neighbor] = current
            depths[neighbor] = depth + 1
            if neighbor == target:
                return _reconstruct_bounded_connector(predecessors, start, target)
            queue.append(neighbor)
    return empty


func _reconstruct_bounded_connector(
    predecessors: Dictionary,
    start: Vector2i,
    target: Vector2i
) -> Array[Vector2i]:
    var reversed: Array[Vector2i] = []
    var current := target
    while current != start:
        if not predecessors.has(current):
            return []
        reversed.append(current)
        current = predecessors[current]
    reversed.reverse()
    return reversed


func _template_index_from_pointer(
    current_pointer_cell: Vector2i,
    templates: Array[Array]
) -> int:
    if current_pointer_cell == Vector2i(-1, -1) or templates.is_empty():
        return -1
    var template_names: Array[StringName] = [&"straight", &"left", &"right"]
    var best_distance := 2147483647
    var best_indices: Array[int] = []
    for index in range(template_names.size()):
        var endpoint: Vector2i = _gesture_target_endpoints.get(
            template_names[index], Vector2i(-1, -1)
        )
        if endpoint == Vector2i(-1, -1):
            continue
        var distance := absi(current_pointer_cell.x - endpoint.x) \
            + absi(current_pointer_cell.y - endpoint.y)
        if distance < best_distance:
            best_distance = distance
            best_indices = [index]
        elif distance == best_distance:
            best_indices.append(index)
    if best_indices.is_empty():
        return -1
    if _gesture_selected_template_index in best_indices:
        return _gesture_selected_template_index
    return best_indices[0]


func get_gesture_origin_observation() -> Dictionary:
    return _gesture_origin_observation()


func get_gesture_origin() -> Dictionary:
    return _gesture_origin_observation()


func get_gesture_editable_span() -> Dictionary:
    return _gesture_editable_span.duplicate(true)


func get_editable_span() -> Dictionary:
    return get_gesture_editable_span()


func get_gesture_target_endpoints() -> Dictionary:
    return _gesture_target_endpoints.duplicate(true)


func append_cells(cells: Array[Vector2i]) -> int:
    var accepted_count := 0
    for cell in cells:
        var candidate_sequence = _sequence.duplicate_sequence()
        var tentative = candidate_sequence.try_append_candidate(cell)
        if tentative == null:
            break
        var candidate_ledger = _duplicate_pieces(_locked_ledger)
        var candidate_anchors = _duplicate_anchors(_anchors)
        var resolution = _stage_stable_retirement(
            candidate_sequence,
            candidate_ledger,
            candidate_anchors,
            _recovered_cells_by_piece
        )
        if not resolution.is_valid:
            break
        _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
        candidate_sequence.apply_resolved_geometry(resolution.pieces)
        if not _validate_candidate(candidate_sequence, candidate_ledger, resolution):
            break
        _commit_candidate(candidate_sequence, candidate_ledger, resolution)
        accepted_count += 1
    _refresh_contact_observations()
    return accepted_count


func cancel_ghost_suffix(cell: Vector2i) -> bool:
    var records = _sequence.get_records()
    var target_index := -1
    for index in range(records.size()):
        if records[index].cell == cell:
            target_index = index
            break
    if target_index < 0:
        return false
    for index in range(target_index, records.size()):
        var record = records[index]
        if (
            record.state != TrackCellRecordScript.State.RESERVED_GHOST
            or record.geometry_locked
            or is_exit_support_route_serial(record.route_serial)
        ):
            return false
        for piece in _pieces:
            if piece.contains_serial(record.route_serial) and piece.locked:
                return false
    var candidate_sequence = _sequence.duplicate_sequence()
    if candidate_sequence.cancel_ghost_suffix(cell) <= 0:
        return false
    var candidate_ledger = _duplicate_pieces(_locked_ledger)
    var candidate_anchors = _duplicate_anchors(_anchors)
    var resolution = _stage_stable_retirement(
        candidate_sequence,
        candidate_ledger,
        candidate_anchors,
        _recovered_cells_by_piece
    )
    if not resolution.is_valid:
        return false
    _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
    candidate_sequence.apply_resolved_geometry(resolution.pieces)
    if not _validate_candidate(candidate_sequence, candidate_ledger, resolution):
        return false
    _commit_candidate(candidate_sequence, candidate_ledger, resolution)
    _refresh_contact_observations()
    return true


func duplicate_runtime() -> GridTrackRuntime:
    assert(not _gesture_active, "Paid staging cannot duplicate an active gesture")
    var copy: GridTrackRuntime = get_script().new(
        _departure_cell,
        _sequence.get_total_track_cells(),
        Vector2(_grid_origin_units),
        Vector2i(_grid_size),
        _cell_size_units
    )
    copy._sequence = _sequence.duplicate_sequence()
    copy._pieces = _duplicate_pieces(_pieces)
    copy._locked_ledger = _duplicate_pieces(_locked_ledger)
    copy._anchors = _duplicate_anchors(_anchors)
    copy._contact_observations = _contact_observations.duplicate(true)
    copy._recovered_cells_by_piece = _recovered_cells_by_piece.duplicate(true)
    copy._recovered_end_distance_cells = _recovered_end_distance_cells
    copy._gesture_rejection_diagnostics_enabled = _gesture_rejection_diagnostics_enabled
    copy._last_gesture_rejection = _last_gesture_rejection.duplicate(true)
    return copy


func replace_with(source: GridTrackRuntime) -> void:
    assert(source != null, "Source track runtime is required")
    assert(not _gesture_active and not source._gesture_active, "Paid install requires inactive gestures")
    _sequence.replace_with(source._sequence)
    _pieces = _duplicate_pieces(source._pieces)
    _locked_ledger = _duplicate_pieces(source._locked_ledger)
    _anchors = _duplicate_anchors(source._anchors)
    _contact_observations = source._contact_observations.duplicate(true)
    _recovered_cells_by_piece = source._recovered_cells_by_piece.duplicate(true)
    _recovered_end_distance_cells = source._recovered_end_distance_cells
    _gesture_rejection_diagnostics_enabled = source._gesture_rejection_diagnostics_enabled
    _last_gesture_rejection = source._last_gesture_rejection.duplicate(true)


func try_paid_demolition(route_serial: int, train_distance_cells: float) -> bool:
    if (
        route_serial < 0
        or not is_finite(train_distance_cells)
        or train_distance_cells < 0.0
        or _gesture_active
    ):
        return false
    var records: Array[TrackCellRecordScript] = _sequence.get_records()
    var target_index := -1
    for index in range(records.size()):
        if records[index].route_serial == route_serial:
            target_index = index
            break
    if target_index < 0:
        return false
    var target := records[target_index]
    if target.state not in [
        TrackCellRecordScript.State.BUILDING,
        TrackCellRecordScript.State.BUILT,
    ]:
        return false
    var target_start: float = target.route_distance_start_cells
    var target_end := target_start + 1.0
    if target_start > train_distance_cells:
        return _try_paid_front_suffix_demolition(records, target_index)
    if target_end <= train_distance_cells:
        var recovered_count := recover_behind(target_end)
        return recovered_count == target_index + 1
    return false


func _try_paid_front_suffix_demolition(
    records: Array[TrackCellRecordScript],
    target_index: int
) -> bool:
    for index in range(target_index, records.size()):
        var record := records[index]
        if record.geometry_locked:
            return false
        for piece in _pieces:
            if piece.locked and piece.contains_serial(record.route_serial):
                return false
    var candidate_sequence = _sequence.duplicate_sequence()
    var removed := candidate_sequence.remove_suffix_from_serial(
        records[target_index].route_serial
    )
    if removed.size() != records.size() - target_index:
        return false
    var candidate_ledger = _duplicate_pieces(_locked_ledger)
    var candidate_anchors = _duplicate_anchors(_anchors)
    var candidate_recovered_cells: Dictionary = _recovered_cells_by_piece.duplicate(true)
    for removed_record in removed:
        _remember_exit_support_cell_in(
            candidate_ledger, candidate_recovered_cells, removed_record
        )
    var resolution = _stage_stable_retirement(
        candidate_sequence,
        candidate_ledger,
        candidate_anchors,
        candidate_recovered_cells
    )
    if not resolution.is_valid:
        return false
    _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
    candidate_sequence.apply_resolved_geometry(resolution.pieces)
    if not _validate_candidate(
        candidate_sequence,
        candidate_ledger,
        resolution,
        candidate_recovered_cells,
        _recovered_end_distance_cells
    ):
        return false
    var candidate_contacts := _build_contact_observations(
        resolution.pieces,
        candidate_anchors,
        candidate_recovered_cells,
        candidate_sequence.get_records()
    )
    _commit_candidate(candidate_sequence, candidate_ledger, resolution)
    _recovered_cells_by_piece = candidate_recovered_cells.duplicate(true)
    _contact_observations = candidate_contacts.duplicate(true)
    return true


func _remember_exit_support_cell_in(
    ledger: Array[TrackGeometryPieceScript],
    recovered_cells_by_piece: Dictionary,
    record: TrackCellRecordScript
) -> void:
    for locked in ledger:
        if locked.exit_support_route_serial != record.route_serial:
            continue
        var key := _piece_key(locked)
        if not recovered_cells_by_piece.has(key):
            recovered_cells_by_piece[key] = {}
        recovered_cells_by_piece[key][record.cell] = true
        return


func set_contact_anchors(anchors: Array[RouteContactAnchorScript]) -> void:
    var candidate_anchors: Array[RouteContactAnchorScript] = []
    for anchor in anchors:
        candidate_anchors.append(anchor.duplicate_anchor())
    var current_stage := _stage_anchor_update(
        _sequence,
        _locked_ledger,
        candidate_anchors,
        _recovered_cells_by_piece,
        _recovered_end_distance_cells
    )
    if current_stage.get("valid", false):
        _commit_candidate(
            current_stage["sequence"],
            current_stage["ledger"],
            current_stage["resolution"]
        )
    _anchors = candidate_anchors
    _refresh_contact_observations()
    if _gesture_active and _gesture_origin_sequence != null:
        var origin_stage := _stage_anchor_update(
            _gesture_origin_sequence,
            _gesture_origin_locked_ledger,
            candidate_anchors,
            _gesture_origin_recovered_cells_by_piece,
            _gesture_origin_recovered_end_distance_cells
        )
        if origin_stage.get("valid", false):
            _gesture_origin_sequence = origin_stage["sequence"]
            _gesture_origin_locked_ledger = origin_stage["ledger"]
            _gesture_origin_pieces = _duplicate_pieces(origin_stage["resolution"].pieces)
        _gesture_origin_anchors = _duplicate_anchors(candidate_anchors)
        _gesture_origin_contacts = _build_contact_observations(
            _gesture_origin_pieces,
            _gesture_origin_anchors,
            _gesture_origin_recovered_cells_by_piece,
            _gesture_origin_sequence.get_records()
        )
        _release_inactive_gesture_warp_latches(candidate_anchors)
        _capture_candidate_warp_latches(
            _sequence, candidate_anchors, _contact_observations
        )


func _stage_anchor_update(
    source_sequence: TrackCellSequenceScript,
    source_ledger: Array[TrackGeometryPieceScript],
    anchors: Array[RouteContactAnchorScript],
    recovered_cells_by_piece: Dictionary,
    recovered_end_distance_cells: float
) -> Dictionary:
    var candidate_sequence = source_sequence.duplicate_sequence()
    var candidate_ledger = _duplicate_pieces(source_ledger)
    var resolution = _stage_stable_retirement(
        candidate_sequence,
        candidate_ledger,
        anchors,
        recovered_cells_by_piece
    )
    if not resolution.is_valid:
        return {"valid": false}
    _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
    candidate_sequence.apply_resolved_geometry(resolution.pieces)
    if not _validate_candidate(
        candidate_sequence,
        candidate_ledger,
        resolution,
        recovered_cells_by_piece,
        recovered_end_distance_cells
    ):
        return {"valid": false}
    return {
        "valid": true,
        "sequence": candidate_sequence,
        "ledger": candidate_ledger,
        "resolution": resolution,
    }


func advance_construction(progress_cells: float) -> float:
    if _gesture_active:
        if _gesture_origin_sequence == null:
            return 0.0
        var candidate_sequence := _sequence.duplicate_sequence()
        var origin_sequence := _gesture_origin_sequence.duplicate_sequence()
        var origin_records_by_serial: Dictionary = {}
        for origin_record in origin_sequence._records:
            origin_records_by_serial[origin_record.route_serial] = origin_record
        var candidate_records_by_serial: Dictionary = {}
        for candidate_record in candidate_sequence._records:
            candidate_records_by_serial[candidate_record.route_serial] = candidate_record
        for route_serial in candidate_records_by_serial:
            if not origin_records_by_serial.has(route_serial):
                continue
            var shared_origin_record: TrackCellRecordScript = (
                origin_records_by_serial[route_serial]
                as TrackCellRecordScript
            )
            var candidate_record: TrackCellRecordScript = (
                candidate_records_by_serial[route_serial]
                as TrackCellRecordScript
            )
            candidate_record.state = shared_origin_record.state
            candidate_record.build_progress = shared_origin_record.build_progress
        var remaining := maxf(progress_cells, 0.0)
        var consumed_total := 0.0
        while remaining > 0.0:
            var target: TrackCellRecordScript = null
            for candidate_record in candidate_sequence._records:
                if not origin_records_by_serial.has(candidate_record.route_serial):
                    continue
                var origin_record: TrackCellRecordScript = (
                    origin_records_by_serial[candidate_record.route_serial]
                    as TrackCellRecordScript
                )
                if origin_record.state != TrackCellRecordScript.State.BUILT:
                    target = candidate_record
                    break
            if target == null:
                break
            var origin_target: TrackCellRecordScript = (
                origin_records_by_serial[target.route_serial]
                as TrackCellRecordScript
            )
            if target.state == TrackCellRecordScript.State.RESERVED_GHOST:
                candidate_sequence.start_building(target.route_serial)
            if origin_target.state == TrackCellRecordScript.State.RESERVED_GHOST:
                origin_sequence.start_building(origin_target.route_serial)
            var candidate_consumed: float = candidate_sequence.add_build_progress(remaining)
            var origin_consumed: float = origin_sequence.add_build_progress(remaining)
            if candidate_consumed != origin_consumed:
                return 0.0
            if origin_consumed <= 0.0:
                break
            candidate_sequence.complete_building()
            origin_sequence.complete_building()
            consumed_total += origin_consumed
            remaining -= origin_consumed
            var updated_origin_record: TrackCellRecordScript = (
                origin_records_by_serial[target.route_serial]
                as TrackCellRecordScript
            )
            var updated_candidate_record: TrackCellRecordScript = (
                candidate_records_by_serial[target.route_serial]
                as TrackCellRecordScript
            )
            updated_candidate_record.state = updated_origin_record.state
            updated_candidate_record.build_progress = updated_origin_record.build_progress
        _sequence.replace_with(candidate_sequence)
        _gesture_origin_sequence = origin_sequence
        return consumed_total
    var remaining := maxf(progress_cells, 0.0)
    var consumed_total := 0.0
    while remaining > 0.0:
        var target = _first_unbuilt_record()
        if target == null:
            break
        if target.state == TrackCellRecordScript.State.RESERVED_GHOST:
            _sequence.start_building(target.route_serial)
        var consumed: float = _sequence.add_build_progress(remaining)
        if consumed <= 0.0:
            break
        consumed_total += consumed
        remaining -= consumed
        _sequence.complete_building()
    return consumed_total


func recover_behind(cutoff_distance_cells: float) -> int:
    var candidate_stage := _stage_recovery_for_route(
        _sequence,
        _locked_ledger,
        _recovered_cells_by_piece,
        _recovered_end_distance_cells,
        _anchors,
        cutoff_distance_cells
    )
    if candidate_stage.is_empty():
        if _gesture_active:
            assert(false, "Active gesture recovery candidate staging must succeed atomically")
        return 0
    var recovered: Array = candidate_stage["recovered"]
    if recovered.is_empty():
        return 0
    var origin_stage := {}
    if _gesture_active:
        if _gesture_origin_sequence == null:
            assert(false, "Active gesture recovery requires an evolving origin")
            return 0
        origin_stage = _stage_recovery_for_route(
            _gesture_origin_sequence,
            _gesture_origin_locked_ledger,
            _gesture_origin_recovered_cells_by_piece,
            _gesture_origin_recovered_end_distance_cells,
            _gesture_origin_anchors,
            cutoff_distance_cells
        )
        if origin_stage.is_empty() or not _same_recovered_serials(
            recovered, origin_stage.get("recovered", [])
        ):
            assert(false, "Active gesture recovery origin and candidate must stage the same records")
            return 0
    _commit_candidate(
        candidate_stage["sequence"],
        candidate_stage["ledger"],
        candidate_stage["resolution"]
    )
    _recovered_cells_by_piece = candidate_stage["recovered_cells_by_piece"].duplicate(true)
    _recovered_end_distance_cells = candidate_stage["recovered_end_distance_cells"]
    _contact_observations = candidate_stage["contacts"].duplicate(true)
    if _gesture_active:
        _gesture_origin_sequence = origin_stage["sequence"]
        _gesture_origin_locked_ledger = _duplicate_pieces(origin_stage["ledger"])
        _gesture_origin_pieces = _duplicate_pieces(origin_stage["resolution"].pieces)
        _gesture_origin_recovered_cells_by_piece = origin_stage["recovered_cells_by_piece"].duplicate(true)
        _gesture_origin_recovered_end_distance_cells = origin_stage["recovered_end_distance_cells"]
        _gesture_origin_contacts = origin_stage["contacts"].duplicate(true)
    return recovered.size()


func _stage_recovery_for_route(
    source_sequence: TrackCellSequenceScript,
    source_ledger: Array[TrackGeometryPieceScript],
    source_recovered_cells_by_piece: Dictionary,
    source_recovered_end_distance_cells: float,
    source_anchors: Array[RouteContactAnchorScript],
    cutoff_distance_cells: float
) -> Dictionary:
    var candidate_sequence = source_sequence.duplicate_sequence()
    var recovered: Array = candidate_sequence.recover_eligible_cells(cutoff_distance_cells)
    if recovered.is_empty():
        return {"recovered": recovered}
    var candidate_ledger = _duplicate_pieces(source_ledger)
    var candidate_recovered_cells_by_piece: Dictionary = source_recovered_cells_by_piece.duplicate(true)
    var candidate_recovered_end_distance_cells := source_recovered_end_distance_cells
    for record in recovered:
        _remember_recovered_piece_cell_in(
            candidate_ledger,
            candidate_recovered_cells_by_piece,
            record
        )
        candidate_recovered_end_distance_cells = maxf(
            candidate_recovered_end_distance_cells,
            record.route_distance_start_cells + 1.0
        )
    _prune_locked_ledger_in(
        candidate_ledger,
        candidate_sequence.get_records(),
        candidate_recovered_cells_by_piece
    )
    var candidate_anchors = _duplicate_anchors(source_anchors)
    var resolution = _resolve_candidate(
        candidate_sequence,
        candidate_ledger,
        candidate_anchors,
        candidate_recovered_cells_by_piece
    )
    if not resolution.is_valid:
        return {}
    _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
    candidate_sequence.apply_resolved_geometry(resolution.pieces)
    if not _validate_candidate(
        candidate_sequence,
        candidate_ledger,
        resolution,
        candidate_recovered_cells_by_piece,
        candidate_recovered_end_distance_cells
    ):
        return {}
    return {
        "sequence": candidate_sequence,
        "ledger": candidate_ledger,
        "resolution": resolution,
        "recovered_cells_by_piece": candidate_recovered_cells_by_piece,
        "recovered_end_distance_cells": candidate_recovered_end_distance_cells,
        "contacts": _build_contact_observations(
            resolution.pieces,
            candidate_anchors,
            candidate_recovered_cells_by_piece,
            candidate_sequence.get_records()
        ),
        "recovered": recovered,
    }


func _same_recovered_serials(first: Array, second: Array) -> bool:
    if first.size() != second.size():
        return false
    for index in range(first.size()):
        if first[index].route_serial != second[index].route_serial:
            return false
    return true


func get_endpoint_cell() -> Vector2i:
    return _sequence.get_endpoint_cell()


func get_cell_records() -> Array[TrackCellRecordScript]:
    return _sequence.get_records()


func get_geometry_pieces() -> Array[TrackGeometryPieceScript]:
    var observations: Array[TrackGeometryPieceScript] = []
    for piece in _pieces:
        observations.append(piece.duplicate_piece())
    return observations


func get_built_end_distance_cells() -> float:
    var result := _recovered_end_distance_cells
    for record in _sequence.get_records():
        if record.state != TrackCellRecordScript.State.BUILT:
            break
        result = record.route_distance_start_cells + 1.0
    return result


func get_reserved_end_distance_cells() -> float:
    var records: Array = _sequence.get_records()
    if records.is_empty():
        return _recovered_end_distance_cells
    return records[-1].route_distance_start_cells + 1.0


func get_available_track_cells() -> int:
    return _sequence.get_available_track_cells()


func get_total_track_cells() -> int:
    return _sequence.get_total_track_cells()


func get_grid_origin_units() -> Vector2:
    return _grid_origin_units


func prepare_for_train_sampling(current_distance: float, through_distance: float) -> bool:
    if _pieces.is_empty():
        return false
    if _train_sampling_intersects_active_gesture(current_distance, through_distance):
        if not gesture_finalize():
            return false
    var current = _canonical_distance_and_owner(current_distance)
    var through = _canonical_distance_and_owner(through_distance)
    var current_owner = current.piece
    var through_owner = through.piece
    if current_owner == null or through_owner == null or through.distance < current.distance:
        return false
    var farthest_owner = current_owner
    if through.distance > current.distance:
        farthest_owner = null
        for piece in _pieces:
            var interval_start := maxf(current.distance, piece.absolute_start_distance_cells)
            var interval_end := minf(
                through.distance,
                piece.absolute_start_distance_cells + float(piece.nominal_length_cells)
            )
            if interval_end > interval_start:
                farthest_owner = piece
        if farthest_owner == null:
            return false
    var farthest_index := -1
    var first_provisional_index := -1
    for index in range(_pieces.size()):
        var piece = _pieces[index]
        if not piece.locked and first_provisional_index < 0:
            first_provisional_index = index
        if piece == farthest_owner:
            farthest_index = index
    if farthest_index < 0:
        return false
    if first_provisional_index < 0 or farthest_index < first_provisional_index:
        return true
    var candidate_sequence = _sequence.duplicate_sequence()
    var candidate_ledger = _duplicate_pieces(_locked_ledger)
    var candidate_anchors = _duplicate_anchors(_anchors)
    var records: Array[TrackCellRecordScript] = candidate_sequence.get_records()
    for index in range(first_provisional_index, farthest_index + 1):
        var ledger_piece = _pieces[index].duplicate_piece()
        if ledger_piece.locked:
            return false
        ledger_piece.group_id = _next_ledger_group_id(candidate_ledger)
        ledger_piece.locked = true
        ledger_piece.exit_support_route_serial = _exit_support_serial(ledger_piece, records)
        if (
            ledger_piece.exit_support_route_serial >= 0
            and ledger_piece.exit_support_route_serial <= ledger_piece.last_route_serial
        ):
            return false
        candidate_ledger.append(ledger_piece)
    var resolution = _resolve_candidate(
        candidate_sequence,
        candidate_ledger,
        candidate_anchors,
        _recovered_cells_by_piece
    )
    if not resolution.is_valid or not _pieces_are_continuous(resolution.pieces):
        return false
    _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
    candidate_sequence.apply_resolved_geometry(resolution.pieces)
    if not _validate_candidate(candidate_sequence, candidate_ledger, resolution):
        return false
    var staged_origin := {}
    if _gesture_active:
        staged_origin = _stage_active_gesture_train_safety_origin(
            candidate_sequence,
            candidate_ledger
        )
        if staged_origin.is_empty():
            return false
    _commit_candidate(candidate_sequence, candidate_ledger, resolution)
    _refresh_contact_observations()
    if _gesture_active:
        _apply_active_gesture_train_safety_origin(staged_origin)
    return true


func _train_sampling_intersects_active_gesture(
    current_distance: float,
    through_distance: float
) -> bool:
    if not _gesture_active or _gesture_origin_sequence == null or through_distance < current_distance:
        return false
    var active_serials: Dictionary = {}
    if not _gesture_editable_span.is_empty():
        var first_serial: int = _gesture_editable_span["first_route_serial"]
        var last_serial: int = _gesture_editable_span["last_route_serial"]
        for serial in range(first_serial, last_serial + 1):
            active_serials[serial] = true
    for fact in _gesture_suffix_input_facts:
        active_serials[int(fact["serial"])] = true
    for fact in _gesture_ordinary_input_facts:
        active_serials[int(fact["serial"])] = true
    if active_serials.is_empty():
        return false
    var current_owner = _canonical_distance_and_owner(current_distance).piece
    var through_owner = _canonical_distance_and_owner(through_distance).piece
    if _piece_owns_any_active_serial(current_owner, active_serials):
        return true
    if _piece_owns_any_active_serial(through_owner, active_serials):
        return true
    for piece in _pieces:
        if not _piece_owns_any_active_serial(piece, active_serials):
            continue
        var piece_start: float = piece.absolute_start_distance_cells
        var piece_end := piece_start + float(piece.nominal_length_cells)
        var interval_start := maxf(current_distance, piece_start)
        var interval_end := minf(through_distance, piece_end)
        if interval_end - interval_start > NOMINAL_BOUNDARY_EPSILON:
            return true
    return false


func _piece_owns_any_active_serial(piece, active_serials: Dictionary) -> bool:
    if piece == null:
        return false
    for serial in active_serials:
        if piece.contains_serial(int(serial)):
            return true
    return false


func get_pose_sample_at_distance(route_distance: float) -> Dictionary:
    var canonical = _canonical_distance_and_owner(route_distance)
    var owner = canonical.piece
    assert(owner != null, "Geometry owner is required for pose sampling")
    if owner == null:
        return {}
    assert(owner.locked, "Locked geometry is required for pose sampling")
    if not owner.locked:
        return {}
    return owner.sample_nominal(canonical.distance - owner.absolute_start_distance_cells)


func get_position_at_distance_cells(route_distance_cells: float) -> Vector2:
    var sample := get_pose_sample_at_distance(route_distance_cells)
    return sample.position


func get_heading_at_distance_cells(route_distance_cells: float) -> Vector2:
    var sample := get_pose_sample_at_distance(route_distance_cells)
    return sample.heading


func get_contact_observations() -> Array[Dictionary]:
    return _contact_observations.duplicate(true)


func get_contact_hits_between(
    previous_distance_cells: float,
    through_distance_cells: float
) -> Array[Dictionary]:
    var hits: Array[Dictionary] = []
    if (
        not is_finite(previous_distance_cells)
        or not is_finite(through_distance_cells)
        or previous_distance_cells < 0.0
        or through_distance_cells <= previous_distance_cells
    ):
        return hits

    var anchors_by_id: Dictionary = {}
    for anchor in _anchors:
        if (
            anchor.contact_mode == RouteContactAnchorScript.ContactMode.CELL_ENTRY
            and not anchors_by_id.has(anchor.anchor_id)
        ):
            anchors_by_id[anchor.anchor_id] = anchor

    var observations_by_id: Dictionary = {}
    for observation in _contact_observations:
        observations_by_id[observation["anchor_id"]] = observation
    for anchor in _anchors:
        if anchor.contact_mode != RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER:
            continue
        var observation: Dictionary = observations_by_id.get(anchor.anchor_id, {})
        if not observation.get("contact_possible", false):
            continue
        var contact_distance: float = observation.get("contact_distance_cells", -1.0)
        var departure_hit := (
            contact_distance == 0.0
            and previous_distance_cells == 0.0
            and through_distance_cells > 0.0
        )
        if not departure_hit and (
            contact_distance <= previous_distance_cells
            or contact_distance > through_distance_cells
        ):
            continue
        hits.append({
            "anchor_id": anchor.anchor_id,
            "cell": anchor.cell,
            "contact_distance_cells": contact_distance,
        })

    if anchors_by_id.is_empty():
        hits.sort_custom(_contact_hit_less)
        return hits

    var emitted_anchor_ids: Dictionary = {}
    var previous_cell := _active_route_cell_at_distance(previous_distance_cells)
    if previous_distance_cells == 0.0:
        _append_contact_hits_for_transition(
            0.0,
            {},
            previous_cell,
            anchors_by_id,
            emitted_anchor_ids,
            hits
        )

    var last_sample_distance := previous_distance_cells
    var next_sample_index := int(floor(
        previous_distance_cells * float(CONTACT_SAMPLES_PER_CELL)
    )) + 1
    while true:
        var sample_distance := (
            float(next_sample_index) / float(CONTACT_SAMPLES_PER_CELL)
        )
        if sample_distance > through_distance_cells:
            break
        var current_cell := _active_route_cell_at_distance(sample_distance)
        _append_contact_hits_for_transition(
            sample_distance,
            previous_cell,
            current_cell,
            anchors_by_id,
            emitted_anchor_ids,
            hits
        )
        previous_cell = current_cell
        last_sample_distance = sample_distance
        next_sample_index += 1

    if last_sample_distance < through_distance_cells:
        var through_cell := _active_route_cell_at_distance(through_distance_cells)
        _append_contact_hits_for_transition(
            through_distance_cells,
            previous_cell,
            through_cell,
            anchors_by_id,
            emitted_anchor_ids,
            hits
        )

    hits.sort_custom(_contact_hit_less)
    return hits


func get_traveled_hazard_distance_cells(
    hazard_cells: Array[Vector2i],
    previous_distance_cells: float,
    through_distance_cells: float
) -> float:
    if (
        not is_finite(previous_distance_cells)
        or not is_finite(through_distance_cells)
        or previous_distance_cells < 0.0
        or through_distance_cells <= previous_distance_cells
        or hazard_cells.is_empty()
    ):
        return 0.0
    var hazard_lookup := {}
    for cell in hazard_cells:
        hazard_lookup[cell] = true
    var traveled := 0.0
    for piece in _pieces:
        if (
            not piece.locked
            or piece.nominal_length_cells <= 0
            or piece.centerline.size() < 2
        ):
            continue
        var local_start := maxf(
            piece.active_local_start_cells,
            previous_distance_cells - piece.absolute_start_distance_cells
        )
        var local_end := minf(
            piece.active_local_end_cells,
            through_distance_cells - piece.absolute_start_distance_cells
        )
        if local_end <= local_start:
            continue
        traveled += _piece_hazard_distance_cells(
            piece, hazard_lookup, local_start, local_end
        )
    return traveled


func _piece_hazard_distance_cells(
    piece: TrackGeometryPieceScript,
    hazard_lookup: Dictionary,
    local_start_cells: float,
    local_end_cells: float
) -> float:
    var segment_count: int = piece.centerline.size() - 1
    var nominal_per_segment := (
        float(piece.nominal_length_cells) / float(segment_count)
    )
    var recovered_cells: Dictionary = _recovered_cells_by_piece.get(
        _piece_key(piece), {}
    )
    var traveled := 0.0
    for segment_index in range(segment_count):
        var segment_local_start := float(segment_index) * nominal_per_segment
        var segment_local_end := segment_local_start + nominal_per_segment
        var overlap_start := maxf(local_start_cells, segment_local_start)
        var overlap_end := minf(local_end_cells, segment_local_end)
        if overlap_end <= overlap_start:
            continue
        var start: Vector2 = piece.centerline[segment_index]
        var finish: Vector2 = piece.centerline[segment_index + 1]
        var parameter_start := (
            (overlap_start - segment_local_start) / nominal_per_segment
        )
        var parameter_end := (
            (overlap_end - segment_local_start) / nominal_per_segment
        )
        var boundaries: Array[float] = [parameter_start, parameter_end]
        _append_axis_grid_crossings(
            boundaries,
            start.x,
            finish.x,
            _grid_origin_units.x,
            parameter_start,
            parameter_end
        )
        _append_axis_grid_crossings(
            boundaries,
            start.y,
            finish.y,
            _grid_origin_units.y,
            parameter_start,
            parameter_end
        )
        boundaries.sort()
        for boundary_index in range(boundaries.size() - 1):
            var interval_start: float = boundaries[boundary_index]
            var interval_end: float = boundaries[boundary_index + 1]
            if interval_end <= interval_start:
                continue
            var midpoint := start.lerp(finish, (interval_start + interval_end) * 0.5)
            var cell := _map_position_to_cell(midpoint)
            if hazard_lookup.has(cell) and not recovered_cells.has(cell):
                traveled += (interval_end - interval_start) * nominal_per_segment
    return traveled


func _append_axis_grid_crossings(
    boundaries: Array[float],
    start_units: float,
    finish_units: float,
    origin_units: float,
    parameter_start: float,
    parameter_end: float
) -> void:
    var delta_units := finish_units - start_units
    if is_zero_approx(delta_units):
        return
    var start_cells := (start_units - origin_units) / _cell_size_units
    var finish_cells := (finish_units - origin_units) / _cell_size_units
    var first_boundary := int(floor(minf(start_cells, finish_cells))) + 1
    var last_boundary := int(floor(maxf(start_cells, finish_cells)))
    for boundary_cell in range(first_boundary, last_boundary + 1):
        var parameter := (
            (float(boundary_cell) - start_cells)
            / (finish_cells - start_cells)
        )
        if (
            parameter > parameter_start
            and parameter < parameter_end
        ):
            boundaries.append(parameter)


func is_exit_support_route_serial(route_serial: int) -> bool:
    if route_serial < 0:
        return false
    for piece in _locked_ledger:
        if piece.exit_support_route_serial == route_serial:
            return true
    return false


func _cell_in_grid(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < _grid_size.x and cell.y < _grid_size.y


func _editable_endpoint_piece():
    if _sequence.get_records().is_empty():
        return null
    var endpoint_serial: int = _sequence.get_records()[-1].route_serial
    for piece in _pieces:
        if piece.contains_serial(endpoint_serial) and not piece.locked:
            return piece
    return null


func _discover_editable_span() -> Dictionary:
    var endpoint_piece = _editable_endpoint_piece()
    if endpoint_piece == null:
        return {}
    var records: Array[TrackCellRecordScript] = _sequence.get_records()
    var first_index := -1
    var last_index := -1
    for index in range(records.size()):
        if endpoint_piece.contains_serial(records[index].route_serial):
            if first_index < 0:
                first_index = index
            last_index = index
    if first_index < 0 or last_index < first_index:
        return {}
    if endpoint_piece.kind == TrackGeometryPieceScript.Kind.STRAIGHT:
        var support_count := 2
        while first_index > 0 and support_count > 0:
            var support = _piece_containing_serial(records[first_index - 1].route_serial)
            if support == null or support.locked or support.kind != TrackGeometryPieceScript.Kind.STRAIGHT:
                break
            first_index -= 1
            support_count -= 1
    var entry_cell: Vector2i = _sequence.get_active_predecessor_cell()
    if first_index > 0:
        entry_cell = records[first_index - 1].cell
    var incoming_heading: Vector2i = records[first_index].cell - entry_cell
    return {
        "first_route_serial": records[first_index].route_serial,
        "last_route_serial": records[last_index].route_serial,
        "first_index": first_index,
        "last_index": last_index,
        "entry_predecessor_cell": entry_cell,
        "incoming_heading": incoming_heading,
        "record_count": last_index - first_index + 1,
    }


func _calculate_target_endpoints(span: Dictionary) -> Dictionary:
    if span.is_empty():
        return {}
    var count: int = span["record_count"]
    var entry: Vector2i = span["entry_predecessor_cell"]
    var heading: Vector2i = span["incoming_heading"]
    var radius: int = maxi(1, int(ceil(float(count) / 2.0)))
    var turn_cell := entry + heading * radius
    var left_heading := Vector2i(-heading.y, heading.x)
    var right_heading := Vector2i(heading.y, -heading.x)
    return {
        "straight": entry + heading * count,
        "left": turn_cell + left_heading * (radius - 1),
        "right": turn_cell + right_heading * (radius - 1),
    }


func _template_cells(span: Dictionary) -> Array[Array]:
    var templates: Array[Array] = []
    if span.is_empty():
        return templates
    var count: int = span["record_count"]
    if count != 3 and count != 5:
        return templates
    var entry: Vector2i = span["entry_predecessor_cell"]
    var heading: Vector2i = span["incoming_heading"]
    var radius: int = maxi(1, int(ceil(float(count) / 2.0)))
    var left_heading := Vector2i(-heading.y, heading.x)
    var right_heading := Vector2i(heading.y, -heading.x)
    var straight_cells: Array[Vector2i] = []
    for index in range(1, count + 1):
        straight_cells.append(entry + heading * index)
    var left_cells: Array[Vector2i] = []
    var right_cells: Array[Vector2i] = []
    for index in range(1, radius + 1):
        left_cells.append(entry + heading * index)
        right_cells.append(entry + heading * index)
    var turn_cell := entry + heading * radius
    for index in range(1, radius):
        left_cells.append(turn_cell + left_heading * index)
        right_cells.append(turn_cell + right_heading * index)
    templates.append(straight_cells)
    templates.append(left_cells)
    templates.append(right_cells)
    return templates


func _matching_template_index(span: Dictionary) -> int:
    if span.is_empty():
        return -1
    var templates := _template_cells(span)
    if templates.is_empty():
        return -1
    var records: Array[TrackCellRecordScript] = _sequence.get_records()
    var first_index: int = span["first_index"]
    var record_count: int = span["record_count"]
    if first_index < 0 or first_index + record_count > records.size():
        return -1
    for template_index in range(templates.size()):
        var template_cells: Array = templates[template_index]
        if template_cells.size() != record_count:
            continue
        var matches := true
        for index in range(record_count):
            if records[first_index + index].cell != template_cells[index]:
                matches = false
                break
        if matches:
            return template_index
    return -1


func _has_legal_template_alternative(span: Dictionary) -> bool:
    for template_cells in _template_cells(span):
        if _template_candidate_is_legal(span, template_cells):
            return true
    return false


func _template_candidate_is_legal(span: Dictionary, template_cells: Array[Vector2i]) -> bool:
    if span.is_empty() or template_cells.size() != span["record_count"]:
        return false
    var records: Array[TrackCellRecordScript] = _sequence.get_records()
    var first_index: int = span["first_index"]
    var last_index: int = span["last_index"]
    if first_index < 0 or last_index >= records.size() or last_index - first_index + 1 != template_cells.size():
        return false
    var differs_from_origin := false
    for index in range(template_cells.size()):
        if records[first_index + index].cell != template_cells[index]:
            differs_from_origin = true
            break
    if not differs_from_origin:
        return false
    for index in range(template_cells.size()):
        records[first_index + index].cell = template_cells[index]
    var occupied: Dictionary = {}
    var active_predecessor := _sequence.get_active_predecessor_cell()
    for index in range(records.size()):
        var record = records[index]
        if not _cell_in_grid(record.cell) or occupied.has(record.cell):
            return false
        occupied[record.cell] = true
        var predecessor: Vector2i = active_predecessor if index == 0 else records[index - 1].cell
        if absi(record.cell.x - predecessor.x) + absi(record.cell.y - predecessor.y) != 1:
            return false
    var candidate_ledger = _duplicate_pieces(_locked_ledger)
    var candidate_anchors = _duplicate_anchors(_anchors)
    var resolution = _resolver.resolve(
        active_predecessor,
        records,
        _blocking_ledger_for_resolution(
            candidate_ledger, _recovered_cells_by_piece
        ),
        candidate_anchors,
        _grid_origin_units,
        _grid_size,
        _cell_size_units
    )
    if not resolution.is_valid or not _pieces_are_continuous(resolution.pieces):
        return false
    for record in records:
        var owner_count := 0
        var owner = null
        for piece in resolution.pieces:
            if piece.contains_serial(record.route_serial):
                owner_count += 1
                owner = piece
        if owner_count != 1 or owner == null:
            return false
    for locked in _locked_ledger:
        var matched := false
        for piece in resolution.pieces:
            if (
                piece.locked
                and piece.first_route_serial == locked.first_route_serial
                and piece.last_route_serial == locked.last_route_serial
                and piece.exit_support_route_serial == locked.exit_support_route_serial
            ):
                matched = true
                break
        if not matched:
            return false
    return _sequence.get_available_track_cells() >= 0


func _piece_containing_serial(route_serial: int):
    for piece in _pieces:
        if piece.contains_serial(route_serial):
            return piece
    return null


func _gesture_template_mutation_is_safe() -> bool:
    if _gesture_editable_span.is_empty() or _gesture_origin_sequence == null:
        return false
    var first_serial: int = _gesture_editable_span["first_route_serial"]
    var last_serial: int = _gesture_editable_span["last_route_serial"]
    var saw_origin_record := false
    for record in _gesture_origin_sequence.get_records():
        if record.route_serial < first_serial or record.route_serial > last_serial:
            continue
        saw_origin_record = true
        var owner = null
        var owner_count := 0
        for piece in _gesture_origin_pieces:
            if piece.contains_serial(record.route_serial):
                owner = piece
                owner_count += 1
        if record.geometry_locked or owner_count != 1 or owner == null or owner.locked:
            return false
    if not saw_origin_record:
        return false
    for locked in _gesture_origin_locked_ledger:
        if locked.last_route_serial < first_serial or locked.first_route_serial > last_serial:
            continue
        return false
    return true


func _gesture_origin_observation() -> Dictionary:
    if not _gesture_active or _gesture_origin_sequence == null:
        return {}
    return {
        "route_records": _gesture_origin_sequence.get_records(),
        "pieces": _duplicate_pieces(_gesture_origin_pieces),
        "locked_ledger": _duplicate_pieces(_gesture_origin_locked_ledger),
        "anchors": _duplicate_anchors(_gesture_origin_anchors),
        "recovery": {
            "recovered_cells_by_piece": _gesture_origin_recovered_cells_by_piece.duplicate(true),
            "recovered_end_distance_cells": _gesture_origin_recovered_end_distance_cells,
        },
        "construction": _gesture_origin_sequence.get_records(),
        "inventory": _gesture_origin_sequence.get_available_track_cells(),
        "contact_observations": _gesture_origin_contacts.duplicate(true),
        "editable_span": _gesture_editable_span.duplicate(true),
        "targets": _gesture_target_endpoints.duplicate(true),
    }


func _clear_gesture_state() -> void:
    _gesture_active = false
    _gesture_origin_sequence = null
    _gesture_origin_pieces.clear()
    _gesture_origin_locked_ledger.clear()
    _gesture_origin_anchors.clear()
    _gesture_origin_recovered_cells_by_piece.clear()
    _gesture_origin_recovered_end_distance_cells = 0.0
    _gesture_origin_contacts.clear()
    _gesture_editable_span.clear()
    _gesture_target_endpoints.clear()
    _gesture_selected_template_index = -1
    _gesture_suffix_input_facts.clear()
    _gesture_ordinary_input_facts.clear()
    _gesture_template_selection_signature_valid = false
    _gesture_template_selection_signature_path.clear()
    _gesture_template_selection_signature_pointer = Vector2i(-1, -1)
    _gesture_live_warp_latches.clear()
    _gesture_latched_suffix_input_facts.clear()
    _gesture_preexisting_nonendpoint_anchor_ids.clear()
    _gesture_press_anchor_ids.clear()
    _last_gesture_rejection.clear()


func _resolve_records():
    return _resolve_candidate(
        _sequence,
        _locked_ledger,
        _anchors,
        _recovered_cells_by_piece
    )


func _duplicate_anchors(source: Array[RouteContactAnchorScript]) -> Array[RouteContactAnchorScript]:
    var copies: Array[RouteContactAnchorScript] = []
    for anchor in source:
        copies.append(anchor.duplicate_anchor())
    return copies


func _duplicate_pieces(source: Array[TrackGeometryPieceScript]) -> Array[TrackGeometryPieceScript]:
    var copies: Array[TrackGeometryPieceScript] = []
    for piece in source:
        copies.append(piece.duplicate_piece())
    return copies


func _resolve_candidate(
    sequence: TrackCellSequenceScript,
    ledger: Array[TrackGeometryPieceScript],
    anchors: Array[RouteContactAnchorScript],
    recovered_cells_by_piece: Dictionary
) -> RefCounted:
    var blocking_ledger = _blocking_ledger_for_resolution(
        ledger, recovered_cells_by_piece
    )
    var resolution = _resolver.resolve(
        sequence.get_active_predecessor_cell(),
        sequence.get_records(),
        blocking_ledger,
        anchors,
        _grid_origin_units,
        _grid_size,
        _cell_size_units
    )
    if resolution.is_valid:
        for resolved_piece in resolution.pieces:
            if not resolved_piece.locked:
                continue
            for source_piece in ledger:
                if (
                    resolved_piece.group_id == source_piece.group_id
                    and resolved_piece.first_route_serial == source_piece.first_route_serial
                    and resolved_piece.last_route_serial == source_piece.last_route_serial
                ):
                    resolved_piece.footprint_cells = source_piece.footprint_cells.duplicate()
                    break
    return resolution


func _blocking_ledger_for_resolution(
    ledger: Array[TrackGeometryPieceScript],
    recovered_cells_by_piece: Dictionary
) -> Array[TrackGeometryPieceScript]:
    var blocking_ledger = _duplicate_pieces(ledger)
    for piece in blocking_ledger:
        var recovered_cells: Dictionary = recovered_cells_by_piece.get(
            _piece_key(piece), {}
        )
        for cell in recovered_cells:
            piece.footprint_cells.erase(cell)
    return blocking_ledger


func _replace_pieces(source: Array) -> void:
    _pieces.clear()
    for piece in source:
        _pieces.append(piece.duplicate_piece())
    _assign_unique_unlocked_group_ids(_pieces, _locked_ledger)
    _sequence.apply_resolved_geometry(_pieces)


func _assign_unique_unlocked_group_ids(
    pieces: Array[TrackGeometryPieceScript],
    ledger: Array[TrackGeometryPieceScript]
) -> void:
    var next_group_id := _next_ledger_group_id(ledger)
    for piece in pieces:
        if piece.locked:
            continue
        piece.group_id = next_group_id
        next_group_id += 1


func _next_ledger_group_id(ledger: Array[TrackGeometryPieceScript]) -> int:
    var next_group_id := 0
    for locked in ledger:
        next_group_id = maxi(next_group_id, locked.group_id + 1)
    return next_group_id


func _exit_support_serial(
    piece: TrackGeometryPieceScript,
    records: Array[TrackCellRecordScript]
) -> int:
    for index in range(records.size()):
        if records[index].route_serial != piece.last_route_serial:
            continue
        if index + 1 < records.size():
            return records[index + 1].route_serial
        return -1
    return -1


func _gesture_candidate_can_finalize(
    sequence: TrackCellSequenceScript,
    ledger: Array[TrackGeometryPieceScript],
    anchors: Array[RouteContactAnchorScript]
) -> bool:
    var final_sequence = sequence.duplicate_sequence()
    var final_ledger = _duplicate_pieces(ledger)
    var final_anchors = _duplicate_anchors(anchors)
    var final_resolution = _stage_stable_retirement(
        final_sequence,
        final_ledger,
        final_anchors,
        _gesture_origin_recovered_cells_by_piece
    )
    if not final_resolution.is_valid or not _pieces_are_continuous(final_resolution.pieces):
        return false
    _assign_unique_unlocked_group_ids(final_resolution.pieces, final_ledger)
    final_sequence.apply_resolved_geometry(final_resolution.pieces)
    return _validate_candidate(
        final_sequence,
        final_ledger,
        final_resolution,
        _gesture_origin_recovered_cells_by_piece,
        _gesture_origin_recovered_end_distance_cells
    )


func _stage_stable_retirement(
    sequence: TrackCellSequenceScript,
    ledger: Array[TrackGeometryPieceScript],
    anchors: Array[RouteContactAnchorScript],
    recovered_cells_by_piece: Dictionary
) -> RefCounted:
    _last_stage_rejection_reason = StringName()
    var resolution = _resolve_candidate(
        sequence, ledger, anchors, recovered_cells_by_piece
    )
    if not resolution.is_valid:
        _last_stage_rejection_reason = resolution.reason
        return TrackGeometryResolutionScript.rejected(-1, &"candidate_resolution")
    if not _pieces_are_continuous(resolution.pieces):
        _last_stage_rejection_reason = &"candidate_continuity"
        return TrackGeometryResolutionScript.rejected(-1, &"candidate_resolution")
    var records: Array[TrackCellRecordScript] = sequence.get_records()
    while true:
        var retire_index := _stable_retirement_index(resolution.pieces, records)
        if retire_index < 0:
            return resolution
        var ledger_piece = resolution.pieces[retire_index].duplicate_piece()
        ledger_piece.group_id = _next_ledger_group_id(ledger)
        ledger_piece.locked = true
        ledger_piece.exit_support_route_serial = _exit_support_serial(ledger_piece, records)
        if (
            ledger_piece.exit_support_route_serial >= 0
            and ledger_piece.exit_support_route_serial <= ledger_piece.last_route_serial
        ):
            _last_stage_rejection_reason = &"invalid_exit_support"
            return TrackGeometryResolutionScript.rejected(-1, &"invalid_exit_support")
        ledger.append(ledger_piece)
        resolution = _resolve_candidate(
            sequence, ledger, anchors, recovered_cells_by_piece
        )
        if not resolution.is_valid:
            _last_stage_rejection_reason = resolution.reason
            return TrackGeometryResolutionScript.rejected(-1, &"retirement_resolution")
        if not _pieces_are_continuous(resolution.pieces):
            _last_stage_rejection_reason = &"retirement_continuity"
            return TrackGeometryResolutionScript.rejected(-1, &"retirement_resolution")
    return resolution


func _stable_retirement_index(
    pieces: Array[TrackGeometryPieceScript],
    records: Array[TrackCellRecordScript]
) -> int:
    if pieces.is_empty() or records.is_empty():
        return -1
    var endpoint_serial: int = records[-1].route_serial
    var endpoint_index := -1
    for index in range(pieces.size()):
        if pieces[index].contains_serial(endpoint_serial):
            endpoint_index = index
            break
    if endpoint_index < 0:
        return -1
    var retained_indices: Dictionary = {endpoint_index: true}
    var endpoint = pieces[endpoint_index]
    if not endpoint.locked:
        var support_count := 0
        if endpoint.kind != TrackGeometryPieceScript.Kind.STRAIGHT:
            support_count = maxi(0, 3 - int(endpoint.kind))
        else:
            support_count = 2
        if support_count > 0:
            for index in range(endpoint_index - 1, -1, -1):
                var support = pieces[index]
                if support.locked or support.kind != TrackGeometryPieceScript.Kind.STRAIGHT:
                    break
                retained_indices[index] = true
                support_count -= 1
                if support_count <= 0:
                    break
    for index in range(endpoint_index):
        if not pieces[index].locked and not retained_indices.has(index):
            return index
    return -1


func _validate_candidate(
    sequence: TrackCellSequenceScript,
    ledger: Array[TrackGeometryPieceScript],
    resolution: RefCounted,
    recovered_cells_by_piece: Dictionary = {},
    recovered_end_distance_cells := 0.0
) -> bool:
    if not resolution.is_valid or not _pieces_are_continuous(resolution.pieces):
        return false
    var records: Array[TrackCellRecordScript] = sequence.get_records()
    var saw_provisional := false
    var active_group_ids: Dictionary = {}
    for piece in resolution.pieces:
        if active_group_ids.has(piece.group_id):
            return false
        active_group_ids[piece.group_id] = true
        if piece.locked:
            if saw_provisional:
                return false
        else:
            saw_provisional = true
    for record in records:
        var owner_count := 0
        var owner = null
        for piece in resolution.pieces:
            if piece.contains_serial(record.route_serial):
                owner_count += 1
                owner = piece
        if (
            owner_count != 1
            or owner == null
            or record.geometry_group_id != owner.group_id
            or record.geometry_locked != owner.locked
        ):
            return false
    for locked in ledger:
        var matched_piece = null
        var match_count := 0
        for piece in resolution.pieces:
            if (
                piece.locked
                and piece.first_route_serial == locked.first_route_serial
                and piece.last_route_serial == locked.last_route_serial
            ):
                matched_piece = piece
                match_count += 1
        if match_count != 1 or matched_piece == null:
            return false
        if matched_piece.exit_support_route_serial != locked.exit_support_route_serial:
            return false
        if locked.exit_support_route_serial >= 0:
            var support_exists := false
            for record in records:
                if record.route_serial == locked.exit_support_route_serial:
                    support_exists = true
                    break
            var recovered_support: Dictionary = recovered_cells_by_piece.get(
                _piece_key(locked), {}
            )
            if not support_exists and recovered_support.is_empty():
                return false
    for key in recovered_cells_by_piece:
        var has_active_ledger_piece := false
        for locked in ledger:
            if _piece_key(locked) == key:
                has_active_ledger_piece = true
                break
        if not has_active_ledger_piece:
            return false
    if recovered_end_distance_cells < 0.0:
        return false
    if not records.is_empty() and recovered_end_distance_cells > records[0].route_distance_start_cells:
        return false
    return sequence.is_conservation_valid()


func _commit_candidate(
    sequence: TrackCellSequenceScript,
    ledger: Array[TrackGeometryPieceScript],
    resolution: RefCounted
) -> void:
    _sequence.replace_with(sequence)
    _locked_ledger = _duplicate_pieces(ledger)
    _pieces = _duplicate_pieces(resolution.pieces)


func _stage_active_gesture_train_safety_origin(
    candidate_sequence: TrackCellSequenceScript,
    candidate_ledger: Array[TrackGeometryPieceScript]
) -> Dictionary:
    if not _gesture_active or _gesture_origin_sequence == null:
        return {}
    var origin_sequence := _gesture_origin_sequence.duplicate_sequence()
    var origin_ledger := _duplicate_pieces(candidate_ledger)
    var origin_resolution = _resolve_candidate(
        origin_sequence,
        origin_ledger,
        _gesture_origin_anchors,
        _gesture_origin_recovered_cells_by_piece
    )
    if not origin_resolution.is_valid or not _pieces_are_continuous(origin_resolution.pieces):
        return {}
    _assign_unique_unlocked_group_ids(origin_resolution.pieces, origin_ledger)
    origin_sequence.apply_resolved_geometry(origin_resolution.pieces)
    var origin_contacts := _build_contact_observations(
        origin_resolution.pieces,
        _gesture_origin_anchors,
        _gesture_origin_recovered_cells_by_piece,
        origin_sequence.get_records()
    )
    return {
        "sequence": origin_sequence,
        "ledger": origin_ledger,
        "pieces": _duplicate_pieces(origin_resolution.pieces),
        "contacts": origin_contacts.duplicate(true),
        "next_route_serial": maxi(
            origin_sequence._next_route_serial,
            candidate_sequence._next_route_serial
        ),
    }


func _apply_active_gesture_train_safety_origin(staged_origin: Dictionary) -> void:
    if not _gesture_active or staged_origin.is_empty():
        return
    _gesture_origin_sequence = staged_origin["sequence"]
    _gesture_origin_locked_ledger = _duplicate_pieces(staged_origin["ledger"])
    _gesture_origin_pieces = _duplicate_pieces(staged_origin["pieces"])
    _gesture_origin_sequence._next_route_serial = maxi(
        _gesture_origin_sequence._next_route_serial,
        int(staged_origin["next_route_serial"])
    )
    _gesture_origin_contacts = staged_origin["contacts"].duplicate(true)


func _advance_gesture_serial_watermark(candidate_sequence: TrackCellSequenceScript) -> void:
    if _gesture_origin_sequence == null:
        return
    _gesture_origin_sequence._next_route_serial = maxi(
        _gesture_origin_sequence._next_route_serial,
        candidate_sequence._next_route_serial
    )


func _append_new_gesture_input_fact(
    existing: Array[Dictionary],
    cell: Vector2i
) -> Array[Dictionary]:
    var facts: Array[Dictionary] = existing.duplicate(true)
    var next_serial: int = _gesture_origin_sequence._next_route_serial
    if not facts.is_empty():
        next_serial = maxi(next_serial, int(facts[-1]["serial"]) + 1)
    facts.append({"serial": next_serial, "cell": cell})
    return facts


func _append_gesture_input_facts(
    sequence: TrackCellSequenceScript,
    facts: Array[Dictionary]
) -> bool:
    var watermark: int = sequence._next_route_serial
    for fact in facts:
        var serial: int = fact["serial"]
        var cell: Vector2i = fact["cell"]
        sequence._next_route_serial = serial
        var appended = sequence.try_append_candidate(cell)
        if appended == null or appended.route_serial != serial:
            return false
    sequence._next_route_serial = maxi(watermark, sequence._next_route_serial)
    return true


func _first_unbuilt_record():
    for record in _sequence.get_records():
        if record.state != TrackCellRecordScript.State.BUILT:
            return record
    return null


func _prune_locked_ledger_in(
    ledger: Array[TrackGeometryPieceScript],
    records: Array,
    recovered_cells_by_piece: Dictionary
) -> void:
    for index in range(ledger.size() - 1, -1, -1):
        var survives := false
        for record in records:
            if ledger[index].contains_serial(record.route_serial):
                survives = true
                break
        if not survives:
            recovered_cells_by_piece.erase(_piece_key(ledger[index]))
            ledger.remove_at(index)


func _remember_recovered_piece_cell_in(
    ledger: Array[TrackGeometryPieceScript],
    recovered_cells_by_piece: Dictionary,
    record
) -> void:
    for locked in ledger:
        if locked.contains_serial(record.route_serial):
            var key := _piece_key(locked)
            if not recovered_cells_by_piece.has(key):
                recovered_cells_by_piece[key] = {}
            recovered_cells_by_piece[key][record.cell] = true
            return


func _piece_key(piece) -> String:
    return "%d:%d" % [piece.first_route_serial, piece.last_route_serial]


func _pieces_are_continuous(pieces: Array) -> bool:
    for index in range(pieces.size() - 1):
        if pieces[index].centerline.is_empty() or pieces[index + 1].centerline.is_empty():
            return false
        if not pieces[index].centerline[-1].is_equal_approx(pieces[index + 1].centerline[0]):
            return false
    return true


func _canonical_distance_and_owner(route_distance: float) -> Dictionary:
    for piece in _pieces:
        var boundary := piece.absolute_start_distance_cells + float(piece.nominal_length_cells)
        if (
            route_distance >= boundary - NOMINAL_BOUNDARY_EPSILON
            and route_distance <= boundary + NOMINAL_BOUNDARY_EPSILON
        ):
            return {"distance": boundary, "piece": piece}
    for piece in _pieces:
        var local_distance: float = route_distance - piece.absolute_start_distance_cells
        if (
            local_distance >= 0.0
            and local_distance <= float(piece.nominal_length_cells)
        ):
            return {"distance": route_distance, "piece": piece}
    return {"distance": route_distance, "piece": null}


func _refresh_contact_observations() -> void:
    _contact_observations = _build_contact_observations(
        _pieces,
        _anchors,
        _recovered_cells_by_piece,
        _sequence.get_records()
    )


func _build_contact_observations(
    pieces: Array[TrackGeometryPieceScript],
    anchors: Array[RouteContactAnchorScript],
    recovered_cells_by_piece: Dictionary,
    route_records: Array = []
) -> Array[Dictionary]:
    var observations: Array[Dictionary] = []
    var records := route_records
    for anchor in anchors:
        var contacted := false
        var contact_distance := -1.0
        if anchor.contact_mode == RouteContactAnchorScript.ContactMode.EXACT_CELL_CENTER:
            var exact_fact := _exact_anchor_contact_fact(
                pieces, records, anchor.cell, recovered_cells_by_piece
            )
            contacted = exact_fact.get("contact_possible", false)
            contact_distance = exact_fact.get("contact_distance_cells", -1.0)
        else:
            for piece in pieces:
                if _active_piece_contacts_cell(piece, anchor.cell, recovered_cells_by_piece):
                    contacted = true
                    break
        observations.append({
            "anchor_id": anchor.anchor_id,
            "cell": anchor.cell,
            "contact_possible": contacted,
            "contacted": contacted,
            "contact_mode": anchor.contact_mode,
            "contact_distance_cells": contact_distance,
        })
    return observations


func _exact_anchor_contact_fact(
    pieces: Array[TrackGeometryPieceScript],
    records: Array,
    cell: Vector2i,
    recovered_cells_by_piece: Dictionary
) -> Dictionary:
    var required_serial := -1
    for record in records:
        if record.cell == cell:
            required_serial = record.route_serial
            break
    if required_serial < 0 and cell != _departure_cell:
        return {"contact_possible": false, "contact_distance_cells": -1.0}
    var target := _grid_origin_units + (Vector2(cell) + Vector2(0.5, 0.5)) * _cell_size_units
    for piece in pieces:
        if required_serial >= 0 and not piece.contains_serial(required_serial):
            continue
        var recovered_cells: Dictionary = recovered_cells_by_piece.get(_piece_key(piece), {})
        if recovered_cells.has(cell):
            continue
        var local_distance: float = piece.find_nominal_distance_at_position(
            target, EXACT_CONTACT_POSITION_EPSILON_UNITS
        )
        if (
            local_distance < 0.0
            or local_distance < piece.active_local_start_cells - NOMINAL_BOUNDARY_EPSILON
            or local_distance > piece.active_local_end_cells + NOMINAL_BOUNDARY_EPSILON
        ):
            continue
        return {
            "contact_possible": true,
            "contact_distance_cells": piece.absolute_start_distance_cells + local_distance,
        }
    return {"contact_possible": false, "contact_distance_cells": -1.0}


func _active_piece_contacts_cell(
    piece,
    cell: Vector2i,
    recovered_cells_by_piece: Dictionary = _recovered_cells_by_piece
) -> bool:
    var recovered_cells: Dictionary = recovered_cells_by_piece.get(_piece_key(piece), {})
    if recovered_cells.has(cell):
        return false
    return piece.contacts_cell_in_nominal_range(
        cell,
        _grid_origin_units,
        _cell_size_units,
        piece.active_local_start_cells,
        piece.active_local_end_cells,
        CONTACT_SAMPLES_PER_CELL
    )


func _active_route_cell_at_distance(route_distance_cells: float) -> Dictionary:
    var canonical := _canonical_distance_and_owner(route_distance_cells)
    var piece = canonical.piece
    if piece == null or not piece.locked:
        return {}
    var local_distance: float = canonical.distance - piece.absolute_start_distance_cells
    if (
        local_distance < piece.active_local_start_cells
        or local_distance > piece.active_local_end_cells
    ):
        return {}
    var position: Vector2 = piece.sample_nominal(local_distance).position
    var cell := _map_position_to_cell(position)
    var recovered_cells: Dictionary = _recovered_cells_by_piece.get(_piece_key(piece), {})
    if recovered_cells.has(cell):
        return {}
    return {"cell": cell}


func _append_contact_hits_for_transition(
    contact_distance_cells: float,
    previous_cell: Dictionary,
    current_cell: Dictionary,
    anchors_by_id: Dictionary,
    emitted_anchor_ids: Dictionary,
    hits: Array[Dictionary]
) -> void:
    if current_cell.is_empty():
        return
    if not previous_cell.is_empty() and previous_cell["cell"] == current_cell["cell"]:
        return
    for anchor_id in anchors_by_id:
        if emitted_anchor_ids.has(anchor_id):
            continue
        var anchor: RouteContactAnchorScript = anchors_by_id[anchor_id]
        if anchor.cell != current_cell["cell"]:
            continue
        hits.append({
            "anchor_id": anchor.anchor_id,
            "cell": anchor.cell,
            "contact_distance_cells": contact_distance_cells,
        })
        emitted_anchor_ids[anchor_id] = true


func _contact_hit_less(first: Dictionary, second: Dictionary) -> bool:
    var first_distance: float = first["contact_distance_cells"]
    var second_distance: float = second["contact_distance_cells"]
    if first_distance != second_distance:
        return first_distance < second_distance
    return String(first["anchor_id"]) < String(second["anchor_id"])


func _map_position_to_cell(position: Vector2) -> Vector2i:
    return Vector2i(
        int(floor((position.x - _grid_origin_units.x) / _cell_size_units)),
        int(floor((position.y - _grid_origin_units.y) / _cell_size_units))
    )
