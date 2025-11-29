class_name BuyBowMenu extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var name_label: Label = $Name
@onready var buy_button: Button = $BuyButton

func _ready() -> void:
	disappear()
	
func appear() -> void:
	animation_player.play("Appear")
	EventBus.change_camera_focus.emit(global_position)

func disappear() -> void:
	animation_player.play("Disappear")
	EventBus.reset_camera_focus.emit()

func set_up(data: WeaponData) -> void:
	name_label.text = data.bow_name
	name_label.add_theme_color_override("font_color",data.text_color)
	pass
