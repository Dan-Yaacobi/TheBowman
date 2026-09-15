class_name Explosion extends Node2D

@onready var explosion = $Explosion
@onready var hurt_box = $HurtBox
@export var damage: int = 1
@onready var after_explosion: CPUParticles2D = $AfterExplosion
@onready var collision_shape: CollisionShape2D = $HurtBox/CollisionShape2D

func _ready() -> void:
	collision_shape.shape.radius = 17.5
	hurt_box.set_text_color(Color.DARK_ORANGE)
	hurt_box.base_damage = damage
	hurt_box.monitoring = true
	explosion.emitting = true
	explosion.finished.connect(next_emitting)

func set_damage(_damage: int) -> void:
	damage = _damage

func next_emitting() -> void:
	after_explosion.emitting = true
	collision_shape.shape.radius *= 1.75
	after_explosion.finished.connect(finished)
func finished() -> void:
	queue_free()
