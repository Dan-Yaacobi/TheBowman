class_name PlayerIdleState extends State

@onready var walking: PlayerWalkingState = $"../Walking"
@onready var slam: PlayerSlamState = $"../Slam"
@onready var dead: PlayerDeadState = $"../Dead"

func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	player.update_animation("Idle")
	player.body.change_side(player.direction_side)
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> State:
	if player.stats.hp <= 0:
		return dead
	if player.direction != 0.0:
		return walking
	player.velocity.x = 0
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> State:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("DropDown"):
		return slam
	return null
