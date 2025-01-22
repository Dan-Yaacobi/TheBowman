class_name Arrow extends Area2D

signal arrow_missed
signal arrow_hit

@export var data: ArrowData

@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var cpu_particles: CPUParticles2D = $CPUParticles2D

var direction: Vector2
var regular_shot: bool = true

func _ready() -> void:
	visible_on_screen_notifier.screen_exited.connect(missed)
	cpu_particles.gravity = direction
	body_shape_entered.connect(hit_wall)
	if data.scale != 0:
		scale *= data.scale

func hit() -> void:
	if regular_shot:
		arrow_hit.emit()
	
func missed() -> void:
	if regular_shot:
		arrow_missed.emit()
	clear_shot()

func clear_shot() -> void:
	queue_free()
	
func _physics_process(delta: float) -> void:
	global_position += direction * delta * data.speed

func hit_wall(_val1,_val2,_val3,_val4) -> void:
	clear_shot()
