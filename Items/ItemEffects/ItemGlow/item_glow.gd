class_name ItemGlow extends Node2D
## Ground glow for dropped equipment, in the color of the item's type
## (precision, tempo, elemental): a soft pulsing halo, a light pillar,
## rising motes, an outline on the sprite and a burst when it lands.

const OUTLINE_SHADER_PATH: String = "res://Items/ItemEffects/ItemGlow/item_glow_outline.gdshader"

@export var halo_radius: float = 18.0
@export var pillar_height: float = 46.0
@export var pillar_width: float = 10.0
@export var pulse_speed: float = 3.0

var color: Color = Color.WHITE
## The sprite that gets the outline shader; its old material comes back on free.
var target_sprite: Sprite2D

var _time: float = 0.0
var _intro: float = 0.0
var _old_material: Material
var _motes: CPUParticles2D

func _ready() -> void:
	z_index = -1
	# Normal blending with a saturated tint: additive washes out to white on the bright sky.
	color = Color.from_hsv(color.h, minf(color.s * 1.5, 1.0), color.v)
	_add_motes()
	_add_landing_burst()
	_apply_outline()
	var tween: Tween = create_tween()
	tween.tween_property(self, "_intro", 1.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_pop_sprite()

func _exit_tree() -> void:
	if is_instance_valid(target_sprite):
		target_sprite.material = _old_material

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_time * pulse_speed)
	# Light pillar: stacked bands fading upward.
	var height: float = pillar_height * _intro * (0.9 + 0.1 * pulse)
	var bands: int = 8
	for i: int in bands:
		var t: float = float(i) / float(bands)
		var width: float = pillar_width * (1.0 - t * 0.6) * _intro
		var alpha: float = (1.0 - t) * 0.22 * (0.75 + 0.25 * pulse)
		var band_height: float = height / float(bands)
		draw_rect(Rect2(-width / 2.0, -band_height * (i + 1), width, band_height + 0.5), Color(color, alpha))
	# Halo: layered circles for a soft falloff.
	var radius: float = halo_radius * _intro * (0.9 + 0.15 * pulse)
	for ring: int in 4:
		var ring_t: float = float(ring) / 4.0
		draw_circle(Vector2.ZERO, radius * (1.0 - ring_t * 0.6), Color(color, 0.08 + 0.04 * pulse))
	# Ground ellipse under the item.
	draw_set_transform(Vector2(0, 9), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, radius * 0.9, Color(color, 0.4 * (0.7 + 0.3 * pulse)))
	# Light rim on the ground glow so the color still reads against a sky of the same hue.
	draw_arc(Vector2.ZERO, radius * 0.9, 0.0, TAU, 32, Color(color.lightened(0.6), 0.5 + 0.3 * pulse), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _add_motes() -> void:
	_motes = CPUParticles2D.new()
	_motes.amount = 10
	_motes.lifetime = 1.4
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.emission_rect_extents = Vector2(9, 3)
	_motes.position = Vector2(0, 6)
	_motes.direction = Vector2.UP
	_motes.spread = 10.0
	_motes.gravity = Vector2(0, -12)
	_motes.initial_velocity_min = 10.0
	_motes.initial_velocity_max = 22.0
	_motes.scale_amount_min = 1.0
	_motes.scale_amount_max = 2.0
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(color.lightened(0.25), 1.0))
	fade.set_color(1, Color(color, 0.0))
	_motes.color_ramp = fade
	add_child(_motes)

func _add_landing_burst() -> void:
	var burst: CPUParticles2D = CPUParticles2D.new()
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 16
	burst.lifetime = 0.5
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = 40.0
	burst.initial_velocity_max = 70.0
	burst.damping_min = 80.0
	burst.damping_max = 120.0
	burst.scale_amount_min = 1.5
	burst.scale_amount_max = 2.5
	burst.color = color.lightened(0.3)
	burst.emitting = true
	add_child(burst)
	get_tree().create_timer(burst.lifetime + 0.1, false).timeout.connect(burst.queue_free)

func _apply_outline() -> void:
	if not is_instance_valid(target_sprite):
		return
	_old_material = target_sprite.material
	var outline: ShaderMaterial = ShaderMaterial.new()
	outline.shader = load(OUTLINE_SHADER_PATH)
	outline.set_shader_parameter("glow_color", color)
	outline.set_shader_parameter("pulse_speed", pulse_speed)
	# Dropped sprites are drawn at ~0.3 scale; ~3 texels keeps the outline about a pixel wide.
	outline.set_shader_parameter("outline_width", 3.0)
	target_sprite.material = outline

## A squash-and-stretch bounce on landing.
func _pop_sprite() -> void:
	if not is_instance_valid(target_sprite):
		return
	var rest: Vector2 = target_sprite.scale
	var tween: Tween = target_sprite.create_tween()
	tween.tween_property(target_sprite, "scale", rest * Vector2(1.3, 0.75), 0.06)
	tween.tween_property(target_sprite, "scale", rest * Vector2(0.85, 1.2), 0.08)
	tween.tween_property(target_sprite, "scale", rest, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
