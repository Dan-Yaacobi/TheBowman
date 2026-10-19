class_name PlayerWalkingState extends State

@onready var idle: PlayerIdleState = $"../Idle"
@onready var slam: PlayerSlamState = $"../Slam"
@onready var dead: PlayerDeadState = $"../Dead"
@onready var dash: PlayerDashState = $"../Dash"
@onready var sword_attack: SwordAttackState = $"../SwordAttack"

func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass

#what happens during process update in this state
func Process(_delta: float) -> State:
	if player.direction == 0:
		return idle
	var target_x = player.direction * player.get_move_speed()
	var acceleration = player.stats.ground_acc if player.is_on_floor() else player.stats.air_acc
	player.velocity.x = move_toward(player.velocity.x, target_x, acceleration * _delta)
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> State:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("dash") and player.can_dash <= 0:
		return dash
		
	if _event.is_action_pressed("swing") and player.can_start_swing():
		return sword_attack
	return null
	
