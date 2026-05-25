class_name Enemies extends Resource

@export_subgroup("Flying Apples")
@export var flying_apple_scene: PackedScene
@export var flying_apples_data: Array[EnemyData]
@export var red_boss: PackedScene
@export var blue_boss: PackedScene

@export_subgroup("Evil Birds")
@export var evil_bird_scene: PackedScene
@export var evil_birds_data: Array[EnemyData]


@export_subgroup("Spiders")
@export var black_spider: PackedScene
@export var spiders_data: Array[EnemyData]

@export_subgroup("Clouds")
@export var regular_cloud: PackedScene
@export var clouds_data: Array[EnemyData]

const SPIDER_BOSS = preload("res://Enemies/Spider/SpiderBoss/SpiderBoss.tscn")

func get_factory(scene: PackedScene, data: EnemyData) -> Callable:
	return func() -> Enemy:
		var node: Enemy = scene.instantiate()
		node.set_data(data)
		return node

func get_red_evil_bird_factory() -> Callable:
	return get_factory(evil_bird_scene,evil_birds_data[0])
func get_regular_cloud_factory() -> Callable:
	return get_factory(regular_cloud,clouds_data[0])
	
func get_black_spider_factory() -> Callable:
	return get_factory(black_spider,spiders_data[0])
	
func get_red_apple_factory() -> Callable:
	return get_factory(flying_apple_scene, flying_apples_data[0])
#func get_enemy(difficulty : int = 0) -> PackedScene:
	#
	#var apple: PackedScene = flying_apple_scene
	#apple.set_data(flying_apples_data[difficulty])
	#return apple
	#
	#if current_wave == 35:
		#return SPIDER_BOSS
		#
	#if current_wave <= 30:
		#if current_wave % 5 == 0:
			#return boss_enemies[(current_wave - 5) / 10].enemy
			#
	#if current_wave > 6:
		#var bird_spawn_int: int = randi_range(0,100)
		#if bird_spawn_int <= 25 or (current_wave + 1) % 5 == 0:
			#return summon_bird(current_wave)
			#
	#if current_wave > 15:
		#var spider_spawn_chance: int = randi_range(0,100)
		#if spider_spawn_chance <= 15:
			#return get_spider(current_wave)
	#
	##if current_wave > 20:
		##var special_spawn_int: int = randi_range(1,100)
		##var chance: int = 5
		##if special_spawn_int <= chance:
			##return get_special_enemy(current_wave)
		#
	#var spawn_int: int = randi_range(1,100)
	#var chance_sum: int = 0
	#
	#for enemy in target_enemies:
		#chance_sum += enemy.spawn_chance
		#if spawn_int > chance_sum:
			#continue
		#return enemy.enemy
	#return null
	#
#func get_special_enemy(current_wave) -> PackedScene:
	#var index: int = current_wave / 20 - 1
	#if index > rare_enemies.size() - 1:
		#index = rare_enemies.size() - 1
	#return rare_enemies[index].enemy
#
#func get_spider(current_wave: int) -> PackedScene:
	#var spawn_int: int = randi_range(1,100)
	#var chance_sum: int = 0
	#for enemy in spiders:
		#chance_sum += enemy.spawn_chance
		#if spawn_int > chance_sum:
			#continue
		#return enemy.enemy
	#return null
#
#func summon_bird(current_wave: int) -> PackedScene:
	#var spawn_int: int = randi_range(1,100)
	#var chance_sum: int = 0
	#
	#for enemy in bird_enemies:
		#chance_sum += enemy.spawn_chance
		#if spawn_int > chance_sum:
			#continue
		#return enemy.enemy
	#return null
	##var bird_array_pos: int = 0
	##if current_wave/10 > bird_enemies.size():
		##bird_array_pos = bird_enemies.size() - 1
	##var new_enemy: PackedScene = bird_enemies[bird_array_pos].enemy
	##return new_enemy
