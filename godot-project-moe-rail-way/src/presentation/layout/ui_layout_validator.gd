class_name UILayoutValidator
extends RefCounted

const MIN_SUPPORTED_VIEWPORT := Vector2i(960, 540)
const MAX_SUPPORTED_VIEWPORT := Vector2i(1920, 1080)
const MIN_FIELD_SIZE := Vector2(640.0, 300.0)

const FIELD_BOUNDS := {
    "outer_padding_x": Vector2(0.0, 48.0),
    "outer_padding_y": Vector2(0.0, 32.0),
    "panel_padding": Vector2(4.0, 20.0),
    "item_gap": Vector2(4.0, 24.0),
    "row_gap": Vector2(2.0, 16.0),
    "hud_height": Vector2(44.0, 80.0),
    "icon_size": Vector2(12.0, 32.0),
}


static func validate(
    profile,
    viewport_size := MIN_SUPPORTED_VIEWPORT
) -> PackedStringArray:
    var errors := PackedStringArray()
    if profile == null:
        errors.append("ui_layout_profile.resource is required.")
        return errors

    for field_name in FIELD_BOUNDS:
        var bounds: Vector2 = FIELD_BOUNDS[field_name]
        var value: float = profile.get(field_name)
        if value < bounds.x or value > bounds.y:
            errors.append(
                "ui_layout_profile.%s must be between %.1f and %.1f; received %.1f."
                % [field_name, bounds.x, bounds.y, value]
            )

    var required_hud_height: float = profile.icon_size + 2.0 * profile.panel_padding
    if profile.hud_height < required_hud_height:
        errors.append(
            "ui_layout_profile.hud_height must be at least "
            + "ui_layout_profile.icon_size + 2 * ui_layout_profile.panel_padding; "
            + "required %.1f, received %.1f." % [required_hud_height, profile.hud_height]
        )

    var field_size := calculate_field_size(profile, viewport_size)
    if field_size.x < MIN_FIELD_SIZE.x:
        errors.append(
            "ui_layout_profile.field_width must be at least %.1f; derived %.1f."
            % [MIN_FIELD_SIZE.x, field_size.x]
        )
    if field_size.y < MIN_FIELD_SIZE.y:
        errors.append(
            "ui_layout_profile.field_height must be at least %.1f; derived %.1f."
            % [MIN_FIELD_SIZE.y, field_size.y]
        )

    return errors


static func calculate_field_size(profile, viewport_size: Vector2i) -> Vector2:
    if profile == null:
        return Vector2.ZERO
    return Vector2(
        float(viewport_size.x) - 2.0 * profile.outer_padding_x,
        float(viewport_size.y) - 2.0 * profile.outer_padding_y - 2.0 * profile.hud_height
    )
