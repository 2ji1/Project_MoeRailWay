extends "res://tests/support/prototype_test.gd"

const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")

func _config(
    total_units := 200.0,
    departure_position := Vector2(100.0, 100.0),
    logical_field_size := Vector2(1200.0, 560.0)
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
        logical_field_size,
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


func _reserve_points(track, points: Array[Vector2]) -> void:
    if points.is_empty():
        return
    var first_frame = _input(points[0], true, true, true, false, false, track.get_reserved_endpoint(), true)
    track.apply_left_input(first_frame)
    for i in range(1, points.size()):
        var frame = _input(points[i], true, true, false, false, false, Vector2.INF, null, Vector2.INF, null)
        track.apply_left_input(frame)
    var last_frame = _input(points[-1], true, false, false, true, false, Vector2.INF, null, Vector2.INF, null)
    track.apply_left_input(last_frame)

func _right(track, position: Vector2) -> bool:
    return track.apply_right_input(
        _input(
            position,
            true,
            false,
            false,
            false,
            true,
            Vector2.INF,
            null,
            position,
            true
        )
    )

func _assert_close(actual: float, expected: float, message: String) -> void:
    assert_true(absf(actual - expected) <= TrackSystemScript.GEOMETRY_EPSILON, message + " (expected " + str(expected) + ", got " + str(actual) + ", epsilon " + str(TrackSystemScript.GEOMETRY_EPSILON) + ")")

func _assert_vector_close(actual: Vector2, expected: Vector2, message: String) -> void:
    assert_true(actual.distance_to(expected) <= TrackSystemScript.GEOMETRY_EPSILON, message + " (expected " + str(expected) + ", got " + str(actual) + ", epsilon " + str(TrackSystemScript.GEOMETRY_EPSILON) + ")")

func _assert_no_adjacent_duplicates(points: PackedVector2Array, context: String) -> void:
    for i in range(1, points.size()):
        assert_true(
            points[i].distance_to(points[i - 1]) > 0.0,
            "%s: adjacent points %d and %d must not be exact duplicates"
            % [context, i - 1, i]
        )

func _test_construction_regions() -> void:
    var track = TrackSystemScript.new(_config())

    var built_points = track.get_built_points()
    var reserved_points = track.get_reserved_points()
    assert_equal(built_points.size(), 1, "New track: built points initially one departure point")
    assert_equal(reserved_points.size(), 1, "New track: reserved points initially one departure point")
    _assert_vector_close(built_points[0], Vector2(100.0, 100.0), "Built point at departure")
    _assert_vector_close(reserved_points[0], Vector2(100.0, 100.0), "Reserved point at departure")

    _reserve_points(track, [Vector2(140.0, 100.0), Vector2(180.0, 100.0)])

    assert_equal(track.get_active_start_distance(), 0.0, "Active start distance initially zero")
    _assert_close(track.get_built_end_distance(), 0.0, "Built end distance initially zero")
    _assert_close(track.get_reserved_end_distance(), 80.0, "Reserved end distance 80 after reserve")

    var advanced = track.advance_construction(2.0)
    assert_equal(advanced, 2, "advance_construction(2.0) returns 2")
    _assert_close(track.get_built_end_distance(), 2.0, "Built end distance 2 after first advance")

    built_points = track.get_built_points()
    reserved_points = track.get_reserved_points()
    assert_equal(built_points.size(), 2, "Built points exactly two after first advance")
    assert_equal(reserved_points.size(), 3, "Reserved points exactly three after first advance")
    _assert_vector_close(built_points[0], Vector2(100.0, 100.0), "Built point 0 at departure")
    _assert_vector_close(built_points[1], Vector2(102.0, 100.0), "Built point 1 at 102,100")
    _assert_vector_close(reserved_points[0], Vector2(102.0, 100.0), "Reserved point 0 at 102,100")
    _assert_vector_close(reserved_points[1], Vector2(140.0, 100.0), "Reserved point 1 at 140,100")
    _assert_vector_close(reserved_points[2], Vector2(180.0, 100.0), "Reserved point 2 at 180,100")

    built_points[0] = Vector2(0.0, 0.0)
    reserved_points[0] = Vector2(0.0, 0.0)
    var fresh_built = track.get_built_points()
    var fresh_reserved = track.get_reserved_points()
    _assert_vector_close(fresh_built[0], Vector2(100.0, 100.0), "Canonical built point 0 unchanged after mutation")
    _assert_vector_close(fresh_reserved[0], Vector2(102.0, 100.0), "Canonical reserved point 0 unchanged after mutation")

    advanced = track.advance_construction(38.0)
    assert_equal(advanced, 38, "advance_construction(38.0) returns 38")
    _assert_close(track.get_built_end_distance(), 40.0, "Built end distance 40 after second advance")

    built_points = track.get_built_points()
    reserved_points = track.get_reserved_points()
    _assert_vector_close(built_points[-1], Vector2(140.0, 100.0), "Built boundary exactly at 140,100")
    _assert_vector_close(reserved_points[0], Vector2(140.0, 100.0), "Reserved boundary exactly at 140,100")
    _assert_no_adjacent_duplicates(built_points, "Built points after 40 units")
    _assert_no_adjacent_duplicates(reserved_points, "Reserved points after 40 units")

    advanced = track.advance_construction(100.0)
    assert_equal(advanced, 40, "advance_construction(100.0) returns 40 (clamped)")
    _assert_close(track.get_built_end_distance(), 80.0, "Built end distance clamped to 80")
    _assert_close(track.get_reserved_end_distance(), 80.0, "Reserved end distance clamped to 80")

    reserved_points = track.get_reserved_points()
    assert_equal(reserved_points.size(), 1, "Reserved zero region contains exactly one point")
    _assert_vector_close(reserved_points[0], Vector2(180.0, 100.0), "Reserved point at 180,100")

    advanced = track.advance_construction(10.0)
    assert_equal(advanced, 0, "Further advance returns 0 when built equals reserved")

    _assert_close(track.get_available_units(), 120.0, "Available units unchanged by construction (200 - 80 = 120)")
    assert_true(track.is_conservation_valid(), "Conservation valid after construction")

func _test_release_and_extension() -> void:
    var track = TrackSystemScript.new(_config())

    _reserve_points(track, [Vector2(140.0, 100.0)])
    track.advance_construction(2.0)

    var release_frame = _input(Vector2(140.0, 100.0), true, false, false, true, false, Vector2.INF, null, Vector2.INF, null)
    track.apply_left_input(release_frame)

    var advanced = track.advance_construction(2.0)
    assert_equal(advanced, 2, "advance_construction(2.0) after release returns 2")
    _assert_close(track.get_built_end_distance(), 4.0, "Built end distance 4 after advance post-release")

    var endpoint = track.get_reserved_endpoint()
    _reserve_points(track, [Vector2(180.0, 100.0)])

    assert_equal(track.get_active_start_distance(), 0.0, "Active remains 0 after new stroke")
    _assert_close(track.get_built_end_distance(), 4.0, "Built remains 4 after new stroke")
    _assert_close(track.get_reserved_end_distance(), 80.0, "Reserved extends from 40 to 80")
    assert_true(track.is_conservation_valid(), "Conservation valid after extension")


func _test_region_getters_keep_noncanonical_near_vertex_boundary() -> void:
    var track = TrackSystemScript.new(_config(1000.0))
    _reserve_points(
        track,
        [Vector2(140.0, 100.0), Vector2(180.0, 100.0)]
    )
    var eps = TrackSystemScript.GEOMETRY_EPSILON
    var requested = 40.0 + eps / 2.0
    var returned = track.advance_construction(requested)
    _assert_close(
        returned,
        requested,
        "Construction must retain the requested near-vertex boundary"
    )
    _assert_close(
        track.get_built_end_distance(),
        requested,
        "Built end must retain the requested near-vertex distance"
    )
    var built_points = track.get_built_points()
    var reserved_points = track.get_reserved_points()
    assert_true(
        built_points[-1] == reserved_points[0],
        "Built and reserved regions must share the exact boundary value"
    )
    var expected_boundary = track.get_position_at_distance(
        track.get_built_end_distance()
    )
    assert_true(
        built_points[-1] == expected_boundary,
        "Built region must end at the exact noncanonical boundary"
    )
    assert_true(
        built_points[-1] != Vector2(140.0, 100.0),
        "Near-vertex boundary must not be suppressed as canonical"
    )
    assert_equal(
        built_points.size(),
        3,
        "Built region must include departure, canonical vertex, and boundary"
    )
    assert_equal(
        reserved_points.size(),
        2,
        "Reserved region must include boundary and endpoint"
    )
    _assert_no_adjacent_duplicates(built_points, "Near-vertex built region")
    _assert_no_adjacent_duplicates(reserved_points, "Near-vertex reserved region")
    assert_true(
        track.is_conservation_valid(),
        "Near-vertex region slicing must conserve inventory"
    )


func _test_cancel_ordering_and_invalid_right_targets() -> void:
    var track = TrackSystemScript.new(_config())

    _reserve_points(track, [Vector2(140.0, 100.0), Vector2(180.0, 100.0)])

    _right(track, Vector2(120.0, 100.0))
    _assert_close(track.get_reserved_end_distance(), 20.0, "Reserved end becomes 20 after right cancel at 120")

    var advanced = track.advance_construction(100.0)
    assert_equal(advanced, 20, "advance_construction(100) returns 20 (clamped to reserved)")
    _assert_close(track.get_built_end_distance(), 20.0, "Built end distance 20")
    _assert_close(track.get_reserved_end_distance(), 20.0, "Reserved end distance 20")

    var snap_active = track.get_active_start_distance()
    var snap_built = track.get_built_end_distance()
    var snap_reserved = track.get_reserved_end_distance()
    var snap_available = track.get_available_units()
    var snap_built_points = track.get_built_points().duplicate()
    var snap_reserved_points = track.get_reserved_points().duplicate()

    _right(track, Vector2(110.0, 100.0))

    assert_equal(track.get_active_start_distance(), snap_active, "Active start unchanged after right-click on built")
    _assert_close(track.get_built_end_distance(), snap_built, "Built end unchanged after right-click on built")
    _assert_close(track.get_reserved_end_distance(), snap_reserved, "Reserved end unchanged after right-click on built")
    assert_equal(track.get_available_units(), snap_available, "Available unchanged after right-click on built")
    assert_equal(track.get_built_points(), snap_built_points, "Built points unchanged after right-click on built")
    assert_equal(track.get_reserved_points(), snap_reserved_points, "Reserved points unchanged after right-click on built")

    var built_click_track = TrackSystemScript.new(_config())
    _reserve_points(
        built_click_track,
        [Vector2(140.0, 100.0), Vector2(180.0, 100.0)]
    )
    built_click_track.advance_construction(20.0)
    var built_click_active = built_click_track.get_active_start_distance()
    var built_click_built = built_click_track.get_built_end_distance()
    var built_click_reserved = built_click_track.get_reserved_end_distance()
    var built_click_available = built_click_track.get_available_units()
    var built_click_built_points = built_click_track.get_built_points().duplicate()
    var built_click_reserved_points = (
        built_click_track.get_reserved_points().duplicate()
    )
    assert_true(
        _right(built_click_track, Vector2(100.0, 100.0)),
        "Right press inside the built prefix must win without canceling"
    )
    assert_equal(
        built_click_track.get_active_start_distance(),
        built_click_active,
        "Built-prefix right press must preserve active start"
    )
    _assert_close(
        built_click_track.get_built_end_distance(),
        built_click_built,
        "Built-prefix right press must preserve built end"
    )
    _assert_close(
        built_click_track.get_reserved_end_distance(),
        built_click_reserved,
        "Built-prefix right press must preserve the reserved suffix"
    )
    assert_equal(
        built_click_track.get_available_units(),
        built_click_available,
        "Built-prefix right press must not refund inventory"
    )
    assert_equal(
        built_click_track.get_built_points(),
        built_click_built_points,
        "Built-prefix right press must preserve built geometry"
    )
    assert_equal(
        built_click_track.get_reserved_points(),
        built_click_reserved_points,
        "Built-prefix right press must preserve reserved geometry"
    )

    var track2 = TrackSystemScript.new(_config())
    _reserve_points(track2, [Vector2(140.0, 100.0), Vector2(180.0, 100.0)])
    track2.advance_construction(80.0)

    var recovered = track2.recover_behind(80.0)
    assert_equal(recovered, 80, "recover_behind(80) returns 80")
    assert_equal(track2.get_active_start_distance(), 80.0, "Active start 80 after recovery")
    _assert_close(track2.get_built_end_distance(), 80.0, "Built end 80 after recovery")
    _assert_close(track2.get_reserved_end_distance(), 80.0, "Reserved end 80 after recovery")

    var route_points = track2.get_built_points()
    assert_equal(route_points.size(), 1, "Route is one point at 180,100")
    _assert_vector_close(route_points[0], Vector2(180.0, 100.0), "Route point at 180,100")

    snap_active = track2.get_active_start_distance()
    snap_built = track2.get_built_end_distance()
    snap_reserved = track2.get_reserved_end_distance()
    snap_available = track2.get_available_units()
    snap_built_points = track2.get_built_points().duplicate()
    snap_reserved_points = track2.get_reserved_points().duplicate()

    _right(track2, Vector2(140.0, 100.0))

    assert_equal(track2.get_active_start_distance(), snap_active, "Active start unchanged after right-click on removed point")
    _assert_close(track2.get_built_end_distance(), snap_built, "Built end unchanged after right-click on removed point")
    _assert_close(track2.get_reserved_end_distance(), snap_reserved, "Reserved end unchanged after right-click on removed point")
    assert_equal(track2.get_available_units(), snap_available, "Available unchanged after right-click on removed point")
    assert_equal(track2.get_built_points(), snap_built_points, "Built points unchanged after right-click on removed point")
    assert_equal(track2.get_reserved_points(), snap_reserved_points, "Reserved points unchanged after right-click on removed point")


func _test_reserved_projection_ignores_nearer_built_prefix() -> void:
    var track = TrackSystemScript.new(_config(1000.0))
    _reserve_points(
        track,
        [
            Vector2(200.0, 100.0),
            Vector2(200.0, 110.0),
            Vector2(100.0, 110.0),
        ]
    )
    _assert_close(
        track.advance_construction(100.0),
        100.0,
        "Reserved-only projection route must construct 100 units"
    )
    _assert_close(
        track.get_reserved_end_distance(),
        210.0,
        "Parallel reserved suffix must end at absolute distance 210"
    )
    var active_snapshot = track.get_active_start_distance()
    var built_snapshot = track.get_built_end_distance()
    var built_points_snapshot = track.get_built_points().duplicate()
    assert_true(
        _right(track, Vector2(150.0, 100.0)),
        "Reserved-only hit testing must ignore the nearer built prefix"
    )
    assert_equal(
        track.get_active_start_distance(),
        active_snapshot,
        "Reserved-only cancellation must preserve active start"
    )
    _assert_close(
        track.get_built_end_distance(),
        built_snapshot,
        "Reserved-only cancellation must preserve built end"
    )
    _assert_close(
        track.get_reserved_end_distance(),
        160.0,
        "Parallel reserved suffix must cancel at absolute distance 160"
    )
    _assert_close(
        track.get_available_units(),
        840.0,
        "Parallel reserved suffix cancellation must refund 50 units"
    )
    assert_equal(
        track.get_built_points(),
        built_points_snapshot,
        "Reserved-only cancellation must preserve built geometry"
    )
    _assert_vector_close(
        track.get_reserved_endpoint(),
        Vector2(150.0, 110.0),
        "Parallel reserved suffix must end at the reserved projection"
    )
    assert_true(
        track.is_conservation_valid(),
        "Reserved-only cancellation must conserve inventory"
    )


func _test_intersection_blockers() -> void:
    var built_track = TrackSystemScript.new(_config(1000.0))
    _reserve_points(
        built_track,
        [Vector2(200.0, 100.0), Vector2(200.0, 200.0)]
    )
    built_track.advance_construction(100.0)
    var old_reserved_end := built_track.get_reserved_end_distance()
    var endpoint_before := built_track.get_reserved_endpoint()
    var target := Vector2(100.0, 0.0)
    var direct_distance := endpoint_before.distance_to(target)
    _reserve_points(built_track, [target])
    var accepted_extension := (
        built_track.get_reserved_end_distance() - old_reserved_end
    )
    assert_true(
        accepted_extension
            < direct_distance - TrackSystemScript.GEOMETRY_EPSILON,
        "Built prefix must block a crossing extension"
    )
    assert_true(
        built_track.get_reserved_endpoint().distance_to(target)
            > TrackSystemScript.GEOMETRY_EPSILON,
        "Built-prefix blocker must stop before the target"
    )
    assert_true(
        built_track.is_conservation_valid(),
        "Built-prefix blocker must conserve inventory"
    )

    var reserved_track = TrackSystemScript.new(_config(1000.0))
    _reserve_points(
        reserved_track,
        [Vector2(200.0, 100.0), Vector2(200.0, 200.0)]
    )
    reserved_track.advance_construction(50.0)
    old_reserved_end = reserved_track.get_reserved_end_distance()
    endpoint_before = reserved_track.get_reserved_endpoint()
    target = Vector2(175.0, 0.0)
    direct_distance = endpoint_before.distance_to(target)
    _reserve_points(reserved_track, [target])
    accepted_extension = (
        reserved_track.get_reserved_end_distance() - old_reserved_end
    )
    assert_true(
        accepted_extension
            < direct_distance - TrackSystemScript.GEOMETRY_EPSILON,
        "Reserved suffix must block a crossing extension"
    )
    assert_true(
        reserved_track.get_reserved_endpoint().distance_to(target)
            > TrackSystemScript.GEOMETRY_EPSILON,
        "Reserved-suffix blocker must stop before the target"
    )
    assert_true(
        reserved_track.is_conservation_valid(),
        "Reserved-suffix blocker must conserve inventory"
    )


func _test_partial_recovery() -> void:
    var track = TrackSystemScript.new(_config())

    _reserve_points(track, [Vector2(140.0, 100.0), Vector2(180.0, 100.0)])
    track.advance_construction(80.0)

    assert_equal(track.get_available_units(), 120.0, "Available before recovery: 120 for total 200")

    var recovered = track.recover_behind(25.0)
    assert_equal(recovered, 25, "recover_behind(25) returns 25")
    assert_equal(track.get_active_start_distance(), 25.0, "Active start becomes 25")
    _assert_close(track.get_built_end_distance(), 80.0, "Built end absolute remains 80")
    _assert_close(track.get_reserved_end_distance(), 80.0, "Reserved end absolute remains 80")

    var built_points = track.get_built_points()
    _assert_vector_close(built_points[0], Vector2(125.0, 100.0), "First built point at 125,100 after recovery")

    var reserved_points = track.get_reserved_points()
    assert_equal(reserved_points.size(), 1, "Reserved zero region remains one point")
    _assert_vector_close(reserved_points[0], Vector2(180.0, 100.0), "Reserved point at 180,100")

    assert_equal(track.get_available_units(), 145.0, "Available becomes 145 (120 + 25)")
    _assert_no_adjacent_duplicates(built_points, "Built points after partial recovery")
    _assert_no_adjacent_duplicates(reserved_points, "Reserved points after partial recovery")
    assert_true(track.is_conservation_valid(), "Conservation valid after partial recovery")

func _test_canonical_recovery() -> void:
    var track = TrackSystemScript.new(_config())

    _reserve_points(track, [Vector2(140.0, 100.0), Vector2(180.0, 100.0), Vector2(220.0, 100.0)])
    track.advance_construction(120.0)

    var recovered = track.recover_behind(40.0)
    assert_equal(recovered, 40, "Exact recovery returns 40")
    assert_equal(track.get_active_start_distance(), 40.0, "Active start exactly 40")

    var built_points = track.get_built_points()
    var count_at_140 = 0
    for p in built_points:
        if p.distance_to(Vector2(140.0, 100.0)) <= TrackSystemScript.GEOMETRY_EPSILON:
            count_at_140 += 1
    assert_equal(count_at_140, 1, "First retained point at 140,100 occurs exactly once")

    var track2 = TrackSystemScript.new(_config())
    _reserve_points(track2, [Vector2(140.0, 100.0), Vector2(180.0, 100.0), Vector2(220.0, 100.0)])
    track2.advance_construction(120.0)

    var eps = TrackSystemScript.GEOMETRY_EPSILON
    recovered = track2.recover_behind(40.0 + eps / 2.0)
    assert_equal(recovered, 40, "Epsilon-above recovery returns exactly 40")
    assert_equal(track2.get_active_start_distance(), 40.0, "Active start exactly 40")

    built_points = track2.get_built_points()
    count_at_140 = 0
    for p in built_points:
        if p.distance_to(Vector2(140.0, 100.0)) <= eps:
            count_at_140 += 1
    assert_equal(count_at_140, 1, "First retained point at 140,100 occurs exactly once (epsilon-above)")
    _assert_no_adjacent_duplicates(built_points, "Built points after epsilon-above recovery")

    recovered = track2.recover_behind(60.0)
    assert_equal(recovered, 20, "Second recovery returns 20 (60 - 40)")
    assert_equal(track2.get_active_start_distance(), 60.0, "Active start exactly 60")
    _assert_close(track2.get_built_end_distance(), 120.0, "Built end absolute still 120")
    _assert_close(track2.get_reserved_end_distance(), 120.0, "Reserved end absolute still 120")

    assert_equal(track.get_available_units(), 120.0, "Available reflects exact recovered length (first track)")
    assert_equal(track2.get_available_units(), 140.0, "Available reflects exact recovered length (second track, 200 - 60)")
    assert_true(track.is_conservation_valid(), "Conservation valid (first track)")
    assert_true(track2.is_conservation_valid(), "Conservation valid (second track)")

func _test_backward_only() -> void:
    var track = TrackSystemScript.new(_config())

    _reserve_points(track, [Vector2(140.0, 100.0), Vector2(180.0, 100.0), Vector2(220.0, 100.0)])
    track.advance_construction(120.0)

    var eps = TrackSystemScript.GEOMETRY_EPSILON
    var raw = 40.0 - eps / 2.0
    var recovered = track.recover_behind(raw)

    assert_true(
        recovered <= raw,
        "Recovery must never move forward beyond the raw cutoff"
    )
    assert_true(
        track.get_active_start_distance() <= raw,
        "Active start must never move forward beyond the raw cutoff"
    )
    assert_true(absf(recovered - raw) <= eps, "Returned recovery equals raw within epsilon")
    assert_true(track.get_active_start_distance() > 0.0, "Active start > 0 (strict forward guard)")

    var pos = track.get_position_at_distance(raw)
    var first_built = track.get_built_points()[0]
    _assert_vector_close(first_built, pos, "First built point equals position at raw distance")
    _assert_vector_close(pos, Vector2(100.0 + raw, 100.0), "Position near (100 + raw, 100)")

    _assert_close(track.get_built_end_distance(), 120.0, "Built end absolute remains 120")
    _assert_close(track.get_reserved_end_distance(), 120.0, "Reserved end absolute remains 120")
    assert_true(track.is_conservation_valid(), "Conservation valid after backward-only recovery")


func _test_recovery_preserves_epsilon_close_corner() -> void:
    var track = TrackSystemScript.new(_config())
    _reserve_points(
        track,
        [Vector2(140.0, 100.0), Vector2(140.0, 140.0)]
    )
    track.advance_construction(80.0)
    var eps = TrackSystemScript.GEOMETRY_EPSILON
    var raw = 40.0 - eps / 2.0
    var recovered = track.recover_behind(raw)
    assert_true(
        recovered <= raw,
        "Corner recovery must not advance beyond the raw cutoff"
    )
    assert_true(
        track.get_active_start_distance() <= raw,
        "Corner recovery active start must not advance beyond raw"
    )
    var built_points = track.get_built_points()
    assert_equal(
        built_points.size(),
        3,
        "Recovery must retain the epsilon-close canonical corner"
    )
    if built_points.size() != 3:
        return
    _assert_vector_close(
        built_points[0],
        Vector2(100.0 + raw, 100.0),
        "Recovery must begin at the raw interpolated cutoff"
    )
    assert_true(
        built_points[1] == Vector2(140.0, 100.0),
        "Recovery must preserve the exact canonical corner"
    )
    assert_true(
        built_points[2] == Vector2(140.0, 140.0),
        "Recovery must preserve the vertical endpoint"
    )
    _assert_vector_close(
        track.get_heading_at_distance(40.0),
        Vector2.DOWN,
        "Exact corner heading uses the outgoing segment"
    )
    _assert_vector_close(
        track.get_heading_at_distance((raw + 40.0) / 2.0),
        Vector2.RIGHT,
        "Heading before the exact corner stays on the incoming segment"
    )
    _assert_vector_close(
        track.get_heading_at_distance(40.0 + eps / 4.0),
        Vector2.DOWN,
        "Heading after the exact corner uses the outgoing segment"
    )
    _assert_vector_close(
        track.get_heading_at_distance(80.0),
        Vector2.DOWN,
        "Endpoint heading uses the final segment"
    )

    var high_track = TrackSystemScript.new(
        _config(200.0, Vector2(1060.0, 100.0))
    )
    _reserve_points(
        high_track,
        [Vector2(1100.0, 100.0), Vector2(1100.0, 140.0)]
    )
    high_track.advance_construction(80.0)
    var high_raw = 40.0 - eps / 2.0
    high_track.recover_behind(high_raw)
    var high_built_points = high_track.get_built_points()
    _assert_no_adjacent_duplicates(
        high_built_points,
        "High-coordinate epsilon-close recovery"
    )
    _assert_vector_close(
        high_track.get_heading_at_distance(
            high_track.get_active_start_distance()
        ),
        Vector2.RIGHT,
        "High-coordinate recovery must preserve the incoming segment heading"
    )

    var final_track = TrackSystemScript.new(
        _config(200.0, Vector2(1100.0, 100.0))
    )
    _reserve_points(final_track, [Vector2(1060.0, 100.0)])
    final_track.advance_construction(40.0)
    var final_raw = 40.0 - eps / 2.0
    var final_recovered = final_track.recover_behind(final_raw)
    assert_true(
        final_recovered <= final_raw,
        "Final collision recovery must never advance past the raw cutoff"
    )
    var final_built_points = final_track.get_built_points()
    assert_equal(
        final_built_points.size(),
        2,
        "Final collision must retain a representable boundary and endpoint"
    )
    _assert_no_adjacent_duplicates(
        final_built_points,
        "Final-endpoint rounding recovery"
    )
    _assert_close(
        final_track.get_built_end_distance(),
        40.0,
        "Final collision must preserve absolute built end"
    )
    _assert_close(
        final_track.get_reserved_end_distance(),
        40.0,
        "Final collision must preserve absolute reserved end"
    )
    _assert_vector_close(
        final_track.get_heading_at_distance(
            final_track.get_active_start_distance()
        ),
        Vector2.LEFT,
        "Final collision must preserve the leftward heading"
    )
    assert_true(
        final_track.is_conservation_valid(),
        "Final collision recovery must conserve inventory"
    )
    _assert_close(
        track.get_built_end_distance(),
        80.0,
        "Corner recovery must preserve absolute built end"
    )
    _assert_close(
        track.get_reserved_end_distance(),
        80.0,
        "Corner recovery must preserve absolute reserved end"
    )
    _assert_no_adjacent_duplicates(
        built_points,
        "Epsilon-close corner recovery"
    )
    assert_true(
        track.is_conservation_valid(),
        "Epsilon-close corner recovery must conserve inventory"
    )


func _test_repeated_diagonal_recovery_preserves_scalar_geometry_alignment() -> void:
    var track = TrackSystemScript.new(
        _config(200.0, Vector2(600.0, 100.8))
    )
    _reserve_points(track, [Vector2(809.0, 196.8)])
    track.advance_construction(track.get_reserved_end_distance())

    var previous_active := track.get_active_start_distance()
    var previous_available := track.get_available_units()
    for step in range(1, 15):
        var expected_cutoff := float(step) * 2.5
        var recovered := track.recover_behind(expected_cutoff)
        _assert_close(
            recovered,
            2.5,
            "Repeated diagonal recovery amount at step " + str(step)
        )
        _assert_close(
            track.get_active_start_distance(),
            expected_cutoff,
            "Repeated diagonal recovery active start at step " + str(step)
        )
        assert_true(
            track.get_active_start_distance() >= previous_active,
            "Repeated diagonal recovery active start must be monotonic at step "
                + str(step)
        )
        _assert_close(
            track.get_available_units(),
            previous_available + 2.5,
            "Repeated diagonal recovery available units at step " + str(step)
        )

        var built_points := track.get_built_points()
        assert_true(
            built_points.size() >= 2,
            "Repeated diagonal recovery must retain a built segment at step "
                + str(step)
        )
        var geometry_remaining := 0.0
        for index in range(1, built_points.size()):
            geometry_remaining += built_points[index - 1].distance_to(
                built_points[index]
            )
        var scalar_remaining := (
            track.get_built_end_distance()
            - track.get_active_start_distance()
        )
        var alignment_delta := absf(scalar_remaining - geometry_remaining)
        assert_true(
            alignment_delta <= TrackSystemScript.GEOMETRY_EPSILON,
            "Repeated diagonal recovery must keep retained scalar and geometry aligned"
                + " at step " + str(step)
                + " (delta " + str(alignment_delta) + ")"
        )
        assert_true(
            track.is_conservation_valid(),
            "Repeated diagonal recovery must conserve inventory at step "
                + str(step)
        )
        previous_active = track.get_active_start_distance()
        previous_available = track.get_available_units()


func _test_maximum_coordinate_recovery_precision() -> void:
    var eps = TrackSystemScript.GEOMETRY_EPSILON
    var field_size = Vector2(4000.0, 2160.0)
    var departure = Vector2(3900.0, 2060.0)
    var corner = Vector2(4000.0, 2160.0)
    var incoming_heading = departure.direction_to(corner)

    var corner_track = TrackSystemScript.new(
        _config(1000.0, departure, field_size)
    )
    _reserve_points(
        corner_track,
        [corner, Vector2(3900.0, 2160.0)]
    )
    var corner_distance = departure.distance_to(corner)
    corner_track.advance_construction(
        corner_track.get_reserved_end_distance()
    )
    var corner_raw = corner_distance - eps / 2.0
    var corner_available_before = corner_track.get_available_units()
    var corner_recovered = corner_track.recover_behind(corner_raw)
    assert_equal(
        corner_recovered,
        corner_raw,
        "Maximum-coordinate corner recovery must preserve the raw scalar"
    )
    assert_equal(
        corner_track.get_active_start_distance(),
        corner_raw,
        "Maximum-coordinate corner active start must preserve the raw scalar"
    )
    assert_equal(
        corner_track.get_available_units(),
        corner_available_before + corner_raw,
        "Maximum-coordinate corner accounting must preserve the raw scalar"
    )
    var corner_built_points = corner_track.get_built_points()
    _assert_no_adjacent_duplicates(
        corner_built_points,
        "Maximum-coordinate corner recovery"
    )
    _assert_vector_close(
        corner_track.get_heading_at_distance(
            corner_track.get_active_start_distance()
        ),
        incoming_heading,
        "Maximum-coordinate corner recovery must preserve incoming heading"
    )
    _assert_vector_close(
        corner_track.get_heading_at_distance(corner_distance),
        Vector2.LEFT,
        "Maximum-coordinate exact corner must use the outgoing heading"
    )
    assert_true(
        corner_track.is_conservation_valid(),
        "Maximum-coordinate corner recovery must conserve inventory"
    )

    var final_track = TrackSystemScript.new(
        _config(1000.0, departure, field_size)
    )
    _reserve_points(final_track, [corner])
    final_track.advance_construction(final_track.get_reserved_end_distance())
    var final_distance = final_track.get_reserved_end_distance()
    var final_raw = final_distance - eps / 2.0
    var final_available_before = final_track.get_available_units()
    var final_recovered = final_track.recover_behind(final_raw)
    assert_equal(
        final_recovered,
        final_raw,
        "Maximum-coordinate final recovery must preserve the raw scalar"
    )
    assert_equal(
        final_track.get_active_start_distance(),
        final_raw,
        "Maximum-coordinate final active start must preserve the raw scalar"
    )
    assert_equal(
        final_track.get_available_units(),
        final_available_before + final_raw + eps / 2.0,
        "Maximum-coordinate final accounting must preserve the raw scalar before the documented snap"
    )
    assert_equal(
        final_track.get_available_units(),
        final_track.get_total_units(),
        "Maximum-coordinate final epsilon remainder must snap inventory to total"
    )
    var final_built_points = final_track.get_built_points()
    assert_equal(
        final_built_points.size(),
        2,
        "Maximum-coordinate final recovery must retain boundary and endpoint"
    )
    _assert_no_adjacent_duplicates(
        final_built_points,
        "Maximum-coordinate final recovery"
    )
    _assert_vector_close(
        final_track.get_heading_at_distance(
            final_track.get_active_start_distance()
        ),
        incoming_heading,
        "Maximum-coordinate final recovery must preserve incoming heading"
    )
    _assert_vector_close(
        final_track.get_heading_at_distance(final_distance),
        incoming_heading,
        "Maximum-coordinate final endpoint must preserve incoming heading"
    )
    assert_true(
        final_track.is_conservation_valid(),
        "Maximum-coordinate final recovery must conserve inventory"
    )

    var scope_property := StringName(
        "_first_segment_uses_float32_recovery_exception"
    )
    var has_scope_property := false
    for property in final_track.get_property_list():
        if property.get("name", StringName()) == scope_property:
            has_scope_property = true
            break
    assert_true(
        has_scope_property,
        "Float32 recovery exception must be scoped to the actual first retained segment"
    )
    if not has_scope_property:
        return
    assert_true(
        bool(corner_track.get(scope_property)),
        "Maximum-coordinate corner recovery must enable the float32 exception"
    )
    assert_true(
        bool(final_track.get(scope_property)),
        "Maximum-coordinate final recovery must enable the float32 exception"
    )
    var ordinary_track = TrackSystemScript.new(_config())
    _reserve_points(
        ordinary_track,
        [Vector2(140.0, 100.0), Vector2(140.0, 140.0)]
    )
    ordinary_track.advance_construction(80.0)
    ordinary_track.recover_behind(40.0 - eps / 2.0)
    assert_true(
        not bool(ordinary_track.get(scope_property)),
        "Representable ordinary recovery must not enable the float32 exception"
    )

    for offset_factor in [1.1, 1.2, 1.3, 1.4, 1.5, 1.8, 2.1, 50.0]:
        var offset_corner_track = TrackSystemScript.new(
            _config(1000.0, departure, field_size)
        )
        _reserve_points(
            offset_corner_track,
            [corner, Vector2(3900.0, 2160.0)]
        )
        offset_corner_track.advance_construction(
            offset_corner_track.get_reserved_end_distance()
        )
        var offset_corner_raw = corner_distance - eps * offset_factor
        var offset_corner_available_before = (
            offset_corner_track.get_available_units()
        )
        var offset_corner_recovered = offset_corner_track.recover_behind(
            offset_corner_raw
        )
        assert_equal(
            offset_corner_recovered,
            offset_corner_raw,
            "Maximum-coordinate corner raw scalar at factor "
                + str(offset_factor)
        )
        assert_equal(
            offset_corner_track.get_active_start_distance(),
            offset_corner_raw,
            "Maximum-coordinate corner active start at factor "
                + str(offset_factor)
        )
        assert_equal(
            offset_corner_track.get_available_units(),
            offset_corner_available_before + offset_corner_raw,
            "Maximum-coordinate corner accounting at factor "
                + str(offset_factor)
        )
        var offset_corner_points = offset_corner_track.get_built_points()
        assert_equal(
            offset_corner_points.size(),
            3,
            "Maximum-coordinate corner must retain three points at factor "
                + str(offset_factor)
        )
        _assert_no_adjacent_duplicates(
            offset_corner_points,
            "Maximum-coordinate corner factor " + str(offset_factor)
        )
        if offset_corner_points.size() >= 2:
            var corner_scalar_remaining: float = (
                corner_distance
                - offset_corner_track.get_active_start_distance()
            )
            var corner_geometry_remaining: float = (
                offset_corner_points[0].distance_to(offset_corner_points[1])
            )
            var corner_max_abs_coordinate: float = maxf(
                maxf(
                    absf(offset_corner_points[0].x),
                    absf(offset_corner_points[0].y)
                ),
                maxf(
                    absf(offset_corner_points[1].x),
                    absf(offset_corner_points[1].y)
                )
            )
            var corner_float32_scale: float = maxf(
                maxf(corner_max_abs_coordinate, corner_scalar_remaining),
                1.0
            )
            var corner_float32_bound: float = (
                eps + corner_float32_scale * pow(2.0, -20.0)
            )
            assert_true(
                absf(corner_scalar_remaining - corner_geometry_remaining)
                    <= corner_float32_bound,
                "Maximum-coordinate corner first geometry delta at factor "
                    + str(offset_factor)
            )
        _assert_vector_close(
            offset_corner_track.get_heading_at_distance(
                offset_corner_track.get_active_start_distance()
            ),
            incoming_heading,
            "Maximum-coordinate corner incoming heading at factor "
                + str(offset_factor)
        )
        _assert_vector_close(
            offset_corner_track.get_heading_at_distance(corner_distance),
            Vector2.LEFT,
            "Maximum-coordinate corner outgoing heading at factor "
                + str(offset_factor)
        )
        assert_true(
            offset_corner_track.is_conservation_valid(),
            "Maximum-coordinate corner conservation at factor "
                + str(offset_factor)
        )
        assert_true(
            bool(offset_corner_track.get(scope_property)),
            "Maximum-coordinate corner must enable the float32 exception at factor "
                + str(offset_factor)
        )

        var offset_final_track = TrackSystemScript.new(
            _config(1000.0, departure, field_size)
        )
        _reserve_points(offset_final_track, [corner])
        offset_final_track.advance_construction(
            offset_final_track.get_reserved_end_distance()
        )
        var offset_final_distance = (
            offset_final_track.get_reserved_end_distance()
        )
        var offset_final_raw = (
            offset_final_distance - eps * offset_factor
        )
        var offset_final_available_before = (
            offset_final_track.get_available_units()
        )
        var offset_final_recovered = offset_final_track.recover_behind(
            offset_final_raw
        )
        assert_equal(
            offset_final_recovered,
            offset_final_raw,
            "Maximum-coordinate final raw scalar at factor "
                + str(offset_factor)
        )
        assert_equal(
            offset_final_track.get_active_start_distance(),
            offset_final_raw,
            "Maximum-coordinate final active start at factor "
                + str(offset_factor)
        )
        assert_equal(
            offset_final_track.get_available_units(),
            offset_final_available_before + offset_final_raw,
            "Maximum-coordinate final accounting at factor "
                + str(offset_factor)
        )
        var offset_final_points = offset_final_track.get_built_points()
        assert_equal(
            offset_final_points.size(),
            2,
            "Maximum-coordinate final must retain two points at factor "
                + str(offset_factor)
        )
        _assert_no_adjacent_duplicates(
            offset_final_points,
            "Maximum-coordinate final factor " + str(offset_factor)
        )
        if offset_final_points.size() >= 2:
            var final_scalar_remaining: float = (
                offset_final_distance
                - offset_final_track.get_active_start_distance()
            )
            var final_geometry_remaining: float = (
                offset_final_points[0].distance_to(offset_final_points[1])
            )
            var final_max_abs_coordinate: float = maxf(
                maxf(
                    absf(offset_final_points[0].x),
                    absf(offset_final_points[0].y)
                ),
                maxf(
                    absf(offset_final_points[1].x),
                    absf(offset_final_points[1].y)
                )
            )
            var final_float32_scale: float = maxf(
                maxf(final_max_abs_coordinate, final_scalar_remaining),
                1.0
            )
            var final_float32_bound: float = (
                eps + final_float32_scale * pow(2.0, -20.0)
            )
            assert_true(
                absf(final_scalar_remaining - final_geometry_remaining)
                    <= final_float32_bound,
                "Maximum-coordinate final first geometry delta at factor "
                    + str(offset_factor)
            )
        _assert_vector_close(
            offset_final_track.get_heading_at_distance(
                offset_final_track.get_active_start_distance()
            ),
            incoming_heading,
            "Maximum-coordinate final incoming heading at factor "
                + str(offset_factor)
        )
        _assert_vector_close(
            offset_final_track.get_heading_at_distance(offset_final_distance),
            incoming_heading,
            "Maximum-coordinate final endpoint heading at factor "
                + str(offset_factor)
        )
        assert_true(
            offset_final_track.is_conservation_valid(),
            "Maximum-coordinate final conservation at factor "
                + str(offset_factor)
        )
        assert_true(
            bool(offset_final_track.get(scope_property)),
            "Maximum-coordinate final must enable the float32 exception at factor "
                + str(offset_factor)
        )

    var negative_factor: float = 10.0
    var negative_corner_track = TrackSystemScript.new(
        _config(1000.0, departure, field_size)
    )
    _reserve_points(
        negative_corner_track,
        [corner, Vector2(3900.0, 2160.0)]
    )
    negative_corner_track.advance_construction(
        negative_corner_track.get_reserved_end_distance()
    )
    negative_corner_track.recover_behind(
        corner_distance - eps * negative_factor
    )
    var negative_corner_points: PackedVector2Array = (
        negative_corner_track.get_built_points()
    )
    assert_equal(
        negative_corner_points.size(),
        3,
        "Maximum-coordinate corner negative control retains three points"
    )
    _assert_no_adjacent_duplicates(
        negative_corner_points,
        "Maximum-coordinate corner negative control"
    )
    if negative_corner_points.size() >= 2:
        var negative_corner_scalar: float = (
            corner_distance
            - negative_corner_track.get_active_start_distance()
        )
        var negative_corner_geometry: float = (
            negative_corner_points[0].distance_to(negative_corner_points[1])
        )
        assert_true(
            absf(negative_corner_scalar - negative_corner_geometry) <= eps,
            "Maximum-coordinate corner factor 10 remains within epsilon"
        )
    assert_true(
        not bool(negative_corner_track.get(scope_property)),
        "Maximum-coordinate corner factor 10 must not enable the exception"
    )
    assert_true(
        negative_corner_track.is_conservation_valid(),
        "Maximum-coordinate corner factor 10 must conserve inventory"
    )

    var negative_final_track = TrackSystemScript.new(
        _config(1000.0, departure, field_size)
    )
    _reserve_points(negative_final_track, [corner])
    negative_final_track.advance_construction(
        negative_final_track.get_reserved_end_distance()
    )
    var negative_final_distance: float = (
        negative_final_track.get_reserved_end_distance()
    )
    negative_final_track.recover_behind(
        negative_final_distance - eps * negative_factor
    )
    var negative_final_points: PackedVector2Array = (
        negative_final_track.get_built_points()
    )
    assert_equal(
        negative_final_points.size(),
        2,
        "Maximum-coordinate final negative control retains two points"
    )
    _assert_no_adjacent_duplicates(
        negative_final_points,
        "Maximum-coordinate final negative control"
    )
    if negative_final_points.size() >= 2:
        var negative_final_scalar: float = (
            negative_final_distance
            - negative_final_track.get_active_start_distance()
        )
        var negative_final_geometry: float = (
            negative_final_points[0].distance_to(negative_final_points[1])
        )
        assert_true(
            absf(negative_final_scalar - negative_final_geometry) <= eps,
            "Maximum-coordinate final factor 10 remains within epsilon"
        )
    assert_true(
        not bool(negative_final_track.get(scope_property)),
        "Maximum-coordinate final factor 10 must not enable the exception"
    )
    assert_true(
        negative_final_track.is_conservation_valid(),
        "Maximum-coordinate final factor 10 must conserve inventory"
    )


func _test_long_non_axis_recovery_precision() -> void:
    var eps := TrackSystemScript.GEOMETRY_EPSILON
    var field_size := Vector2(4000.0, 2160.0)
    var departure := Vector2(
        2804.983642578125,
        1368.7210693359375
    )
    var collision := Vector2(
        391.3240966796875,
        905.2901000976562
    )
    var expected_segment_scalar: float = 2457.7470703125
    var scope_property := StringName(
        "_first_segment_uses_float32_recovery_exception"
    )

    var positive_track = TrackSystemScript.new(
        _config(3000.0, departure, field_size)
    )
    _reserve_points(positive_track, [collision])
    assert_equal(
        positive_track.get_reserved_endpoint(),
        Vector2(391.323883056640625, 905.2901611328125),
        "Long non-axis route must preserve its concrete stored endpoint"
    )
    assert_equal(
        positive_track.get_reserved_end_distance(),
        expected_segment_scalar,
        "Long non-axis route must preserve its stored scalar"
    )
    positive_track.advance_construction(
        positive_track.get_reserved_end_distance()
    )
    var positive_available_before: float = positive_track.get_available_units()
    var positive_raw: float = 0.2
    var positive_recovered: float = positive_track.recover_behind(positive_raw)
    assert_equal(
        positive_recovered,
        positive_raw,
        "Long non-axis recovery must return the raw scalar"
    )
    assert_equal(
        positive_track.get_active_start_distance(),
        positive_raw,
        "Long non-axis recovery must retain the raw active scalar"
    )
    assert_equal(
        positive_track.get_available_units(),
        positive_available_before + positive_raw,
        "Long non-axis recovery must credit the exact raw scalar"
    )
    var positive_points: PackedVector2Array = positive_track.get_built_points()
    assert_equal(
        positive_points.size(),
        2,
        "Long non-axis recovery must retain one segment"
    )
    if positive_points.size() >= 2:
        assert_equal(
            positive_points[0],
            Vector2(2804.787353515625, 1368.683349609375),
            "Long non-axis recovery must retain the expected float32 boundary"
        )
        var positive_scalar: float = (
            positive_track.get_built_end_distance()
            - positive_track.get_active_start_distance()
        )
        var positive_geometry: float = positive_points[0].distance_to(
            positive_points[1]
        )
        assert_equal(
            positive_scalar,
            2457.5470703125002,
            "Long non-axis recovery must preserve remaining scalar"
        )
        assert_equal(
            positive_geometry,
            2457.54736328125,
            "Long non-axis recovery must expose expected float32 geometry"
        )
        var positive_delta: float = absf(positive_scalar - positive_geometry)
        assert_true(
            positive_delta > eps,
            "Long non-axis positive control must require the exception"
        )
        var positive_max_abs_coordinate: float = maxf(
            maxf(absf(positive_points[0].x), absf(positive_points[0].y)),
            maxf(absf(positive_points[1].x), absf(positive_points[1].y))
        )
        var positive_float32_scale: float = maxf(
            maxf(positive_max_abs_coordinate, positive_scalar),
            1.0
        )
        var positive_bound: float = (
            eps + positive_float32_scale * pow(2.0, -20.0)
        )
        assert_true(
            positive_delta <= positive_bound,
            "Long non-axis positive control must stay within float32 bound"
        )
    assert_true(
        bool(positive_track.get(scope_property)),
        "Long non-axis positive control must enable the exception"
    )
    _assert_no_adjacent_duplicates(
        positive_points,
        "Long non-axis positive control"
    )
    _assert_vector_close(
        positive_track.get_heading_at_distance(
            positive_track.get_active_start_distance()
        ),
        departure.direction_to(collision),
        "Long non-axis positive control must preserve heading"
    )
    assert_true(
        positive_track.is_conservation_valid(),
        "Long non-axis positive control must conserve inventory"
    )

    var negative_track = TrackSystemScript.new(
        _config(3000.0, departure, field_size)
    )
    _reserve_points(negative_track, [collision])
    negative_track.advance_construction(
        negative_track.get_reserved_end_distance()
    )
    var negative_raw: float = 100.5
    var negative_recovered: float = negative_track.recover_behind(negative_raw)
    assert_equal(
        negative_recovered,
        negative_raw,
        "Long non-axis negative control must return the raw scalar"
    )
    assert_equal(
        negative_track.get_active_start_distance(),
        negative_raw,
        "Long non-axis negative control must retain the raw active scalar"
    )
    var negative_points: PackedVector2Array = negative_track.get_built_points()
    assert_equal(
        negative_points.size(),
        2,
        "Long non-axis negative control must retain one segment"
    )
    if negative_points.size() >= 2:
        assert_equal(
            negative_points[0],
            Vector2(2706.286376953125, 1349.7708740234375),
            "Long non-axis negative control must retain expected boundary"
        )
        var negative_scalar: float = (
            negative_track.get_built_end_distance()
            - negative_track.get_active_start_distance()
        )
        var negative_geometry: float = negative_points[0].distance_to(
            negative_points[1]
        )
        assert_equal(
            negative_scalar,
            2357.2470703125,
            "Long non-axis negative control remaining scalar"
        )
        assert_equal(
            negative_geometry,
            2357.2470703125,
            "Long non-axis negative control geometric length"
        )
        assert_true(
            absf(negative_scalar - negative_geometry) <= eps,
            "Long non-axis negative control must stay within epsilon"
        )
    assert_true(
        not bool(negative_track.get(scope_property)),
        "Long non-axis negative control must not enable the exception"
    )
    _assert_no_adjacent_duplicates(
        negative_points,
        "Long non-axis negative control"
    )
    _assert_vector_close(
        negative_track.get_heading_at_distance(
            negative_track.get_active_start_distance()
        ),
        departure.direction_to(collision),
        "Long non-axis negative control must preserve heading"
    )
    assert_true(
        negative_track.is_conservation_valid(),
        "Long non-axis negative control must conserve inventory"
    )


func _test_float32_exception_cancellation_uses_route_scalar_distance() -> void:
    var field_size := Vector2(4000.0, 2160.0)
    var departure := Vector2(
        2804.983642578125,
        1368.7210693359375
    )
    var collision := Vector2(
        391.3240966796875,
        905.2901000976562
    )

    var endpoint_track = TrackSystemScript.new(
        _config(3000.0, departure, field_size)
    )
    _reserve_points(endpoint_track, [collision])
    endpoint_track.advance_construction(1000.0)
    endpoint_track.recover_behind(0.2)
    var endpoint_reserved_before: float = (
        endpoint_track.get_reserved_end_distance()
    )
    var endpoint_available_before: float = endpoint_track.get_available_units()
    var endpoint_before: Vector2 = endpoint_track.get_reserved_endpoint()
    assert_true(
        _right(endpoint_track, endpoint_before),
        "Float32 endpoint cancellation must be handled"
    )
    _assert_close(
        endpoint_track.get_reserved_end_distance(),
        endpoint_reserved_before,
        "Float32 endpoint cancellation must preserve reserved distance"
    )
    _assert_close(
        endpoint_track.get_available_units(),
        endpoint_available_before,
        "Float32 endpoint cancellation must preserve available units"
    )
    _assert_vector_close(
        endpoint_track.get_reserved_endpoint(),
        endpoint_before,
        "Float32 endpoint cancellation must preserve endpoint"
    )
    assert_true(
        endpoint_track.is_conservation_valid(),
        "Float32 endpoint cancellation must conserve inventory"
    )

    var interior_track = TrackSystemScript.new(
        _config(3000.0, departure, field_size)
    )
    _reserve_points(interior_track, [collision])
    interior_track.advance_construction(1000.0)
    interior_track.recover_behind(0.2)
    var cut_distance: float = 1800.0
    var click_position: Vector2 = interior_track.get_position_at_distance(
        cut_distance
    )
    var interior_reserved_before: float = (
        interior_track.get_reserved_end_distance()
    )
    var interior_available_before: float = interior_track.get_available_units()
    assert_true(
        _right(interior_track, click_position),
        "Float32 interior cancellation must be handled"
    )
    _assert_close(
        interior_track.get_reserved_end_distance(),
        cut_distance,
        "Float32 interior cancellation must use route scalar distance"
    )
    _assert_close(
        interior_track.get_available_units(),
        interior_available_before + interior_reserved_before - cut_distance,
        "Float32 interior cancellation must refund route scalar distance"
    )
    _assert_vector_close(
        interior_track.get_reserved_endpoint(),
        click_position,
        "Float32 interior cancellation must preserve projected endpoint"
    )
    assert_true(
        interior_track.is_conservation_valid(),
        "Float32 interior cancellation must conserve inventory"
    )


func _test_float32_exception_clears_after_suffix_cancellation() -> void:
    var eps = TrackSystemScript.GEOMETRY_EPSILON
    var departure = Vector2(3900.0, 2060.0)
    var corner = Vector2(4000.0, 2160.0)
    var track = TrackSystemScript.new(
        _config(1000.0, departure, Vector2(4000.0, 2160.0))
    )
    var scope_property := StringName(
        "_first_segment_uses_float32_recovery_exception"
    )

    _reserve_points(track, [corner])
    var corner_distance = departure.distance_to(corner)
    var raw = corner_distance - eps * 1.1
    track.advance_construction(raw)
    track.recover_behind(raw)
    assert_true(
        bool(track.get(scope_property)),
        "Maximum-coordinate recovery must enable the float32 exception"
    )

    assert_equal(
        track.recover_behind(raw),
        0.0,
        "Same-cutoff recovery must remain an exact no-op"
    )
    assert_equal(
        track.recover_behind(raw - eps),
        0.0,
        "Earlier-cutoff recovery must remain an exact no-op"
    )
    assert_true(
        bool(track.get(scope_property)),
        "Recovery no-ops must preserve the active float32 exception"
    )

    _right(track, track.get_built_points()[0])
    var exception_remains := bool(track.get(scope_property))
    assert_true(
        not exception_remains,
        "Cancelling the represented exception segment must clear its scope"
    )
    if exception_remains:
        return

    assert_equal(
        track.get_built_points().size(),
        1,
        "Suffix cancellation must leave one built boundary point"
    )
    assert_equal(
        track.get_reserved_points().size(),
        1,
        "Suffix cancellation must leave one reserved boundary point"
    )
    assert_equal(
        track.get_available_units(),
        track.get_total_units(),
        "Suffix cancellation must restore the exact total inventory"
    )

    var normal_point = Vector2(3900.0, 2160.0)
    var normal_length = track.get_reserved_endpoint().distance_to(normal_point)
    var normal_available_before = track.get_available_units()
    _reserve_points(track, [normal_point])
    assert_true(
        not bool(track.get(scope_property)),
        "Normal reuse must keep the float32 exception disabled"
    )
    _assert_no_adjacent_duplicates(
        track.get_reserved_points(),
        "Normal reuse after float32 exception cancellation"
    )
    assert_equal(
        track.get_available_units(),
        normal_available_before - normal_length,
        "Normal reuse must debit its exact geometric length"
    )

    assert_equal(
        track.advance_construction(normal_length),
        normal_length,
        "Normal reused segment must build its exact length"
    )
    var recovery_available_before = track.get_available_units()
    assert_equal(
        track.recover_behind(raw + 40.0),
        40.0,
        "Later ordinary recovery must return the newly eligible distance"
    )
    assert_equal(
        track.get_active_start_distance(),
        raw + 40.0,
        "Later ordinary recovery must preserve the absolute scalar"
    )
    assert_equal(
        track.get_available_units(),
        recovery_available_before + 40.0,
        "Later ordinary recovery must credit exact inventory"
    )
    assert_true(
        not bool(track.get(scope_property)),
        "Later ordinary recovery must not restore the float32 exception"
    )
    assert_true(
        track.is_conservation_valid(),
        "Exception cancellation and ordinary reuse must conserve inventory"
    )


func _test_idempotence_noops_reuse() -> void:
    var track = TrackSystemScript.new(_config())

    _reserve_points(track, [Vector2(140.0, 100.0), Vector2(180.0, 100.0)])
    track.advance_construction(80.0)

    var recovered = track.recover_behind(80.0)
    assert_equal(recovered, 80, "recover_behind(80) returns 80")
    assert_equal(track.get_active_start_distance(), 80.0, "Active start 80")
    _assert_close(track.get_built_end_distance(), 80.0, "Built end 80")
    _assert_close(track.get_reserved_end_distance(), 80.0, "Reserved end 80")

    var built_points = track.get_built_points()
    var reserved_points = track.get_reserved_points()
    assert_equal(built_points.size(), 1, "Built points: one at 180,100")
    assert_equal(reserved_points.size(), 1, "Reserved points: one at 180,100")
    _assert_vector_close(built_points[0], Vector2(180.0, 100.0), "Built point at 180,100")
    _assert_vector_close(reserved_points[0], Vector2(180.0, 100.0), "Reserved point at 180,100")

    var noop_available = track.get_available_units()
    var noop_built_points = track.get_built_points().duplicate()
    var noop_reserved_points = track.get_reserved_points().duplicate()
    recovered = track.recover_behind(80.0)
    _assert_close(recovered, 0.0, "Same-cutoff recovery must be a no-op")
    assert_equal(
        track.get_available_units(),
        noop_available,
        "Same-cutoff recovery must preserve inventory"
    )
    assert_equal(
        track.get_built_points(),
        noop_built_points,
        "Same-cutoff recovery must preserve built geometry"
    )
    assert_equal(
        track.get_reserved_points(),
        noop_reserved_points,
        "Same-cutoff recovery must preserve reserved geometry"
    )
    recovered = track.recover_behind(40.0)
    _assert_close(recovered, 0.0, "Earlier-cutoff recovery must be a no-op")
    assert_equal(
        track.get_available_units(),
        noop_available,
        "Earlier-cutoff recovery must preserve inventory"
    )
    assert_equal(
        track.get_built_points(),
        noop_built_points,
        "Earlier-cutoff recovery must preserve built geometry"
    )
    assert_equal(
        track.get_reserved_points(),
        noop_reserved_points,
        "Earlier-cutoff recovery must preserve reserved geometry"
    )

    var advanced = track.advance_construction(10.0)
    assert_equal(advanced, 0, "Advance when built=reserved returns 0")

    _right(track, Vector2(140.0, 100.0))
    assert_equal(track.get_available_units(), 200.0, "Right-click recovered point: no change to available")
    assert_true(track.is_conservation_valid(), "Conservation valid after right-click on recovered")

    _reserve_points(track, [Vector2(100.0, 100.0)])
    assert_equal(track.get_reserved_endpoint(), Vector2(100.0, 100.0), "Endpoint at 100,100 after reserve back along old geometry")
    assert_equal(track.get_active_start_distance(), 80.0, "Active remains 80")
    _assert_close(track.get_built_end_distance(), 80.0, "Built remains 80")
    _assert_close(track.get_reserved_end_distance(), 160.0, "Reserved becomes 160 absolute (not renormalized)")
    assert_equal(track.get_available_units(), 120.0, "Available total - 80 = 120")
    assert_true(track.is_conservation_valid(), "Conservation valid after reuse")

    advanced = track.advance_construction(1000.0)
    assert_equal(advanced, 80, "Construction advances 80 (clamped to available)")
    _assert_close(track.get_built_end_distance(), 160.0, "Built becomes 160")

    advanced = track.advance_construction(10.0)
    assert_equal(advanced, 0, "Further construction returns 0")

    recovered = track.recover_behind(160.0)
    assert_equal(recovered, 80, "recover_behind(160) returns 80")
    assert_equal(track.get_active_start_distance(), 160.0, "Active becomes 160")
    _assert_close(track.get_built_end_distance(), 160.0, "Built becomes 160")
    _assert_close(track.get_reserved_end_distance(), 160.0, "Reserved becomes 160")
    assert_equal(track.get_available_units(), 200.0, "Available returns to total")

    recovered = track.recover_behind(160.0)
    assert_equal(recovered, 0, "Repeated recovery returns 0")

    built_points = track.get_built_points()
    reserved_points = track.get_reserved_points()
    _assert_no_adjacent_duplicates(built_points, "Built points final")
    _assert_no_adjacent_duplicates(reserved_points, "Reserved points final")
    assert_true(track.is_conservation_valid(), "Conservation valid throughout")

func run() -> PackedStringArray:
    var track = TrackSystemScript.new(_config())

    if not track.has_method("advance_construction"):
        assert_true(false, "Construction must advance exactly 2 units per default tick")
        return finish()

    _test_construction_regions()
    _test_release_and_extension()
    _test_region_getters_keep_noncanonical_near_vertex_boundary()
    _test_cancel_ordering_and_invalid_right_targets()
    _test_reserved_projection_ignores_nearer_built_prefix()
    _test_intersection_blockers()
    _test_partial_recovery()
    _test_canonical_recovery()
    _test_backward_only()
    _test_recovery_preserves_epsilon_close_corner()
    _test_repeated_diagonal_recovery_preserves_scalar_geometry_alignment()
    _test_maximum_coordinate_recovery_precision()
    _test_long_non_axis_recovery_precision()
    _test_float32_exception_cancellation_uses_route_scalar_distance()
    _test_float32_exception_clears_after_suffix_cancellation()
    _test_idempotence_noops_reuse()

    return finish()
