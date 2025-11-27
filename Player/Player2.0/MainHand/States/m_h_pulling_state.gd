class_name PullingMainHandState extends MainHandState

@onready var max_pull: MaxPullMainHandState = $"../MaxPull"
@onready var idle: IdleMainHandState = $"../Idle"

@export var speed_decrease: float
var init_animation_speed: float = 1
var finished_pulling: bool = false
var full_pull_duration: float
var pull_start_time: float
# store a refernece to the player this belongs to
func init() -> void:
	entity.animation_player.animation_finished.connect(finished)
	full_pull_duration = entity.animation_player.get_animation("Pull").length
	pass
	
func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	entity.draw_arrow()
	PlayerManager.player.shooting = true
	entity.shot_power = 0
	#Input.set_custom_mouse_cursor(load("res://PlayGround/Sprites/AimCursor32.png"))
	entity.animation_player.speed_scale = PlayerManager.player.get_pull_speed()
	finished_pulling = false
	entity.animation_player.play("Pull")
	pull_start_time = Time.get_unix_time_from_system()
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	entity.animation_player.speed_scale = init_animation_speed
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> MainHandState:
	entity.arrow_setup()
	entity.shot_power = Time.get_unix_time_from_system() - pull_start_time
	#print(PlayerManager.player.stats.min_move_shoot_spd.final_stat())
	#if PlayerManager.player.stats.move_speed > PlayerManager.player.stats.min_move_shoot_spd:
		#PlayerManager.player.stats.move_speed -= _delta* speed_decrease
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> MainHandState:
	#GlobalPlayer.shot_zoom(_delta*GlobalPlayer.get_pull_speed(), true,6,5)
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> MainHandState:
	if _event.is_action_released("shoot",true):
		PlayerManager.player.set_shooting(true)
		#entity.set_offset(0)
		entity.release_arrow()
		PlayerManager.player.shooting = false
		return idle
	return null
	
func finished(_animation_name) -> void:
	if _animation_name == 'Pull':
		finished_pulling = true 
		entity.shot_power = 1.0
		state_machine.ChangeState(max_pull)
		
