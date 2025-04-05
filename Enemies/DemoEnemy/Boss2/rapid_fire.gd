class_name RapidFire extends Boss2Ability
@export var amount: int

func activate_ability() -> void:
	amount = randi_range(6,10)
	for i in range(amount):
		boss.shoot(boss.calculate_direction_to_player())
		await get_tree().create_timer(0.25).timeout
	ended.emit()
