class_name SpawnMarker extends Marker2D
## Where an enemy can appear. Combat rifts (EncounterDirector) put one enemy of the rolled
## encounter on each marker before the player arrives; it sleeps there until woken.
## GROUND markers take ground enemies (place them on an island's surface), AIR markers flyers.

enum Zone { GROUND, AIR }

@export var zone: Zone = Zone.GROUND
## Combat rifts: the enemy here wakes when the player gets this close. 0 = the director's default.
@export var wake_radius: float = 0.0

func _ready() -> void:
	visible = false
