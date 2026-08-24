class_name TrackSystem
extends RefCounted

const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")

const GEOMETRY_EPSILON := 0.0001

var _route_points := PackedVector2Array()
var _route_distances := PackedFloat64Array()
var _first_segment_uses_float32_recovery_exception := false
var _active_start_distance := 0.0
var _built_end_distance := 0.0
var _reserved_end_distance := 0.0
var _available_units := 0.0
var _total_units := 0.0
var _logical_field_size := Vector2.ZERO
var _endpoint_grab_radius_units := 0.0
var _route_hit_radius_units := 0.0
var _minimum_sample_distance_units := 0.0
var _intersection_clearance_units := 0.0
var _stroke_active := false
var _waiting_for_left_release := false


func _init(start_config: SessionStartConfigScript) -> void:
    assert(start_config != null)
    _total_units = start_config.total_track_units
    _available_units = _total_units
    _logical_field_size = start_config.logical_field_size
    _endpoint_grab_radius_units = start_config.endpoint_grab_radius_units
    _route_hit_radius_units = start_config.route_hit_radius_units
    _minimum_sample_distance_units = start_config.minimum_sample_distance_units
    _intersection_clearance_units = start_config.intersection_clearance_units
    _route_points.append(start_config.departure_position)
    _route_distances.append(0.0)
    _assert_invariants()


func apply_right_input(input_frame: TrackInputFrameScript) -> bool:
    if input_frame == null or not input_frame.right_pressed:
        return false
    var must_wait_for_left_release := (
        (_waiting_for_left_release and not input_frame.left_released)
        or (_stroke_active and not input_frame.left_released)
        or input_frame.left_held
    )
    _stroke_active = false
    _waiting_for_left_release = must_wait_for_left_release
    if not input_frame.right_press_inside_field:
        return true
    var cut_distance := _find_reserved_projection(input_frame.right_press_position)
    if is_nan(cut_distance):
        return true
    cut_distance = _canonicalize_route_distance(
        cut_distance,
        _built_end_distance,
        _reserved_end_distance
    )
    var refund := _reserved_end_distance - cut_distance
    _truncate_route_at(cut_distance)
    _reserved_end_distance = cut_distance
    _available_units += refund
    assert(_available_units <= _total_units + GEOMETRY_EPSILON)
    if absf(_available_units - _total_units) <= GEOMETRY_EPSILON:
        _available_units = _total_units
    _assert_invariants()
    return true


func apply_left_input(input_frame: TrackInputFrameScript) -> void:
    if input_frame == null:
        return
    if input_frame.left_released:
        _stroke_active = false
        _waiting_for_left_release = false
        return
    if _waiting_for_left_release:
        return
    if input_frame.left_pressed:
        if (
            not input_frame.left_press_inside_field
            or input_frame.left_press_position.distance_to(get_reserved_endpoint())
                > _endpoint_grab_radius_units
        ):
            return
        _stroke_active = true
    if input_frame.left_held and _stroke_active and not _waiting_for_left_release:
        _append_held_sample(input_frame.cursor_position, input_frame.cursor_inside_field)


func advance_construction(distance_units: float) -> float:
    assert(distance_units >= 0.0)
    var actual: float = minf(
        distance_units,
        _reserved_end_distance - _built_end_distance
    )
    _built_end_distance += actual
    _assert_invariants()
    return actual


func _get_float32_recovery_bound(
    start_point: Vector2,
    collision_point: Vector2,
    scalar_length: float
) -> float:
    var max_abs_coordinate := maxf(
        maxf(absf(start_point.x), absf(start_point.y)),
        maxf(absf(collision_point.x), absf(collision_point.y))
    )
    var float32_scale := maxf(maxf(max_abs_coordinate, scalar_length), 1.0)
    return GEOMETRY_EPSILON + float32_scale * pow(2.0, -20.0)


