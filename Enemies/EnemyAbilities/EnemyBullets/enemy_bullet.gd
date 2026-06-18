class_name EnemyBullet extends Area2D

@export var data: EnemyBulletData

@onready var sprite: Sprite2D = $Sprite2D
@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: HitBox = $HitBox

var direction: Vector2 = Vector2.ZERO

func _ready() -> void: 
	sprite.texture = data.texture
	visible_on_screen_notifier.screen_exited.connect(clear_shot)
	body_shape_entered.connect(hit_wall)
	hurt_box.damage = data.damage
	hurt_box.knockback_power = data.knockback
	hit_box.Damaged.connect(clear_shot)
	hurt_box.successful_hit.connect(clear_shot)
	extra_ready_function()
	
func extra_ready_function() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	global_position += direction * data.move_speed * delta
	rotation += randf_range(0.02,0.04)
	pass

func hit_wall(_v1,_v2,_v3,_v4) -> void:
	if _v2 is Island:
		clear_shot()
	
func clear_shot(_h = null) -> void:
	queue_free()
