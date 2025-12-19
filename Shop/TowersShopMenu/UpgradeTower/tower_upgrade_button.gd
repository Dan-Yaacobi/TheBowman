class_name TowerUpgradeButton extends TextureButton
@onready var cost_label: Label = $CostLabel

@export var stat: String

func set_cost_label(cost: int) -> void:
	cost_label.text = "cost: " + str(cost)

func set_stat_tooltip(_stat: String, amount: float) -> void:
	tooltip_text = _stat + ": " + str(amount)

func set_ability_tooltip(_stat: String, ability: String) -> void:
	tooltip_text = _stat + ": " + ability
