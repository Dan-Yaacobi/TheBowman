class_name SpiderWebProjectile extends Area2D
const WEB_SLOW_EFFECT = preload("res://Enemies/Spider/SpiderBoss/WebSlowEffect.tscn")

@export var move_speed: int = 100

@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(hit)
	visible_on_screen_notifier_2d.screen_exited.connect(queue_free)
	
func _physics_process(delta: float) -> void:
	global_position += direction * move_speed * delta
	pass
	
func hit(b) -> void:
	if b is Player:
		b.slow_player(2,WEB_SLOW_EFFECT.instantiate())
		queue_free()
	pass
