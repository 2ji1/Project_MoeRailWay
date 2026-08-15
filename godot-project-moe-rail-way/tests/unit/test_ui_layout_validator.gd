extends "res://tests/support/prototype_test.gd"

const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")
const Validator = preload("res://src/presentation/layout/ui_layout_validator.gd")

const FIELD_BOUNDS := {
    "outer_padding_x": Vector2(0.0, 48.0),
    "outer_padding_y": Vector2(0.0, 32.0),
    "panel_padding": Vector2(4.0, 20.0),
    "item_gap": Vector2(4.0, 24.0),
    "row_gap": Vector2(2.0, 16.0),
    "hud_height": Vector2(44.0, 80.0),
    "icon_size": Vector2(12.0, 32.0),
}

const DEFAULT_VALUES := {
    "outer_padding_x": 16.0,
    "outer_padding_y": 12.0,
    "panel_padding": 10.0,
    "item_gap": 12.0,
    "row_gap": 6.0,
    "hud_height": 56.0,
    "icon_size": 20.0,
}


func run() -> PackedStringArray:
    _verify_tracked_defaults_at_supported_viewports()
    _verify_inclusive_minimums()
    _verify_inclusive_maximums()
    _verify_outer_padding_axes_are_independent()
    _verify_all_field_bounds_are_aggregated()
    _verify_hud_content_constraint()
    _verify_field_size_constraints()
    _verify_null_profile_is_rejected()
    return finish()


func _verify_tracked_defaults_at_supported_viewports() -> void:
    var profile = load("res://data/ui_layout_profile.tres")
    assert_not_null(profile, "The tracked UI layout profile must load")
    if profile == null:
        return

    for field_name in DEFAULT_VALUES:
        assert_equal(
            profile.get(field_name),
            DEFAULT_VALUES[field_name],
            "The tracked profile must preserve the %s default" % field_name
        )

    assert_equal(
        Validator.MIN_SUPPORTED_VIEWPORT,
        Vector2i(960, 540),
        "The minimum supported viewport must remain 960x540"
    )
    assert_equal(
        Validator.MAX_SUPPORTED_VIEWPORT,
        Vector2i(1920, 1080),
        "The maximum automated viewport must remain 1920x1080"
    )
    for viewport_size in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
        assert_equal(
            Validator.validate(profile, viewport_size).size(),
            0,
            "The default profile must be valid at %s" % viewport_size
        )


func _verify_inclusive_minimums() -> void:
    var profile = _profile_with_bound_values(0)
    assert_equal(
        Validator.validate(profile, Vector2i(960, 540)).size(),
        0,
        "Every inclusive minimum must be valid at 960x540"
    )


func _verify_inclusive_maximums() -> void:
    var profile = _profile_with_bound_values(1)
    var viewport_size := Vector2i(960, 540)
    assert_equal(
        Validator.validate(profile, viewport_size).size(),
        0,
        "Every inclusive maximum must be valid at 960x540"
    )
    var field_size: Vector2 = Validator.calculate_field_size(profile, viewport_size)
    assert_true(
        field_size.x >= Validator.MIN_FIELD_SIZE.x,
        "Maximum layout values must leave the minimum field width"
    )
    assert_true(
        field_size.y >= Validator.MIN_FIELD_SIZE.y,
        "Maximum layout values must leave the minimum field height"
    )


func _verify_outer_padding_axes_are_independent() -> void:
    var viewport_size := Vector2i(1280, 720)
    var baseline = UILayoutProfileScript.new()
    var baseline_size: Vector2 = Validator.calculate_field_size(baseline, viewport_size)

    var horizontal = UILayoutProfileScript.new()
    horizontal.outer_padding_x += 5.0
    var horizontal_size: Vector2 = Validator.calculate_field_size(horizontal, viewport_size)
    assert_equal(
        horizontal_size.x,
        baseline_size.x - 10.0,
        "Horizontal outer padding must affect field width twice"
    )
    assert_equal(
        horizontal_size.y,
        baseline_size.y,
        "Horizontal outer padding must not affect field height"
    )

    var vertical = UILayoutProfileScript.new()
    vertical.outer_padding_y += 5.0
    var vertical_size: Vector2 = Validator.calculate_field_size(vertical, viewport_size)
    assert_equal(
        vertical_size.x,
        baseline_size.x,
        "Vertical outer padding must not affect field width"
    )
    assert_equal(
        vertical_size.y,
        baseline_size.y - 10.0,
        "Vertical outer padding must affect field height twice"
    )

    var taller_hud = UILayoutProfileScript.new()
    taller_hud.hud_height += 7.0
    var taller_hud_size: Vector2 = Validator.calculate_field_size(taller_hud, viewport_size)
    assert_equal(
        taller_hud_size.y,
        baseline_size.y - 14.0,
        "HUD height changes must affect field height twice"
    )


