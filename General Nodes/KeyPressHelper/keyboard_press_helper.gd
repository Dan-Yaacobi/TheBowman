class_name KeyBoardHelper extends Control

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var key_text: Label = $KeyText

func set_up(_key: String = "E") -> void:
	if _key.length() == 1:
		key_text.text = _key
		animation_player.play("press")
	else:
		queue_free()
