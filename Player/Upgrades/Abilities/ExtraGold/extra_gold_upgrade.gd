class_name ExtraGoldUpgrade extends PlayerUpgrade

const ABILITY_SCRIPT: String = "res://Player/Abilities2.0/PassiveAbilities/ExtraGold/extra_gold_ability.gd"

var ability: PlayerAbility

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
