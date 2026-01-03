class_name Rift extends Node2D

@onready var rift_generator: RiftGenerator = $RiftGenerator
@export var rift_values: Array[float]

var current_enemies: Array[Enemy]

func _ready() -> void:
	EventBus.enemy_summoned.connect(add_enemy)
	EventBus.enemy_died.connect(remove_enemy)
	
func set_scene(_player) -> void:
	#for i in range(20):
		#rift_generator.generate()
	_player.stats.rift_level += 1
	var start_chunk: IntroChunk = rift_generator.generate(_player.stats.rift_level)
	PlayerManager.player.global_position = start_chunk.spawn_position()
	PlayerManager.player.show_buffs()
	EventBus.entered_rift.emit()
	EventBus.summon_effect.connect(summon_effect)
	
func exit_scene(_player) -> void:
	PlayerManager.player.hide_buffs()
	rift_generator._reset_world()
	EventBus.summon_effect.disconnect(summon_effect)
	kill_all_enemies()
	
func add_enemy(_enemy: Enemy) -> void:
	if _enemy:
		current_enemies.append(_enemy)

func remove_enemy(_enemy: Enemy) -> void:
	current_enemies.erase(_enemy)
	
func kill_all_enemies() -> void:
	for enemy in current_enemies:
		remove_enemy(enemy)
		enemy.queue_free()

func summon_effect(effect: Node2D) -> void:
	add_child(effect)
