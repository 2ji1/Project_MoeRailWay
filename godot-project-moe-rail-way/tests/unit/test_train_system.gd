extends "res://tests/support/prototype_test.gd"

const TrainSystemScript = preload("res://src/domain/train/train_system.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")


func _config(
    total_units := 300.0,
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
    var resolved_left_inside := (
        false if left_press_inside_field == null
        else bool(left_press_inside_field)
    )
    if left_pressed:
        if left_press_position == Vector2.INF:
            resolved_left_position = cursor_position
        if left_press_inside_field == null:
            resolved_left_inside = cursor_inside_field
    var resolved_right_position: Vector2 = right_press_position
    var resolved_right_inside := (
        false if right_press_inside_field == null
        else bool(right_press_inside_field)
    )
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
    track.apply_left_input(
        _input(
            points[0],
            true,
            true,
            true,
            false,
            false,
            track.get_reserved_endpoint(),
            true
        )
    )
    for index in range(1, points.size()):
        track.apply_left_input(_input(points[index], true, true))
    track.apply_left_input(_input(points[-1], true, false, false, true))


func _orthogonal_track(built_distance := 160.0):
    var track = TrackSystemScript.new(_config())
    _reserve_points(
        track,
        [Vector2(140.0, 100.0), Vector2(140.0, 160.0), Vector2(200.0, 160.0)]
    )
    track.advance_construction(built_distance)
    return track


func _partial_track():
    var track = TrackSystemScript.new(_config())
    _reserve_points(
        track,
        [Vector2(140.0, 100.0), Vector2(140.0, 160.0)]
    )
    track.advance_construction(50.0)
    return track


func _run_probe(case_name: String, expected: String) -> void:
    var output: Array = []
    var arguments := PackedStringArray([
        "--headless",
        "--path",
        ProjectSettings.globalize_path("res://"),
        "--script",
        "res://tests/run_all.gd",
        "--quit-after",
        "1",
        "--",
        "--train-invalid-probe=" + case_name,
    ])
    OS.execute(OS.get_executable_path(), arguments, output, true)
    var output_lines := PackedStringArray()
    for chunk in output:
        output_lines.append(str(chunk))
    var captured_text := "\n".join(output_lines)
    assert_true(
        captured_text.contains("TRAIN_INVALID_PROBE_BEGIN:" + case_name),
        "Invalid probe must emit its unique begin marker: " + case_name
    )
    assert_true(
        captured_text.contains(expected),
        "Invalid probe must emit its expected assertion: " + case_name
    )


func _verify_invalid_assertion_probes() -> void:
    _run_probe("speed_zero", "Train speed must be positive")
    _run_probe("speed_negative", "Train speed must be positive")
    _run_probe("depart_negative", "Departure distance must be non-negative")
    _run_probe("tick_zero", "Tick duration must be positive")
    _run_probe("tick_negative", "Tick duration must be positive")
    _run_probe(
        "backward_tick",
        "Train route distance cannot be behind active track"
    )
    _run_probe(
        "backward_position",
        "Train route distance cannot be behind active track"
    )
    _run_probe(
        "backward_heading",
        "Train route distance cannot be behind active track"
    )


func run_invalid_probe(case_name: String) -> void:
    if case_name == "speed_zero":
        TrainSystemScript.new(0.0)
        return
    if case_name == "speed_negative":
        TrainSystemScript.new(-1.0)
        return
    if case_name == "depart_negative":
        TrainSystemScript.new(60.0).depart(-1.0)
        return

    var track = _orthogonal_track()
    var train = TrainSystemScript.new(60.0)
    train.depart(20.0)
    if case_name == "tick_zero":
        train.advance_tick(track, 0.0)
        return
    if case_name == "tick_negative":
        train.advance_tick(track, -1.0 / 60.0)
        return

    track.recover_behind(30.0)
    if case_name == "backward_tick":
        train.advance_tick(track, 1.0 / 60.0)
        return
    if case_name == "backward_position":
        train.get_position(track)
        return
    if case_name == "backward_heading":
        train.get_heading(track)
        return
    assert(false, "Unknown train invalid probe: " + case_name)


func _test_inactive_train() -> void:
    var track = _orthogonal_track()
    var train = TrainSystemScript.new(60.0)

    assert_false(train.is_active(), "Train must begin inactive")
    assert_equal(train.get_route_distance(), 0.0, "Inactive train starts at departure distance")
    assert_equal(
        train.get_position(track),
        Vector2(100.0, 100.0),
        "Inactive train remains at departure"
    )
    assert_equal(
        train.get_heading(track),
        Vector2.RIGHT,
        "Inactive train uses departure heading"
    )
    assert_false(
        train.advance_tick(track, 1.0 / 60.0),
        "Inactive train must not request the endpoint"
    )
    assert_equal(train.get_route_distance(), 0.0, "Inactive tick must not move")


func _test_departure_and_default_tick() -> void:
    var track = _orthogonal_track()
    var train = TrainSystemScript.new(60.0)

    train.depart(0.0)
    assert_true(train.is_active(), "depart(0) activates the train")
    train.depart(25.0)
    assert_equal(
        train.get_route_distance(),
        0.0,
        "Repeated depart must not reset an active train"
    )
    assert_false(
        train.advance_tick(track, 1.0 / 60.0),
        "One default tick must remain before the endpoint"
    )
    assert_equal(
        train.get_route_distance(),
        1.0,
        "Default speed must advance exactly one logical unit per tick"
    )


func _test_fractional_vertex_crossing() -> void:
    var track = _orthogonal_track()
    var train = TrainSystemScript.new(90.0)
    train.depart(39.5)

    assert_false(
        train.advance_tick(track, 1.0 / 60.0),
        "Fractional corner crossing must not request a distant endpoint"
    )
    assert_equal(train.get_route_distance(), 41.0, "Corner crossing must lose no distance")
    assert_equal(train.get_position(track), Vector2(140.0, 101.0), "Corner crossing position")
    assert_equal(train.get_heading(track), Vector2.DOWN, "Corner crossing heading")

    var multi_corner_train = TrainSystemScript.new(60.0)
    multi_corner_train.depart(39.5)
    assert_false(
        multi_corner_train.advance_tick(track, 2.0),
        "Multiple-corner movement must remain before the endpoint"
    )
    assert_equal(
        multi_corner_train.get_route_distance(),
        159.5,
        "Multiple-corner movement must preserve fractional distance"
    )
    assert_equal(
        multi_corner_train.get_position(track),
        Vector2(199.5, 160.0),
        "Multiple-corner movement must interpolate the final segment"
    )


func _test_corner_positions_and_headings() -> void:
    var track = _orthogonal_track()
    var distances := [39.0, 40.0, 41.0]
    var positions := [
        Vector2(139.0, 100.0),
        Vector2(140.0, 100.0),
        Vector2(140.0, 101.0),
    ]
    var headings := [Vector2.RIGHT, Vector2.DOWN, Vector2.DOWN]

    for index in range(distances.size()):
        var train = TrainSystemScript.new(60.0)
        train.depart(distances[index])
        assert_equal(
            train.get_position(track),
            positions[index],
            "Train position before, at, or after the corner"
        )
        assert_equal(
            train.get_heading(track),
            headings[index],
            "Train heading before, at, or after the corner"
        )
        assert_equal(
            train.get_heading(track).length(),
            1.0,
            "Train heading must remain normalized"
        )


func _test_built_endpoint_semantics() -> void:
    var track = _partial_track()
    assert_equal(track.get_built_end_distance(), 50.0, "Partial built endpoint")
    assert_equal(track.get_reserved_end_distance(), 100.0, "Reserved route remains ahead")

    var clamped_train = TrainSystemScript.new(60.0)
    clamped_train.depart(49.0)
    assert_true(
        clamped_train.advance_tick(track, 1.0 / 60.0),
        "Movement reaching the built endpoint must request it"
    )
    assert_equal(clamped_train.get_route_distance(), 50.0, "Movement clamps to built track")
    assert_equal(
        clamped_train.get_position(track),
        Vector2(140.0, 110.0),
        "Clamped train must not enter reserved-unbuilt track"
    )

    var exact_train = TrainSystemScript.new(60.0)
    exact_train.depart(48.0)
    assert_false(
        exact_train.advance_tick(track, 1.0 / 60.0),
        "Movement before the built endpoint must not request it"
    )
    assert_equal(exact_train.get_route_distance(), 49.0, "First endpoint approach tick")
    assert_true(
        exact_train.advance_tick(track, 1.0 / 60.0),
        "Movement exactly reaching the built endpoint must request it"
    )
    assert_equal(exact_train.get_route_distance(), 50.0, "Exact endpoint distance")

    var endpoint_train = TrainSystemScript.new(60.0)
    endpoint_train.depart(50.0)
    assert_true(
        endpoint_train.advance_tick(track, 1.0 / 60.0),
        "Zero remaining built distance requests the endpoint immediately"
    )
    assert_equal(endpoint_train.get_route_distance(), 50.0, "Endpoint tick remains clamped")

    var zero_track = TrackSystemScript.new(_config())
    var zero_train = TrainSystemScript.new(60.0)
    zero_train.depart(0.0)
    assert_true(
        zero_train.advance_tick(zero_track, 1.0 / 60.0),
        "Departure with zero built distance requests the endpoint on first active tick"
    )
    assert_equal(zero_train.get_route_distance(), 0.0, "Zero built route remains at departure")


func _test_getter_value_contract() -> void:
    var track = _orthogonal_track()
    var train = TrainSystemScript.new(60.0)
    train.depart(10.0)

    assert_equal(typeof(train.is_active()), TYPE_BOOL, "Active getter exposes a bool")
    assert_equal(typeof(train.get_route_distance()), TYPE_FLOAT, "Distance getter exposes a float")
    assert_equal(typeof(train.get_position(track)), TYPE_VECTOR2, "Position getter exposes a Vector2")
    assert_equal(typeof(train.get_heading(track)), TYPE_VECTOR2, "Heading getter exposes a Vector2")
    var position_copy: Vector2 = train.get_position(track)
    position_copy.x += 1000.0
    assert_equal(
        train.get_position(track),
        Vector2(110.0, 100.0),
        "Mutating a returned position value must not mutate train state"
    )


func run() -> PackedStringArray:
    _test_inactive_train()
    _test_departure_and_default_tick()
    _test_fractional_vertex_crossing()
    _test_corner_positions_and_headings()
    _test_built_endpoint_semantics()
    _test_getter_value_contract()
    _verify_invalid_assertion_probes()
    return finish()
