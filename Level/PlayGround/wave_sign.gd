class_name WaveSign extends RigidBody2D

@onready var play_ground: PlayGround = $".."

@export var max_strength: float
@export var strength_fade: float

func _ready() -> void:
	play_ground.new_wave.connect(push_sign)
	
func push_sign() -> void:
	pass
	
