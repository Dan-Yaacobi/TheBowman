class_name PlayerBody extends CharacterBody2D

@export var charge_shaders: Dictionary[Charges,Shader] = {}

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var charge: CPUParticles2D = $Charge

enum Charges{BLOOD,THUNDER,SOUL,FIRE}

const BLOOD = preload("uid://dl8nl0pf7u1tn")

var touch_effects: Array[Callable] = []
var facing_direction: int = 1
var charge_tween: Tween


func _ready() -> void:
	EventBus.charge_gauge.connect(gauge_activated)
	EventBus.gauge_charge_used.connect(clear_charge)
func _process(_delta: float) -> void:
	pass

func change_direction(_direction: bool) -> void:
	scale.x *= -1
	facing_direction *= -1

func update_animation(anim: String) -> void:
	if anim == "":
		animation_player.stop()
	else:
		animation_player.play(anim)

func apply_touch_effects(_hurt_box: HurtBox, _damage, _result) -> void:
	return
	#var enemy = _hurt_box.get_parent()
	#if enemy is Enemy:
		#apply_touch_burn(enemy)
		#pass
		#
#const BURN_DEBUFF = preload("uid://caiebherwxilx")
#
#func apply_touch_burn(_enemy: Enemy) -> void:
	#if _enemy:
		#var burn_debuff: BurnDebuff = BURN_DEBUFF.instantiate()
		#burn_debuff.fire_damage = PlayerManager.player.stats.burn_damage.value()
		#var duration = PlayerManager.player.stats.burn_duration.value()
		#var ticks = PlayerManager.player.stats.burn_ticks.value()
		#_enemy.debuff_handler.add_debuff(burn_debuff,CustomVariables.BURN_DEBUFF_ID, duration, ticks)

func gauge_activated(_amount: int, color: Color, charge_type: Charges) -> void:
	charge_effect(color)
	set_charge(charge_type)
	
func clear_charge() -> void:
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	if charge_tween:
		charge_tween.kill()
	charge_tween = create_tween()
	charge_tween.tween_property(mat, "shader_parameter/strength", 0.0, 0.3)
	charge_tween.tween_callback(func() -> void: mat.shader = null)
	
func set_charge(charge: Charges) -> void:
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	mat.shader = charge_shaders[charge]
	mat.set_shader_parameter("strength", 0.0)
	if charge_tween:
		charge_tween.kill()
	charge_tween = create_tween()
	charge_tween.tween_property(mat, "shader_parameter/strength", 1.0, 0.3)
	
func charge_effect(color: Color) -> void:
	charge.color = color
	charge.emitting = true
