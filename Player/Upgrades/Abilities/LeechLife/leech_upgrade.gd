class_name LeechUpgrade extends PlayerUpgrade

const LEECH_ABILITY: String = "res://Player/Upgrades/Abilities/LeechLife/leech_ability.gd"

func upgrade(_player: Player) -> void:
	if _player != null:
		if ability_chosen == false:
			ability_chosen = true
			var node = load(LEECH_ABILITY).new()
			_player.add_ability("shooting",node)
		else:
			upgrade2(_player)

func upgrade2(_player: Player) -> void:
	_player.stats.leech_chance += randi_range(1,5)
	#_player.current_weapon.weapon_data.leech_chance += 5

func get_current(_player: Player) -> String:
	if _player != null:
		return "none"
	return ""
	
func get_buff_tooltip(_player: Player) -> String:
	return "Leech Chance: " + str(_player.stats.leech_chance) + "%"
