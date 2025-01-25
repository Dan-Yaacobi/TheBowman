class_name ThunderArrow extends Arrow

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer

func _ready() -> void:
	visible_on_screen_notifier.screen_exited.connect(missed)
	cpu_particles.gravity = direction
	body_shape_entered.connect(hit_wall)
	if data.scale != 0:
		scale *= data.scale
	animation_player.play("Shoot")
	
func missed() -> void:
	if regular_shot:
		arrow_missed.emit()
	queue_free()
