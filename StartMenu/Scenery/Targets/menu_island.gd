class_name MenuIsland extends MenuTarget
## A floating island: bobs gently, and when shot the arrow sticks, dust puffs,
## pebbles crumble off the underside and the island dips before settling.

@export var bob_height: float = 1.5
@export var bob_speed: float = 0.6
@export var dip_depth: float = 3.0
@export var dust_color: Color = Color(0.72, 0.6, 0.45)
@export var pebble_color: Color = Color(0.36, 0.25, 0.22)

var _rest: Vector2
var _phase: float = 0.0
var _time: float = 0.0
## Extra downward push from hits, eased back to 0.
var _dip: float = 0.0

func _ready() -> void:
	_rest = position
	_phase = randf() * TAU

func _process(delta: float) -> void:
	_time += delta
	_dip = move_toward(_dip, 0.0, delta * 6.0)
	position = _rest + Vector2(0.0, sin(_time * bob_speed + _phase) * bob_height + _dip)

func react(arrow: MenuArrow, local_point: Vector2) -> void:
	super.react(arrow, local_point)
	play_hit_sound()
	_dip = dip_depth
	_spawn_dust(local_point)
	_spawn_pebbles(local_point)

func _spawn_dust(local_point: Vector2) -> void:
	var dust: CPUParticles2D = CPUParticles2D.new()
	dust.position = local_point
	dust.amount = 10
	dust.lifetime = 0.45
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.direction = Vector2.UP
	dust.spread = 80.0
	dust.gravity = Vector2(0.0, 30.0)
	dust.initial_velocity_min = 10.0
	dust.initial_velocity_max = 28.0
	dust.damping_min = 20.0
	dust.damping_max = 40.0
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.0
	dust.color_ramp = _fade_ramp(dust_color)
	_emit_once(dust)

func _spawn_pebbles(local_point: Vector2) -> void:
	var pebbles: CPUParticles2D = CPUParticles2D.new()
	# From the underside, straight below the hit.
	var bottom: float = get_rect().end.y - 4.0
	pebbles.position = Vector2(local_point.x, maxf(local_point.y, bottom * 0.6))
	pebbles.amount = 5
	pebbles.lifetime = 1.1
	pebbles.one_shot = true
	pebbles.explosiveness = 0.7
	pebbles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pebbles.emission_rect_extents = Vector2(6.0, 2.0)
	pebbles.direction = Vector2.DOWN
	pebbles.spread = 20.0
	pebbles.gravity = Vector2(0.0, 140.0)
	pebbles.initial_velocity_min = 5.0
	pebbles.initial_velocity_max = 20.0
	pebbles.scale_amount_min = 1.0
	pebbles.scale_amount_max = 2.0
	pebbles.color_ramp = _fade_ramp(pebble_color)
	_emit_once(pebbles)

func _emit_once(particles: CPUParticles2D) -> void:
	particles.emitting = true
	add_child(particles)
	particles.finished.connect(particles.queue_free)

func _fade_ramp(color: Color) -> Gradient:
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color, 0.0))
	return ramp
