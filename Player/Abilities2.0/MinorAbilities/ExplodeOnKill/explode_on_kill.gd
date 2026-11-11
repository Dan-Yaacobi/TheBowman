class_name ExplodeOnKill extends MinorAbility

const EXPLOSION = preload("uid://c8xxhiavn7s50")

@export var explosion_damage: int

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _target and _target is Enemy and _result and _result.killed:
			explosion_damage = roundi(PlayerManager.player.main_hand.get_base_hit_damage() * 2.0)
			var explosion: Explosion = EXPLOSION.instantiate()
			explosion.global_position = _target.global_position
			explosion.set_damage(explosion_damage)
			EventBus.summon_effect.emit(explosion)
				
func get_tooltip() -> String:
	return "Cause enemies to explode upon death"
	
func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT

func get_tooltip_color() -> Color:
	return Color.TOMATO
