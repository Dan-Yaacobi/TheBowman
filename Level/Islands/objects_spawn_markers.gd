class_name ObjectSpawnMarkers extends Node2D

var markers: Array[Marker2D]

func _ready() -> void:
	for child in get_children():
		if child is Marker2D:
			markers.append(child)

func get_spawn_position() -> Vector2:
	return markers.pick_random().global_position
