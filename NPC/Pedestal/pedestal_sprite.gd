class_name PedestalSprite extends Sprite2D
## Pedestal art from Pedestals.png. Each column is one pedestal style;
## rows are variants of that style. A random variant is picked on spawn.

## 0-based column in the sheet (e.g. 7 = mossy equipment pedestal, 5 = red scroll pedestal).
@export var style_column: int = 0

func _ready() -> void:
	var column: int = clampi(style_column, 0, hframes - 1)
	frame = column + hframes * randi_range(0, vframes - 1)
