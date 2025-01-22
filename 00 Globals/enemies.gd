class_name Enemies extends Resource
#enemies_array
@export var target_enemies: Array[EnemySpawnData]
@export var bird_enemies: Array[EnemySpawnData]
@export var boss_enemies: Array[EnemySpawnData]
@export var rare_enemies: Array[EnemySpawnData]
@export var spawn_time: float

func get_enemy(current_wave : int) -> PackedScene:
	if current_wave <= 20:
		if current_wave % 5 == 0:
			return boss_enemies[(current_wave - 5) / 10].enemy
			
	if current_wave > 10:
		var bird_spawn_int: int = randi_range(0,100)
		if bird_spawn_int <= 25:
			return summon_bird(current_wave)

	var spawn_int: int = randi_range(1,100)
	var chance_sum: int = 0
	
	for enemy in target_enemies:
		chance_sum += enemy.spawn_chance
		if spawn_int > chance_sum:
			continue
		return enemy.enemy
	return null
	
func summon_target() -> void:

	pass
	
func get_special_enemy(chance: int) -> PackedScene:
	var special_spawn_int: int = randi_range(1,100)
	if special_spawn_int <= chance:
		return rare_enemies[0].enemy
	return null

func summon_bird(current_wave: int) -> PackedScene:
	var spawn_int: int = randi_range(1,100)
	var chance_sum: int = 0
	
	for enemy in bird_enemies:
		chance_sum += enemy.spawn_chance
		if spawn_int > chance_sum:
			continue
		return enemy.enemy
	return null
	#var bird_array_pos: int = 0
	#if current_wave/10 > bird_enemies.size():
		#bird_array_pos = bird_enemies.size() - 1
	#var new_enemy: PackedScene = bird_enemies[bird_array_pos].enemy
	#return new_enemy
