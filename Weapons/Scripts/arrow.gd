class_name Arrow extends Area2D

signal arrow_missed
signal arrow_hit
signal arrow_hit_sound

@export var data: ArrowData

@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var cpu_particles: CPUParticles2D = $CPUParticles2D

const WALL_HIT_EFFECT = preload("res://Weapons/Effects/WallHitEffect/WallHitEffect.tscn")
const HIT_SOUND = preload("res://Weapons/Effects/HitSound/HitSound.tscn")
var direction: Vector2
var regular_shot: bool = true

var wall_hit_effect: CPUParticles2D
var hit_sound: AudioStreamPlayer2D

func _ready() -> void:
	hit_sound = HIT_SOUND.instantiate()
	visible_on_screen_notifier.screen_exited.connect(missed)
	cpu_particles.gravity = direction
	body_shape_entered.connect(hit_wall)
	if data.scale != 0:
		scale *= data.scale

func hit() -> void:
	if regular_shot:
		arrow_hit.emit()
	
func missed() -> void:
	if regular_shot:
		arrow_missed.emit()
	queue_free()

func clear_shot() -> void:
	arrow_hit_sound.emit()
	queue_free()
	
func _physics_process(delta: float) -> void:
	global_position += direction * delta * data.speed

func hit_wall(_val1,_val2,_val3,_val4) -> void:
	if _val2 is TileMapLayer:
		wall_hit_effect = WALL_HIT_EFFECT.instantiate()
		if wall_hit_effect.get_parent() == null:
			get_parent().call_deferred("add_child",wall_hit_effect)
		wall_hit_effect.emitting = true
		wall_hit_effect.global_position = global_position
		clear_shot()
