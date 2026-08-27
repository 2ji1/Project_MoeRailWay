class_name GridTrackRuntime
extends RefCounted

const TrackCellSequenceScript = preload("res://src/domain/track/track_cell_sequence.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackGeometryResolverScript = preload("res://src/domain/track/track_geometry_resolver.gd")
const TrackGeometryResolutionScript = preload("res://src/domain/track/track_geometry_resolution.gd")

const NOMINAL_BOUNDARY_EPSILON := 0.0001

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
        if not _cell_in_grid(cell) or cell == _departure_cell:
            continue
        var candidate_sequence = _sequence.duplicate_sequence()
        if candidate_sequence.try_append_candidate(cell) == null:
            continue
        var candidate_ledger = _duplicate_pieces(_locked_ledger)
        var candidate_anchors = _duplicate_anchors(_anchors)
        var resolution = _stage_stable_retirement(
            candidate_sequence,
            candidate_ledger,
            candidate_anchors
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
    _gesture_active = true
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
        candidate_anchors
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
        _recovered_cells_by_piece
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
    current_pointer_cell: Vector2i = Vector2i(-1, -1)
) -> bool:
    if not _gesture_active:
        return false
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
        return false
    else:
        next_ordinary_input_facts = _reconcile_gesture_input_facts(
            _gesture_ordinary_input_facts,
            live_path
        )

    var template_changed := next_template_index != previous_template_index
    if next_template_index >= 0:
        var selected_target_index := -1
        if next_template_index < frame_target_indices.size():
            selected_target_index = frame_target_indices[next_template_index]
        var current_suffix_cells: Array[Vector2i] = []
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
        var existing_suffix_input_facts: Array[Dictionary] = []
        if next_template_index == previous_template_index:
            existing_suffix_input_facts = _gesture_suffix_input_facts
        if template_changed:
            existing_suffix_input_facts = []
        next_suffix_input_facts = _reconcile_gesture_input_facts(
            existing_suffix_input_facts,
            current_suffix_cells
        )
    var candidate_sequence = _gesture_origin_sequence.duplicate_sequence()
    if next_template_index >= 0:
        if not _gesture_template_mutation_is_safe():
            return false
        var template_cells: Array[Vector2i] = []
        for cell in templates[next_template_index]:
            template_cells.append(cell)
        if not candidate_sequence.replace_span_in_place(
            _gesture_editable_span["first_route_serial"],
            _gesture_editable_span["last_route_serial"],
            template_cells
        ):
            return false
        if not _append_gesture_input_facts(candidate_sequence, next_suffix_input_facts):
            return false
    else:
        if not _append_gesture_input_facts(candidate_sequence, next_ordinary_input_facts):
            return false
    var candidate_ledger = _duplicate_pieces(_gesture_origin_locked_ledger)
    var candidate_anchors = _duplicate_anchors(_gesture_origin_anchors)
    var resolution = _resolve_candidate(candidate_sequence, candidate_ledger, candidate_anchors)
    if not resolution.is_valid or not _pieces_are_continuous(resolution.pieces):
        return false
    _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
    candidate_sequence.apply_resolved_geometry(resolution.pieces)
    if not _validate_candidate(candidate_sequence, candidate_ledger, resolution):
        return false
    if not _gesture_candidate_can_finalize(candidate_sequence, candidate_ledger, candidate_anchors):
        return false
    var candidate_contacts := _build_contact_observations(
        resolution.pieces,
        candidate_anchors,
        _gesture_origin_recovered_cells_by_piece
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
    return true


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
        var resolution = _stage_stable_retirement(candidate_sequence, candidate_ledger, candidate_anchors)
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
    var resolution = _stage_stable_retirement(candidate_sequence, candidate_ledger, candidate_anchors)
    if not resolution.is_valid:
        return false
    _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
    candidate_sequence.apply_resolved_geometry(resolution.pieces)
    if not _validate_candidate(candidate_sequence, candidate_ledger, resolution):
        return false
    _commit_candidate(candidate_sequence, candidate_ledger, resolution)
    _refresh_contact_observations()
    return true


func set_contact_anchors(anchors: Array[RouteContactAnchorScript]) -> void:
    var candidate_anchors: Array[RouteContactAnchorScript] = []
    for anchor in anchors:
        candidate_anchors.append(anchor.duplicate_anchor())
    var candidate_sequence = _sequence.duplicate_sequence()
    var candidate_ledger = _duplicate_pieces(_locked_ledger)
    var resolution = _stage_stable_retirement(
        candidate_sequence,
        candidate_ledger,
        candidate_anchors
    )
    if resolution.is_valid:
        _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
        candidate_sequence.apply_resolved_geometry(resolution.pieces)
        if _validate_candidate(
            candidate_sequence,
            candidate_ledger,
            resolution,
            _recovered_cells_by_piece,
            _recovered_end_distance_cells
        ):
            _commit_candidate(candidate_sequence, candidate_ledger, resolution)
    _anchors = candidate_anchors
    _refresh_contact_observations()


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
            if not is_equal_approx(candidate_consumed, origin_consumed):
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
    if _gesture_active:
        return 0
    var candidate_sequence = _sequence.duplicate_sequence()
    var recovered: Array = candidate_sequence.recover_eligible_cells(cutoff_distance_cells)
    if recovered.is_empty():
        return 0
    var candidate_ledger = _duplicate_pieces(_locked_ledger)
    var candidate_recovered_cells_by_piece: Dictionary = _recovered_cells_by_piece.duplicate(true)
    var candidate_recovered_end_distance_cells := _recovered_end_distance_cells
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
    var candidate_anchors = _duplicate_anchors(_anchors)
    var resolution = _resolve_candidate(candidate_sequence, candidate_ledger, candidate_anchors)
    if not resolution.is_valid:
        return 0
    _assign_unique_unlocked_group_ids(resolution.pieces, candidate_ledger)
    candidate_sequence.apply_resolved_geometry(resolution.pieces)
    if not _validate_candidate(
        candidate_sequence,
        candidate_ledger,
        resolution,
        candidate_recovered_cells_by_piece,
        candidate_recovered_end_distance_cells
    ):
        return 0
    var candidate_contacts = _build_contact_observations(
        resolution.pieces,
        candidate_anchors,
        candidate_recovered_cells_by_piece
    )
    _commit_candidate(candidate_sequence, candidate_ledger, resolution)
    _recovered_cells_by_piece = candidate_recovered_cells_by_piece.duplicate(true)
    _recovered_end_distance_cells = candidate_recovered_end_distance_cells
    _contact_observations = candidate_contacts.duplicate(true)
    return recovered.size()


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
    var resolution = _resolve_candidate(candidate_sequence, candidate_ledger, candidate_anchors)
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
        candidate_ledger,
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
    if _gesture_editable_span.is_empty():
        return false
    var first_serial: int = _gesture_editable_span["first_route_serial"]
    var last_serial: int = _gesture_editable_span["last_route_serial"]
    for record in _sequence.get_records():
        if record.route_serial < first_serial or record.route_serial > last_serial:
            continue
        if record.geometry_locked:
            return false
        var owner = _piece_containing_serial(record.route_serial)
        if owner == null or owner.locked:
            return false
    for locked in _locked_ledger:
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


func _resolve_records():
    return _resolve_candidate(_sequence, _locked_ledger, _anchors)


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
    anchors: Array[RouteContactAnchorScript]
) -> RefCounted:
    return _resolver.resolve(
        sequence.get_active_predecessor_cell(),
        sequence.get_records(),
        ledger,
        anchors,
        _grid_origin_units,
        _grid_size,
        _cell_size_units
    )


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
        final_anchors
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
    anchors: Array[RouteContactAnchorScript]
) -> RefCounted:
    var resolution = _resolve_candidate(sequence, ledger, anchors)
    if not resolution.is_valid or not _pieces_are_continuous(resolution.pieces):
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
            return TrackGeometryResolutionScript.rejected(-1, &"invalid_exit_support")
        ledger.append(ledger_piece)
        resolution = _resolve_candidate(sequence, ledger, anchors)
        if not resolution.is_valid or not _pieces_are_continuous(resolution.pieces):
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
            if not support_exists:
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
        _gesture_origin_anchors
    )
    if not origin_resolution.is_valid or not _pieces_are_continuous(origin_resolution.pieces):
        return {}
    _assign_unique_unlocked_group_ids(origin_resolution.pieces, origin_ledger)
    origin_sequence.apply_resolved_geometry(origin_resolution.pieces)
    var origin_contacts := _build_contact_observations(
        origin_resolution.pieces,
        _gesture_origin_anchors,
        _gesture_origin_recovered_cells_by_piece
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
        _recovered_cells_by_piece
    )


