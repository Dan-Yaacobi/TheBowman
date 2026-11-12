class_name BloodExplosion extends CPUParticles2D

const BLEED_DEBUFF = preload("uid://b0pv21kfxpvci")
@onready var hurt_box: HurtBox = $HurtBox
## The bow's color bonus, set by the Blood Gauge before it's added.
var damage_mult: float = 1.0

func _ready() -> void:
	emitting = true
	@warning_ignore("narrowing_conversion")
	hurt_box.use_default_color = false
	hurt_box.combat_text_color = Color.DARK_RED
	@warning_ignore("narrowing_conversion")
	hurt_box.base_damage = maxi(1, roundi(PlayerManager.player.stats.bleed_damage.value() * damage_mult))
	hurt_box.add_before_effect(apply_bleed)
	

func apply_bleed(_target: GameEntity, _var2) -> void:
	if _target is Enemy:
		var bleed_debuff: BleedDebuff = BLEED_DEBUFF.instantiate()
		@warning_ignore("narrowing_conversion")
		bleed_debuff.bleed_damage = maxi(1, roundi(PlayerManager.player.stats.bleed_damage.value() * damage_mult))
		var duration = PlayerManager.player.stats.bleed_duration.value()
		var ticks = PlayerManager.player.stats.dot_ticks("bleed")
		_target.apply_debuff(bleed_debuff,CustomVariables.get_buff_id(),duration,ticks)

func _on_finished() -> void:
	queue_free()
