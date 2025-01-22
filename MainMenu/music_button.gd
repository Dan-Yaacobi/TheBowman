class_name MusicButton extends Button

func _ready() -> void:
	pressed.connect(music)
	
func music() -> void:
	var node: Node2D = get_parent().get_parent()
	if node is Game:
		node.music_on = not node.music_on
