class_name CargoSystem
extends RefCounted

const CargoSlotRecordScript = preload("res://src/domain/cargo/cargo_slot_record.gd")

var _slots: Array[CargoSlotRecordScript] = []
var _base_delivery_reward: int
var _delivered_pair_count := 0
var _base_delivery_reward_total := 0


func _init(base_slot_count: int, base_delivery_reward: int) -> void:
    _base_delivery_reward = base_delivery_reward
    for slot_index in range(max(0, base_slot_count)):
        var slot := CargoSlotRecordScript.new()
        slot.slot_index = slot_index
        _slots.append(slot)


func try_load(pair_id: StringName, style_index: int) -> int:
    if pair_id.is_empty():
        return -1
    for slot in _slots:
        if slot.pair_id == pair_id:
            return -1
    for slot in _slots:
        if not slot.is_empty():
            continue
        slot.pair_id = pair_id
        slot.style_index = style_index
        return slot.slot_index
    return -1


func try_deliver(pair_id: StringName) -> Dictionary:
    if pair_id.is_empty():
        return _empty_delivery_result()
    for slot in _slots:
        if slot.pair_id != pair_id:
            continue
        var slot_index := slot.slot_index
        _clear_slot(slot)
        _delivered_pair_count += 1
        _base_delivery_reward_total += _base_delivery_reward
        return {
            "delivered": true,
            "slot_index": slot_index,
            "amount": _base_delivery_reward,
        }
    return _empty_delivery_result()


func remove_pair(pair_id: StringName) -> int:
    if pair_id.is_empty():
        return -1
    for slot in _slots:
        if slot.pair_id != pair_id:
            continue
        var slot_index := slot.slot_index
        _clear_slot(slot)
        return slot_index
    return -1


func clear_all() -> void:
    for slot in _slots:
        _clear_slot(slot)


func get_slot_records() -> Array[CargoSlotRecordScript]:
    var copies: Array[CargoSlotRecordScript] = []
    for slot in _slots:
        copies.append(slot.duplicate_record())
    return copies


func get_occupied_slot_count() -> int:
    var occupied := 0
    for slot in _slots:
        if not slot.is_empty():
            occupied += 1
    return occupied


func get_total_slot_count() -> int:
    return _slots.size()


func get_delivered_pair_count() -> int:
    return _delivered_pair_count


func get_base_delivery_reward_total() -> int:
    return _base_delivery_reward_total


func _clear_slot(slot: CargoSlotRecordScript) -> void:
    slot.pair_id = StringName()
    slot.style_index = -1


func _empty_delivery_result() -> Dictionary:
    return {
        "delivered": false,
        "slot_index": -1,
        "amount": 0,
    }
