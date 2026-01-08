class_name PowerOrb extends Node2D

@export var amplitude := 6.0      # how high it floats
@export var speed := 2.0          # how fast it floats

var base_y := 0.0
var t := 0.0

func _ready():
	base_y = position.y

func _process(delta):
	t += delta * speed
	position.y = base_y + sin(t) * amplitude
	
func _on_player_detector_body_entered(body: Node2D) -> void:
	if body is Player:
		EventBus.open_upgrades_window.emit(1)
		queue_free()
