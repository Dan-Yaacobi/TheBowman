class_name UndertowAbility extends PlayerAbility
## Perfect shots pull the enemy toward the archer instead of pushing it away.

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var hurt_box: HurtBox = _activator as HurtBox
	if hurt_box == null or _target == null:
		return
	var arrow: Arrow = hurt_box.get_parent() as Arrow
	if arrow == null or not arrow.perfect_shot:
		return
	hurt_box.knockback_dir = (PlayerManager.player.global_position - _target.global_position).normalized()

func get_tooltip() -> String:
	return "Perfect shots pull enemies toward you"

func get_tooltip_color() -> Color:
	return Color.MEDIUM_PURPLE

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT
