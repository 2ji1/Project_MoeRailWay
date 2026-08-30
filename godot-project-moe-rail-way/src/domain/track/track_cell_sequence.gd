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


func try_append_candidate(
    cell: Vector2i,
    allow_grade_separated_crossing: bool = false,
    crossing_partner_route_serial: int = -1
) -> Variant:
    var active_count := get_active_occurrence_count(cell)
    if (
        _available_track_cells <= 0
        or _departure_coordinate_is_reserved(cell)
        or (active_count > 0 and not allow_grade_separated_crossing)
        or active_count > 1
    ):
        return null
    if allow_grade_separated_crossing:
        if active_count != 1 or crossing_partner_route_serial < 0:
            return null
        var partner = get_record_by_serial(crossing_partner_route_serial)
        if (
            partner == null
            or partner.cell != cell
            or partner.grade_separated_crossing
        ):
            return null
    var endpoint := get_endpoint_cell()
    if absi(cell.x - endpoint.x) + absi(cell.y - endpoint.y) != 1:
        return null
    var record = TrackCellRecordScript.new(
        _next_route_serial,
        cell,
        _next_nominal_start_cells,
        TrackCellRecordScript.State.RESERVED_GHOST,
        0.0,
        -1,
        false,
        allow_grade_separated_crossing,
        crossing_partner_route_serial if allow_grade_separated_crossing else -1
    )
    _records.append(record)
    _increment_active_cell(cell)
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
    _decrement_active_cell(record.cell)
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
    if first_serial > last_serial:
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
    for index in range(first_index, last_index + 1):
        if _records[index].grade_separated_crossing:
            return false
    var occupied: Dictionary = {}
    for index in range(_records.size()):
        if index < first_index or index > last_index:
            occupied[_records[index].cell] = true
    var predecessor: Vector2i = _active_predecessor_cell if first_index == 0 else _records[first_index - 1].cell
    for index in range(new_cells.size()):
        var cell: Vector2i = new_cells[index]
        if _departure_coordinate_is_reserved(cell) or occupied.has(cell):
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
        _increment_active_cell(record.cell)
    return true


func _departure_coordinate_is_reserved(cell: Vector2i) -> bool:
    return cell == _departure_cell and _active_predecessor_cell == _departure_cell


func cancel_ghost_suffix(cell: Vector2i) -> int:
    var target_index := -1
    for index in range(_records.size()):
        if _records[index].cell == cell:
            target_index = index
            break
    if target_index < 0:
        return 0
    return cancel_ghost_suffix_from_serial(_records[target_index].route_serial)


func cancel_ghost_suffix_from_serial(route_serial: int) -> int:
    var target_index := -1
    for index in range(_records.size()):
        if _records[index].route_serial == route_serial:
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
        _decrement_active_cell(_records[index].cell)
        _records.remove_at(index)
    _available_track_cells += removed_count
    _next_nominal_start_cells = replacement_distance
    if _records.is_empty():
        _active_predecessor_cell = _departure_cell
    return removed_count


func remove_suffix_from_serial(route_serial: int) -> Array[TrackCellRecordScript]:
    var removed: Array[TrackCellRecordScript] = []
    var target_index := -1
    for index in range(_records.size()):
        if _records[index].route_serial == route_serial:
            target_index = index
            break
    if target_index < 0:
        return removed
    var replacement_distance: float = _records[target_index].route_distance_start_cells
    for index in range(_records.size() - 1, target_index - 1, -1):
        var record = _records[index]
        removed.push_front(record.duplicate_record())
        _decrement_active_cell(record.cell)
        _records.remove_at(index)
    _available_track_cells += removed.size()
    _next_nominal_start_cells = replacement_distance
    if _records.is_empty():
        _active_predecessor_cell = _departure_cell
    return removed


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
        _decrement_active_cell(record.cell)
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


func get_record_by_serial(route_serial: int):
    for record in _records:
        if record.route_serial == route_serial:
            return record
    return null


func get_active_occurrence_count(cell: Vector2i) -> int:
    return int(_active_cells.get(cell, 0))


func get_active_records_in_cell(cell: Vector2i) -> Array[TrackCellRecordScript]:
    var records: Array[TrackCellRecordScript] = []
    for record in _records:
        if record.cell == cell:
            records.append(record.duplicate_record())
    return records


