class_name MenuLayer extends Node2D
## One depth slice of the title-screen scenery. Nearer layers sit later in the tree,
## drift further with the mouse and catch arrows at a bigger scale.

## 0 = the horizon, 1 = right in front of the viewer.
@export_range(0.0, 1.0) var depth: float = 0.5
## How much of the scenery's parallax this layer takes (0 = fixed to the sky).
@export var parallax: float = 0.5

var _rest: Vector2

func _ready() -> void:
	_rest = position

## `offset` is the scenery-wide parallax offset for a fully near layer.
func apply_parallax(offset: Vector2) -> void:
	position = _rest + offset * parallax
