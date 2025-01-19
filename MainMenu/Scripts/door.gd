class_name Door extends Sprite2D

@onready var area_2d: Area2D = $Area2D
@onready var enter: Area2D = $Enter

func _ready() -> void:
	area_2d.body_entered.connect(open_door)
	area_2d.body_exited.connect(close_door)
	
func open_door(_val) -> void:
	if _val is Player:
		frame += 1
	
func close_door(_val) -> void:
	if _val is Player:
		frame -= 1

func disable_door() -> void:
	area_2d.monitoring = false
	enter.monitoring = false

func enable_door() -> void:
	area_2d.monitoring = true
	enter.monitoring = true
