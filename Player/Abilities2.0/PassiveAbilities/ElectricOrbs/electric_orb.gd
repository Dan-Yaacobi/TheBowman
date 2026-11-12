class_name ElectricOrb extends Node2D

@onready var hurt_box: HurtBox = $HurtBox
const STUN_DEBUFF = preload("uid://c1gcykybdcokh")
## The ring's color bonus, set by the orb controller before the orb is added.
var damage_mult: float = 1.0

func _ready() -> void:
	hurt_box.add_after_effect(thunder_stun)
	hurt_box.base_damage = maxi(1, roundi(PlayerManager.player.main_hand.get_base_hit_damage() / 2.0 * damage_mult))
	hurt_box.successful_hit.connect(release_orb)
	
func thunder_stun(body: Node2D, _hurt_box: Node2D, _result: DamageResult) -> void:
	if body is Enemy and not _result.killed:
		var stun: StunDebuff = STUN_DEBUFF.instantiate()
		stun.can_stack = false
		var duration: float = PlayerManager.player.stats.stun_duration.value()
		body.apply_debuff(stun,CustomVariables.STUN_DEBUFF_ID, duration,1)

func release_orb(_hurt_box: HurtBox, _hit_box: Area2D, _result: DamageResult) -> void:
	hurt_box.successful_hit.disconnect(release_orb)
	hurt_box.set_deferred("monitoring", false)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)