func recover_behind(cutoff_distance: float) -> float:
    var old_active: float = _active_start_distance
    var raw_target: float = clampf(
        cutoff_distance,
        old_active,
        _built_end_distance
    )
    var normalized: float = _canonicalize_route_distance(
        raw_target,
        old_active,
        raw_target
    )
    if normalized <= old_active + GEOMETRY_EPSILON:
        return 0.0
    var uses_float32_recovery_exception := false
    var target_position: Vector2 = get_position_at_distance(normalized)
    for index in range(_route_points.size()):
        if _route_distances[index] <= normalized:
            continue
        var collision_point: Vector2 = _route_points[index]
        var remaining_scalar := _route_distances[index] - normalized
        if _route_distances[index - 1] < normalized:
            target_position = (
                collision_point
                - _route_points[index - 1].direction_to(collision_point)
                * remaining_scalar
            )
        if target_position == collision_point:
            var retreat: float = GEOMETRY_EPSILON
            for _iteration in range(48):
                var candidate_distance: float = maxf(
                    old_active,
                    normalized - retreat
                )
                var candidate_position: Vector2 = get_position_at_distance(
                    candidate_distance
                )
                if candidate_position != collision_point:
                    target_position = candidate_position
                    break
                retreat *= 2.0
            assert(target_position != collision_point)
        var remaining_geometry := target_position.distance_to(collision_point)
        var alignment_delta := absf(remaining_scalar - remaining_geometry)
        var recovery_bound := _get_float32_recovery_bound(
            target_position,
            collision_point,
            remaining_scalar
        )
        uses_float32_recovery_exception = (
            alignment_delta > GEOMETRY_EPSILON
            and alignment_delta <= recovery_bound
        )
        break
    if normalized <= old_active + GEOMETRY_EPSILON:
        return 0.0
    assert(normalized <= raw_target)
    var new_points: PackedVector2Array = PackedVector2Array()
    var new_distances: PackedFloat64Array = PackedFloat64Array()
    new_points.append(target_position)
    new_distances.append(normalized)
    for i in range(_route_points.size()):
        var distance: float = _route_distances[i]
        if distance > normalized:
            new_points.append(_route_points[i])
            new_distances.append(distance)
    _route_points = new_points
    _route_distances = new_distances
    _active_start_distance = normalized
    _first_segment_uses_float32_recovery_exception = (
        uses_float32_recovery_exception
    )
    var recovered: float = normalized - old_active
    _available_units += recovered
    assert(_available_units <= _total_units + GEOMETRY_EPSILON)
    if absf(_available_units - _total_units) <= GEOMETRY_EPSILON:
        _available_units = _total_units
    _assert_invariants()
    return recovered


func get_active_start_distance() -> float:
    return _active_start_distance


func get_built_end_distance() -> float:
    return _built_end_distance


func get_reserved_end_distance() -> float:
    return _reserved_end_distance


func get_built_length() -> float:
    return _built_end_distance - _active_start_distance


func get_available_units() -> float:
    return _available_units


func get_total_units() -> float:
    return _total_units


func get_reserved_endpoint() -> Vector2:
    return _route_points[_route_points.size() - 1]


func get_built_points() -> PackedVector2Array:
    return _slice_route_region(_active_start_distance, _built_end_distance)


func get_reserved_points() -> PackedVector2Array:
    return _slice_route_region(_built_end_distance, _reserved_end_distance)


func get_position_at_distance(route_distance: float) -> Vector2:
    var target := clampf(route_distance, _active_start_distance, _reserved_end_distance)
    for index in range(_route_distances.size()):
        if _route_distances[index] == target:
            return _route_points[index]
        if _route_distances[index] > target:
            var previous := index - 1
            var segment_length := _route_distances[index] - _route_distances[previous]
            var weight := (target - _route_distances[previous]) / segment_length
            return _route_points[previous].lerp(_route_points[index], weight)
    return get_reserved_endpoint()


func get_heading_at_distance(route_distance: float) -> Vector2:
    if _route_points.size() == 1:
        return Vector2.RIGHT
    var target := clampf(route_distance, _active_start_distance, _reserved_end_distance)
    for index in range(_route_distances.size()):
        if _route_distances[index] == target:
            if index < _route_points.size() - 1:
                return _route_points[index].direction_to(_route_points[index + 1])
            return _route_points[index - 1].direction_to(_route_points[index])
    for index in range(_route_distances.size()):
        if _route_distances[index] > target:
            return _route_points[index - 1].direction_to(_route_points[index])
    return _route_points[-2].direction_to(_route_points[-1])


func is_stroke_active() -> bool:
    return _stroke_active


func is_waiting_for_left_release() -> bool:
    return _waiting_for_left_release


func is_conservation_valid() -> bool:
    return absf(
        _available_units + _reserved_end_distance - _active_start_distance - _total_units
    ) <= GEOMETRY_EPSILON


