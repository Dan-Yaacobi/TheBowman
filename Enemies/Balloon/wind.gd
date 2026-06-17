class_name Wind extends Area2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var cpu_particles: CPUParticles2D = $CPUParticles2D

const START_WIDTH: float = 20.0
const MAX_WIDTH: float = 200.0
const HEIGHT: float = 30.0
@export var knockback_force: float = 1500.0

func _ready() -> void:
	collision_shape.shape = collision_shape.shape.duplicate()
	disable()

func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	for body in get_overlapping_bodies():
		if body is Player:
			var dir = Vector2(scale.x, 0)
			body.apply_knockback(dir, knockback_force * _delta, true)

func enable(direction: Vector2) -> void:
	monitoring = true
	cpu_particles.direction = Vector2(1, 0)
	cpu_particles.gravity = Vector2(200.0, 0)
	
	cpu_particles.emitting = true
	reset_size()

func disable() -> void:
	monitoring = false
	cpu_particles.emitting = false
	reset_size()

func reset_size() -> void:
	collision_shape.shape.size = Vector2(START_WIDTH, HEIGHT)
	collision_shape.position.x = START_WIDTH / 2.0

func grow(amount: float) -> void:
	var current_width: float = collision_shape.shape.size.x
	var new_width: float = minf(current_width + amount, MAX_WIDTH)
	collision_shape.shape.size = Vector2(new_width, HEIGHT)
	collision_shape.position.x = new_width / 2.0
	var progress: float = new_width / MAX_WIDTH
	cpu_particles.gravity = Vector2(lerpf(50.0, 400.0, progress) * scale.x, 0)
	
func face_player() -> void:
	var dir = sign(PlayerManager.player.global_position.x - global_position.x)
	scale.x = dir
	position.x = abs(position.x) * dir
	
func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.reset_knockback()
