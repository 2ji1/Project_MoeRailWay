class_name SessionShell
extends Control

const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionSnapshotScript = preload("res://src/domain/session/session_snapshot.gd")
const UILayoutProfileScript = preload("res://src/presentation/layout/ui_layout_profile.gd")

@onready var _outer_margin: MarginContainer = %OuterMargin
@onready var _main_column: VBoxContainer = %MainColumn
@onready var _top_hud: PanelContainer = %TopHud
@onready var _top_content: MarginContainer = %TopContent
@onready var _top_items: HBoxContainer = %TopItems
@onready var _field: PanelContainer = %Field
@onready var _bottom_hud: PanelContainer = %BottomHud
@onready var _bottom_content: MarginContainer = %BottomContent
@onready var _bottom_items: HBoxContainer = %BottomItems
@onready var _result_overlay: CenterContainer = %ResultOverlay
@onready var _result_panel: PanelContainer = %ResultPanel
@onready var _result_content: MarginContainer = %ResultContent
@onready var _result_rows: VBoxContainer = %ResultRows
@onready var _time_value: Label = %TimeValue

@onready var _top_item_controls: Array[Control] = [
    %TimeItem,
    %TrackItem,
    %CashItem,
    %DurabilityItem,
]
@onready var _bottom_item_controls: Array[Control] = [
    %ContractItem,
    %CargoItem,
    %TrackEndItem,
]
@onready var _icon_controls: Array[Control] = [
    %TimeIcon,
    %TrackIcon,
    %CashIcon,
    %DurabilityIcon,
    %ContractIcon,
    %CargoIcon,
    %TrackEndIcon,
]
@onready var _result_labels: Array[Label] = [
    %ResultTitle,
    %ResultReason,
    %ResultNotice,
]

var _profile: UILayoutProfileScript
var _showing_result := false


func _ready() -> void:
    _result_overlay.hide()


func configure(
    profile: UILayoutProfileScript,
    initial_snapshot: SessionSnapshotScript
) -> void:
    _profile = profile
    _apply_profile()
    present(initial_snapshot)


func present(snapshot: SessionSnapshotScript) -> void:
    if snapshot == null:
        return
    var display_seconds := snapshot.get_display_seconds()
    var minutes := int(display_seconds / 60)
    var seconds := display_seconds % 60
    _time_value.text = "%d:%02d" % [minutes, seconds]


func show_result(result: SessionResultScript) -> void:
    if _showing_result or result == null:
        return
    if result.get_reason() != SessionResultScript.Reason.REGULAR_TIME_EXPIRED:
        return
    _showing_result = true
    _result_overlay.show()


func is_showing_result() -> bool:
    return _showing_result


func get_field_global_rect() -> Rect2:
    return _field.get_global_rect()


func is_viewport_point_in_field(viewport_position: Vector2) -> bool:
    return try_viewport_to_field(viewport_position) != null


func try_viewport_to_field(viewport_position: Vector2) -> Variant:
    var inverse_transform := _field.get_global_transform_with_canvas().affine_inverse()
    var field_position := inverse_transform * viewport_position
    if not Rect2(Vector2.ZERO, _field.size).has_point(field_position):
        return null
    return field_position


