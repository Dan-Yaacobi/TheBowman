extends Label

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("Crit")
	animation_player.animation_finished.connect(done)
	pass

func _physics_process(delta: float) -> void:
	global_position.y -= 50*delta


func done(v: String) -> void:
	if v == "Crit":
		queue_free()
