class_name FrostBreathAbility extends PlayerShootAbility

const FROST_BREATH = preload("uid://cn3n10s62mfsj")
var breath: FrostBreath

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	breath = FROST_BREATH.instantiate()
	if _activator and _activator is Arrow:
		breath.after_hit_abilities = _activator.after_hit_abilities
		breath.before_hit_abilities = _activator.before_hit_abilities
		breath.position = PlayerManager.player.main_hand.hold_position.position
		PlayerManager.player.add_child(breath)
		breath.active = true
		_activator.queue_free()
	else:
		breath.queue_free()


func draw_ended() -> void:
	if is_instance_valid(breath):
		breath.queue_free()
