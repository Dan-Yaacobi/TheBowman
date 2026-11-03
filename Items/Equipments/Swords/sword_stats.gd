class_name SwordStats extends Resource

@export var knockback_power: int
@export var damage: int
@export_custom(PROPERTY_HINT_NONE, "suffix:%") var bleed_chance: int = 0

@export_group("Visuals")
## Sword sprite drawn in the player's hand. Draw it upright, tip up.
@export var texture: Texture2D
## Pixel position of the handle centre inside the texture. The sword rotates around this point.
@export var grip_position: Vector2 = Vector2(7.5, 53.0)
