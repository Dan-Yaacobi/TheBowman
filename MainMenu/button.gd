@tool
class_name MainButton extends Button

signal clicked

@onready var area_2d: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@export var button_data: ButtonData

var player: Player

func _ready() -> void:
	update_collision_size()
	pressed.connect(button_action_activate)
	area_2d.area_entered.connect(shoot_click)

func _set(property, value):
	if property == "text":
		property = value
		update_collision_size()
	if property == "size":
		property = value
		update_collision_size()

func button_action_activate() -> void:
	if button_data.button_action != null:
		button_data.button_action.button_pressed_action(self,get_parent().get_parent())
		#clicked.emit()

func shoot_click(_area) -> void:
	return
	
	#if _area is Arrow:
		#_area.clear_shot()

func update_collision_size() -> void:
	if collision_shape == null:
		collision_shape = get_node("Area2D/CollisionShape2D")
	add_theme_font_size_override("font_size",250)
	collision_shape.shape.size = size
	collision_shape.position = size/2

func disable_area() -> void:
	area_2d.set_deferred("monitoring", false)
	
func disable_button() -> void:
	disabled = true
	disable_area()
	
func enable_button() -> void:
	disabled = false
	enable_area()
	
func enable_area() -> void:
	area_2d.set_deferred("monitoring", true)
