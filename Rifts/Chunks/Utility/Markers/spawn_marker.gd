@tool
class_name SpawnMarker extends Marker2D
## Where an enemy can appear. Combat rifts (EncounterDirector) place the rolled encounter on
## these before the player arrives.
## GROUND markers take ground enemies: they drop onto the island below and use their own sleep.
## AIR markers take flyers, which sleep on the spot until their marker activates.
## A marker activates when its flyer's wake radius reaches the player or its enemy is hit;
## it then activates every marker within its link radius (which pass it on through theirs).
## In the editor: blue circle = wake radius (air only), orange circle = link radius.

enum Zone { GROUND, AIR }

const WAKE_COLOR: Color = Color(0.47, 0.47, 0.47, 0.8)
const LINK_COLOR: Color = Color(1.0, 0.6, 0.2, 0.8)
const CIRCLE_WIDTH: float = 1.0

@export var zone: Zone = Zone.GROUND:
	set(value):
		zone = value
		queue_redraw()
## AIR only: the flyer here wakes when the player gets this close.
@export var wake_radius: float = 120.0:
	set(value):
		wake_radius = maxf(value, 0.0)
		queue_redraw()
## When this marker activates, markers within this distance activate too. 0 = none.
@export var link_radius: float = 40.0:
	set(value):
		link_radius = maxf(value, 0.0)
		queue_redraw()
## Always gets an enemy, even past the encounter's size. Other markers are only used for
## whatever the encounter has left over, picked at random.
@export var always_fill: bool = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if zone == Zone.AIR and wake_radius > 0.0:
		draw_arc(Vector2.ZERO, wake_radius, 0.0, TAU, 64, WAKE_COLOR, CIRCLE_WIDTH)
	if link_radius > 0.0:
		draw_arc(Vector2.ZERO, link_radius, 0.0, TAU, 48, LINK_COLOR, CIRCLE_WIDTH)
