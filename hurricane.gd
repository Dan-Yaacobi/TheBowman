@tool
class_name HurricaneParticles extends Node2D
class Particle:
	var phase: float
	var radius: float
	var angular_speed: float
	var rise_speed: float
	var age: float = 0.0
	var lifetime: float
	var base_color: Color
@export var particle_texture: Texture2D = null     # leave empty for a plain pixel square
@export var rotate_with_swirl: bool = true         # spin sprites to face their orbit direction
@export var pixel_colors: Array[Color] = [
	Color(1.0, 1.0, 1.0, 1.0),
	Color(0.6, 0.8, 1.0, 1.0),
	Color(0.8, 0.9, 1.0, 1.0),
]
@export var pixel_size: float = 6.0
@export var spawn_rate: float = 40.0          # pixels spawned per second
@export var top_radius: float = 45.0          # funnel width at the top
@export var taper: float = 0.75               # 0 = cylinder, 1 = fully pinched at the bottom
@export var funnel_lifetime: float = 3.0      # seconds to rise + widen
@export var rise_speed: float = 55.0          # pixels/sec upward
@export var swirl_speed_min: float = 3.0      # radians/sec
@export var swirl_speed_max: float = 5.5
var particles: Array[Particle] = []
var spawn_accumulator: float = 0.0

func _process(delta: float) -> void:
	spawn_accumulator += delta * spawn_rate
	while spawn_accumulator >= 1.0:
		spawn_accumulator -= 1.0
		_spawn_particle()
	var i: int = particles.size() - 1
	while i >= 0:
		var p: Particle = particles[i]
		p.age += delta
		if p.age >= p.lifetime:
			particles.remove_at(i)
		i -= 1
	queue_redraw()
func _spawn_particle() -> void:
	if pixel_colors.is_empty():
		return
	var p: Particle = Particle.new()
	p.phase = randf() * TAU
	p.radius = top_radius * randf_range(0.7, 1.0)
	p.angular_speed = randf_range(swirl_speed_min, swirl_speed_max)
	p.rise_speed = rise_speed * randf_range(0.85, 1.15)
	p.lifetime = funnel_lifetime * randf_range(0.85, 1.15)
	p.base_color = pixel_colors[randi() % pixel_colors.size()]
	particles.append(p)
	
func _draw() -> void:
	for p: Particle in particles:
		var height_frac: float = p.age / p.lifetime
		var y: float = -p.rise_speed * p.age
		# Narrow at the bottom (height_frac = 0), full width at the top.
		var radius_now: float = p.radius * (1.0 - taper * (1.0 - height_frac))
		var angle: float = p.phase + p.angular_speed * p.age
		var x: float = cos(angle) * radius_now
		var life_frac: float = 1.0 - height_frac
		var size: float = pixel_size * max(life_frac, 0.05)
		var color: Color = p.base_color
		# Pixels on the "near" side of the swirl (sin > 0) read slightly
		# brighter than the "far" side -- a cheap fake-depth cue that
		# sells the rotation instead of a flat left-right wobble.
		color.v = clamp(color.v * (0.75 + 0.25 * sin(angle)), 0.0, 1.0)
		color.a = clamp(life_frac, 0.0, 1.0)
		var rotation_now: float = angle if rotate_with_swirl else 0.0
		if particle_texture:
			var tex_size: Vector2 = particle_texture.get_size()
			var scale_now: float = size / max(tex_size.x, tex_size.y)
			draw_set_transform(Vector2(x, y), rotation_now, Vector2(scale_now, scale_now))
			draw_texture(particle_texture, -tex_size * 0.5, color)
		else:
			draw_set_transform(Vector2(x, y), rotation_now, Vector2.ONE)
			draw_rect(Rect2(-size * 0.5, -size * 0.5, size, size), color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
