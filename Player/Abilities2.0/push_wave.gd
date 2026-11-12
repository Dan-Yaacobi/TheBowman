class_name PushWave extends Node2D
## A ring that expands from a point and pushes nearby enemies away (Gust Ring, Meteor Band).

var radius: float = 56.0
var color: Color = Color.WHITE
var _t: float = 0.0
const DURATION: float = 0.3

## Pushes every living enemy within radius away from center, deals damage if > 0, and shows the ring.
## break_objects: also breaks destructible world objects (crates, barrels, vases) in the radius.
static func burst(world: World2D, center: Vector2, _radius: float, force: float, damage: int, _color: Color, upward_bias: float = 0.3, break_objects: bool = false) -> int:
	if break_objects:
		_break_objects(world, center, _radius)
	var hit: int = 0
	for enemy in MinorHitHelpers.enemies_in_radius(world, center, _radius):
		var dir: Vector2 = enemy.global_position - center
		dir = (dir.normalized() if dir.length() > 0.1 else Vector2.UP) + Vector2.UP * upward_bias
		if enemy.stats.can_be_knockedback:
			enemy.knockback_velocity += dir.normalized() * force
		if damage > 0:
			enemy.take_damage(null, damage, null, _color)
			if not enemy.is_dead:
				enemy.take_hit_effect()
		hit += 1
	var wave: PushWave = PushWave.new()
	wave.radius = _radius
	wave.color = _color
	wave.global_position = center
	EventBus.summon_effect.emit(wave)
	return hit

## Collision layer of world objects' hit boxes (value 8 = layer 4).
const OBJECT_HITBOX_MASK: int = 8

static func _break_objects(world: World2D, center: Vector2, _radius: float) -> void:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = _radius
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0.0, center)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = OBJECT_HITBOX_MASK
	for hit in world.direct_space_state.intersect_shape(params, 32):
		var area: Area2D = hit.collider as Area2D
		var object: GameObject = area.get_parent() as GameObject if area else null
		if object and not object.got_hit:
			object.break_item(null)

func _ready() -> void:
	z_index = 3
	var dust: CPUParticles2D = CPUParticles2D.new()
	dust.one_shot = true
	dust.explosiveness = 0.9
	dust.amount = 16
	dust.lifetime = 0.35
	dust.spread = 180.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = radius * 1.5
	dust.initial_velocity_max = radius * 2.5
	dust.damping_min = radius * 3.0
	dust.damping_max = radius * 4.0
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.5
	dust.color = Color(color, 0.7)
	add_child(dust)
	dust.emitting = true

func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION + 0.2:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k: float = clampf(_t / DURATION, 0.0, 1.0)
	var r: float = lerpf(radius * 0.2, radius, 1.0 - pow(1.0 - k, 3.0))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(color, (1.0 - k) * 0.9), lerpf(3.0, 1.0, k))
