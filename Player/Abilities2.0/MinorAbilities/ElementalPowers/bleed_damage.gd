class_name BleedDamageMinor extends MinorAbility

func on_equipped() -> void:
	if dynamic_debuff_id == 0:
		dynamic_debuff_id = CustomVariables.get_buff_id()
	var stat: Stat = PlayerManager.player.stats.bleed_damage
	stat.remove_buff_completly(dynamic_debuff_id, Stat.buff_type.ADDITIVE)
	# Scales with the item's color level (scrolls).
	stat.add_buff(dynamic_debuff_id, value * power(), Stat.buff_type.ADDITIVE)

func refresh_power() -> void:
	on_equipped()

func on_unequipped() -> void:
	PlayerManager.player.stats.bleed_damage.remove_buff_completly(dynamic_debuff_id,Stat.buff_type.ADDITIVE)

func get_tooltip() -> String:
	return "+%d Bleed Damage per tick" % roundi(value * power())
	
func get_type() -> TriggerType:
	return TriggerType.PASSIVE

func get_tooltip_color() -> Color:
	return Color.CRIMSON
