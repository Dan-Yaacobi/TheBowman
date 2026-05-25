class_name BirdBullet extends EnemyBullet

@onready var explosion_detector: Area2D = $Explosion/ExplosionDetector
@onready var explosion: CPUParticles2D = $Explosion

func _ready() -> void:
	sprite.texture = data.texture
	scale *= 0.75
	visible_on_screen_notifier.screen_exited.connect(queue_free)
	body_entered.connect(clear_shot)
	#body_entered.connect(PlayerManager.player.hit_player)
	body_shape_entered.connect(clear_shot)
	explosion_detector.monitoring = false
	#explosion_detector.body_entered.connect(hit_player)
	

func _physics_process(delta: float) -> void:
	global_position.y += data.move_speed * delta
	pass


func clear_shot(_h = null) -> void:
	explosion.emitting = true
	explosion_detector.monitoring = true
	sprite.visible = false
	explosion.call_deferred("reparent",get_parent())
	
	
	set_deferred("monitoring", false)
	#
	#await get_tree().create_timer(0.2).timeout
	#
	#explosion.queue_free()
	queue_free()
