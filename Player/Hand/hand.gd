class_name Hand extends CharacterBody2D

@onready var timer: Timer = $Timer
@onready var sprite: Sprite2D = $Sprite2D
@onready var player: Player = $".."
@onready var player_state_machine: PlayerStateMachine = $"../PlayerStateMachine"
@onready var mouse_detector: Area2D = $"../MouseDetector"

var hand_direction: Vector2

func _process(delta: float) -> void:

	calculate_direction_to_cursor()
	set_hand_direction()
	pass
	
func calculate_direction_to_cursor() -> void:
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	hand_direction = Vector2(mouse_pos[0] - player_pos[0],
	 mouse_pos[1] - player_pos[1])
	if player_state_machine.curr_state != PlayerDashState:
		if mouse_pos.x > player_pos.x + 4:
			player.update_direction(false)
		elif mouse_pos.x < player_pos.x - 4:
			player.update_direction(true)

func set_hand_direction() -> void:
	rotation = hand_direction.angle() - PI/2
