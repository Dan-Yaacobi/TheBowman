class_name PlayerWalkingState extends State

@onready var idle: PlayerIdleState = $"../Idle"

func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	player.update_animation("Walk")
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> State:
	if player.direction == 0:
		return idle
	player.update_direction(player.direction < 0)
	if player.stats.in_menu:
		player.velocity.x = player.direction * player.stats.menu_speed
	else:
		player.velocity.x = player.direction * player.stats.move_speed
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> State:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> State:
	return null
	
