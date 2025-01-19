class_name BlueBowAbility extends SpecialAbility

const JUMP_EFFECT = preload("res://Player/Abilities/SpecialAbilities/BlueBowAbility/JumpEffect.tscn")

func activate_special_ability(_player: Player) -> void:
	for i in 10:
		await _player.get_tree().create_timer(0.07).timeout
		_player.current_weapon.shoot()


# old ability which was flash jump
func old_ability(_player: Player) -> void:
	var direction: int = 1
	var jump_effect: CPUParticles2D = JUMP_EFFECT.instantiate()
	jump_effect.emitting = true
	
	if not _player.direction_side:
		direction = - 1
	jump_effect.gravity = Vector2(50*direction,50)
	_player.call_deferred("add_child", jump_effect)
	_player.set_pushback_values(Vector2(-direction,0),50)
	_player.velocity.y += -70
	#_player.velocity += Vector2(-direction*250,-_player.stats.jump_height)
	pass
	
	pass
