class_name MainHandStateMachine extends Node2D

var states: Array [ MainHandState ]
var prev_state: MainHandState
var curr_state: MainHandState

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	ChangeState(curr_state.Process(delta))


func _physics_process(delta: float) -> void:
	ChangeState(curr_state.Physics(delta))
	
	
func _unhandled_input(event: InputEvent) -> void:
	ChangeState(curr_state.HandleInput(event))


func Initialize(_entity: PlayerMainHand)->void:
	states = []
	for c in get_children():
		if c is MainHandState:
			states.append(c)
			
	if states.size() == 0:
		return
		
	states[0].entity = _entity
	states[0].state_machine = self
	
	for state in states:
		state.init()
		
	ChangeState(states[0])
	process_mode = Node.PROCESS_MODE_INHERIT 
	# because this is an attribute of the Player(Player is the main scene) 
	# then INHERIT means it is enabled as long as Player is
	

func ChangeState(new_state: MainHandState) -> void:
	
	if new_state == null or new_state == curr_state:
		return
	if curr_state:
		curr_state.Exit()
	prev_state = curr_state
	curr_state = new_state
	curr_state.Enter()
