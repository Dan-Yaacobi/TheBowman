extends Sprite2D

@onready var _parent: Node2D = get_parent()

func _ready() -> void:
	top_level = true
	
func _process(_delta: float) -> void:
	var facing: float = sign(_parent.scale.x)
	global_position = _parent.global_position + Vector2(15 * facing, 0)
	scale.x = abs(scale.x) * facing
