class_name UpgradeTowerButton extends Control

@onready var cost_label: Label = $CostLabel
@onready var upgrade_button: TextureButton = $UpgradeButton

@export var stat: String
@export var normal_sprite: Texture
@export var pressed_sprite: Texture
@export var hover_sprite: Texture

func _ready() -> void:
	upgrade_button.texture_normal = normal_sprite
	upgrade_button.texture_pressed = pressed_sprite
	upgrade_button.texture_hover = hover_sprite
	pass
	
func set_cost_label(cost: int) -> void:
	cost_label.text = "cost: " + str(cost)

func set_stat_tooltip(stat: String, amount: float) -> void:
	upgrade_button.tooltip_text = stat + ": " + str(amount)

func set_ability_tooltip(stat: String, ability: String) -> void:
	upgrade_button.tooltip_text = stat + ": " + ability
