class_name CargoSlotRecord
extends RefCounted

var slot_index: int
var pair_id: StringName
var style_index: int = -1


func is_empty() -> bool:
    return pair_id.is_empty()


func duplicate_record() -> RefCounted:
    var copy = get_script().new()
    copy.slot_index = slot_index
    copy.pair_id = pair_id
    copy.style_index = style_index
    return copy
