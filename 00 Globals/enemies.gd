class_name Enemies extends Resource

@export_subgroup("Flying Apples")
@export var flying_apple_scene: PackedScene
@export var flying_apples_data: Array[EnemyData]
@export var red_boss: PackedScene
@export var blue_boss: PackedScene

@export_subgroup("Evil Birds")
@export var evil_bird_scene: PackedScene
@export var evil_birds_data: Array[EnemyData]

const SPIDER_BOSS = preload("res://Enemies/Spider/SpiderBoss/SpiderBoss.tscn")

func get_enemy(current_wave : int) -> Enemy:
	
	var apple: FlyingApple = flying_apple_scene.instantiate()
	apple.set_data(flying_apples_data[0])
	return apple
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
