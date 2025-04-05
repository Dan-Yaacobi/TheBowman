class_name BulletExplosion extends Boss2Ability

var total_shots: int = 12
var total_explosions: int

func activate_ability() -> void:
	total_explosions = randi_range(2,4)
	for j in range(total_explosions):
		total_shots = randi_range(8,18)
		for i in range(total_shots):
			boss.shoot(get_direction(i))
		await get_tree().create_timer(1).timeout
	ended.emit()
	pass
	
func get_direction(_shot_number: int) -> Vector2:
	return Vector2(cos(get_angle(_shot_number)),sin(get_angle(_shot_number)))
	
func get_angle(_shot_number: int) -> int:
	return _shot_number*(360/total_shots)
