class_name PlayerIdleState extends State

@onready var walking: PlayerWalkingState = $"../Walking"
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
	if player.direction != 0.0:
		return walking
	var deceleration = player.stats.ground_dec if player.is_on_floor() else player.stats.air_dec
	player.velocity.x = move_toward(player.velocity.x,0,deceleration*_delta)
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
