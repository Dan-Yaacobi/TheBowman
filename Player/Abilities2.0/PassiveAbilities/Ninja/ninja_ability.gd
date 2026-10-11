class_name NinjaAblity extends PlayerPassiveAbility

const SHURIKEN = preload("uid://eeno88yuag1l")
@export var pull_speed_increase: float = 5
var id_1: int
var id_2: int
var id_3: int
func on_equipped() -> void:
	id_1 = CustomVariables.get_buff_id()
	id_2 = CustomVariables.get_buff_id()
	id_3 = CustomVariables.get_buff_id()
	PlayerManager.player.stats.pull_speed.add_buff(id_1, pull_speed_increase, Stat.buff_type.ADDITIVE)
	PlayerManager.player.stats.arrow_damage.add_buff(id_2, -0.5,Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.perfect_shot_bonus.add_buff(id_3, -0.2, Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.arrow_texture_override = SHURIKEN
	PlayerManager.player.stats.only_perfect = true
	PlayerManager.player.stats.can_knockback += 1
	
func on_unequipped() -> void:
	PlayerManager.player.stats.pull_speed.remove_buff_stack(id_1, Stat.buff_type.ADDITIVE)
	PlayerManager.player.stats.arrow_damage.remove_buff_stack(id_2, Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.perfect_shot_bonus.remove_buff_stack(id_3, Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.arrow_texture_override = null
	PlayerManager.player.stats.only_perfect = false
	PlayerManager.player.stats.can_knockback -= 1

func get_tooltip() -> String:
	return "You arrows turn into shurikens. Insane pull speed, only Perfect shots work, reduced damage, no Knockback"

func get_tooltip_color() -> Color:
	return Color.SLATE_GRAY
