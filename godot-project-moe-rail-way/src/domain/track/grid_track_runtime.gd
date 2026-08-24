class_name GridTrackRuntime
extends RefCounted

const TrackCellSequenceScript = preload("res://src/domain/track/track_cell_sequence.gd")
const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")
const TrackGeometryResolverScript = preload("res://src/domain/track/track_geometry_resolver.gd")

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
        var tentative = _sequence.try_append_candidate(cell)
        if tentative == null:
            break
        var resolution = _resolve_records()
        if not resolution.is_valid or not _pieces_are_continuous(resolution.pieces):
            _sequence.rollback_last_unlocked_ghost(tentative.route_serial)
            break
        _replace_pieces(resolution.pieces)
        accepted_count += 1
    _refresh_contact_observations()
    return accepted_count


func cancel_ghost_suffix(cell: Vector2i) -> bool:
    if _sequence.cancel_ghost_suffix(cell) <= 0:
        return false
    var resolution = _resolve_records()
    if resolution.is_valid:
        _replace_pieces(resolution.pieces)
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
            _lock_piece_for_serial(target.route_serial)
            _sequence.start_building(target.route_serial)
        var consumed: float = _sequence.add_build_progress(remaining)
        if consumed <= 0.0:
            break
        consumed_total += consumed
        remaining -= consumed
        _sequence.complete_building()
    return consumed_total


func recover_behind(cutoff_distance_cells: float) -> int:
    var recovered: Array = _sequence.recover_eligible_cells(cutoff_distance_cells)
    if recovered.is_empty():
        return 0
    for record in recovered:
        _remember_recovered_piece_cell(record)
        _recovered_end_distance_cells = maxf(
            _recovered_end_distance_cells,
            record.route_distance_start_cells + 1.0
        )
    _prune_locked_ledger(_sequence.get_records())
    var resolution = _resolve_records()
    if resolution.is_valid:
        _replace_pieces(resolution.pieces)
    _refresh_contact_observations()
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


func get_position_at_distance_cells(route_distance_cells: float) -> Vector2:
    var sample := _sample_at_distance(route_distance_cells)
    return sample.position


func get_heading_at_distance_cells(route_distance_cells: float) -> Vector2:
    var sample := _sample_at_distance(route_distance_cells)
    return sample.heading


func get_contact_observations() -> Array[Dictionary]:
    return _contact_observations.duplicate(true)


func _resolve_records():
    return _resolver.resolve(
        _sequence.get_active_predecessor_cell(),
        _sequence.get_records(),
        _locked_ledger,
        _anchors,
        _grid_origin_units,
        _grid_size,
        _cell_size_units
    )


func _replace_pieces(source: Array) -> void:
    _pieces.clear()
    for piece in source:
        _pieces.append(piece.duplicate_piece())
    _assign_unique_unlocked_group_ids()
    _sequence.apply_resolved_geometry(_pieces)


func _assign_unique_unlocked_group_ids() -> void:
    var next_group_id := 0
    for locked in _locked_ledger:
        next_group_id = maxi(next_group_id, locked.group_id + 1)
    for piece in _pieces:
        if piece.locked:
            continue
        piece.group_id = next_group_id
        next_group_id += 1


func _first_unbuilt_record():
    for record in _sequence.get_records():
        if record.state != TrackCellRecordScript.State.BUILT:
            return record
    return null


func _lock_piece_for_serial(route_serial: int) -> void:
    var source = null
    for piece in _pieces:
        if piece.contains_serial(route_serial):
            source = piece
            break
    if source == null:
        return
    for locked in _locked_ledger:
        if (
            locked.first_route_serial == source.first_route_serial
            and locked.last_route_serial == source.last_route_serial
        ):
            source.locked = true
            return
    var ledger_piece = source.duplicate_piece()
    ledger_piece.locked = true
    _locked_ledger.append(ledger_piece)
    source.locked = true


func _prune_locked_ledger(records: Array) -> void:
    for index in range(_locked_ledger.size() - 1, -1, -1):
        var survives := false
        for record in records:
            if _locked_ledger[index].contains_serial(record.route_serial):
                survives = true
                break
        if not survives:
            _recovered_cells_by_piece.erase(_piece_key(_locked_ledger[index]))
            _locked_ledger.remove_at(index)


func _remember_recovered_piece_cell(record) -> void:
    for locked in _locked_ledger:
        if locked.contains_serial(record.route_serial):
            var key := _piece_key(locked)
            if not _recovered_cells_by_piece.has(key):
                _recovered_cells_by_piece[key] = {}
            _recovered_cells_by_piece[key][record.cell] = true
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


func _sample_at_distance(route_distance_cells: float) -> Dictionary:
    for piece in _locked_ledger:
        var locked_local_distance: float = route_distance_cells - piece.absolute_start_distance_cells
        if (
            locked_local_distance >= -0.0001
            and locked_local_distance <= float(piece.nominal_length_cells) + 0.0001
        ):
            return piece.sample_nominal(locked_local_distance)
    for piece in _pieces:
        var local_distance: float = route_distance_cells - piece.absolute_start_distance_cells
        if (
            local_distance >= piece.active_local_start_cells - 0.0001
            and local_distance <= piece.active_local_end_cells + 0.0001
        ):
            return piece.sample_nominal(local_distance)
    return {
        "position": _grid_origin_units + (Vector2(_departure_cell) + Vector2(0.5, 0.5)) * _cell_size_units,
        "heading": Vector2.RIGHT,
    }


func _refresh_contact_observations() -> void:
    _contact_observations.clear()
    for anchor in _anchors:
        var contacted := false
        for piece in _pieces:
            if _active_piece_contacts_cell(piece, anchor.cell):
                contacted = true
                break
        _contact_observations.append({
            "anchor_id": anchor.anchor_id,
            "cell": anchor.cell,
            "contact_possible": contacted,
            "contacted": contacted,
        })


func _active_piece_contacts_cell(piece, cell: Vector2i) -> bool:
    var recovered_cells: Dictionary = _recovered_cells_by_piece.get(_piece_key(piece), {})
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
