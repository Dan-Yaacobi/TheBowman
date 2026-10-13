class_name FireBallAbility extends PlayerShootAbility

const FIREBALL = preload("uid://omda1dnp3kkq")

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _activator and _activator is Arrow and _activator.perfect_shot:
		var fire_ball: FireBall = FIREBALL.instantiate()
		fire_ball.damage = _activator.damage
		fire_ball.can_burn = true
		fire_ball.knockback = _activator.knockback
		fire_ball.global_position = PlayerManager.player.global_position
		fire_ball.after_hit_abilities = _activator.after_hit_abilities
		fire_ball.before_hit_abilities = _activator.before_hit_abilities
		fire_ball.enemy_owned = false
		fire_ball.launch(_activator.global_position,_activator.velocity.normalized())
		_activator.queue_free()
		EventBus.summon_effect.emit(fire_ball)

func get_tooltip() -> String:
	return "Turns Perfect Shots to a FireBall"

func get_tooltip_color() -> Color:
	return Color.ORANGE_RED
