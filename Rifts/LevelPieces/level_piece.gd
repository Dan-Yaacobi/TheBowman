@tool
class_name LevelPiece extends Node2D
## Base for hand-crafted level prefabs. Add ConnectorMarker children where pieces join.
## In the editor, when this piece is released after a move (or dropped into a scene), it snaps
## so its closest connector lines up with a nearby connector of another piece.
## Snapping only happens inside the edited scene, never when editing the piece's own scene.

var _last_position: Vector2 = Vector2.ZERO
var _snap_pending: bool = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	_last_position = global_position
	# Freshly dropped pieces get one snap check once the rest of the scene is in the tree.
	_snap_pending = true


func _process(_delta: float) -> void:
	if global_position != _last_position:
		_last_position = global_position
		_snap_pending = true
	if _snap_pending and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_snap_pending = false
		_try_snap()


func _try_snap() -> void:
	if not _is_in_edited_scene():
		return
	var own: Array[ConnectorMarker] = get_connectors()
	if own.is_empty():
		return

	var scene_root: Node = get_tree().edited_scene_root
	var best_offset: Vector2 = Vector2.ZERO
	var best_distance: float = INF

	for node: Node in get_tree().get_nodes_in_group(ConnectorMarker.GROUP):
		var other: ConnectorMarker = node as ConnectorMarker
		if other == null or is_ancestor_of(other) or not scene_root.is_ancestor_of(other):
			continue
		for mine: ConnectorMarker in own:
			var offset: Vector2 = other.global_position - mine.global_position
			var distance: float = offset.length()
			var reach: float = maxf(mine.snap_radius, other.snap_radius)
			if distance <= reach and distance < best_distance:
				best_distance = distance
				best_offset = offset

	if best_distance == INF or best_offset.is_zero_approx():
		return
	global_position += best_offset
	_last_position = global_position


func get_connectors() -> Array[ConnectorMarker]:
	var connectors: Array[ConnectorMarker] = []
	for node: Node in get_tree().get_nodes_in_group(ConnectorMarker.GROUP):
		var connector: ConnectorMarker = node as ConnectorMarker
		if connector and is_ancestor_of(connector):
			connectors.append(connector)
	return connectors


func _is_in_edited_scene() -> bool:
	var scene_root: Node = get_tree().edited_scene_root
	return scene_root != null and scene_root != self and scene_root.is_ancestor_of(self)
