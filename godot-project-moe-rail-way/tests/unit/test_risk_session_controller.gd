extends "res://tests/support/prototype_test.gd"

const CargoSystemScript = preload("res://src/domain/cargo/cargo_system.gd")
const RouteContactAnchorScript = preload("res://src/domain/track/route_contact_anchor.gd")
const SessionControllerScript = preload("res://src/domain/session/session_controller.gd")
const SessionResultScript = preload("res://src/domain/session/session_result.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const TrackInputFrameScript = preload("res://src/domain/track/track_input_frame.gd")
const TrackSystemScript = preload("res://src/domain/track/track_system.gd")
const TrainSystemScript = preload("res://src/domain/train/train_system.gd")
const WarpPairSystemScript = preload("res://src/domain/warp/warp_pair_system.gd")

const HAZARD_SYSTEM_PATH := "res://src/domain/hazard/hazard_system.gd"


class RiskTrackSpy extends TrackSystemScript:
	var _risk_anchors: Array[RouteContactAnchorScript] = []

	func set_contact_anchors(anchors: Array[RouteContactAnchorScript]) -> void:
		super.set_contact_anchors(anchors)
		_risk_anchors.clear()
		for anchor in anchors:
			_risk_anchors.append(anchor.duplicate_anchor())

	func get_contact_hits_between(_previous: float, _through: float) -> Array[Dictionary]:
		var hits: Array[Dictionary] = []
		for anchor in _risk_anchors:
			var is_origin := String(anchor.anchor_id).ends_with("/origin")
			hits.append({
				"anchor_id": anchor.anchor_id,
				"cell": anchor.cell,
				"contact_distance_cells": 0.2 if is_origin else 0.3,
			})
		return hits

	func get_traveled_hazard_distance_cells(
		_hazard_cells: Array[Vector2i], _previous: float, _through: float
	) -> float:
		return 1.0


func run() -> PackedStringArray:
	_test_train_durability_contract()
	_test_zero_durability_wins_after_same_sweep_warp_delivery()
	return finish()


func _test_train_durability_contract() -> void:
	var train_script: Script = load("res://src/domain/train/train_system.gd")
	for method_name in [&"get_maximum_durability", &"get_current_durability", &"apply_damage"]:
		if not _script_has_method(train_script, method_name):
			assert_true(false, "Train exposes %s" % method_name)
			return
	var train: Variant = train_script.new(1.0, 100.0)
	assert_equal(train.call("get_maximum_durability"), 100.0, "Train starts with configured maximum")
	assert_equal(train.call("get_current_durability"), 100.0, "Train starts fully durable")
	assert_equal(train.call("apply_damage", 2.5), 2.5, "Train applies partial damage")
	assert_equal(train.call("get_current_durability"), 97.5, "Partial damage reduces durability")
	assert_equal(train.call("apply_damage", 200.0), 97.5, "Damage clamps to remaining durability")
	assert_equal(train.call("get_current_durability"), 0.0, "Durability never becomes negative")
	assert_equal(train.call("apply_damage", 1.0), 0.0, "Depleted train ignores repeated damage")


func _test_zero_durability_wins_after_same_sweep_warp_delivery() -> void:
	assert_true(ResourceLoader.exists(HAZARD_SYSTEM_PATH), "Hazard system exists for controller composition")
	if not ResourceLoader.exists(HAZARD_SYSTEM_PATH):
		return
	var config := _config()
	for property_name in [&"hazard_cell_count", &"maximum_durability", &"damage_per_traveled_cell", &"repair_cost_per_durability"]:
		if not _object_has_property(config, property_name):
			assert_true(false, "Session config exposes %s" % property_name)
			return
	config.hazard_cell_count = config.grid_size.x * config.grid_size.y - 1
	config.maximum_durability = 10.0
	config.damage_per_traveled_cell = 10.0
	config.repair_cost_per_durability = 1.0
	var track := RiskTrackSpy.new(config)
	var train_script: Script = load("res://src/domain/train/train_system.gd")
	var train: Variant = train_script.new(config.train_speed_cells_per_second, config.maximum_durability)
	var warp := WarpPairSystemScript.new(config, SessionRngScript.new(config.seed))
	var cargo := CargoSystemScript.new(config.cargo_base_slot_count, config.cargo_base_delivery_reward)
	var hazard: Variant = load(HAZARD_SYSTEM_PATH).new(config)
	var controller_script: Script = load("res://src/domain/session/session_controller.gd")
	var controller: Variant = controller_script.new(config, track, train, warp, cargo, hazard)
	var results: Array = []
	controller.session_completed.connect(func(result): results.append(result))
	controller.start()
	controller.advance_tick(_draw_frame([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]))
	assert_equal(results.size(), 1, "Zero durability completes exactly once")
	if results.is_empty():
		return
	assert_true(SessionResultScript.Reason.has("DURABILITY_DEPLETED"), "Durability result reason exists")
	assert_equal(results[0].get_reason(), SessionResultScript.Reason.get("DURABILITY_DEPLETED"), "Durability wins track end")
	assert_equal(results[0].get_delivered_pair_count(), 1, "Same-sweep Warp delivery is retained")
	assert_equal(results[0].get_base_delivery_reward_total(), 37, "Same-sweep base reward is retained")
	var snapshot: Variant = controller.get_snapshot()
	assert_equal(snapshot.call("get_current_durability"), 0.0, "Terminal snapshot exposes zero durability")
	assert_equal(snapshot.call("get_maximum_durability"), 10.0, "Terminal snapshot exposes maximum durability")
	assert_equal(snapshot.call("get_repair_cost_basis"), 10, "Terminal snapshot exposes repair basis")
	assert_equal(snapshot.call("get_hazard_cells").size(), 23, "Terminal snapshot exposes detached hazards")
	var detached_hazards: Array = snapshot.call("get_hazard_cells")
	detached_hazards[0] = Vector2i(-1, -1)
	assert_false(snapshot.call("get_hazard_cells")[0] == Vector2i(-1, -1), "Terminal hazard cells are recursively detached")
	assert_equal(results[0].call("get_durability_loss"), 10.0, "Result retains durability loss")
	assert_equal(results[0].call("get_repair_cost_basis"), 10, "Result retains repair basis")
	controller.advance_tick()
	assert_equal(results.size(), 1, "Completed controller emits no later result")
	assert_equal(snapshot.call("get_current_durability"), 0.0, "Terminal observation remains immutable")


func _config() -> SessionStartConfigScript:
	return SessionStartConfigScript.new(
		73013, 20.0, 1,
		1.0, 8, 1, 2.0, 10.0, 1,
		Vector2(240.0, 160.0), Vector2i(6, 4), 40.0, Vector2.ZERO,
		&"risk_departure", Vector2(20.0, 20.0), Vector2i(0, 0),
		0, 1, 5, 5, 2, 2, 37, 100, 300
	)


func _draw_frame(cells: Array[Vector2i]) -> TrackInputFrameScript:
	return TrackInputFrameScript.new(
		cells, Vector2i(0, 0), true, Vector2i(-1, -1), false,
		true, false, true, false, cells[-1], true
	)


func _object_has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if property.get("name", StringName()) == property_name:
			return true
	return false


func _script_has_method(script: Script, method_name: StringName) -> bool:
	for method in script.get_script_method_list():
		if method.get("name", StringName()) == method_name:
			return true
	return false
