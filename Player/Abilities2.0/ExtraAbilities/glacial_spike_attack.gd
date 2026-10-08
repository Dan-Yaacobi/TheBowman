class_name IslandAttack extends Node2D

@export var attack_effect: PackedScene
var islands_inside: Array[Island]

func _on_island_detector_body_entered(body: Node2D) -> void:
	if body is Island:
		islands_inside.append(body)
		
func _on_island_detector_body_exited(body: Node2D) -> void:
	if body is Island:
		islands_inside.erase(body)
		
func activate_attack() -> void:
	for island in islands_inside:
		if attack_effect:
			var new_effect: Node2D = attack_effect.instantiate()
			new_effect.global_position = island.objects_spawn_markers.global_position
			EventBus.summon_effect.emit(new_effect)
