class_name IdleMainHandState extends MainHandState
@onready var pulling: PullingMainHandState = $"../Pulling"
@onready var swing: SwingMainHandState = $"../Swing"

func init() -> void:
	EventBus.start_shooting.connect(change_to_pulling)
	pass
	
func _ready() -> void:
	pass

func Enter() -> void:
	Input.set_custom_mouse_cursor(null)
	entity.animation_player.play("Idle")
	entity.rotation = 0
	pass
	
func Exit() -> void:
	pass
	
func Process(_delta: float) -> MainHandState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> MainHandState:
	#GlobalPlayer.shot_zoom(_delta*3, false,6,5)
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> MainHandState:
	if _event.is_action_pressed("swing") and entity.can_swing:
		state_machine.ChangeState(swing)
	return null
	
func change_to_pulling() -> void:
	if not entity.is_swinging():
		state_machine.ChangeState(pulling)
	
