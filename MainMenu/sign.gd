extends RigidBody2D
@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.area_entered.connect(hit)
	
func hit(a) -> void:
	if a is Arrow:
		self.apply_force(a.direction)
		a.clear_shot()
