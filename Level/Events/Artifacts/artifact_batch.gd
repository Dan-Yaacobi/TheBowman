class_name ArtifactBatch extends Resource
## Three artifacts that tell one chapter. A batch opens once every earlier batch is found;
## its artifacts can then turn up in any order.

@export var title: String = ""
## Off for batches placed by hand (the tower), so rift events never roll them.
@export var spawns_in_rifts: bool = true
@export var entries: Array[ArtifactEntry] = []

## True once every artifact in the batch has been picked up.
func is_complete() -> bool:
	for entry: ArtifactEntry in entries:
		if entry and entry.item and not Lore.has_found(entry.item.id):
			return false
	return true

## Event scenes of artifacts in this batch that can still be found.
func get_available_events() -> Array[PackedScene]:
	var out: Array[PackedScene] = []
	for entry: ArtifactEntry in entries:
		if entry and entry.event_scene and Lore.can_obtain(entry.item):
			out.append(entry.event_scene)
	return out