func _verify_all_field_bounds_are_aggregated() -> void:
    var below_minimum = UILayoutProfileScript.new()
    var above_maximum = UILayoutProfileScript.new()
    for field_name in FIELD_BOUNDS:
        below_minimum.set(field_name, FIELD_BOUNDS[field_name].x - 1.0)
        above_maximum.set(field_name, FIELD_BOUNDS[field_name].y + 1.0)

    var below_errors: PackedStringArray = Validator.validate(below_minimum)
    var above_errors: PackedStringArray = Validator.validate(above_maximum)
    assert_equal(below_errors.size(), FIELD_BOUNDS.size(), "Every below-minimum field must be reported")
    assert_equal(above_errors.size(), FIELD_BOUNDS.size(), "Every above-maximum field must be reported")
    for field_name in FIELD_BOUNDS:
        _assert_contains_error(
            below_errors,
            "ui_layout_profile.%s" % field_name,
            "A below-minimum error must name %s" % field_name
        )
        _assert_contains_error(
            above_errors,
            "ui_layout_profile.%s" % field_name,
            "An above-maximum error must name %s" % field_name
        )


func _verify_hud_content_constraint() -> void:
    var exact_profile = UILayoutProfileScript.new()
    exact_profile.hud_height = 44.0
    exact_profile.icon_size = 20.0
    exact_profile.panel_padding = 12.0
    assert_equal(
        Validator.validate(exact_profile).size(),
        0,
        "A HUD exactly equal to icon size plus twice its padding must be valid"
    )

    var profile = UILayoutProfileScript.new()
    profile.panel_padding = 20.0
    profile.icon_size = 32.0
    profile.hud_height = 44.0
    var errors: PackedStringArray = Validator.validate(profile)
    _assert_contains_error(
        errors,
        "ui_layout_profile.hud_height",
        "A HUD too short for its icon and padding must name hud_height"
    )
    _assert_contains_error(
        errors,
        "ui_layout_profile.icon_size",
        "The HUD content constraint must name icon_size"
    )
    _assert_contains_error(
        errors,
        "ui_layout_profile.panel_padding",
        "The HUD content constraint must name panel_padding"
    )


func _verify_field_size_constraints() -> void:
    var profile = UILayoutProfileScript.new()
    var exact_viewport := Vector2i(672, 436)
    assert_equal(
        Validator.calculate_field_size(profile, exact_viewport),
        Vector2(640.0, 300.0),
        "The exact minimum field boundary must be calculated without rounding"
    )
    assert_equal(
        Validator.validate(profile, exact_viewport).size(),
        0,
        "A field exactly 640x300 must remain valid"
    )

    var viewport_size := Vector2i(671, 435)
    assert_equal(
        Validator.calculate_field_size(profile, viewport_size),
        Vector2(639.0, 299.0),
        "Field size must subtract only outer padding and the two HUD bands"
    )
    var errors: PackedStringArray = Validator.validate(profile, viewport_size)
    _assert_contains_error(
        errors,
        "ui_layout_profile.field_width",
        "A narrow derived field must name the layout field-width boundary"
    )
    _assert_contains_error(
        errors,
        "ui_layout_profile.field_height",
        "A short derived field must name the layout field-height boundary"
    )


func _verify_null_profile_is_rejected() -> void:
    var errors: PackedStringArray = Validator.validate(null)
    _assert_contains_error(
        errors,
        "ui_layout_profile.resource",
        "A null layout profile must name the required layout Resource"
    )


func _profile_with_bound_values(bound_index: int):
    var profile = UILayoutProfileScript.new()
    for field_name in FIELD_BOUNDS:
        profile.set(field_name, FIELD_BOUNDS[field_name][bound_index])
    return profile


func _assert_contains_error(
    errors: PackedStringArray,
    expected_fragment: String,
    message: String
) -> void:
    var found := false
    for error_message in errors:
        if error_message.contains(expected_fragment):
            found = true
            break
    assert_true(found, message)
