class_name ActiveAbility extends Resource

@export var cooldown: float = 10.0
@export var is_passive: bool = false
@export var icon: Texture2D
@export var description: String
@export var name: String

func activate(_player: Player) -> void:
	pass

func on_equipped(_player: Player) -> void:
	pass

func on_unequipped(_player: Player) -> void:
	pass

func get_tooltip() -> String:
	return description
