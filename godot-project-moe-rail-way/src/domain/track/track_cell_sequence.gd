class_name TrackCellSequence
extends RefCounted

const TrackCellRecordScript = preload("res://src/domain/track/track_cell_record.gd")
const TrackGeometryPieceScript = preload("res://src/domain/track/track_geometry_piece.gd")

var _departure_cell: Vector2i
var _total_track_cells: int
var _available_track_cells: int
var _records: Array[TrackCellRecordScript] = []
var _active_cells: Dictionary = {}
var _next_route_serial := 1
var _next_nominal_start_cells := 0.0
var _active_predecessor_cell: Vector2i


func _init(departure_cell: Vector2i, total_track_cells: int) -> void:
    _departure_cell = departure_cell
    _active_predecessor_cell = departure_cell
    _total_track_cells = total_track_cells
    _available_track_cells = total_track_cells


func try_append_candidate(cell: Vector2i) -> Variant:
    if (
        _available_track_cells <= 0
        or cell == _departure_cell
        or _active_cells.has(cell)
    ):
        return null
    var endpoint := get_endpoint_cell()
    if absi(cell.x - endpoint.x) + absi(cell.y - endpoint.y) != 1:
        return null
    var record = TrackCellRecordScript.new(
        _next_route_serial,
        cell,
        _next_nominal_start_cells
    )
    _records.append(record)
    _active_cells[cell] = true
    _available_track_cells -= 1
    _next_route_serial += 1
    _next_nominal_start_cells += 1.0
    return record.duplicate_record()


func rollback_last_unlocked_ghost(expected_route_serial: int) -> void:
    if _records.is_empty():
        return
    var record = _records[-1]
    if (
        record.route_serial != expected_route_serial
        or record.state != TrackCellRecordScript.State.RESERVED_GHOST
        or record.geometry_locked
    ):
        return
    _records.pop_back()
    _active_cells.erase(record.cell)
    _available_track_cells += 1
    _next_nominal_start_cells = record.route_distance_start_cells


func append_candidates(cells: Array[Vector2i]) -> int:
    var accepted_count := 0
    for cell in cells:
        if try_append_candidate(cell) == null:
            break
        accepted_count += 1
    return accepted_count


func replace_span_in_place(
    first_serial: int,
    last_serial: int,
    new_cells: Array[Vector2i]
) -> bool:
    if first_serial > last_serial or new_cells.size() != last_serial - first_serial + 1:
        return false
    var first_index := -1
    var last_index := -1
    for index in range(_records.size()):
        if _records[index].route_serial == first_serial:
            first_index = index
        if _records[index].route_serial == last_serial:
            last_index = index
    if (
        first_index < 0
        or last_index < first_index
        or last_index - first_index + 1 != new_cells.size()
    ):
        return false
    var occupied: Dictionary = {}
    for index in range(_records.size()):
        if index < first_index or index > last_index:
            occupied[_records[index].cell] = true
    var predecessor: Vector2i = _departure_cell if first_index == 0 else _records[first_index - 1].cell
    for index in range(new_cells.size()):
        var cell: Vector2i = new_cells[index]
        if cell == _departure_cell or occupied.has(cell):
            return false
        if absi(cell.x - predecessor.x) + absi(cell.y - predecessor.y) != 1:
            return false
        occupied[cell] = true
        predecessor = cell
    if last_index + 1 < _records.size():
        var successor: Vector2i = _records[last_index + 1].cell
        if absi(successor.x - predecessor.x) + absi(successor.y - predecessor.y) != 1:
            return false
    for index in range(new_cells.size()):
        _records[first_index + index].cell = new_cells[index]
    _active_cells.clear()
    for record in _records:
        _active_cells[record.cell] = true
    return true


func cancel_ghost_suffix(cell: Vector2i) -> int:
    var target_index := -1
    for index in range(_records.size()):
        if _records[index].cell == cell:
            target_index = index
            break
    if target_index < 0:
        return 0
    for index in range(target_index, _records.size()):
        var record = _records[index]
        if (
            record.state != TrackCellRecordScript.State.RESERVED_GHOST
            or record.geometry_locked
        ):
            return 0
    var removed_count := _records.size() - target_index
    var replacement_distance: float = _records[target_index].route_distance_start_cells
    for index in range(_records.size() - 1, target_index - 1, -1):
        _active_cells.erase(_records[index].cell)
        _records.remove_at(index)
    _available_track_cells += removed_count
    _next_nominal_start_cells = replacement_distance
    if _records.is_empty():
        _active_predecessor_cell = _departure_cell
    return removed_count


