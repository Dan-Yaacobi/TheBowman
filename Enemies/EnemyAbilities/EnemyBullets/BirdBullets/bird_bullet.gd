class_name BirdBullet extends EnemyBullet

@onready var explosion_detector: Area2D = $Explosion/ExplosionDetector
@onready var explosion: CPUParticles2D = $Explosion

func _ready() -> void:
	sprite.texture = data.texture
	visible_on_screen_notifier.screen_exited.connect(clear_shot)
	
	body_entered.connect(hit_player)
	body_shape_entered.connect(hit_wall)
	
	explosion_detector.monitoring = false
	explosion_detector.body_entered.connect(hit_player)
	

func _physics_process(delta: float) -> void:
	global_position.y += data.move_speed
	pass


func clear_shot() -> void:
	explosion.emitting = true
	explosion_detector.monitoring = true
	
	explosion.call_deferred("reparent",get_parent())
	sprite.visible = false
	
	set_deferred("monitoring", false)
	
	await get_tree().create_timer(0.2).timeout
	
	explosion.queue_free()
	queue_free()
