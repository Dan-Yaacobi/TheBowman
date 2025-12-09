extends Node2D

@export var rift_config: RiftClusterConfig

var islands: Array[Island]

func build_rift(config: RiftClusterConfig) -> void:
	var generator := RiftClusterGenerator.new()
	var data := generator.generate_cluster(config)

	for island_data in data:
		var island: Island = config.island_scene.pick_random().instantiate()
		island.position = island_data.position
		add_child(island)
		islands.append(island)
		island.floating = [true,false].pick_random()
		# later: island.setup(island_data.type) etc.

func set_scene(_player: Player) -> void:
	visible = false
	islands = []
	build_rift(rift_config)
	PlayerManager.player.global_position = islands[0].spawn_position()
	visible = true
	
func exit_scene(_player: Player) -> void:
	for child in get_children():
		if child is Island:
			child.queue_free()
			
	visible = false
