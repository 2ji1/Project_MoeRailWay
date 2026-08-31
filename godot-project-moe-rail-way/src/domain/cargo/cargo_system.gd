class_name CargoSystem
extends RefCounted

const CargoSlotRecordScript = preload("res://src/domain/cargo/cargo_slot_record.gd")
const MAX_SLOT_COUNT := 8

var _slots: Array[CargoSlotRecordScript] = []
var _base_delivery_reward: int
var _delivered_pair_count := 0
var _delivery_fee_total := 0


func _init(base_slot_count: int, base_delivery_reward: int = 0) -> void:
    assert(
        base_slot_count >= 1 and base_slot_count <= 8,
        "Cargo slot count must be between 1 and 8"
    )
    assert(
        base_delivery_reward >= 0 and base_delivery_reward <= 1000000,
        "Cargo delivery reward must be between 0 and 1000000"
    )
    _base_delivery_reward = base_delivery_reward
    for slot_index in range(base_slot_count):
        var slot := CargoSlotRecordScript.new()
        slot.slot_index = slot_index
        _slots.append(slot)


func try_load(
    pair_id: StringName,
    style_index: int,
    company_id: StringName = StringName(),
    base_delivery_fee: int = -1
) -> int:
    if pair_id.is_empty():
        return -1
    var resolved_company_id := company_id
    var resolved_fee := base_delivery_fee
    if resolved_company_id.is_empty() and resolved_fee < 0:
        resolved_company_id = &"legacy"
        resolved_fee = _base_delivery_reward
    if resolved_company_id.is_empty() or resolved_fee < 0 or resolved_fee > 1000000:
        return -1
    for slot in _slots:
        if slot.pair_id == pair_id:
            return -1
    for slot in _slots:
        if not slot.is_empty():
            continue
        slot.pair_id = pair_id
        slot.style_index = style_index
        slot.company_id = resolved_company_id
        slot.base_delivery_fee = resolved_fee
        return slot.slot_index
    return -1


func try_deliver(pair_id: StringName) -> Dictionary:
    if pair_id.is_empty():
        return _empty_delivery_result()
    for slot in _slots:
        if slot.pair_id != pair_id:
            continue
        var slot_index := slot.slot_index
        var company_id := slot.company_id
        var base_delivery_fee := slot.base_delivery_fee
        if (
            _delivered_pair_count == 9223372036854775807
            or _delivery_fee_total > 9223372036854775807 - base_delivery_fee
        ):
            return _empty_delivery_result()
        _clear_slot(slot)
        _delivered_pair_count += 1
        _delivery_fee_total += base_delivery_fee
        return {
            "delivered": true,
            "slot_index": slot_index,
            "amount": base_delivery_fee,
            "company_id": company_id,
            "base_delivery_fee": base_delivery_fee,
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


func try_append_empty_slots(additional_slots: int) -> bool:
    if additional_slots <= 0 or _slots.size() > MAX_SLOT_COUNT - additional_slots:
        return false
    var first_new_index := _slots.size()
    for offset in range(additional_slots):
        var slot := CargoSlotRecordScript.new()
        slot.slot_index = first_new_index + offset
        _slots.append(slot)
    return true


func duplicate_cargo() -> CargoSystem:
    var copy: CargoSystem = get_script().new(1, _base_delivery_reward)
    copy._slots.clear()
    for slot in _slots:
        copy._slots.append(slot.duplicate_record())
    copy._delivered_pair_count = _delivered_pair_count
    copy._delivery_fee_total = _delivery_fee_total
    return copy


func replace_with(source: CargoSystem) -> void:
    assert(source != null, "Source cargo system is required")
    _slots.clear()
    for slot in source._slots:
        _slots.append(slot.duplicate_record())
    _base_delivery_reward = source._base_delivery_reward
    _delivered_pair_count = source._delivered_pair_count
    _delivery_fee_total = source._delivery_fee_total


func get_delivered_pair_count() -> int:
    return _delivered_pair_count


func get_base_delivery_reward_total() -> int:
    return _delivery_fee_total


func get_delivery_fee_total() -> int:
    return _delivery_fee_total


func _clear_slot(slot: CargoSlotRecordScript) -> void:
    slot.pair_id = StringName()
    slot.style_index = -1
    slot.company_id = StringName()
    slot.base_delivery_fee = 0


func _empty_delivery_result() -> Dictionary:
    return {
        "delivered": false,
        "slot_index": -1,
        "amount": 0,
        "company_id": StringName(),
        "base_delivery_fee": 0,
    }
