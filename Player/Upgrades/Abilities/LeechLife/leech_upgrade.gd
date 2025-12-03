class_name LeechUpgrade extends PlayerUpgrade

const ABILITY_SCRIPT: String = "res://Player/Abilities2.0/ShootAbilities/leech/leech_ability.gd"

var ability: PlayerShootAbility

func _ready() -> void:
	ability = load(ABILITY_SCRIPT).new()

func upgrade(_player: Player) -> void:
	if ability_chosen == false:
		ability_chosen = true
		ability.add_ability()
	else:
		ability.update_ability()

func get_buff_tooltip(_player: Player) -> String:
	return ability.get_tooltip()
