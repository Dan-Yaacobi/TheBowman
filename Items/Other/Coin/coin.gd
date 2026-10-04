class_name Coin extends Item
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func extra_process_functions(_delta: float) -> void:
	animation_player.play("Spin")
