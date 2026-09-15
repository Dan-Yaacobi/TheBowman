class_name FrostBreathAbility extends PlayerShootAbility

const FROST_BREATH = preload("uid://cn3n10s62mfsj")
var breath: FrostBreath

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _activator and _activator is Arrow:
		_activator.queue_free()
	breath = FROST_BREATH.instantiate()
	breath.abilities = PlayerManager.player.get_abilities(PlayerAbility.TriggerType.SHOOT)
	breath.position = PlayerManager.player.main_hand.hold_position.position
	PlayerManager.player.add_child(breath)
	breath.active = true

func draw_ended() -> void:
	if is_instance_valid(breath):
		breath.queue_free()
