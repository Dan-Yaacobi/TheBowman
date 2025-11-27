class_name MaxPullMainHandState extends MainHandState

@onready var idle: IdleMainHandState = $"../Idle"
@export var perfect_shot_time: float = 0.5
@onready var perfect_aim_particles: CPUParticles2D = $"../../PerfectAimParticles"
@onready var perfect_shot_window: Timer = $PerfectShotWindow

var hold_time: float = 0
var tired: bool = false
signal max_pull

# store a refernece to the player this belongs to
func init() -> void:
	perfect_shot_window.timeout.connect(getting_tired)
	pass
	
func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	EventBus.out_of_mana.connect(release)
	tired = false
	perfect_shot_window.wait_time = perfect_shot_time + PlayerManager.player.get_stamina()*0.1
	perfect_aim_particles.rotation = entity.rotation
	perfect_aim_particles.emitting = true
	hold_time = 0
	max_pull.emit()
	entity.animation_player.play("Max_Pull")
	perfect_shot_window.start()
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	if entity.shot_power <= 0:
		entity.shot_power = entity.min_shot_power
	#entity.set_offset(hold_time)
	entity.release_arrow()
	hold_time = 0
	PlayerManager.player.shooting = false
	EventBus.out_of_mana.disconnect(release)
#what happens during process update in this state
func Process(_delta: float) -> MainHandState:
	entity.arrow_setup()
	if tired:
		hold_time += _delta * 3
		entity.shot_power -= _delta/2
	return null
	
func release() -> void:
	state_machine.ChangeState(idle)

func Physics(_delta: float) -> MainHandState:
	PlayerManager.player.use_mana(_delta)
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> MainHandState:
	if _event.is_action_released("shoot",true):
		return idle
	return null

func getting_tired() -> void:
	tired = true
