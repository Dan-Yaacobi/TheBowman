class_name ArtifactEvent extends Event
## A quiet event holding one lore artifact, set in a scene of its own.
## Finished once the artifact is picked up. Falling respawns inside the event.

@export var pickup: LoreItemPickup

var _world: GameWorld = null
var _world_respawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	EventBus.lore_item_found.connect(_on_event_bus_lore_item_found)
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

func _on_event_bus_lore_item_found(item: LoreItemData) -> void:
	if is_instance_valid(pickup) and item == pickup.lore_item:
		report_finished(true)
