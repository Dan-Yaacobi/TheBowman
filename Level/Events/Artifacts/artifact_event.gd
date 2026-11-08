class_name ArtifactEvent extends Event
## A quiet event holding one lore artifact, set in a scene of its own.
## Finished once the artifact is picked up. Falling respawns inside the event.
## With a set piece (the artifact drawn into the scenery, e.g. a shield on a cairn), the
## pickup's own sprite stays hidden until it's taken; then the set piece swaps to its
## empty version and the artifact's icon rises out of it.

@export var pickup: LoreItemPickup
## The scenery the artifact sits in. Empty for artifacts that float on their own.
@export var set_piece: Sprite2D
## The set piece once the artifact is gone.
@export var empty_texture: Texture2D

var _world: GameWorld = null
var _world_respawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	EventBus.lore_item_found.connect(_on_event_bus_lore_item_found)
	# The pickup frees itself if already found; show the scenery without it then.
	if not is_instance_valid(pickup) or pickup.is_queued_for_deletion():
		_empty_set_piece()
	elif set_piece:
		pickup.sprite.visible = false
	# Islands here set the respawn point when landed on, which can happen before
	# on_event_entered. Keep the rift's now, while the player hasn't arrived yet.
	_world = get_parent() as GameWorld
	if _world:
		_world_respawn_position = _world.respawn_position
		_world.respawn_position = get_event_spawn()

func on_event_exited() -> void:
	if is_instance_valid(_world):
		_world.respawn_position = _world_respawn_position

## The artifact's name in the run tally.
func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	if is_instance_valid(pickup) and pickup.lore_item:
		return pickup.lore_item.display_name
	return ""

func _empty_set_piece() -> void:
	if set_piece and empty_texture:
		set_piece.texture = empty_texture

func _on_event_bus_lore_item_found(item: LoreItemData) -> void:
	if not is_instance_valid(pickup) or item != pickup.lore_item:
		return
	_empty_set_piece()
	pickup.sprite.visible = true
	report_finished(true)
