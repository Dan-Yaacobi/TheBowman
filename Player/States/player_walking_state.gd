class_name PlayerWalkingState extends State

@onready var idle: PlayerIdleState = $"../Idle"
@onready var slam: PlayerSlamState = $"../Slam"
@onready var dead: PlayerDeadState = $"../Dead"
@onready var dash: PlayerDashState = $"../Dash"

func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	player.body.update_animation("Walk")
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	player.body.update_animation("")

#what happens during process update in this state
func Process(_delta: float) -> State:
	if player.stats.hp <= 0:
		return dead
	if player.direction == 0:
		return idle
	
	player.velocity.x = player.direction * (player.stats.move_speed + player.get_agility())
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> State:
	player.update_direction(player.direction < 0)
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("DropDown") and player.velocity.y != 0:
		return slam
	if _event.is_action_pressed("dash") and player.can_dash:
		return dash
	return null
	
