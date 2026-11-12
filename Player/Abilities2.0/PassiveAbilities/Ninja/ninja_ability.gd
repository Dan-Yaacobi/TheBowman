class_name NinjaAblity extends PlayerPassiveAbility
## Hanzo's ability. Its very fast draw comes from the bow's own draw time (0.25s), not a buff here.

const SHURIKEN = preload("uid://eeno88yuag1l")
var id_3: int
func on_equipped() -> void:
	id_3 = CustomVariables.get_buff_id()
	PlayerManager.player.stats.perfect_shot_bonus.add_buff(id_3, -0.2, Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.arrow_texture_override = SHURIKEN
	PlayerManager.player.stats.only_perfect = true
	PlayerManager.player.stats.can_knockback += 1
	
func on_unequipped() -> void:
	PlayerManager.player.stats.perfect_shot_bonus.remove_buff_stack(id_3, Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.arrow_texture_override = null
	PlayerManager.player.stats.only_perfect = false
	PlayerManager.player.stats.can_knockback -= 1

func get_tooltip() -> String:
	return "You arrows turn into shurikens. Very fast draw, only Perfect shots work, lighter hits, no Knockback"

func get_tooltip_color() -> Color:
	return Color.LIGHT_SLATE_GRAY
