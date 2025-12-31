class_name Rift extends Node2D
@onready var rift_generator: RiftGenerator = $RiftGenerator
@export var rift_values: Array[float]

var current_enemies: Array[Enemy]
func ready() -> void:
	EventBus.enemy_summoned.connect(add_enemy)
	EventBus.enemy_died.connect(remove_enemy)
	
func set_scene(_player) -> void:
	#for i in range(20):
		#rift_generator.generate()
	var start_chunk: IntroChunk = rift_generator.generate()
	PlayerManager.player.global_position = start_chunk.spawn_position()
	PlayerManager.player.show_buffs()
	pass

func exit_scene(_player) -> void:
	PlayerManager.player.hide_buffs()
	rift_generator._reset_world()
	kill_all_enemies()
	pass

func add_enemy(_enemy: Enemy) -> void:
	print("added ", _enemy)
	if _enemy:
		current_enemies.append(_enemy)

func remove_enemy(_enemy: Enemy) -> void:
	print("removing ", _enemy)
	print(" whether it exist here: ", current_enemies)
	current_enemies.erase(_enemy)
	
func kill_all_enemies() -> void:
	print("when killing all: ", current_enemies)
	for enemy in current_enemies:
		remove_enemy(enemy)
		enemy.queue_free()
		
