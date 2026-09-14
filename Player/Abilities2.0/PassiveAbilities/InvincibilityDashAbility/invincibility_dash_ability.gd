class_name InvincibilityDashAbility extends PlayerDashAbility

func activate_ability(_target: Node2D = null , _arrow: Arrow = null, _result: DamageResult = null) -> void:
	PlayerManager.player.start_invincibilty()
	
func get_tooltip() -> String:
	return "Invincible on dash"
