class_name PullingMainHandState extends MainHandState

@onready var max_pull: MaxPullMainHandState = $"../MaxPull"
@onready var idle: IdleMainHandState = $"../Idle"

var init_animation_speed: float = 1
var finished_pulling: bool = false
var full_pull_duration: float
var pull_start_time: float

var charge_rate: float
# store a refernece to the player this belongs to

func init() -> void:
	entity.animation_player.animation_finished.connect(finished)
	full_pull_duration = entity.animation_player.get_animation("Pull").length
	pass
	
func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	entity.animation_player.play("Pull")
	entity.draw_arrow()
	PlayerManager.player.shooting = true
	entity.shot_power = 0
	#Input.set_custom_mouse_cursor(load("res://PlayGround/Sprites/AimCursor32.png"))
	charge_rate = PlayerManager.player.get_pull_speed()
	entity.animation_player.speed_scale = charge_rate
	finished_pulling = false
	EventBus.string_pull_sound.emit(charge_rate)
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	entity.animation_player.speed_scale = init_animation_speed
	entity.shot_power = min(entity.shot_power, 1.0)
	EventBus.string_pull_stop.emit()
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> MainHandState:
	entity.arrow_setup()
	entity.shot_power += _delta * charge_rate
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> MainHandState:	
	#GlobalPlayer.shot_zoom(_delta*GlobalPlayer.get_pull_speed(), true,6,5)
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> MainHandState:
	if _event.is_action_released("shoot",true):
		release()
	return null

func release() -> void:
	PlayerManager.player.set_shooting(true)
	entity.release_arrow()
	PlayerManager.player.shooting = false
	state_machine.ChangeState(idle)

func finished(_animation_name) -> void:
	if _animation_name == 'Pull':
		finished_pulling = true 
		entity.shot_power = 1.0
		state_machine.ChangeState(max_pull)
		
