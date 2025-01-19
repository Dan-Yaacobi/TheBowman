class_name ThunderArrow extends Arrow

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer

func _ready() -> void:
	visible_on_screen_notifier.screen_exited.connect(clear_shot)
	cpu_particles.gravity = direction
	body_shape_entered.connect(hit_wall)
	if data.scale != 0:
		scale *= data.scale
	animation_player.play("Shoot")
	
func direction_offset() -> void:
	pass	
