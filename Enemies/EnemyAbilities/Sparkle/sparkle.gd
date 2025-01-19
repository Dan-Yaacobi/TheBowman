class_name EnemySparkle extends EnemyAbility

const SPARKLE = preload("res://Enemies/EnemyAbilities/Sparkle/Sparkle.tscn")

@export var sparkle_color: String
@export var sparkle_scene: PackedScene  = SPARKLE

func activate_ability(_enemy) -> void:
	if sparkle_scene != null:
		var new_sparkle = sparkle_scene.instantiate()
		new_sparkle.color = sparkle_color
		new_sparkle.emitting = true
		_enemy.add_child(new_sparkle)
