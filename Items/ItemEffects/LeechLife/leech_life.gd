class_name LeechLife extends Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("Effect")
	animation_player.animation_finished.connect(done)

func done(v) -> void:
	queue_free()
