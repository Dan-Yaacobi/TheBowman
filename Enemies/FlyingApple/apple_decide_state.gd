class_name AppleDecideState extends EnemyState

@onready var seek: AppleSeekState = $"../Seek"
@onready var shoot: AppleShootState = $"../Shoot"
@onready var decision_timer: Timer = $"../DecisionTimer"

@export var max_shooting_distance: float = 150
#what happens when we initialize this state
func init() -> void:
	decision_timer.timeout.connect(decide)
	#decision_timer.start()
	pass

#what happens when the player enters this state
func Enter() -> void:
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	return null
	
func decide() -> void:
	if not PlayerManager.player.is_on_floor() and enemy.calculate_distance_to_player() <= max_shooting_distance:
		state_machine.ChangeState(shoot)
	else:
		state_machine.ChangeState(seek)
