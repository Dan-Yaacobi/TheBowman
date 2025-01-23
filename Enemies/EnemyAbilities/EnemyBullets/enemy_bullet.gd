class_name EnemyBullet extends Area2D

@export var data: EnemyBulletData

@onready var sprite: Sprite2D = $Sprite2D
@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var direction: Vector2 = Vector2.ZERO

func _ready() -> void: 
	sprite.texture = data.texture
	visible_on_screen_notifier.screen_exited.connect(clear_shot)
	body_entered.connect(hit_player)
	body_shape_entered.connect(hit_wall)
	
func _physics_process(delta: float) -> void:
	global_position += direction * data.move_speed * delta
	rotation += randf_range(0.5,10)
	pass

func hit_player(b) -> void:
	if b is Player:
		b.hit_player(data.damage)
		b.set_pushback_values(direction,data.knockback)
		clear_shot()

func hit_wall(_v1,_v2,_v3,_v4) -> void:
	clear_shot()
	
func clear_shot() -> void:
	queue_free()
