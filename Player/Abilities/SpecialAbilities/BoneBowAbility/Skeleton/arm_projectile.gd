class_name SkeletonArm extends Area2D

@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

@export var direction: Vector2
@export var speed: int
@export var damage :int
func _ready() -> void:
	body_entered.connect(hit_enemy)
	visible_on_screen_notifier_2d.screen_exited.connect(queue_free)
	pass

func _physics_process(_delta: float) -> void:
	global_position += direction*speed
	rotation += 0.1

func hit_enemy(b) -> void:
	if b is Enemy:
		b.take_damage(damage)
		queue_free()