func _build_contact_observations(
    pieces: Array[TrackGeometryPieceScript],
    anchors: Array[RouteContactAnchorScript],
    recovered_cells_by_piece: Dictionary
) -> Array[Dictionary]:
    var observations: Array[Dictionary] = []
    for anchor in anchors:
        var contacted := false
        for piece in pieces:
            if _active_piece_contacts_cell(piece, anchor.cell, recovered_cells_by_piece):
                contacted = true
                break
        observations.append({
            "anchor_id": anchor.anchor_id,
            "cell": anchor.cell,
            "contact_possible": contacted,
            "contacted": contacted,
        })
    return observations


func _active_piece_contacts_cell(
    piece,
    cell: Vector2i,
    recovered_cells_by_piece: Dictionary = _recovered_cells_by_piece
) -> bool:
    var recovered_cells: Dictionary = recovered_cells_by_piece.get(_piece_key(piece), {})
    if recovered_cells.has(cell):
        return false
    var local_start: float = piece.active_local_start_cells
    var local_end: float = piece.active_local_end_cells
    if local_end < local_start:
        return false
    var steps := maxi(1, int(ceil((local_end - local_start) * 8.0)))
    for step in range(steps + 1):
        var weight := float(step) / float(steps)
        var local_distance := lerpf(local_start, local_end, weight)
        var position: Vector2 = piece.sample_nominal(local_distance).position
        var mapped := Vector2i(
            int(floor((position.x - _grid_origin_units.x) / _cell_size_units)),
            int(floor((position.y - _grid_origin_units.y) / _cell_size_units))
        )
        if mapped == cell:
            return true
    return false
