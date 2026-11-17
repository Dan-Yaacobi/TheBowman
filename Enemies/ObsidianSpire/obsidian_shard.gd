class_name ObsidianShard extends EnemyBullet
## Flies straight (no arc, no spin), pointing where it's going, and vanishes after lifetime.

@export var lifetime: float = 2.5


func extra_ready_function() -> void:
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
