class_name OrbController extends Node2D

const ELECTRIC_ORB = preload("uid://crtombw7sghj6")

@export var max_orbs: int = 1
@export var spawn_interval: float = 3.0
@export var orbit_radius: float = 24.0
# Radians per second. Negative orbits the other way.
@export var orbit_speed: float = 3.0
# How quickly orbs slide into their new spots when the count changes.
@export var respace_speed: float = 6.0
@export var appear_duration: float = 0.25

var orbs: Array[ElectricOrb] = []
# Each orb's current angle around the circle, eased toward its even-spaced slot.
var offsets: Dictionary[ElectricOrb, float] = {}
var orbit_angle: float = 0.0
var spawn_timer: float = 0.0

func _ready() -> void:
	_spawn_orb()
	
func _process(delta: float) -> void:
	_update_spawning(delta)
	_update_orbit(delta)

func _update_spawning(delta: float) -> void:
	if orbs.size() >= max_orbs:
		# Stay at zero while full, so a lost orb takes the full interval to return.
		spawn_timer = 0.0
		return
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_orb()

func _spawn_orb() -> void:
	var orb: ElectricOrb = ELECTRIC_ORB.instantiate()
	orbs.append(orb)
	# Start the new orb in its own final slot; the others slide over to make room.
	offsets[orb] = TAU * (orbs.size() - 1) / orbs.size()
	orb.position = _orbit_position(offsets[orb])
	orb.scale = Vector2.ZERO
	add_child(orb)
	orb.tree_exiting.connect(_on_orb_removed.bind(orb))
	var tween: Tween = orb.create_tween()
	tween.tween_property(orb, "scale", Vector2.ONE, appear_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_orbit(delta: float) -> void:
	orbit_angle = wrapf(orbit_angle + orbit_speed * delta, 0.0, TAU)
	var count: int = orbs.size()
	var weight: float = 1.0 - exp(-respace_speed * delta)
	for i: int in count:
		var orb: ElectricOrb = orbs[i]
		var target: float = TAU * i / count
		offsets[orb] = lerp_angle(offsets[orb], target, weight)
		orb.position = _orbit_position(offsets[orb])

func _orbit_position(offset: float) -> Vector2:
	return Vector2.RIGHT.rotated(orbit_angle + offset) * orbit_radius

func _on_orb_removed(orb: ElectricOrb) -> void:
	# tree_exiting also fires when the player is moved to a new map (reparent).
	# Only forget orbs that are actually being freed.
	if not orb.is_queued_for_deletion():
		return
	orbs.erase(orb)
	offsets.erase(orb)
