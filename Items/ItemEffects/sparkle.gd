class_name Sparkle extends ItemEffect

const SPARKLE = preload("res://Items/ItemEffects/Sparkle.tscn")

@export var sparkle_color: String
@export var sparkle_scene: PackedScene = SPARKLE

func activate_ability(_item) -> void:
	if sparkle_scene != null:
		var new_sparkle = sparkle_scene.instantiate()
		new_sparkle.color = sparkle_color
		new_sparkle.emitting = true
		_item.add_child(new_sparkle)
