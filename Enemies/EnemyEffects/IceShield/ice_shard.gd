class_name IceShard extends EnemyBullet

signal shard_destroyed

@export var rotation_speed: float = 5.0
@onready var frost_particles: CPUParticles2D = $FrostParticles

func extra_ready_function() -> void:
	sprite.frame = sprite.hframes * sprite.vframes - 1
	if !was_fired:
		frost_particles.emitting = false
		sprite.frame = randi_range(0, sprite.hframes * sprite.vframes - 2)
		body_shape_entered.disconnect(hit_wall)
		visible_on_screen_notifier.screen_exited.disconnect(clear_shot)
		
func _physics_process(delta: float) -> void:
	if was_fired:
		global_position += direction * data.move_speed * delta
	rotate(delta * rotation_speed)
	
func clear_shot(_h = null) -> void:
	shard_destroyed.emit()
	queue_free()
