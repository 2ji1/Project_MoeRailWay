extends "res://tests/support/prototype_test.gd"

const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")


func run() -> PackedStringArray:
    _verify_reservation_and_cancel()
    _verify_press_edges_and_sampling()
    _verify_inventory_and_field_clipping()
    _verify_self_intersection_and_continuity()
    _verify_cancellation_projection_selection()
    _verify_vertex_snapping_and_preserved_right_press()
    _verify_right_press_stroke_state()
    _verify_public_point_contract()
    _verify_stale_field_flag_regression()
    _verify_noncanonical_interior_cancellation_regression()
    _verify_float32_endpoint_accounting()
    _verify_float32_clipped_cap_accounting()
    _verify_float32_right_boundary_containment()
    _verify_sub_epsilon_axis_field_exit()
    _verify_canonical_vertex_chooses_true_nearest()
    _verify_float32_inventory_under_rounding()
    _verify_projection_tie_does_not_chain()
    return finish()


func _config(
    total_units := 100.0,
    departure_position := Vector2(100.0, 100.0)
) -> SessionStartConfigScript:
    return SessionStartConfigScript.new(
        123,
        120.0,
        60,
        90.0,
        total_units,
        30.0,
        3.0,
        120.0,
        24.0,
        16.0,
        8.0,
        4.0,
        32.0,
        Vector2(1200.0, 560.0),
        &"departure_01",
        departure_position
    )


func _input(
    cursor_position: Vector2,
    cursor_inside_field: bool,
    left_held := false,
    left_pressed := false,
    left_released := false,
    right_pressed := false,
    left_press_position := Vector2.INF,
    left_press_inside_field: Variant = null,
    right_press_position := Vector2.INF,
    right_press_inside_field: Variant = null
) -> TrackInputFrameScript:
    var resolved_left_position: Vector2 = left_press_position
    var resolved_left_inside := false if left_press_inside_field == null else bool(left_press_inside_field)
    if left_pressed:
        if left_press_position == Vector2.INF:
            resolved_left_position = cursor_position
        if left_press_inside_field == null:
            resolved_left_inside = cursor_inside_field
    var resolved_right_position: Vector2 = right_press_position
    var resolved_right_inside := false if right_press_inside_field == null else bool(right_press_inside_field)
    if right_pressed:
        if right_press_position == Vector2.INF:
            resolved_right_position = cursor_position
        if right_press_inside_field == null:
            resolved_right_inside = cursor_inside_field
    return TrackInputFrameScript.new(
        cursor_position,
        cursor_inside_field,
        left_pressed,
        left_held,
        left_released,
        right_pressed,
        resolved_left_position,
        resolved_left_inside,
        resolved_right_position,
        resolved_right_inside
    )


func _verify_reservation_and_cancel() -> void:
    var track = TrackSystemScript.new(_config(100.0))
    track.apply_left_input(_input(Vector2(100.0, 100.0), true, true, true))
    track.apply_left_input(_input(Vector2(140.0, 100.0), true, true))
    _assert_close(track.get_reserved_end_distance(), 40.0, "Drag must reserve exact length")
    _assert_close(track.get_available_units(), 60.0, "Reservation must charge immediately")
    assert_true(track.is_conservation_valid(), "Reservation must conserve inventory")

    var right_won := track.apply_right_input(
        _input(Vector2(125.0, 100.0), true, true, false, false, true)
    )
    assert_true(right_won, "Every right press must win the tick")
    _assert_close(track.get_reserved_end_distance(), 25.0, "Click projection must cut suffix")
    _assert_close(track.get_available_units(), 75.0, "Canceled suffix must refund once")
    assert_true(track.is_waiting_for_left_release(), "Right press must suppress held left")
    track.apply_left_input(_input(Vector2(150.0, 100.0), true, true))
    _assert_close(track.get_reserved_end_distance(), 25.0, "Held left must not resume after right press")
    track.apply_left_input(_input(Vector2.ZERO, false, false, false, true))
    assert_false(track.is_waiting_for_left_release(), "Later release must clear suppression")


