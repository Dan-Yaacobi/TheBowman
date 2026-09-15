class_name ExplodeOnSwordKill extends PlayerSwordAbility

const EXPLOSION = preload("uid://c8xxhiavn7s50")

@export var explosion_damage: int

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _target and _target is Enemy and _result and _result.killed:
			@warning_ignore("narrowing_conversion")
			explosion_damage = PlayerManager.player.stats.arrow_damage.value() * 2
			var explosion: Explosion = EXPLOSION.instantiate()
			explosion.global_position = _target.global_position
			explosion.set_damage(explosion_damage)
			EventBus.summon_effect.emit(explosion)
				
func get_tooltip() -> String:
	return "Cause enemies to explode upon death"
