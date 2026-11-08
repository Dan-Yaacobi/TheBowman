class_name ArtifactCatalog extends Resource
## Every lore artifact batch, in story order. The rift's artifact event rolls from here.

@export var batches: Array[ArtifactBatch] = []

## The first batch not fully found, or null once all are found.
func get_current_batch() -> ArtifactBatch:
	for batch: ArtifactBatch in batches:
		if batch and not batch.is_complete():
			return batch
	return null

## True when the current batch spawns in rifts and still has an artifact to find.
func has_rift_event() -> bool:
	return not _rift_events().is_empty()

## Rolls one still-missing artifact event from the current batch. Null if there is none.
func roll_event(rng: RandomNumberGenerator) -> PackedScene:
	var events: Array[PackedScene] = _rift_events()
	if events.is_empty():
		return null
	return events[rng.randi_range(0, events.size() - 1)]

func _rift_events() -> Array[PackedScene]:
	var batch: ArtifactBatch = get_current_batch()
	if batch == null or not batch.spawns_in_rifts:
		return []
	return batch.get_available_events()
