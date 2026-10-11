class_name EnemyBullet extends Area2D

@export var data: EnemyBulletData
@export var arc_height: float = 40.0
@export var min_flight_time: float = 0.2

@onready var sprite: Sprite2D = $Sprite2D
@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: HitBox = $HitBox

var was_fired: bool = false
var direction: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.INF
var velocity: Vector2 = Vector2.ZERO
var bullet_gravity: float = 0.0

func _ready() -> void:
	if sprite.texture:
		sprite.texture = data.texture
	visible_on_screen_notifier.screen_exited.connect(queue_free)
	hurt_box.base_damage = data.damage
	hurt_box.knockback_power = data.knockback
	hit_box.Damaged.connect(clear_shot)
	hurt_box.successful_hit.connect(clear_shot)
	_init_velocity()
	
	extra_ready_function()
	
func extra_ready_function() -> void:
	pass


func _init_velocity() -> void:
	if target_position == Vector2.INF:
		velocity = direction * data.move_speed
		return
	var to_target: Vector2 = target_position - global_position
	var flight_time: float = max(to_target.length() / data.move_speed, min_flight_time)
	bullet_gravity = 8.0 * arc_height / (flight_time * flight_time)
	var gravity_vector: Vector2 = Vector2.DOWN * bullet_gravity
	velocity = to_target / flight_time - 0.5 * gravity_vector * flight_time
	
func _physics_process(delta: float) -> void:
	velocity += Vector2.DOWN * bullet_gravity * delta
	global_position += velocity * delta
	rotation += randf_range(0.02,0.04)

func clear_shot(_var1, _var, _var3) -> void:
	queue_free()
