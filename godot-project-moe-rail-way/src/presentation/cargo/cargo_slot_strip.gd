class_name CargoSlotStrip
extends Control

const STYLE_COLORS := [
    Color("2ec4b6"), Color("ff9f1c"), Color("9b5de5"),
    Color("f4d35e"), Color("3a86ff"), Color("ff5d8f"),
]
const STYLE_SHAPES := [&"circle", &"diamond", &"square", &"circle", &"diamond", &"square"]
const EMPTY_COLOR := Color(0.62, 0.68, 0.70, 0.7)
const BASE_MINIMUM_SIZE := Vector2(52.0, 20.0)
const MINIMUM_SLOT_WIDTH := 10.0

var _slots: Array = []
var _occupied := 0
var _total := 0


func _init() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = BASE_MINIMUM_SIZE


func present(snapshot) -> void:
    if snapshot == null:
        return
    _slots = snapshot.get_cargo_slot_records()
    _occupied = snapshot.get_occupied_cargo_slots()
    _total = snapshot.get_total_cargo_slots()
    custom_minimum_size.x = maxf(BASE_MINIMUM_SIZE.x, float(_total) * MINIMUM_SLOT_WIDTH)
    queue_redraw()


func get_render_observation() -> Dictionary:
    var rendered_slots: Array[Dictionary] = []
    for slot in _slots:
        var filled: bool = not StringName(slot.pair_id).is_empty()
        var style_index := clampi(slot.style_index, 0, STYLE_COLORS.size() - 1) if filled else -1
        rendered_slots.append({
            "slot_index": slot.slot_index,
            "pair_id": StringName(slot.pair_id),
            "company_id": StringName(slot.company_id) if filled else StringName(),
            "company_marker": _company_marker(StringName(slot.company_id)) if filled else "",
            "style_index": style_index,
            "shape": STYLE_SHAPES[style_index] if filled else &"square",
            "color": Color(STYLE_COLORS[style_index]) if filled else Color(EMPTY_COLOR),
            "filled": filled,
        })
    return {
        "occupied": _occupied,
        "total": _total,
        "text": "%d / %d" % [_occupied, _total],
        "slots": rendered_slots,
    }


func _draw() -> void:
    var observations: Array = get_render_observation().slots
    if observations.is_empty():
        return
    var slot_width := size.x / float(observations.size())
    var radius := clampf(minf(slot_width, size.y) * 0.3, 4.0, 8.0)
    for index in range(observations.size()):
        var slot: Dictionary = observations[index]
        var center := Vector2(slot_width * (float(index) + 0.5), size.y * 0.5)
        _draw_slot_shape(center, radius, slot.shape, slot.color, slot.filled)
        if slot.filled and not String(slot.company_marker).is_empty():
            draw_string(
                ThemeDB.fallback_font,
                center + Vector2(-radius * 0.75, radius * 0.45),
                String(slot.company_marker),
                HORIZONTAL_ALIGNMENT_LEFT,
                -1.0,
                9,
                Color(0.05, 0.07, 0.08, 1.0)
            )


func _draw_slot_shape(
    center: Vector2,
    radius: float,
    shape: StringName,
    color: Color,
    filled: bool
) -> void:
    if shape == &"circle":
        draw_circle(center, radius, color, filled, -1.0 if filled else 2.0, true)
        return
    var points := PackedVector2Array()
    if shape == &"diamond":
        points = PackedVector2Array([
            center + Vector2(0.0, -radius), center + Vector2(radius, 0.0),
            center + Vector2(0.0, radius), center + Vector2(-radius, 0.0),
        ])
    else:
        points = PackedVector2Array([
            center + Vector2(-radius, -radius), center + Vector2(radius, -radius),
            center + Vector2(radius, radius), center + Vector2(-radius, radius),
        ])
    if filled:
        draw_colored_polygon(points, color)
        return
    points.append(points[0])
    draw_polyline(points, color, 2.0, true)


func _company_marker(company_id: StringName) -> String:
    var text := String(company_id)
    if text.begins_with("company_"):
        return "C%d" % int(text.trim_prefix("company_"))
    return text.left(3).to_upper()