func _slice_route_region(
    start_distance: float,
    end_distance: float
) -> PackedVector2Array:
    assert(start_distance <= end_distance + GEOMETRY_EPSILON)
    var result: PackedVector2Array = PackedVector2Array()
    result.append(get_position_at_distance(start_distance))
    if end_distance == start_distance:
        return result
    for i in range(_route_distances.size()):
        var distance: float = _route_distances[i]
        if distance > start_distance and distance < end_distance:
            _append_region_point(result, _route_points[i])
    _append_region_point(result, get_position_at_distance(end_distance))
    return result


func _append_region_point(points: PackedVector2Array, point: Vector2) -> void:
    if points.is_empty() or points[-1] != point:
        points.append(point)


func _append_held_sample(sample_position: Vector2, _sample_inside_field: bool) -> void:
    var start := get_reserved_endpoint()
    var raw_length := start.distance_to(sample_position)
    if raw_length < _minimum_sample_distance_units:
        return
    var direction := start.direction_to(sample_position)
    var accepted_limit := minf(raw_length, _available_units)
    var field_limit := _distance_to_first_field_exit(start, sample_position)
    var field_is_limiting := (field_limit <= accepted_limit) and (field_limit < raw_length)
    if field_is_limiting:
        accepted_limit = field_limit
    var intersection_distance := _distance_to_first_active_intersection(
        start,
        sample_position
    )
    if not is_inf(intersection_distance):
        var clearance_limit := maxf(0.0, intersection_distance - _intersection_clearance_units)
        if clearance_limit < accepted_limit:
            accepted_limit = clearance_limit
            field_is_limiting = false
    if accepted_limit <= GEOMETRY_EPSILON:
        return
    var accepted_endpoint := sample_position
    var stored_length := raw_length
    if accepted_limit < raw_length:
        var lower_bound := 0.0
        var upper_bound := minf(raw_length, accepted_limit + 1.0)
        var best_safe_endpoint := start
        var best_safe_length := 0.0
        for _iteration in range(48):
            var candidate_length := (lower_bound + upper_bound) * 0.5
            var candidate_endpoint := start + direction * candidate_length
            if field_is_limiting:
                candidate_endpoint.x = clampf(
                    candidate_endpoint.x,
                    0.0,
                    _logical_field_size.x
                )
                candidate_endpoint.y = clampf(
                    candidate_endpoint.y,
                    0.0,
                    _logical_field_size.y
                )
            var candidate_distance := start.distance_to(candidate_endpoint)
            var candidate_inside_field := (
                candidate_endpoint.x >= 0.0
                and candidate_endpoint.y >= 0.0
                and candidate_endpoint.x <= _logical_field_size.x
                and candidate_endpoint.y <= _logical_field_size.y
            )
            if candidate_distance <= accepted_limit and candidate_inside_field:
                lower_bound = candidate_length
                best_safe_endpoint = candidate_endpoint
                best_safe_length = candidate_distance
            else:
                upper_bound = candidate_length
        for axis_index in range(2):
            if direction[axis_index] == 0.0:
                continue
            var axis_origin := best_safe_endpoint
            var refinement_lower := 0.0
            var refinement_upper := 1.0
            for _refinement_iteration in range(48):
                var weight := (refinement_lower + refinement_upper) * 0.5
                var candidate_endpoint := axis_origin
                candidate_endpoint[axis_index] = (
                    axis_origin[axis_index]
                    + signf(direction[axis_index]) * GEOMETRY_EPSILON * weight
                )
                candidate_endpoint.x = clampf(
                    candidate_endpoint.x,
                    0.0,
                    _logical_field_size.x
                )
                candidate_endpoint.y = clampf(
                    candidate_endpoint.y,
                    0.0,
                    _logical_field_size.y
                )
                var candidate_distance := start.distance_to(candidate_endpoint)
                var candidate_inside_field := (
                    candidate_endpoint.x >= 0.0
                    and candidate_endpoint.y >= 0.0
                    and candidate_endpoint.x <= _logical_field_size.x
                    and candidate_endpoint.y <= _logical_field_size.y
                )
                var stored_component_delta := absf(
                    candidate_endpoint[axis_index] - axis_origin[axis_index]
                )
                if (
                    candidate_distance <= accepted_limit
                    and candidate_distance >= best_safe_length
                    and candidate_inside_field
                    and stored_component_delta <= GEOMETRY_EPSILON
                ):
                    refinement_lower = weight
                    best_safe_endpoint = candidate_endpoint
                    best_safe_length = candidate_distance
                else:
                    refinement_upper = weight
        accepted_endpoint = best_safe_endpoint
        stored_length = best_safe_length
    if stored_length <= GEOMETRY_EPSILON:
        return
    _reserved_end_distance += stored_length
    _route_points.append(accepted_endpoint)
    _route_distances.append(_reserved_end_distance)
    _available_units -= stored_length
    assert(_available_units >= -GEOMETRY_EPSILON)
    if absf(_available_units) <= GEOMETRY_EPSILON:
        _available_units = 0.0
    _assert_invariants()


