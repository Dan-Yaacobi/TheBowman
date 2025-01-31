class_name ArrowExplosionParticles extends CPUParticles2D

@onready var area: Area2D = $Area2D

@export var damage: int = 1

func _ready() -> void:
	rotate(randf_range(0,1))
	area.body_entered.connect(hit_enemy)
	area.monitoring = false
	finished.connect(queue_free)
	
func hit_enemy(b) -> void:
	if b is Enemy:
		b.take_damage(damage)

func start() -> void:
	area.monitoring = true
	emitting = true
