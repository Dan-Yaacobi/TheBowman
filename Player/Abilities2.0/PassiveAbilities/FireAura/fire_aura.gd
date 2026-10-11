class_name FireAura extends Sprite2D

# Fireball shown around the player while dashing. Built and added in code by
# FireDashAbility, so the player scene doesn't need it.
# The tail follows the player's actual velocity, so it also trails nicely
# while fading out after the dash ends.
const BURN_DEBUFF = preload("uid://caiebherwxilx")
@onready var hurt_box: HurtBox = $HurtBox

var fade_in: float = 0.05
var fade_out: float = 0.15

var mat: ShaderMaterial
var tween: Tween

func setup(_shader: Shader, _scale: float, _offset: Vector2) -> void:
	# The texture only gives the shader a canvas to draw on; size comes from scale.
	# A real 64x64 image, so the texture's actual size matches its reported size.
	var img: Image = Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(img)
	mat = ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("strength", 0.0)
	material = mat
	scale = Vector2.ONE * _scale
	position = _offset
	# Draw behind the player so the flames surround him rather than cover him.
	show_behind_parent = false

	
func _ready() -> void:
	set_process(false)
	hurt_box.base_damage = roundi(PlayerManager.player.stats.burn_damage.value())
	hurt_box.add_after_effect(apply_burn)
	
func ignite() -> void:
	hurt_box.monitoring = true
	set_process(true)
	_update_direction()
	_fade_to(1.0, fade_in)

func extinguish() -> void:
	hurt_box.monitoring = false
	_fade_to(0.0, fade_out)
	tween.tween_callback(set_process.bind(false))

func _process(_delta: float) -> void:
	_update_direction()

func _update_direction() -> void:
	var velocity: Vector2 = PlayerManager.player.velocity
	# Keep the last direction when nearly stopped, so the tail doesn't snap.
	if velocity.length() > 10.0:
		mat.set_shader_parameter("direction", velocity.normalized())

func _fade_to(target: float, duration: float) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(mat, "shader_parameter/strength", target, duration)
	
func apply_burn(enemy: Enemy, _parent, _result) -> void:
	var burn_debuff: BurnDebuff = BURN_DEBUFF.instantiate()
	burn_debuff.set_damage(roundi(PlayerManager.player.stats.burn_damage.value()))
	var duration = PlayerManager.player.stats.burn_duration.value()
	var ticks = PlayerManager.player.stats.burn_ticks.value()
	enemy.apply_debuff(burn_debuff,CustomVariables.BURN_DEBUFF_ID,duration,ticks)