func _find_reserved_projection(position: Vector2) -> float:
    if _reserved_end_distance - _built_end_distance <= GEOMETRY_EPSILON:
        return NAN
    var best_route_distance := NAN
    var best_distance_squared := INF
    var selected_distance := INF
    for index in range(1, _route_points.size()):
        var segment_start_distance := _route_distances[index - 1]
        var segment_end_distance := _route_distances[index]
        if segment_end_distance <= _built_end_distance + GEOMETRY_EPSILON:
            continue
        var segment_start := _route_points[index - 1]
        var segment_end := _route_points[index]
        var segment := segment_end - segment_start
        var segment_length_squared := segment.length_squared()
        if segment_length_squared <= GEOMETRY_EPSILON * GEOMETRY_EPSILON:
            continue
        var segment_route_length := segment_end_distance - segment_start_distance
        var minimum_weight := clampf(
            (maxf(segment_start_distance, _built_end_distance) - segment_start_distance)
                / segment_route_length,
            0.0,
            1.0
        )
        var weight := clampf(
            (position - segment_start).dot(segment) / segment_length_squared,
            minimum_weight,
            1.0
        )
        var projection := segment_start + segment * weight
        var candidate_distance_squared := position.distance_squared_to(projection)
        var candidate_route_distance := segment_start_distance + segment_route_length * weight
        var candidate_distance := sqrt(candidate_distance_squared)
        if is_nan(best_route_distance):
            best_route_distance = candidate_route_distance
            best_distance_squared = candidate_distance_squared
            selected_distance = candidate_distance
            continue
        var best_distance := sqrt(best_distance_squared)
        if candidate_distance < best_distance:
            best_distance_squared = candidate_distance_squared
            if selected_distance - candidate_distance > GEOMETRY_EPSILON:
                best_route_distance = candidate_route_distance
                selected_distance = candidate_distance
            elif candidate_route_distance > best_route_distance:
                best_route_distance = candidate_route_distance
                selected_distance = candidate_distance
        elif (
            candidate_distance - best_distance <= GEOMETRY_EPSILON
            and candidate_route_distance > best_route_distance
        ):
            best_route_distance = candidate_route_distance
            selected_distance = candidate_distance
    if (
        is_nan(best_route_distance)
        or sqrt(best_distance_squared) > _route_hit_radius_units
    ):
        return NAN
    return best_route_distance


func _canonicalize_route_distance(
    value: float,
    minimum_allowed: float,
    maximum_allowed: float
) -> float:
    var best_distance := NAN
    var best_delta := INF
    for route_distance in _route_distances:
        if route_distance < minimum_allowed or route_distance > maximum_allowed:
            continue
        var delta := absf(route_distance - value)
        if delta > GEOMETRY_EPSILON:
            continue
        if (
            is_nan(best_distance)
            or delta < best_delta
            or (delta == best_delta and route_distance > best_distance)
        ):
            best_distance = route_distance
            best_delta = delta
    return value if is_nan(best_distance) else best_distance


func _truncate_route_at(cut_distance: float) -> void:
    var retained_points := PackedVector2Array()
    var retained_distances := PackedFloat64Array()
    for index in range(_route_distances.size()):
        var route_distance := _route_distances[index]
        if route_distance < cut_distance:
            retained_points.append(_route_points[index])
            retained_distances.append(route_distance)
            continue
        if route_distance == cut_distance:
            retained_points.append(_route_points[index])
            retained_distances.append(route_distance)
            break
        var previous := index - 1
        var segment_length := route_distance - _route_distances[previous]
        var weight := (cut_distance - _route_distances[previous]) / segment_length
        var terminal_point := _route_points[previous].lerp(_route_points[index], weight)
        retained_points.append(terminal_point)
        retained_distances.append(cut_distance)
        break
    _route_points = retained_points
    _route_distances = retained_distances
    if _route_points.size() < 2:
        _first_segment_uses_float32_recovery_exception = false


