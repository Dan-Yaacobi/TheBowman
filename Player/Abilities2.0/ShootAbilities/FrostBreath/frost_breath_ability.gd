class_name FrostBreathAbility extends PlayerShootAbility

const FROST_BREATH = preload("uid://cn3n10s62mfsj")
var breath: FrostBreath

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)
	
func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _arrow:
		_arrow.queue_free()
	breath = FROST_BREATH.instantiate()
	breath.position = PlayerManager.player.main_hand.hold_position.position
	PlayerManager.player.add_child(breath)
	breath.active = true

func draw_ended() -> void:
	if is_instance_valid(breath):
		breath.queue_free()
