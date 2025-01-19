class_name ItemData extends Resource

@export var image: Texture
@export var image_size: float
@export var value: int
@export var effects: Array[ItemEffect]

func activate_abilities(_item) -> void:
	for effect in effects:
		effect.activate_ability(self)

	
	