func _verify_press_edges_and_sampling() -> void:
    var track = TrackSystemScript.new(_config(100.0))
    track.apply_left_input(
        _input(
            Vector2(125.0, 100.0), true, true, true, false, false,
            Vector2(125.0, 100.0), true
        )
    )
    track.apply_left_input(_input(Vector2(100.0, 100.0), true, true))
    _assert_close(track.get_reserved_end_distance(), 0.0, "Off-endpoint press must remain a no-op")
    assert_false(track.is_stroke_active(), "Off-endpoint press must not start a stroke")

    track = TrackSystemScript.new(_config(100.0))
    track.apply_left_input(
        _input(
            Vector2(140.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    _assert_close(track.get_reserved_end_distance(), 40.0, "Preserved press must start from the endpoint")
    var points = track.get_reserved_points()
    _assert_vector_close(points[points.size() - 1], Vector2(140.0, 100.0), "Latest held cursor must be sampled once")

    track = TrackSystemScript.new(_config(100.0))
    track.apply_left_input(_input(Vector2(100.0, 100.0), true, true, true))
    track.apply_left_input(_input(Vector2(107.5, 100.0), true, true))
    _assert_close(track.get_reserved_end_distance(), 0.0, "Sample below eight units must be ignored")


func _verify_inventory_and_field_clipping() -> void:
    var track = TrackSystemScript.new(_config(30.0))
    track.apply_left_input(
        _input(
            Vector2(150.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    _assert_close(track.get_reserved_end_distance(), 30.0, "Inventory must clip the accepted length")
    _assert_close(track.get_available_units(), 0.0, "Inventory clip must charge exactly once")
    assert_true(track.get_available_units() >= 0.0, "Available inventory must not become negative")
    var points = track.get_reserved_points()
    _assert_vector_close(points[points.size() - 1], Vector2(130.0, 100.0), "Inventory clip must append its exact endpoint")
    assert_true(track.is_conservation_valid(), "Inventory clip must conserve units")

    track = TrackSystemScript.new(_config(2000.0))
    track.apply_left_input(
        _input(
            Vector2(1300.0, 100.0), false, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    _assert_close(track.get_reserved_end_distance(), 1100.0, "Field exit must clip at the first edge")
    points = track.get_reserved_points()
    _assert_vector_close(points[points.size() - 1], Vector2(1200.0, 100.0), "Field clip must end on the boundary")
    assert_true(track.is_stroke_active(), "Field clipping must keep the stroke active")

    track.apply_left_input(_input(Vector2(1190.0, 110.0), true, true))
    _assert_close(
        track.get_reserved_end_distance(),
        1100.0 + sqrt(200.0),
        "Reentered held stroke must continue from the boundary"
    )
    points = track.get_reserved_points()
    _assert_vector_close(points[points.size() - 2], Vector2(1200.0, 100.0), "Reentry must retain the boundary endpoint")
    _assert_vector_close(points[points.size() - 1], Vector2(1190.0, 110.0), "Reentry must append continuously")
    assert_true(track.is_conservation_valid(), "Field clipping and reentry must conserve units")


func _verify_self_intersection_and_continuity() -> void:
    var track = TrackSystemScript.new(_config(1000.0))
    track.apply_left_input(
        _input(
            Vector2(200.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    _assert_route_continuous(track, "Square first edge")
    track.apply_left_input(_input(Vector2(200.0, 200.0), true, true))
    _assert_route_continuous(track, "Square second edge")
    track.apply_left_input(_input(Vector2(100.0, 200.0), true, true))
    _assert_route_continuous(track, "Square third edge")
    track.apply_left_input(_input(Vector2(100.0, 90.0), true, true))
    _assert_close(track.get_reserved_end_distance(), 396.0, "Square close must stop four units before contact")
    var points = track.get_reserved_points()
    _assert_vector_close(points[points.size() - 1], Vector2(100.0, 104.0), "Square close endpoint must preserve clearance")
    _assert_route_continuous(track, "Square clipped edge")
    assert_true(track.is_conservation_valid(), "Square clipping must conserve units")

    track = TrackSystemScript.new(_config(1000.0))
    track.apply_left_input(
        _input(
            Vector2(150.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    track.apply_left_input(_input(Vector2(150.0, 150.0), true, true))
    _assert_close(track.get_reserved_end_distance(), 100.0, "Owned endpoint must not count as self-intersection")
    _assert_route_continuous(track, "Owned endpoint turn")

    track = TrackSystemScript.new(_config(1000.0))
    track.apply_left_input(
        _input(
            Vector2(200.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    track.apply_left_input(_input(Vector2(200.0, 200.0), true, true))
    track.apply_left_input(_input(Vector2(300.0, 200.0), true, true))
    var crossing_start := Vector2(300.0, 200.0)
    var crossing_target := Vector2(100.0, 150.0)
    var contact_distance := crossing_start.distance_to(crossing_target) * 0.5
    var accepted_length := contact_distance - 4.0
    track.apply_left_input(_input(crossing_target, true, true))
    _assert_close(
        track.get_reserved_end_distance(),
        300.0 + accepted_length,
        "Every retained reserved segment must block crossing"
    )
    points = track.get_reserved_points()
    _assert_vector_close(
        points[points.size() - 1],
        crossing_start + crossing_start.direction_to(crossing_target) * accepted_length,
        "Crossing clip must stop before the retained middle segment"
    )
    _assert_route_continuous(track, "Retained middle-segment crossing")
    assert_true(track.is_conservation_valid(), "Intersection clipping must conserve units")


func _verify_cancellation_projection_selection() -> void:
    var track = _new_parallel_route()
    var right_won = track.apply_right_input(
        _input(Vector2(150.0, 106.0), true, false, false, false, true)
    )
    assert_true(right_won, "Nearest-projection right press must win the tick")
    _assert_close(track.get_reserved_end_distance(), 50.0, "Nearest projection must win")
    _assert_close(track.get_available_units(), 950.0, "Nearest cut must refund its suffix once")
    _assert_route_continuous(track, "Nearest-projection cancellation")
    assert_true(track.is_conservation_valid(), "Nearest-projection cancellation must conserve units")

    track = _new_parallel_route()
    right_won = track.apply_right_input(
        _input(Vector2(150.0, 110.0), true, false, false, false, true)
    )
    assert_true(right_won, "Equal-projection right press must win the tick")
    _assert_close(track.get_reserved_end_distance(), 170.0, "Equal projections must choose greatest route distance")
    _assert_close(track.get_available_units(), 830.0, "Equal-projection cut must refund its suffix once")
    _assert_route_continuous(track, "Equal-projection cancellation")
    assert_true(track.is_conservation_valid(), "Equal-projection cancellation must conserve units")

    var epsilon = TrackSystemScript.GEOMETRY_EPSILON
    track = _new_parallel_route()
    right_won = track.apply_right_input(
        _input(Vector2(150.0, 110.0 - epsilon / 4.0), true, false, false, false, true)
    )
    assert_true(right_won, "Epsilon-tied right press must win the tick")
    _assert_close(track.get_reserved_end_distance(), 170.0, "Epsilon tie must choose greatest route distance")
    _assert_close(track.get_available_units(), 830.0, "Epsilon-tied cut must refund its suffix once")
    _assert_route_continuous(track, "Epsilon-tied cancellation")
    assert_true(track.is_conservation_valid(), "Epsilon-tied cancellation must conserve units")

    track = _new_parallel_route()
    right_won = track.apply_right_input(
        _input(Vector2(150.0, 110.0 - epsilon), true, false, false, false, true)
    )
    assert_true(right_won, "Distinct-projection right press must win the tick")
    _assert_close(track.get_reserved_end_distance(), 50.0, "Difference above epsilon must choose nearest projection")
    _assert_close(track.get_available_units(), 950.0, "Distinct-projection cut must refund its suffix once")
    _assert_route_continuous(track, "Distinct-projection cancellation")
    assert_true(track.is_conservation_valid(), "Distinct-projection cancellation must conserve units")


func _new_parallel_route():
    var track = TrackSystemScript.new(_config(1000.0))
    track.apply_left_input(
        _input(
            Vector2(200.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    track.apply_left_input(_input(Vector2(200.0, 120.0), true, true))
    track.apply_left_input(_input(Vector2(100.0, 120.0), true, true))
    _assert_close(track.get_reserved_end_distance(), 220.0, "Parallel route must reserve its exact length")
    _assert_route_continuous(track, "Parallel route construction")
    assert_true(track.is_conservation_valid(), "Parallel route construction must conserve units")
    return track


func _verify_vertex_snapping_and_preserved_right_press() -> void:
    var epsilon = TrackSystemScript.GEOMETRY_EPSILON
    for offset in [0.0, -epsilon / 2.0, epsilon / 2.0]:
        var track = _new_straight_route()
        var right_won = track.apply_right_input(
            _input(Vector2(140.0 + offset, 100.0), true, false, false, false, true)
        )
        assert_true(right_won, "Vertex cancellation must win the tick")
        _assert_close(track.get_reserved_end_distance(), 40.0, "Vertex cancellation must snap to the stored distance")
        _assert_close(track.get_available_units(), 60.0, "Vertex cancellation must refund the exact suffix")
        var points = track.get_reserved_points()
        var distances = _derive_cumulative_distances(points)
        assert_equal(points.size(), 2, "Vertex cancellation must retain one boundary vertex")
        _assert_vector_close(points[1], Vector2(140.0, 100.0), "Vertex cancellation must retain the exact stored point")
        _assert_close(distances[1], 40.0, "Vertex cancellation must retain the exact stored distance")
        _assert_route_continuous(track, "Vertex-snapped cancellation")
        assert_true(track.is_conservation_valid(), "Vertex-snapped cancellation must conserve units")

        right_won = track.apply_right_input(
            _input(Vector2(140.0 + offset, 100.0), true, false, false, false, true)
        )
        assert_true(right_won, "Repeated vertex cancellation must win the tick")
        _assert_close(track.get_reserved_end_distance(), 40.0, "Repeated vertex cancellation must keep the cut")
        _assert_close(track.get_available_units(), 60.0, "Repeated vertex cancellation must not refund twice")
        _assert_route_continuous(track, "Repeated vertex cancellation")
        assert_true(track.is_conservation_valid(), "Repeated vertex cancellation must conserve units")

        track.apply_left_input(_input(Vector2.ZERO, false, false, false, true))
        assert_false(track.is_waiting_for_left_release(), "Release must clear vertex-cancel suppression")
        track.apply_left_input(
            _input(
                Vector2(160.0, 100.0), true, true, true, false, false,
                Vector2(140.0, 100.0), true
            )
        )
        _assert_close(track.get_reserved_end_distance(), 60.0, "Fresh append must start from the snapped boundary")
        _assert_close(track.get_available_units(), 40.0, "Fresh append must charge once after the refund")
        points = track.get_reserved_points()
        var boundary_count = 0
        for point in points:
            if point == Vector2(140.0, 100.0):
                boundary_count += 1
        assert_equal(boundary_count, 1, "Fresh append must retain the snapped boundary exactly once")
        _assert_route_continuous(track, "Append after vertex cancellation")
        assert_true(track.is_conservation_valid(), "Append after vertex cancellation must conserve units")

    var track = _new_straight_route()
    var preserved_right = _input(
        Vector2(900.0, 500.0), false, false, false, false, true,
        Vector2.INF, null, Vector2(125.0, 100.0), true
    )
    var right_won = track.apply_right_input(preserved_right)
    assert_true(right_won, "Preserved right press must win after cursor motion")
    _assert_close(track.get_reserved_end_distance(), 25.0, "Preserved right position must select the cancellation projection")
    _assert_close(track.get_available_units(), 75.0, "Preserved right cancellation must refund exactly once")
    var points = track.get_reserved_points()
    _assert_vector_close(points[points.size() - 1], Vector2(125.0, 100.0), "Preserved right cancellation must retain its exact endpoint")
    assert_false(
        track.apply_right_input(_input(Vector2(900.0, 500.0), false)),
        "A later frame without a right edge must not cancel again"
    )
    _assert_close(track.get_available_units(), 75.0, "A consumed right edge must not refund twice")
    _assert_route_continuous(track, "Preserved right cancellation")
    assert_true(track.is_conservation_valid(), "Preserved right cancellation must conserve units")


func _new_straight_route(total_units := 100.0):
    var track = TrackSystemScript.new(_config(total_units))
    track.apply_left_input(
        _input(
            Vector2(140.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    track.apply_left_input(_input(Vector2(180.0, 100.0), true, true))
    _assert_close(track.get_reserved_end_distance(), 80.0, "Straight route must reserve its exact length")
    _assert_route_continuous(track, "Straight route construction")
    assert_true(track.is_conservation_valid(), "Straight route construction must conserve units")
    return track


func _verify_right_press_stroke_state() -> void:
    var track = TrackSystemScript.new(_config(200.0))
    var right_won = track.apply_right_input(
        _input(Vector2(100.0, 100.0), true, false, false, false, true)
    )
    assert_true(right_won, "Right press on an empty route must win the tick")
    _assert_close(track.get_reserved_end_distance(), 0.0, "Empty-route right press must not change geometry")
    assert_false(track.is_stroke_active(), "Empty-route right press must leave no active stroke")
    assert_false(track.is_waiting_for_left_release(), "Idle right press must not suppress a fresh left press")
    _assert_route_continuous(track, "Empty-route right press")
    assert_true(track.is_conservation_valid(), "Empty-route right press must conserve units")

    track = _new_straight_route(200.0)
    right_won = track.apply_right_input(
        _input(Vector2(500.0, 500.0), true, false, false, false, true)
    )
    assert_true(right_won, "Outside-radius right press must win the tick")
    _assert_close(track.get_reserved_end_distance(), 80.0, "Outside-radius right press must not change geometry")
    assert_false(track.is_stroke_active(), "Outside-radius right press must end the active stroke")
    assert_true(track.is_waiting_for_left_release(), "Active stroke must remain suppressed until release")
    _assert_route_continuous(track, "Outside-radius right press")
    assert_true(track.is_conservation_valid(), "Outside-radius right press must conserve units")

    track = _new_straight_route(200.0)
    right_won = track.apply_right_input(
        _input(
            Vector2(1300.0, 100.0), false, false, false, false, true,
            Vector2.INF, null, Vector2(1300.0, 100.0), false
        )
    )
    assert_true(right_won, "Outside-field right press must win the tick")
    _assert_close(track.get_reserved_end_distance(), 80.0, "Outside-field right press must not change geometry")
    assert_false(track.is_stroke_active(), "Outside-field right press must end the active stroke")
    _assert_route_continuous(track, "Outside-field right press")
    assert_true(track.is_conservation_valid(), "Outside-field right press must conserve units")

    track = _new_straight_route(200.0)
    track.apply_left_input(_input(Vector2.ZERO, false, false, false, true))
    assert_false(track.is_stroke_active(), "Release must end the setup stroke")
    right_won = track.apply_right_input(
        _input(Vector2(500.0, 500.0), true, false, false, false, true)
    )
    assert_true(right_won, "Idle outside-radius right press must win the tick")
    assert_false(track.is_waiting_for_left_release(), "Idle right press must allow the next fresh left press")
    track.apply_left_input(
        _input(
            Vector2(200.0, 100.0), true, true, true, false, false,
            Vector2(180.0, 100.0), true
        )
    )
    _assert_close(track.get_reserved_end_distance(), 100.0, "Fresh left press must append after an idle right press")
    _assert_route_continuous(track, "Fresh left after idle right")
    assert_true(track.is_conservation_valid(), "Fresh left after idle right must conserve units")

    track = _new_straight_route(200.0)
    track.apply_right_input(_input(Vector2(500.0, 500.0), true, false, false, false, true))
    track.apply_left_input(
        _input(
            Vector2(200.0, 100.0), true, true, true, false, false,
            Vector2(180.0, 100.0), true
        )
    )
    _assert_close(track.get_reserved_end_distance(), 80.0, "Suppressed left press must not resume an active stroke")
    track.apply_left_input(
        _input(
            Vector2(200.0, 100.0), true, true, true, true, false,
            Vector2(180.0, 100.0), true
        )
    )
    _assert_close(track.get_reserved_end_distance(), 80.0, "Buffered release must return before same-frame press")
    assert_false(track.is_stroke_active(), "Buffered release must leave the stroke inactive")
    assert_false(track.is_waiting_for_left_release(), "Buffered release must clear suppression")
    track.apply_left_input(
        _input(
            Vector2(200.0, 100.0), true, true, true, false, false,
            Vector2(180.0, 100.0), true
        )
    )
    _assert_close(track.get_reserved_end_distance(), 100.0, "Fresh press after buffered release must append")
    _assert_route_continuous(track, "Buffered release precedence")
    assert_true(track.is_conservation_valid(), "Buffered release sequence must conserve units")

    track = TrackSystemScript.new(_config(200.0))
    right_won = track.apply_right_input(
        _input(Vector2(100.0, 100.0), true, true, false, false, true)
    )
    assert_true(right_won, "Simultaneous held-right press must win the tick")
    assert_true(track.is_waiting_for_left_release(), "Simultaneously held left must be suppressed")
    track.apply_left_input(
        _input(
            Vector2(140.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    _assert_close(track.get_reserved_end_distance(), 0.0, "Simultaneously held left must stay suppressed")
    track.apply_left_input(_input(Vector2.ZERO, false, false, false, true))
    assert_false(track.is_waiting_for_left_release(), "Later release must clear simultaneous suppression")
    track.apply_left_input(
        _input(
            Vector2(140.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    _assert_close(track.get_reserved_end_distance(), 40.0, "Fresh left press must start after simultaneous suppression clears")
    _assert_route_continuous(track, "Simultaneous held-right suppression")
    assert_true(track.is_conservation_valid(), "Simultaneous suppression sequence must conserve units")


func _assert_close(actual: float, expected: float, message: String) -> void:
    assert_true(
        absf(actual - expected) <= TrackSystemScript.GEOMETRY_EPSILON,
        message
    )


func _assert_vector_close(actual: Vector2, expected: Vector2, message: String) -> void:
    assert_true(
        actual.distance_to(expected) <= TrackSystemScript.GEOMETRY_EPSILON,
        message
    )


func _assert_route_continuous(track, message: String) -> void:
    var points = track.get_reserved_points()
    var distances = _derive_cumulative_distances(points)
    assert_equal(points.size(), distances.size(), "%s point/distance counts" % message)
    assert_true(points.size() >= 1, "%s must retain the departure point" % message)
    _assert_close(distances[0], 0.0, "%s must start at zero distance" % message)
    for index in range(1, points.size()):
        assert_true(distances[index] > distances[index - 1], "%s distances must increase" % message)
        _assert_close(
            distances[index] - distances[index - 1],
            points[index - 1].distance_to(points[index]),
            "%s segment length must match absolute distances" % message
        )
    assert_true(
        absf(
            distances[distances.size() - 1]
            - track.get_reserved_end_distance()
        ) <= TrackSystemScript.GEOMETRY_EPSILON,
        "%s final cumulative distance must match reserved end within fixed epsilon" % message
    )


func _derive_cumulative_distances(points: PackedVector2Array) -> PackedFloat64Array:
    var distances := PackedFloat64Array()
    distances.append(0.0)
    for index in range(1, points.size()):
        distances.append(
            distances[index - 1] + points[index - 1].distance_to(points[index])
        )
    return distances


func _verify_public_point_contract() -> void:
    var track = TrackSystemScript.new(_config(100.0))
    track.apply_left_input(
        _input(
            Vector2(140.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    track.apply_left_input(_input(Vector2(180.0, 100.0), true, true))
    assert_false(
        track.has_method("get_route_points"),
        "get_route_points should not be public"
    )
    assert_false(
        track.has_method("get_route_distances"),
        "get_route_distances should not be public"
    )
    assert_true(
        track.has_method("get_built_points"),
        "get_built_points should be public"
    )
    assert_true(
        track.has_method("get_reserved_points"),
        "get_reserved_points should be public"
    )
    var built_points = track.get_built_points()
    var reserved_points = track.get_reserved_points()
    assert_equal(built_points.size(), 1, "Built points should have exactly one point")
    _assert_vector_close(
        built_points[0],
        Vector2(100.0, 100.0),
        "Built points should contain the departure point"
    )
    assert_equal(reserved_points.size(), 3, "Reserved points should contain the complete route")
    _assert_vector_close(reserved_points[0], Vector2(100.0, 100.0), "Reserved route should start at departure")
    _assert_vector_close(reserved_points[1], Vector2(140.0, 100.0), "Reserved route should include the first sample")
    _assert_vector_close(reserved_points[2], Vector2(180.0, 100.0), "Reserved route should include the second sample")
    var reserved_distance_before = track.get_reserved_end_distance()
    built_points[0] = Vector2(999.0, 999.0)
    reserved_points[0] = Vector2(999.0, 999.0)
    var fresh_built = track.get_built_points()
    var fresh_reserved = track.get_reserved_points()
    assert_equal(fresh_built.size(), 1, "Fresh built points should have exactly one point")
    _assert_vector_close(fresh_built[0], Vector2(100.0, 100.0), "Fresh built points should be unchanged")
    assert_equal(fresh_reserved.size(), 3, "Fresh reserved points should contain the complete route")
    _assert_vector_close(fresh_reserved[0], Vector2(100.0, 100.0), "Fresh reserved departure should be unchanged")
    _assert_vector_close(fresh_reserved[1], Vector2(140.0, 100.0), "Fresh reserved first sample should be unchanged")
    _assert_vector_close(fresh_reserved[2], Vector2(180.0, 100.0), "Fresh reserved endpoint should be unchanged")
    _assert_vector_close(track.get_reserved_endpoint(), Vector2(180.0, 100.0), "Reserved endpoint should remain unchanged")
    _assert_close(
        track.get_reserved_end_distance(),
        reserved_distance_before,
        "Reserved end distance should remain unchanged"
    )
    assert_true(track.is_conservation_valid(), "Detached point arrays should preserve conservation")


func _verify_stale_field_flag_regression() -> void:
    var track = TrackSystemScript.new(_config(1200.0))
    track.apply_left_input(
        _input(
            Vector2(1300.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    _assert_close(
        track.get_reserved_end_distance(),
        1100.0,
        "Stale field flag should still clip at the field boundary"
    )
    _assert_close(
        track.get_available_units(),
        100.0,
        "Stale field flag should charge only the clipped length"
    )
    _assert_vector_close(
        track.get_reserved_endpoint(),
        Vector2(1200.0, 100.0),
        "Stale field flag should end at the field boundary"
    )
    var points = track.get_reserved_points()
    _assert_vector_close(
        points[points.size() - 1],
        Vector2(1200.0, 100.0),
        "Stale field flag should expose the clipped endpoint"
    )
    assert_true(track.is_conservation_valid(), "Stale field flag clipping should conserve units")


func _verify_noncanonical_interior_cancellation_regression() -> void:
    var track = TrackSystemScript.new(_config(100.0))
    track.apply_left_input(
        _input(
            Vector2(140.0, 100.0), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    var cancel_position := Vector2(100.0002, 100.0)
    var right_won = track.apply_right_input(
        _input(cancel_position, true, false, false, false, true)
    )
    assert_true(right_won, "Noncanonical interior cancellation should win the tick")
    var cut_distance = track.get_reserved_end_distance()
    _assert_close(cut_distance, 0.0002, "Noncanonical cut should retain its exact distance")
    assert_true(
        cut_distance > TrackSystemScript.GEOMETRY_EPSILON,
        "Noncanonical cut should be strictly beyond the departure epsilon"
    )
    var points = track.get_reserved_points()
    assert_equal(points.size(), 2, "Noncanonical cut should retain an explicit terminal point")
    _assert_vector_close(points[0], Vector2(100.0, 100.0), "Noncanonical cut should retain departure")
    _assert_vector_close(points[1], cancel_position, "Noncanonical cut should retain the exact terminal point")
    _assert_vector_close(
        points[1],
        track.get_position_at_distance(cut_distance),
        "Noncanonical terminal should match its distance position"
    )
    _assert_vector_close(
        track.get_reserved_endpoint(),
        cancel_position,
        "Noncanonical cut should expose the exact reserved endpoint"
    )
    _assert_close(
        track.get_available_units(),
        99.9998,
        "Noncanonical cut should refund the exact suffix"
    )
    assert_true(track.is_conservation_valid(), "Noncanonical cut should conserve units")
    _assert_route_continuous(track, "Noncanonical interior cancellation")


func _verify_float32_endpoint_accounting() -> void:
    var track = TrackSystemScript.new(_config(2000.0))
    track.apply_left_input(
        _input(
            Vector2(55.533947, 458.24698), true, true, true, false, false,
            Vector2(100.0, 100.0), true
        )
    )
    track.apply_left_input(_input(Vector2(1058.9739, 80.27229), true, true))
    var reserved_points = track.get_reserved_points()
    assert_equal(
        reserved_points.size(),
        3,
        "Long diagonal route should retain three points"
    )
    var geometry_length := 0.0
    for index in range(1, reserved_points.size()):
        geometry_length += reserved_points[index - 1].distance_to(reserved_points[index])
    assert_true(
        absf(track.get_reserved_end_distance() - geometry_length)
        <= TrackSystemScript.GEOMETRY_EPSILON,
        "Reserved scalar distance should match stored geometry within fixed epsilon"
    )
    assert_true(
        absf(track.get_available_units() + geometry_length - track.get_total_units())
        <= TrackSystemScript.GEOMETRY_EPSILON,
        "Stored geometry and available units should conserve inventory"
    )
    _assert_vector_close(
        track.get_reserved_endpoint(),
        reserved_points[reserved_points.size() - 1],
        "Reserved endpoint should match detached route endpoint"
    )
    assert_true(
        track.is_conservation_valid(),
        "Long diagonal route should conserve scalar inventory"
    )


func _verify_float32_clipped_cap_accounting() -> void:
    var departure := Vector2(600.0, 100.8)
    var sample := Vector2(1185.2179, 534.0648)
    var track = TrackSystemScript.new(_config(720.0, departure))
    track.apply_left_input(
        _input(
            sample, true, true, true, false, false,
            departure, true
        )
    )
    var reserved_points = track.get_reserved_points()
    assert_equal(
        reserved_points.size(),
        2,
        "Diagonal inventory clip should retain two points"
    )
    var geometry_length = reserved_points[0].distance_to(reserved_points[1])
    var radial_x := 1178.6697998046875
    assert_true(
        absf(reserved_points[1].x - radial_x)
        <= TrackSystemScript.GEOMETRY_EPSILON,
        "Stored X refinement must remain within one fixed-epsilon lattice correction"
    )
    assert_true(
        geometry_length <= 720.0,
        "Diagonal inventory clip geometry must not exceed cap"
    )
    assert_true(
        720.0 - geometry_length <= TrackSystemScript.GEOMETRY_EPSILON,
        "Diagonal inventory clip must reach cap within fixed epsilon from below"
    )
    assert_true(
        track.get_reserved_end_distance() <= 720.0,
        "Clipped scalar distance must not exceed cap"
    )
    assert_true(
        absf(track.get_reserved_end_distance() - geometry_length)
        <= TrackSystemScript.GEOMETRY_EPSILON,
        "Clipped scalar distance should match stored geometry within fixed epsilon"
    )
    assert_equal(
        track.get_available_units(),
        0.0,
        "Diagonal inventory clip should canonicalize remaining units to zero"
    )
    _assert_vector_close(
        reserved_points[reserved_points.size() - 1],
        track.get_reserved_endpoint(),
        "Detached clipped endpoint should match reserved endpoint"
    )
    assert_true(
        track.is_conservation_valid(),
        "Diagonal inventory clip should conserve units"
    )


func _verify_float32_right_boundary_containment() -> void:
    var departure := Vector2(156.3, 420.8)
    var sample := Vector2(1380.3, 472.8)
    var track := TrackSystemScript.new(_config(2000.0, departure))
    track.apply_left_input(_input(sample, true, true, true, false, false, departure, true))
    var reserved_points := track.get_reserved_points()
    assert_equal(reserved_points.size(), 2,
        "Reserved points count must be exactly 2")
    var endpoint := reserved_points[1]
    assert_true(endpoint.x <= 1200.0,
        "Endpoint x-coordinate must not exceed right boundary at 1200.0")
    var boundary_gap := 1200.0 - endpoint.x
    assert_true(boundary_gap >= 0.0,
        "Boundary gap must be non-negative")
    assert_true(boundary_gap <= TrackSystemScript.GEOMETRY_EPSILON,
        "Boundary gap must not exceed geometry epsilon")
    var delta_x := sample.x - departure.x
    var delta_y := sample.y - departure.y
    var ratio := (1200.0 - departure.x) / delta_x
    var boundary_delta_x := delta_x * ratio
    var boundary_delta_y := delta_y * ratio
    var field_cap := sqrt(
        boundary_delta_x * boundary_delta_x
        + boundary_delta_y * boundary_delta_y
    )
    var scalar_distance := track.get_reserved_end_distance()
    assert_true(scalar_distance <= field_cap,
        "Scalar distance must not exceed field cap")
    assert_true(field_cap - scalar_distance <= TrackSystemScript.GEOMETRY_EPSILON,
        "Field cap minus scalar distance must not exceed geometry epsilon")
    var geometry_length := reserved_points[0].distance_to(reserved_points[1])
    assert_true(absf(scalar_distance - geometry_length) <= TrackSystemScript.GEOMETRY_EPSILON,
        "Absolute difference between scalar distance and geometry length must not exceed geometry epsilon")
    assert_true(track.is_conservation_valid(),
        "Track conservation must be valid")


func _verify_sub_epsilon_axis_field_exit() -> void:
    var departure := Vector2(0.00005, 100.0)
    var sample := Vector2(-0.00004, 200.0)
    var track := TrackSystemScript.new(_config(2000.0, departure))
    track.apply_left_input(
        _input(sample, false, true, true, false, false, departure, true)
    )
    var reserved_points := track.get_reserved_points()
    assert_equal(reserved_points.size(), 2, "Reserved points count must be 2")
    var endpoint := reserved_points[1]
    assert_true(endpoint.x >= 0.0, "Endpoint X must be >= 0.0")
    assert_true(
        endpoint.x <= TrackSystemScript.GEOMETRY_EPSILON,
        "Endpoint X must be <= GEOMETRY_EPSILON"
    )
    assert_true(endpoint.y >= 0.0, "Endpoint Y must be >= 0.0")
    assert_true(endpoint.y <= 560.0, "Endpoint Y must be <= 560.0")
    var geometry_length := reserved_points[0].distance_to(endpoint)
    var reserved_end_distance := track.get_reserved_end_distance()
    assert_true(
        absf(reserved_end_distance - geometry_length)
        <= TrackSystemScript.GEOMETRY_EPSILON,
        "Reserved end distance must match geometry length within epsilon"
    )
    assert_true(track.is_conservation_valid(), "Conservation must be valid")


func _verify_canonical_vertex_chooses_true_nearest() -> void:
    var departure := Vector2.ZERO
    var track := TrackSystemScript.new(_config(100.0, departure))
    track.apply_left_input(
        _input(
            Vector2(40.0, 0.0), true, true, true, false, false,
            departure, true
        )
    )
    assert_true(
        track.apply_right_input(
            _input(Vector2(0.00011, 0.0), true, false, false, false, true)
        ),
        "First cancel should win"
    )
    var terminal_distance := track.get_reserved_end_distance()
    assert_true(
        terminal_distance > TrackSystemScript.GEOMETRY_EPSILON,
        "Terminal distance should exceed epsilon"
    )
    assert_equal(
        track.get_reserved_points().size(),
        2,
        "Reserved points should be 2 after first cancel"
    )
    var query_distance := 0.0000505
    assert_true(
        query_distance < terminal_distance - query_distance,
        "Query distance should be strictly nearer to departure"
    )
    assert_true(
        track.apply_right_input(
            _input(Vector2(query_distance, 0.0), true, false, false, false, true)
        ),
        "Second cancel at query_distance should win"
    )
    assert_equal(
        track.get_reserved_end_distance(),
        0.0,
        "Reserved end distance should be exactly 0.0"
    )
    assert_equal(
        track.get_reserved_points().size(),
        1,
        "Reserved points should be 1 after second cancel"
    )
    assert_equal(
        track.get_available_units(),
        100.0,
        "Available units should be exactly 100.0"
    )
    assert_true(track.is_conservation_valid(), "Conservation should hold")


func _verify_float32_inventory_under_rounding() -> void:
    var departure := Vector2(106.0, 298.0)
    var sample := Vector2(1115.1, 352.6)
    var track := TrackSystemScript.new(_config(1000.0, departure))
    track.apply_left_input(
        _input(sample, true, true, true, false, false, departure, true)
    )
    var reserved_points := track.get_reserved_points()
    assert_equal(
        reserved_points.size(),
        2,
        "Inventory under-rounding should retain two reserved points"
    )
    var geometry_length := reserved_points[0].distance_to(reserved_points[1])
    assert_true(
        geometry_length <= 1000.0,
        "Inventory-clipped geometry must not exceed the cap"
    )
    assert_true(
        1000.0 - geometry_length <= TrackSystemScript.GEOMETRY_EPSILON,
        "Inventory-clipped geometry must reach the cap within fixed epsilon"
    )
    assert_true(
        track.get_reserved_end_distance() <= 1000.0,
        "Inventory-clipped scalar distance must not exceed the cap"
    )
    assert_true(
        absf(track.get_reserved_end_distance() - geometry_length)
        <= TrackSystemScript.GEOMETRY_EPSILON,
        "Inventory-clipped scalar distance must match stored geometry"
    )
    assert_equal(
        track.get_available_units(),
        0.0,
        "Inventory under-rounding must canonicalize remaining units to zero"
    )
    assert_true(
        track.is_conservation_valid(),
        "Inventory under-rounding must conserve units"
    )


func _verify_projection_tie_does_not_chain() -> void:
    var total := 2000.0
    var departure := Vector2(100.0, 100.0)
    var track := TrackSystemScript.new(_config(total, departure))
    var p1 := Vector2(200.0, 100.0)
    var p2 := Vector2(300.0, 100.000075)
    var p3 := Vector2(100.0, 100.000075)
    var p4 := Vector2(0.0, 100.00015)
    var p5 := Vector2(200.0, 100.00015)
    track.apply_left_input(
        _input(p1, true, true, true, false, false, departure, true)
    )
    track.apply_left_input(_input(p2, true, true))
    track.apply_left_input(_input(p3, true, true))
    track.apply_left_input(_input(p4, true, true))
    track.apply_left_input(_input(p5, true, true))
    assert_equal(
        track.get_reserved_points().size(),
        6,
        "Projection tie route should contain six points before cancellation"
    )
    var query := Vector2(150.0, 100.0)
    var right_won := track.apply_right_input(
        _input(query, true, false, false, false, true)
    )
    assert_true(right_won, "Projection tie cancellation should win the tick")
    var expected_projection := Vector2(150.0, 100.000075)
    var expected_distance := (
        departure.distance_to(p1)
        + p1.distance_to(p2)
        + p2.distance_to(expected_projection)
    )
    var reserved_end := track.get_reserved_end_distance()
    assert_true(
        absf(reserved_end - expected_distance)
        <= TrackSystemScript.GEOMETRY_EPSILON,
        "Projection tie must select the greatest route within the true nearest epsilon"
    )
    assert_true(
        track.get_reserved_endpoint().distance_to(expected_projection)
        <= TrackSystemScript.GEOMETRY_EPSILON,
        "Projection tie endpoint must lie on the second segment"
    )
    assert_true(
        absf(track.get_available_units() + reserved_end - total)
        <= TrackSystemScript.GEOMETRY_EPSILON,
        "Projection tie cancellation must conserve scalar inventory"
    )
    assert_true(
        track.is_conservation_valid(),
        "Projection tie cancellation must preserve conservation"
    )
