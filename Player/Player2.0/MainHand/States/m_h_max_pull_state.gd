class_name MaxPullMainHandState extends MainHandState

@onready var idle: IdleMainHandState = $"../Idle"

@onready var perfect_aim_particles: CPUParticles2D = $"../../PerfectAimParticles"
@onready var perfect_shot_window: Timer = $PerfectShotWindow

var hold_time: float = 0
var tired: bool = false
signal max_pull

func init() -> void:
	perfect_shot_window.timeout.connect(getting_tired)

func Enter() -> void:
	tired = false
	perfect_shot_window.wait_time = PlayerManager.player.stats.perfect_shot_window.value()
	#perfect_aim_particles.rotation = entity.rotation
	#perfect_aim_particles.emitting = true
	hold_time = 0
	max_pull.emit()
	entity.animation_player.play("Max_Pull")
	perfect_shot_window.start()
	pass
	
func Exit() -> void:
	entity.release_arrow()
	hold_time = 0
	PlayerManager.player.shooting = false

func Process(_delta: float) -> MainHandState:
	entity.arrow_setup()

	if tired:
		hold_time += _delta * 3
		entity.shot_power = max(entity.shot_power - _delta/2, entity.min_shot_power)

	return null
	
func release() -> void:
	state_machine.ChangeState(idle)

func Physics(_delta: float) -> MainHandState:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> MainHandState:
	if _event.is_action_released("shoot",true):
		return idle
	return null

func getting_tired() -> void:
	tired = true
