class_name ChargeMegaUpgrade extends PlayerUpgrade

const CHARGE_MEGA_ABILITY = "res://Player/Upgrades/Abilities/ChargeMegaArrow/charge_mega_ability.gd"
func upgrade(_player: Player) -> void:
	if _player != null:
		var node = load(CHARGE_MEGA_ABILITY).new()
		_player.add_ability("shooting",node)

func get_current(_player: Player) -> String:
	if _player != null:
		return "none"
	return ""
