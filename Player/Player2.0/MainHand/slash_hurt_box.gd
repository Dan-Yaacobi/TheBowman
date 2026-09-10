class_name SlashHurtBox extends HurtBox

var bleed_chance: int = 0
var sword: Sword
var swing_state: SwingMainHandState
const BLEED_DEBUFF = preload("res://Debuffs/Bleed/BleedDebuff.tscn")

func set_sword(_sword: Sword) -> void:
	sword = _sword

func AreaEnetered(a: Area2D) -> void:
	if a is HitBox:
		if a.get_parent() is Enemy:
			if swing_state and not swing_state.try_hit_enemy(a.get_parent()):
				return
		combat_text_color = DEFAULT_COMBAT_TEXT_COLOR
		effect_color = DEFAULT_HIT_EFFECT_COLOR
		knockback_dir = -(PlayerManager.player.global_position - self.global_position).normalized()
		a.TakeDamage(self)
	#if a.get_parent() is Enemy:
		#_apply_effects(a.get_parent())
		EventBus.sword_hit.emit(a.get_parent())
	successful_hit.emit(self)

func apply_bleed(a: Enemy) -> void:
	var try_bleed: int = randi_range(1, 100)
	if try_bleed < sword.get_bleed_chance():
		var new_bleed_debuff: BleedDebuff = BLEED_DEBUFF.instantiate()
		new_bleed_debuff.set_damage(max(floor(PlayerManager.player.get_strength() / 10), 1))
		a.apply_debuff(new_bleed_debuff,CustomVariables.BLEED_DEBUFF_ID, 5, 5)