func get_available_track_cells() -> int:
    return _available_track_cells


func get_total_track_cells() -> int:
    return _total_track_cells


func is_conservation_valid() -> bool:
    if (
        _available_track_cells < 0
        or _available_track_cells + _records.size() != _total_track_cells
    ):
        return false
    var counted_records := 0
    for cell in _active_cells:
        var count := int(_active_cells[cell])
        if count <= 0 or count > 2:
            return false
        counted_records += count
    return counted_records == _records.size() and _crossing_topology_is_valid()


func duplicate_sequence() -> TrackCellSequence:
    var copy = get_script().new(_departure_cell, _total_track_cells)
    copy._available_track_cells = _available_track_cells
    copy._next_route_serial = _next_route_serial
    copy._next_nominal_start_cells = _next_nominal_start_cells
    copy._active_predecessor_cell = _active_predecessor_cell
    for record in _records:
        var record_copy = record.duplicate_record()
        copy._records.append(record_copy)
        copy._increment_active_cell(record_copy.cell)
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
        _increment_active_cell(record_copy.cell)


func _increment_active_cell(cell: Vector2i) -> void:
    _active_cells[cell] = get_active_occurrence_count(cell) + 1


func _decrement_active_cell(cell: Vector2i) -> void:
    var remaining := get_active_occurrence_count(cell) - 1
    if remaining <= 0:
        _active_cells.erase(cell)
    else:
        _active_cells[cell] = remaining


func _crossing_topology_is_valid() -> bool:
    var records_by_serial := {}
    var records_by_cell := {}
    for record in _records:
        records_by_serial[record.route_serial] = record
        if not records_by_cell.has(record.cell):
            records_by_cell[record.cell] = []
        records_by_cell[record.cell].append(record)
    for cell in records_by_cell:
        var occurrences: Array = records_by_cell[cell]
        if occurrences.size() == 1:
            var only = occurrences[0]
            if (
                only.grade_separated_crossing
                and only.crossing_partner_route_serial >= only.route_serial
            ):
                return false
            continue
        if occurrences.size() != 2:
            return false
        var earlier = occurrences[0]
        var later = occurrences[1]
        if (
            earlier.route_serial >= later.route_serial
            or earlier.grade_separated_crossing
            or not later.grade_separated_crossing
            or later.crossing_partner_route_serial != earlier.route_serial
            or not earlier.geometry_locked
            or not _record_is_straight(earlier.route_serial)
            or not _record_is_straight(later.route_serial)
        ):
            return false
        var earlier_heading := _record_heading(earlier.route_serial)
        var later_heading := _record_heading(later.route_serial)
        if earlier_heading == Vector2i.ZERO or later_heading == Vector2i.ZERO:
            return false
        if earlier_heading.x * later_heading.x + earlier_heading.y * later_heading.y != 0:
            return false
    for record in _records:
        if not record.grade_separated_crossing:
            if record.crossing_partner_route_serial >= 0:
                return false
            continue
        if record.crossing_partner_route_serial < 0 or record.crossing_partner_route_serial >= record.route_serial:
            return false
        if not _record_is_straight(record.route_serial):
            return false
        var partner = records_by_serial.get(record.crossing_partner_route_serial)
        if partner != null and partner.cell != record.cell:
            return false
    return true


func _record_is_straight(route_serial: int) -> bool:
    return _record_heading(route_serial) != Vector2i.ZERO


func _record_heading(route_serial: int) -> Vector2i:
    var record_index := -1
    for index in range(_records.size()):
        if _records[index].route_serial == route_serial:
            record_index = index
            break
    if record_index < 0 or record_index + 1 >= _records.size():
        return Vector2i.ZERO
    var previous: Vector2i = (
        _active_predecessor_cell if record_index == 0 else _records[record_index - 1].cell
    )
    var current: Vector2i = _records[record_index].cell
    var following: Vector2i = _records[record_index + 1].cell
    var incoming := current - previous
    var outgoing := following - current
    if (
        absi(incoming.x) + absi(incoming.y) != 1
        or absi(outgoing.x) + absi(outgoing.y) != 1
        or incoming != outgoing
    ):
        return Vector2i.ZERO
    return incoming