func get_layout_observation() -> Dictionary:
    var top_hud_rect := _top_hud.get_global_rect()
    var top_content_rect := _top_items.get_global_rect()
    var bottom_hud_rect := _bottom_hud.get_global_rect()
    var bottom_content_rect := _bottom_items.get_global_rect()
    var result_panel_rect := _result_panel.get_global_rect()
    var result_content_rect := _result_rows.get_global_rect()
    var top_item_rects := _global_rects(_top_item_controls)
    var bottom_item_rects := _global_rects(_bottom_item_controls)
    var result_row_rects := _global_rects(_result_labels)

    return {
        "top_hud_rect": top_hud_rect,
        "top_content_rect": top_content_rect,
        "top_content_insets": _content_insets(top_hud_rect, top_content_rect),
        "field_rect": get_field_global_rect(),
        "bottom_hud_rect": bottom_hud_rect,
        "bottom_content_rect": bottom_content_rect,
        "bottom_content_insets": _content_insets(bottom_hud_rect, bottom_content_rect),
        "result_panel_rect": result_panel_rect,
        "result_content_rect": result_content_rect,
        "result_content_insets": _content_insets(result_panel_rect, result_content_rect),
        "icon_rects": _global_rects(_icon_controls),
        "top_item_rects": top_item_rects,
        "bottom_item_rects": bottom_item_rects,
        "top_item_gaps": _horizontal_gaps(top_item_rects),
        "bottom_item_gaps": _horizontal_gaps(bottom_item_rects),
        "result_row_rects": result_row_rects,
        "result_row_gaps": _vertical_gaps(result_row_rects),
        "root_separation": float(_main_column.get_theme_constant("separation")),
        "time_text": _time_value.text,
        "hud_texts": PackedStringArray([
            %TimeTitle.text,
            _time_value.text,
            %TrackTitle.text,
            %TrackValue.text,
            %CashTitle.text,
            %CashValue.text,
            %DurabilityTitle.text,
            %DurabilityValue.text,
            %ContractTitle.text,
            %ContractValue.text,
            %CargoTitle.text,
            %CargoValue.text,
            %TrackEndTitle.text,
            %TrackEndValue.text,
        ]),
        "result_texts": PackedStringArray([
            %ResultTitle.text,
            %ResultReason.text,
            %ResultNotice.text,
        ]),
    }


func _apply_profile() -> void:
    if _profile == null:
        return

    _set_margins(_outer_margin, _profile.outer_padding_x, _profile.outer_padding_y)
    _set_margins(_top_content, _profile.panel_padding, _profile.panel_padding)
    _set_margins(_bottom_content, _profile.panel_padding, _profile.panel_padding)
    _set_margins(_result_content, _profile.panel_padding, _profile.panel_padding)

    _main_column.add_theme_constant_override("separation", 0)
    _top_items.add_theme_constant_override("separation", int(round(_profile.item_gap)))
    _bottom_items.add_theme_constant_override("separation", int(round(_profile.item_gap)))
    _result_rows.add_theme_constant_override("separation", int(round(_profile.row_gap)))

    _top_hud.custom_minimum_size.y = _profile.hud_height
    _bottom_hud.custom_minimum_size.y = _profile.hud_height
    for icon in _icon_controls:
        icon.custom_minimum_size = Vector2(_profile.icon_size, _profile.icon_size)

    _outer_margin.queue_sort()
    _main_column.queue_sort()
    _top_content.queue_sort()
    _bottom_content.queue_sort()
    _result_content.queue_sort()


func _set_margins(container: MarginContainer, horizontal: float, vertical: float) -> void:
    var horizontal_pixels := int(round(horizontal))
    var vertical_pixels := int(round(vertical))
    container.add_theme_constant_override("margin_left", horizontal_pixels)
    container.add_theme_constant_override("margin_top", vertical_pixels)
    container.add_theme_constant_override("margin_right", horizontal_pixels)
    container.add_theme_constant_override("margin_bottom", vertical_pixels)


func _global_rects(controls: Array) -> Array:
    var rects := []
    for control in controls:
        rects.append(control.get_global_rect())
    return rects


func _content_insets(panel_rect: Rect2, content_rect: Rect2) -> Vector4:
    return Vector4(
        content_rect.position.x - panel_rect.position.x,
        content_rect.position.y - panel_rect.position.y,
        panel_rect.end.x - content_rect.end.x,
        panel_rect.end.y - content_rect.end.y
    )


func _horizontal_gaps(rects: Array) -> PackedFloat32Array:
    var gaps := PackedFloat32Array()
    for index in range(1, rects.size()):
        gaps.append(rects[index].position.x - rects[index - 1].end.x)
    return gaps


func _vertical_gaps(rects: Array) -> PackedFloat32Array:
    var gaps := PackedFloat32Array()
    for index in range(1, rects.size()):
        gaps.append(rects[index].position.y - rects[index - 1].end.y)
    return gaps
