class_name GridTrackRuntime
extends RefCounted

const TrackCellSequenceScript = preload("res://src/domain/track/track_cell_sequence.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackGeometryResolverScript = preload("res://src/domain/track/track_geometry_resolver.gd")
const TrackGeometryResolutionScript = preload("res://src/domain/track/track_geometry_resolution.gd")

const NOMINAL_BOUNDARY_EPSILON := 0.0001
const NOMINAL_BOUNDARY_FLOAT_TOLERANCE := 0.0000002

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


func append_cells(cells: Array[Vector2i]) -> int:
    var accepted_count := 0
    for cell in cells:
        var candidate_sequence = _sequence.duplicate_sequence()
        var tentative = candidate_sequence.try_append_candidate(cell)
        if tentative == null:
            break
        var candidate_ledger = _duplicate_pieces(_locked_ledger)
        var candidate_anchors = _duplicate_anchors(_anchors)
        var resolution = _stage_horizon(candidate_sequence, candidate_ledger, candidate_anchors)
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
    var resolution = _stage_horizon(candidate_sequence, candidate_ledger, candidate_anchors)
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
    _anchors.clear()
    for anchor in anchors:
        _anchors.append(anchor.duplicate_anchor())
    var resolution = _resolve_records()
    if resolution.is_valid:
        _replace_pieces(resolution.pieces)
    _refresh_contact_observations()


func advance_construction(progress_cells: float) -> float:
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
    _commit_candidate(candidate_sequence, candidate_ledger, resolution)
    _refresh_contact_observations()
    return true


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


func _count_provisional_records(
    pieces: Array[TrackGeometryPieceScript],
    records: Array[TrackCellRecordScript]
) -> int:
    var count := 0
    for record in records:
        for piece in pieces:
            if piece.contains_serial(record.route_serial):
                if not piece.locked:
                    count += 1
                break
    return count


func _earliest_provisional_piece(
    pieces: Array[TrackGeometryPieceScript]
) -> TrackGeometryPieceScript:
    for piece in pieces:
        if not piece.locked:
            return piece
    return null


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


func _stage_horizon(
    sequence: TrackCellSequenceScript,
    ledger: Array[TrackGeometryPieceScript],
    anchors: Array[RouteContactAnchorScript]
) -> RefCounted:
    var resolution = _resolve_candidate(sequence, ledger, anchors)
    if not resolution.is_valid or not _pieces_are_continuous(resolution.pieces):
        return TrackGeometryResolutionScript.rejected(-1, &"candidate_resolution")
    var records: Array[TrackCellRecordScript] = sequence.get_records()
    var provisional_count := _count_provisional_records(resolution.pieces, records)
    while provisional_count > 5:
        var earliest = _earliest_provisional_piece(resolution.pieces)
        if earliest == null:
            return TrackGeometryResolutionScript.rejected(-1, &"missing_provisional_piece")
        var ledger_piece = earliest.duplicate_piece()
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
            return TrackGeometryResolutionScript.rejected(-1, &"horizon_resolution")
        provisional_count = _count_provisional_records(resolution.pieces, records)
    return resolution


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
    if _count_provisional_records(resolution.pieces, records) > 5:
        return false
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
        if absf(route_distance - boundary) <= NOMINAL_BOUNDARY_EPSILON + NOMINAL_BOUNDARY_FLOAT_TOLERANCE:
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
