class_name ObjectSpawnMarkers extends Node2D

var markers: Array[Marker2D]

func _ready() -> void:
	for child in get_children():
		if child is Marker2D:
			markers.append(child)

func get_spawn_position() -> Vector2:
	markers.shuffle()
	var marker: Marker2D = markers.pop_back()
	return marker.global_position

func get_total_possible_spawns() -> int:
	return markers.size()