func _distance_to_first_field_exit(start: Vector2, end: Vector2) -> float:
    var delta := end - start
    var raw_length := sqrt(delta.x * delta.x + delta.y * delta.y)
    if raw_length <= GEOMETRY_EPSILON:
        return 0.0
    var exit_weight := 1.0
    if delta.x > 0.0:
        exit_weight = minf(
            exit_weight,
            (_logical_field_size.x - start.x) / delta.x
        )
    elif delta.x < 0.0:
        exit_weight = minf(exit_weight, (0.0 - start.x) / delta.x)
    if delta.y > 0.0:
        exit_weight = minf(
            exit_weight,
            (_logical_field_size.y - start.y) / delta.y
        )
    elif delta.y < 0.0:
        exit_weight = minf(exit_weight, (0.0 - start.y) / delta.y)
    return raw_length * clampf(exit_weight, 0.0, 1.0)


func _distance_to_first_active_intersection(start: Vector2, end: Vector2) -> float:
    var candidate_segment := end - start
    var candidate_length := candidate_segment.length()
    if candidate_length <= GEOMETRY_EPSILON:
        return INF
    var candidate_length_squared := candidate_segment.length_squared()
    var best_distance := INF
    var final_segment_index := _route_points.size() - 1
    for index in range(1, _route_points.size()):
        var retained_start := _route_points[index - 1]
        var retained_segment := _route_points[index] - retained_start
        var denominator := candidate_segment.cross(retained_segment)
        var offset := retained_start - start
        if absf(denominator) <= GEOMETRY_EPSILON:
            if absf(offset.cross(candidate_segment)) > GEOMETRY_EPSILON:
                continue
            var first_weight := offset.dot(candidate_segment) / candidate_length_squared
            var second_weight := (
                (_route_points[index] - start).dot(candidate_segment)
                / candidate_length_squared
            )
            var overlap_start := maxf(0.0, minf(first_weight, second_weight))
            var overlap_end := minf(1.0, maxf(first_weight, second_weight))
            if overlap_end < overlap_start - GEOMETRY_EPSILON:
                continue
            if index == final_segment_index and overlap_end <= GEOMETRY_EPSILON:
                continue
            var overlap_distance := maxf(0.0, overlap_start) * candidate_length
            best_distance = minf(best_distance, overlap_distance)
            continue
        var candidate_weight := offset.cross(retained_segment) / denominator
        var retained_weight := offset.cross(candidate_segment) / denominator
        if (
            candidate_weight < -GEOMETRY_EPSILON
            or candidate_weight > 1.0 + GEOMETRY_EPSILON
            or retained_weight < -GEOMETRY_EPSILON
            or retained_weight > 1.0 + GEOMETRY_EPSILON
        ):
            continue
        var intersection_distance := clampf(candidate_weight, 0.0, 1.0) * candidate_length
        if (
            index == final_segment_index
            and intersection_distance <= GEOMETRY_EPSILON
            and absf(retained_weight - 1.0) <= GEOMETRY_EPSILON
        ):
            continue
        best_distance = minf(best_distance, intersection_distance)
    return best_distance


func _assert_invariants() -> void:
    assert(_route_points.size() == _route_distances.size())
    assert(not _route_points.is_empty())
    assert(_active_start_distance >= -GEOMETRY_EPSILON)
    assert(_built_end_distance + GEOMETRY_EPSILON >= _active_start_distance)
    assert(_reserved_end_distance + GEOMETRY_EPSILON >= _built_end_distance)
    assert(
        absf(_route_distances[0] - _active_start_distance)
        <= GEOMETRY_EPSILON
    )
    assert(
        absf(_route_distances[_route_distances.size() - 1] - _reserved_end_distance)
        <= GEOMETRY_EPSILON
    )
    assert(_available_units >= -GEOMETRY_EPSILON)
    assert(_available_units <= _total_units + GEOMETRY_EPSILON)
    for index in range(1, _route_points.size()):
        assert(_route_points[index] != _route_points[index - 1])
        var absolute_delta := _route_distances[index] - _route_distances[index - 1]
        assert(absolute_delta > 0.0)
        var geometry_delta := (
            _route_points[index - 1].distance_to(_route_points[index])
        )
        if index == 1 and _first_segment_uses_float32_recovery_exception:
            var recovery_bound := _get_float32_recovery_bound(
                _route_points[index - 1],
                _route_points[index],
                absolute_delta
            )
            assert(absf(absolute_delta - geometry_delta) <= recovery_bound)
        else:
            assert(absf(absolute_delta - geometry_delta) <= GEOMETRY_EPSILON)
    assert(is_conservation_valid())
