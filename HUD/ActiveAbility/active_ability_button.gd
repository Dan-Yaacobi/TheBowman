class_name ActiveAbilityButton extends PanelContainer

signal ability_chosen(ability: ActiveAbility)

@onready var icon: TextureRect = $MarginContainer/VBoxContainer/Icon
@onready var title_label: Label = $MarginContainer/VBoxContainer/Title
@onready var description_label: Label = $MarginContainer/VBoxContainer/Description
@onready var choose_button: Button = $MarginContainer/VBoxContainer/ChooseButton

var ability: ActiveAbility

func setup(_ability: ActiveAbility) -> void:
	ability = _ability
	icon.texture = _ability.icon
	title_label.text = _ability.name
	description_label.text = _ability.get_tooltip()

func _on_choose_button_pressed() -> void:
	ability_chosen.emit(ability)
