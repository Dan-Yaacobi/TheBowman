class_name RiftChunk extends Node2D

@onready var bounds: Bounds = $Bounds
@onready var entry: EntryMarker = $EntryMarker

@export var allowed_spawn: bool = true
@export var spawn_chance: float = 0.2

var connected_chunks: Array[RiftChunk] = []
var rift: Rift
var rift_level: RiftLevel
var is_main_path: bool = false
var visited: bool = false
var is_side_path_terminal: bool = false

func _ready() -> void:

	free_exits()
	extra_ready_functions()

func extra_ready_functions() -> void:
	pass

func set_rift(_rift: Rift) -> void:
	if _rift:
		rift = _rift

func get_entry_global() -> Vector2:
	return entry.global_position

func get_exit_markers() -> Array[ExitMarker]:
	var exits: Array[ExitMarker] = []

	for n in get_children():
		if n is ExitMarker:
			if n.available:
				exits.append(n)

	exits.sort_custom(
		func(a: ExitMarker, b: ExitMarker) -> bool:
		return String(a.name) < String(b.name)
	)
	return exits

func get_exit_global(exit_index: int) -> Vector2:
	var exits: Array[ExitMarker] = get_exit_markers()
	if exit_index < 0 or exit_index >= exits.size():
		return global_position
	return exits[exit_index].global_position

func get_bounds_rect() -> Rect2:
	return bounds.get_boundaries()

func get_bounds_shape() -> Shape2D:
	return bounds.get_shape()

func get_bounds_transform() -> Transform2D:
	return bounds.transform
	
func free_exits() -> void:
	for n in get_children():
		if n is ExitMarker:
			n.available = true

func set_rift_level(_rift_level: RiftLevel) -> void:
	if _rift_level:
		rift_level = _rift_level
