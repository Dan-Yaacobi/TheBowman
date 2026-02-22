class_name Effect extends Resource

@export var effect: PackedScene
@export var ID: int
@export_custom(PROPERTY_HINT_NONE,"suffix:%") var chance: int

func apply_effect(_target: Node2D, _arrow: Arrow) -> void:
	pass
