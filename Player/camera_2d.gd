extends Camera2D

@onready var player: Player = $".."
@export var random_strength: float = 30.0
@export var shake_fade: float = 5.0

var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0

func _ready() -> void:
	player.took_hit.connect(apply_shake)
	pass
	
func _physics_process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0 , shake_fade * delta)
		
		offset = random_offset()
	pass

func apply_shake() -> void:
	shake_strength = random_strength
	
func random_offset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength,shake_strength),rng.randf_range(-shake_strength,shake_strength))
