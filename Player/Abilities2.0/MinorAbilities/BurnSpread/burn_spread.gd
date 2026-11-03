class_name BurnSpreadMinor extends MinorAbility
## Burning enemies spread burn to enemies around them when they die. value = spread radius.

const BURN_DEBUFF_PATH: String = "res://Debuffs/Burned/BurnDebuff.tscn"

func on_equipped() -> void:
	if not EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.connect(_on_enemy_died)

func on_unequipped() -> void:
	if EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.disconnect(_on_enemy_died)

func _on_enemy_died(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or not enemy.is_inside_tree() or not enemy.has_debuff(CustomVariables.BURN_DEBUFF_ID):
		return
	var stats: PlayerStats = PlayerManager.player.stats
	for other in MinorHitHelpers.enemies_in_radius(enemy.get_world_2d(), enemy.global_position, value):
		if other == enemy:
			continue
		# Same burn as the fire abilities apply.
		var burn: BurnDebuff = load(BURN_DEBUFF_PATH).instantiate()
		burn.set_damage(roundi(stats.burn_damage.value()))
		other.apply_debuff(burn, CustomVariables.BURN_DEBUFF_ID, stats.burn_duration.value(), stats.burn_ticks.value())

func get_tooltip() -> String:
	return "Burning enemies spread burn when they die"

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

func get_tooltip_color() -> Color:
	return Color.ORANGE_RED
