class_name BloodExplosion extends CPUParticles2D

const BLEED_DEBUFF = preload("uid://b0pv21kfxpvci")
@onready var enemy_detector: Area2D = $EnemyDetector

func _ready() -> void:
	emitting = true

func _on_enemy_detector_body_entered(body: Node2D) -> void:
	if body is Enemy:
		var bleed_debuff: BleedDebuff = BLEED_DEBUFF.instantiate()
		bleed_debuff.bleed_damage = PlayerManager.player.stats.bleed_damage
		body.apply_debuff(bleed_debuff,6,6)

func _on_finished() -> void:
	queue_free()
