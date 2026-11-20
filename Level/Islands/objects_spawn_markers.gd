class_name ObjectSpawnMarkers extends Node2D

var markers: Array[Marker2D]
## The free marker closest to this node's origin; null once it's taken
var center_marker: Marker2D

func _ready() -> void:
	for child in get_children():
		if child is Marker2D:
			markers.append(child)
	for marker: Marker2D in markers:
		if center_marker == null or marker.position.length() < center_marker.position.length():
			center_marker = marker

func get_spawn_position() -> Vector2:
	markers.shuffle()
	var marker: Marker2D = markers.pop_back()
	if marker == center_marker:
		center_marker = null
	return marker.global_position

func get_total_possible_spawns() -> int:
	return markers.size()

func has_free_center() -> bool:
	return center_marker != null

## Takes the center marker (e.g. for an enemy that must sit mid-island) and returns its position.
func get_center_position() -> Vector2:
	var marker: Marker2D = center_marker
	markers.erase(marker)
	center_marker = null
	return marker.global_position
