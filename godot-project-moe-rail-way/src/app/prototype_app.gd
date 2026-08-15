extends Node

const ValidatorScript = preload("res://src/config/prototype_config_validator.gd")
const PrototypeBalanceScript = preload("res://src/config/prototype_balance.gd")
const SessionStartConfigScript = preload("res://src/domain/session/session_start_config.gd")
const SessionRngScript = preload("res://src/domain/random/session_rng.gd")

@export var balance: PrototypeBalanceScript
@export var startup_seed := 1

var session_start_config: SessionStartConfigScript
var session_rng: SessionRngScript


func _ready() -> void:
	var errors := ValidatorScript.validate(balance)
	if not errors.is_empty():
		for error_message in errors:
			push_error(error_message)
		if OS.is_debug_build():
			get_tree().quit(2)
		return

	session_start_config = balance.create_session_start_config(startup_seed)
	session_rng = SessionRngScript.new(session_start_config.seed)
	if is_inside_tree():
		print(
			"Moe Rail Way prototype foundation ready | seed=%d ticks=%d" %
			[
				session_start_config.seed,
				session_start_config.simulation_ticks_per_second,
			]
		)
