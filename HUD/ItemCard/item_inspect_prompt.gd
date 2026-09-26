class_name ItemInspectPrompt extends Control

@export var offset: Vector2 = Vector2(0, -50)
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var keyboard_press_helper: KeyBoardHelper = $VBoxContainer/KeyboardPressHelper
@onready var action_label: Label = $VBoxContainer/ActionLabel

var target: Equipment

func _ready() -> void:
	hide()
	keyboard_press_helper.set_up("E")

func show_for(equipment: Equipment) -> void:
	target = equipment
	name_label.text = equipment.data.display_name
	name_label.add_theme_color_override("font_color", CustomVariables.rarity_color(equipment.data.rarity))
	var slot_empty: bool = PlayerManager.player.get_equipped_in_slot(equipment.data.slot) == null
	action_label.text = "Equip" if slot_empty else "Inspect"
	show()
	_update_position()
	
func clear() -> void:
	target = null
	hide()

# Follows the item every frame, so camera movement and the bob don't leave it behind.
func _process(_delta: float) -> void:
	if target:
		_update_position()

func _update_position() -> void:
	var screen_pos: Vector2 = target.get_viewport().get_canvas_transform() * target.global_position
	global_position = screen_pos + offset - Vector2(size.x * 0.5, size.y)
