class_name BirdBullet extends EnemyBullet

@onready var explosion_detector: Area2D = $Explosion/HurtBox2
@onready var explosion: CPUParticles2D = $Explosion
@onready var bullet_sprite: Sprite2D = $Sprite2D

var new_texture: Texture2D
@export var acceleration_rate: float = 1.0
var _elapsed: float = 0.0

func _physics_process(delta: float) -> void:
	_elapsed += delta
	var current_speed: float = data.move_speed * exp(acceleration_rate * _elapsed)
	
	global_position.y += current_speed * delta
func set_texture(texture: Texture2D) -> void:
	new_texture = texture
	
func extra_ready_function() -> void:
	scale*= 0.4
	bullet_sprite.texture = new_texture
	
func clear_shot(_h = null) -> void:
	explosion.emitting = true
	explosion_detector.monitoring = true
	sprite.visible = false
	explosion.call_deferred("reparent",get_parent())
	set_deferred("monitoring", false)
	queue_free()
