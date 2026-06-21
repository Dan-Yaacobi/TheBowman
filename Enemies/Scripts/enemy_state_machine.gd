class_name EnemyStateMachine extends Node

signal pausing(_stop: bool)

var states: Array[EnemyState]
var prev_state: EnemyState
var curr_state: EnemyState

var paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	pass
	
func cause_pause(_stop: bool) -> void:
	paused = _stop
	pausing.emit(_stop)
	
func _process(delta: float) -> void:
	ChangeState(curr_state.Process(delta))

func _physics_process(delta: float) -> void:
	if paused:
		return
	ChangeState(curr_state.Physics(delta))
	
func Initialize(_enemy: Enemy)->void:
	states = []
	for c in get_children():
		if c is EnemyState:
			states.append(c)
	for s in states:
		s.enemy = _enemy
		s.state_machine = self
		s.init()
		
	if states.size() > 0:
		ChangeState(states[0])
		process_mode = Node.PROCESS_MODE_INHERIT 
		# because this is an attribute of the Player(Player is the main scene) 
		# then INHERIT means it is enabled as long as Player is
	pass
func ChangeState(new_state: EnemyState) -> void:
	if new_state == null or new_state == curr_state:
		return
		
	if curr_state:
		curr_state.Exit()
		
	prev_state = curr_state
	curr_state = new_state
	curr_state.Enter()
