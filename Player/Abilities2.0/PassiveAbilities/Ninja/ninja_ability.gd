class_name NinjaAblity extends PlayerPassiveAbility

const SHURIKEN = preload("uid://eeno88yuag1l")

func on_equipped() -> void:
	PlayerManager.player.stats.pull_speed.add_buff(6768, 10, Stat.buff_type.ADDITIVE)
	PlayerManager.player.stats.arrow_damage.add_buff(6769, 0.3,Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.arrow_texture_override = SHURIKEN
	PlayerManager.player.stats.can_knockback += 1
	
func on_unequipped() -> void:
	PlayerManager.player.stats.pull_speed.remove_buff_stack(6768, Stat.buff_type.ADDITIVE)
	PlayerManager.player.stats.arrow_damage.remove_buff_stack(6769, Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.arrow_texture_override = null
	PlayerManager.player.stats.can_knockback -= 1

func get_tooltip() -> String:
	return "You arrows turn into shurikens. Insane pull speed, Low damage, no Knockback"
