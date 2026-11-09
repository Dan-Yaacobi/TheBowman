class_name ArtifactEntry extends Resource
## One lore artifact and the event scene it is found in.

@export var item: LoreItemData
## The event this artifact is found in. Empty = not found through rift events (e.g. the tower).
@export var event_scene: PackedScene
