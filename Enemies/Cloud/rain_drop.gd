class_name RainDrop extends Node2D

var gravity: int = 75
@onready var hurt_box: HurtBox = $HurtBox
@onready var pop_particles: CPUParticles2D = $PopParticles
@onready var wall_detector: Area2D = $WallDetector

func _ready() -> void:
	hurt_box.successful_hit.connect(pop)
	scale *= randf_range(0.5,0.8)
	wall_detector.body_shape_entered.connect(wall_pop)
	
func _physics_process(delta: float) -> void:
	global_position.y += gravity * delta 

func wall_pop(_var1,_var2,_var3,_var4) -> void:
	pop()
	
func pop() -> void:
	pop_particles.reparent(get_parent())
	pop_particles.amount = randi_range(5,10)
	pop_particles.emitting = true
	queue_free()
