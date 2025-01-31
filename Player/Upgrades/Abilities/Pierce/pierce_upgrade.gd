class_name PierceUpgrade extends PlayerUpgrade

@export var amount: int

const PierceAbility = "res://Player/Upgrades/Abilities/Pierce/pierce_ability.gd"

func upgrade(_player: Player) -> void:
	if _player != null:
		var node = load(PierceAbility).new()
		_player.add_ability("shooting",node)

func get_current(_player: Player) -> String:
	if _player != null:
		return "none"
	return ""
