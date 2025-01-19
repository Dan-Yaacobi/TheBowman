class_name Enemies extends Resource

@export var enemies_array: Array[EnemySpawnData]
@export var boss_enemies: Array[EnemySpawnData]
@export var rare_enemies: Array[EnemySpawnData]
@export var spawn_time: float

func get_enemy(current_wave : int) -> PackedScene:
	if current_wave <= 20:
		if current_wave % 5 == 0:
			return boss_enemies[(current_wave - 5) / 10].enemy
	var spawn_int: int = randi_range(1,100)
	var chance_sum: int = 0
	for enemy in enemies_array:
		chance_sum += enemy.spawn_chance
		if spawn_int > chance_sum:
			continue
		return enemy.enemy
	return null

func get_special_enemy(chance: int) -> PackedScene:
	var special_spawn_int: int = randi_range(1,100)
	if special_spawn_int <= chance:
		return rare_enemies[0].enemy
	return null
