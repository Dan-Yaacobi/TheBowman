extends Control

@export var texture: Texture
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if texture and sprite:
		sprite.texture = texture