func apply_resolved_geometry(pieces: Array[TrackGeometryPieceScript]) -> void:
    for record in _records:
        record.geometry_group_id = -1
        record.geometry_locked = false
        for piece in pieces:
            if piece.contains_serial(record.route_serial):
                record.geometry_group_id = piece.group_id
                record.geometry_locked = piece.locked
                break


func start_building(route_serial: int) -> void:
    for record in _records:
        if record.state == TrackCellRecordScript.State.BUILDING:
            return
    var target = null
    for record in _records:
        if record.route_serial == route_serial:
            target = record
            break
    if (
        target == null
        or target.state != TrackCellRecordScript.State.RESERVED_GHOST
        or target.geometry_group_id < 0
    ):
        return
    target.state = TrackCellRecordScript.State.BUILDING
    target.build_progress = 0.0


func add_build_progress(amount: float) -> float:
    if amount <= 0.0:
        return 0.0
    for record in _records:
        if record.state == TrackCellRecordScript.State.BUILDING:
            var consumed := minf(amount, 1.0 - record.build_progress)
            record.build_progress += consumed
            return consumed
    return 0.0


func complete_building() -> void:
    for record in _records:
        if (
            record.state == TrackCellRecordScript.State.BUILDING
            and record.build_progress >= 1.0
        ):
            record.build_progress = 1.0
            record.state = TrackCellRecordScript.State.BUILT
            return


func recover_eligible_cells(cutoff_distance_cells: float) -> Array[TrackCellRecordScript]:
    var recovered: Array[TrackCellRecordScript] = []
    while not _records.is_empty():
        var record = _records[0]
        if (
            record.state != TrackCellRecordScript.State.BUILT
            or record.route_distance_start_cells + 1.0 > cutoff_distance_cells
        ):
            break
        recovered.append(record.duplicate_record())
        _records.pop_front()
        _active_cells.erase(record.cell)
        _available_track_cells += 1
        _active_predecessor_cell = record.cell
    if _records.is_empty():
        _active_predecessor_cell = _departure_cell
    return recovered


func get_departure_cell() -> Vector2i:
    return _departure_cell


func get_active_predecessor_cell() -> Vector2i:
    return _active_predecessor_cell


func get_endpoint_cell() -> Vector2i:
    if _records.is_empty():
        return _departure_cell
    return _records[-1].cell


func get_records() -> Array[TrackCellRecordScript]:
    var observations: Array[TrackCellRecordScript] = []
    for record in _records:
        observations.append(record.duplicate_record())
    return observations


func get_available_track_cells() -> int:
    return _available_track_cells


func get_total_track_cells() -> int:
    return _total_track_cells


func is_conservation_valid() -> bool:
    return (
        _available_track_cells >= 0
        and _available_track_cells + _records.size() == _total_track_cells
        and _active_cells.size() == _records.size()
    )


func duplicate_sequence() -> TrackCellSequence:
    var copy = get_script().new(_departure_cell, _total_track_cells)
    copy._available_track_cells = _available_track_cells
    copy._next_route_serial = _next_route_serial
    copy._next_nominal_start_cells = _next_nominal_start_cells
    copy._active_predecessor_cell = _active_predecessor_cell
    for record in _records:
        var record_copy = record.duplicate_record()
        copy._records.append(record_copy)
        copy._active_cells[record_copy.cell] = true
    return copy


func replace_with(source: TrackCellSequence) -> void:
    _departure_cell = source._departure_cell
    _total_track_cells = source._total_track_cells
    _available_track_cells = source._available_track_cells
    _next_route_serial = source._next_route_serial
    _next_nominal_start_cells = source._next_nominal_start_cells
    _active_predecessor_cell = source._active_predecessor_cell
    _records.clear()
    _active_cells.clear()
    for record in source._records:
        var record_copy = record.duplicate_record()
        _records.append(record_copy)
        _active_cells[record_copy.cell] = true
