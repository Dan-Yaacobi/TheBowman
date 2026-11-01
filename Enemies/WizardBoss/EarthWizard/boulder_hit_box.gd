class_name BoulderHitBox extends HitBox
## Lets arrows (and other player attacks) strike a boulder without it being an enemy.

signal struck(hurt_box: HurtBox)

func TakeDamage(hurt_box: HurtBox, _result: DamageResult = null) -> void:
	struck.emit(hurt_box)
