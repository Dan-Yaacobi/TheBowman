class_name BirdBullet extends EnemyBullet

@onready var explosion_detector: Area2D = $Explosion/HurtBox2
@onready var explosion: CPUParticles2D = $Explosion


func _physics_process(delta: float) -> void:
	global_position.y += data.move_speed * delta
	pass

func extra_ready_function() -> void:
	scale*= 0.75
	
func clear_shot(_h = null) -> void:
	explosion.emitting = true
	explosion_detector.monitoring = true
	sprite.visible = false
	explosion.call_deferred("reparent",get_parent())
	set_deferred("monitoring", false)
	queue_free()
