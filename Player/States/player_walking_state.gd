class_name PlayerWalkingState extends State

@onready var idle: PlayerIdleState = $"../Idle"
@onready var slam: PlayerSlamState = $"../Slam"
@onready var dead: PlayerDeadState = $"../Dead"
@onready var dash: PlayerDashState = $"../Dash"
@onready var sword_attack: SwordAttackState = $"../SwordAttack"

## Ground distance between footstep sounds (~2 steps per Walk loop at base speed).
@export var footstep_distance: float = 30.0

var _step_progress: float = 0.0

func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	# First step lands right away.
	_step_progress = footstep_distance
	
#what happens when the player exits this state
func Exit() -> void:
	pass

#what happens during process update in this state
func Process(_delta: float) -> State:
	if player.direction == 0:
		return idle
	var target_x = player.direction * player.get_move_speed()
	var acceleration: float = player.get_move_acceleration()
	player.velocity.x = move_toward(player.velocity.x, target_x, acceleration * _delta)
	_update_footsteps(_delta)
	return null

func _update_footsteps(delta: float) -> void:
	if not player.is_on_floor():
		# Next step plays on landing.
		_step_progress = footstep_distance
		return
	_step_progress += absf(player.velocity.x) * delta
	if _step_progress >= footstep_distance:
		_step_progress = 0.0
		EventBus.footstep_sound.emit()
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> State:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("dash") and player.can_start_dash():
		return dash
		
	if _event.is_action_pressed("swing") and player.can_start_swing():
		return sword_attack
	return null
	
