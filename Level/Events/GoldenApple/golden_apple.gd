class_name GoldenApple extends Enemy

## Skittish golden apple chased in the Golden Apple event.
## Every direct hit deals exactly 1 damage regardless of gear and drops gold
## (stats.avg_coins_dropped per hit). DoT ticks are ignored.

const HIT_DAMAGE: int = 1
const HIT_TEXT_COLOR: Color = Color.GOLD

func extra_ready_functions() -> void:
	debuff_immune = true
	state_machine.Initialize(self)

func _handle_take_damage(_hurt_box: HurtBox, _raw_damage, _result: DamageResult = null, _alter_dmg_color: Color = Color.WHITE) -> void:
	# DoT ticks come in without a hurt box; only direct hits count
	if is_dead or _hurt_box == null:
		return
	current_hp -= HIT_DAMAGE
	show_damage(HIT_DAMAGE, HIT_TEXT_COLOR)
	EventBus.drop_item.emit(CustomVariables.items.COIN, global_position, 100.0, stats.avg_coins_dropped)
	if current_hp <= 0:
		is_dead = true
		activate_death_ability()
		enemy_died()
		if _result:
			_result.killed = true
