class_name EnemyDataCurse extends ChallengeCurse

## Name of a property on EnemyData, e.g. "knockback", "max_hp", "move_speed", "can_be_knockedback".
@export var property_name: String
## Numbers are multiplied by this. Stats get a multiplicative buff of (multiplier - 1).
@export var multiplier: float = 1.0
## Used only for bool properties.
@export var bool_value: bool = false

func on_enemy_spawned(_challenge: ChallengeStoneEvent, enemy: Enemy) -> void:
	var current: Variant = enemy.stats.get(property_name)
	match typeof(current):
		TYPE_INT:
			enemy.stats.set(property_name, roundi(current * multiplier))
		TYPE_FLOAT:
			enemy.stats.set(property_name, current * multiplier)
		TYPE_BOOL:
			enemy.stats.set(property_name, bool_value)
		TYPE_OBJECT:
			if current is Stat:
				current.add_buff(get_instance_id(), multiplier - 1.0, Stat.buff_type.MULTIPLICATIVE)
			else:
				push_warning("EnemyDataCurse: '%s' is not a Stat." % property_name)
		_:
			push_warning("EnemyDataCurse: '%s' not found or unsupported on EnemyData." % property_name)
