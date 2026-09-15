class_name ShadowAbility extends PlayerPassiveAbility
const SHADOW_EFFECT = preload("uid://bsx66xsp8vyxd")
var new_effect: CPUParticles2D
var arrow_effect: ShadowArrow

func on_equipped() -> void:
	arrow_effect = ShadowArrow.new()
	PlayerManager.player.modulate = "ed4fffc6"
	new_effect = SHADOW_EFFECT.instantiate()
	PlayerManager.player.add_child(new_effect)
	PlayerManager.player.stats.arrow_pierce.add_buff(CustomVariables.ARROW_PIERCE_ID,999, Stat.buff_type.ADDITIVE)
	PlayerManager.player.stats.arrow_visual_effects.append(arrow_effect)
	
func on_unequipped() -> void:
	PlayerManager.player.modulate = Color.WHITE
	PlayerManager.player.stats.arrow_visual_effects.erase(arrow_effect)
	if is_instance_valid(new_effect):
		new_effect.queue_free()
		new_effect = null
	PlayerManager.player.stats.arrow_pierce.remove_buff_stack(CustomVariables.ARROW_PIERCE_ID, Stat.buff_type.ADDITIVE)
	
func get_tooltip() -> String:
	return "You and your arrow are made of shadows"
