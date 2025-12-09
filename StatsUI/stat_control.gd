@tool
class_name StatControl extends Control

signal trying_to_upgrade(stat: CustomVariables.stats, stat_control: StatControl)

@onready var stat_value: Label = $StatValue
@onready var stat: Label = $Stat

@export var stat_upgrade: CustomVariables.stats
@export var text: String = "":
	set(value):
		text = value
		_update_label()
@export var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		_update_label()

func _ready() -> void:
	if not Engine.is_editor_hint():
		_update_label()
		
func _update_label() -> void:
	if !stat:
		return
	stat.text = text
	stat.set("theme_override_colors/font_color", text_color)
	stat_value.set("theme_override_colors/font_color", text_color)
	

func _on_button_pressed() -> void:
	trying_to_upgrade.emit(stat_upgrade,self)
	return

func update_stat_value() -> void:
	if stat_upgrade == CustomVariables.stats.Strength:
		stat_value.text = str(PlayerManager.player.get_strength())
	elif stat_upgrade == CustomVariables.stats.Agility:
		stat_value.text = str(PlayerManager.player.get_agility())
	elif stat_upgrade == CustomVariables.stats.Stamina:
		stat_value.text = str(PlayerManager.player.get_stamina())
