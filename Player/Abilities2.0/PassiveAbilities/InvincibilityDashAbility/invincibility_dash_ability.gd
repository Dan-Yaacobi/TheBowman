class_name InvincibilityDashAbility extends PlayerDashAbility

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	PlayerManager.player.start_invincibilty()

func get_tooltip() -> String:
	return "Invincible on dash"

func get_tooltip_color() -> Color:
	return Color.CORNFLOWER_BLUE
