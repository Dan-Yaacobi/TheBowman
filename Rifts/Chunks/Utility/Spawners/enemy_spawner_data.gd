class_name EnemySpawnerData extends Resource

const FLYING_APPLE = preload("uid://cn76h3jplsrfn")
const RED_FLYING_APPLE = preload("uid://dbsxgoiwtydme")
const BLUE_FLYING_APPLE = preload("uid://bogvy8w5pn6fb")
const GREEN_FLYING_APPLE = preload("uid://d2ua6hue6crj6")
const COLORLESS_FLYING_APPLE = preload("uid://bifydptc2miel")

@export_subgroup("Flying Apples")
@export var apple_scene: PackedScene = FLYING_APPLE
@export var apple_data: Array[EnemyData]= [
	RED_FLYING_APPLE,BLUE_FLYING_APPLE,GREEN_FLYING_APPLE,
	COLORLESS_FLYING_APPLE
	]
@export var total: int = 3

func get_apple(_tier = 0) -> Enemy:
	var new_enemy: FlyingApple = apple_scene.instantiate()
	new_enemy.set_data(apple_data[min(_tier,apple_data.size())])
	return new_enemy
