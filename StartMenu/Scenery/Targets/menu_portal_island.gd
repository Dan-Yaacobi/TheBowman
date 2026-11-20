class_name MenuPortalIsland extends MenuIsland
## The island holding the rift portal. Arrows into the portal itself are swallowed:
## the swirl spins up, sparks fly out, and the arrow is simply gone.

## The portal's opening in local (centered) coordinates.
@export var portal_rect: Rect2 = Rect2(-12.0, -45.0, 24.0, 36.0)
@export var spark_color: Color = Color(0.45, 0.85, 1.0)
## Swirl speed while the portal is excited by a hit.
@export var excited_speed: float = 7.0
@export var portal_sound: AudioStream

var _base_speed: float = 1.2

func _ready() -> void:
	super._ready()
	if material is ShaderMaterial:
		_base_speed = (material as ShaderMaterial).get_shader_parameter("speed")

## Where the camera dives in when a game starts, in global canvas coordinates.
func get_portal_center() -> Vector2:
	return to_global(portal_rect.get_center())

func react(arrow: MenuArrow, local_point: Vector2) -> void:
	if not portal_rect.has_point(local_point):
		super.react(arrow, local_point)
		return
	arrow.reparent(self)
	arrow.swallow(portal_rect.get_center())
	play_sound(portal_sound)
	_spin_up()
	_spawn_sparks()

func _spin_up() -> void:
	var shader: ShaderMaterial = material as ShaderMaterial
	if shader == null:
		return
	var tween: Tween = create_tween()
	tween.tween_method(_set_swirl_speed, excited_speed, _base_speed, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flash(1.4, 0.4)

func _set_swirl_speed(value: float) -> void:
	(material as ShaderMaterial).set_shader_parameter("speed", value)

func _spawn_sparks() -> void:
	var sparks: CPUParticles2D = CPUParticles2D.new()
	sparks.position = portal_rect.get_center()
	sparks.amount = 14
	sparks.lifetime = 0.6
	sparks.one_shot = true
	sparks.explosiveness = 0.9
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = portal_rect.size * 0.3
	sparks.direction = Vector2.UP
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 15.0
	sparks.initial_velocity_max = 40.0
	sparks.damping_min = 30.0
	sparks.damping_max = 60.0
	sparks.color_ramp = _fade_ramp(spark_color)
	_emit_once(sparks)
