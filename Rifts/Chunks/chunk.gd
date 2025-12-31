class_name RiftChunk extends Node2D

@onready var bounds: Bounds = $Bounds
@onready var entry: EntryMarker = $EntryMarker

var rift: Rift

func _ready() -> void:
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
			exits.append(n)

	exits.sort_custom(
		func(a: ExitMarker, b: ExitMarker) -> bool:
		return String(a.name) < String(b.name)
	)
	return exits

func get_exit_count() -> int:
	var exits: Array[ExitMarker] = get_exit_markers()
	return exits.size()

func get_exit_global(exit_index: int) -> Vector2:
	var exits: Array[ExitMarker] = get_exit_markers()
	if exit_index < 0 or exit_index >= exits.size():
		return global_position
	return exits[exit_index].global_position

func get_bounds_rect() -> Rect2:
	return bounds.get_boundaries()
