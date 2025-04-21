class_name UpgradeTowerButton extends Control

@onready var cost_label: Label = $CostLabel
@onready var upgrade_button: TextureButton = $UpgradeButton

func set_cost_label(cost: int) -> void:
	cost_label.text = "cost: " + str(cost)

func set_tooltip(stat: String, amount: float, ) -> void:
	upgrade_button.tooltip_text = stat + ": " + str(amount)
