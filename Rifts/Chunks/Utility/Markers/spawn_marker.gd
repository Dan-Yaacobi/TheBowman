class_name SpawnMarker extends Marker2D
## Where an enemy can appear. Combat rifts (EncounterDirector) only put ground enemies on
## GROUND markers (place them on an island's surface) and flying ones on AIR markers.

enum Zone { GROUND, AIR }

@export var zone: Zone = Zone.GROUND

func _ready() -> void:
	visible = false
