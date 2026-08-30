class_name WarpPairRecord
extends RefCounted

enum State {
    FORECAST,
    ACTIVE_UNLOADED,
    IN_TRANSIT,
    DELIVERED,
    EXPIRED,
    VOIDED,
}

var pair_id: StringName
var ordinal: int
var origin_cell: Vector2i
var destination_cell: Vector2i
var state: State
var forecast_remaining_ticks: int
var lifetime_total_ticks: int
var lifetime_remaining_ticks: int
var style_index: int
var company_id: StringName
var base_delivery_fee: int = -1


func duplicate_record() -> RefCounted:
    var copy = get_script().new()
    copy.pair_id = pair_id
    copy.ordinal = ordinal
    copy.origin_cell = origin_cell
    copy.destination_cell = destination_cell
    copy.state = state
    copy.forecast_remaining_ticks = forecast_remaining_ticks
    copy.lifetime_total_ticks = lifetime_total_ticks
    copy.lifetime_remaining_ticks = lifetime_remaining_ticks
    copy.style_index = style_index
    copy.company_id = company_id
    copy.base_delivery_fee = base_delivery_fee
    return copy
