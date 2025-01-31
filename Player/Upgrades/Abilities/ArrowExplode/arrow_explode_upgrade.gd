class_name ArrowExplodeUpgrade extends PlayerUpgrade

const AbilityArrowExplode = "res://Player/Upgrades/Abilities/ArrowExplode/ability_arrow_explode.gd"

func upgrade(_player: Player) -> void:
	if _player != null:
		var node = load(AbilityArrowExplode).new()
		_player.add_ability("shooting",node)

func get_current(_player: Player) -> String:
	if _player != null:
		return "none"
	return ""
