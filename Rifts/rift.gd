class_name Rift extends Node2D
@onready var rift_generator: RiftGenerator = $RiftGenerator

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
	pass
