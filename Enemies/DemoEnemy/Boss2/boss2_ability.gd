class_name Boss2Ability extends Node2D

var boss: DemoEnemyBoss2

signal ended

func set_boss_var(_boss: DemoEnemyBoss2) -> void:
	if _boss != null:
		boss = _boss
	pass
	
func activate_ability() -> void:
	pass
