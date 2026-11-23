class_name SpawnMarker extends Marker2D
## Where an enemy can appear. Combat rifts (EncounterDirector) put one enemy of the rolled
## encounter on each marker before the player arrives.
## GROUND markers take ground enemies: they drop onto the island below and use their own sleep.
## AIR markers take flyers, which sleep on the spot until the player comes near or hits them.

enum Zone { GROUND, AIR }

@export var zone: Zone = Zone.GROUND
## Combat rifts, AIR only: the flyer here wakes when the player gets this close. 0 = the director's default.
@export var wake_radius: float = 0.0
## Combat rifts: always gets an enemy, even past the encounter's size. Other markers are only
## used for whatever the encounter has left over, picked at random.
@export var always_fill: bool = false

func _ready() -> void:
	visible = false
