class_name StunUpgrade extends PlayerUpgrade

const STUN_ABILITY = "res://Player/Upgrades/Abilities/StunUpgrade/stun_ability.gd"

func upgrade(_player: Player) -> void:
	if _player != null:
		if ability_chosen == false:
			ability_chosen = true
			var node = load(STUN_ABILITY).new()
			_player.add_ability("shooting",node)
		else:
			upgrade2(_player)

func upgrade2(_player: Player) -> void:
	_player.stats.stun_chance += 5
	#_player.current_weapon.weapon_data.stun_chance += 5
	
func get_current(_player: Player) -> String:
	if _player != null:
		return "none"
	return ""

func get_buff_tooltip(_player: Player) -> String:
	return "Stun Chance: " + str(_player.stats.stun_chance) + "%"
