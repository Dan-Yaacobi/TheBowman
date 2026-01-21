class_name PlayerDashState extends State

@export var base_dash_cooldown: float = 2.0
@export var max_agility_reduce_dash_cd: int = 50
@onready var walking: PlayerWalkingState = $"../Walking"
@onready var slam: PlayerSlamState = $"../Slam"
@onready var dead: PlayerDeadState = $"../Dead"
@onready var dust: CPUParticles2D = $Dust
@onready var dash_cooldown: Timer = $DashCooldown

var dash_direction: int
var done_dash: bool
var dash_distance: int
var init_position: float

func init() -> void:
	player.dash_finished.connect(go_to_walking)
	dash_cooldown.timeout.connect(can_dash_again)
	
func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	dash_cooldown.wait_time = max(1.0, base_dash_cooldown - float(player.get_agility())/max_agility_reduce_dash_cd)
	player.can_dash = false
	dash_distance = player.stats.dash_distance
	init_position = player.global_position.x
	done_dash = false
	player.body.update_animation("Jump")
	dash_direction = 1
	if player.direction_side:
		dash_direction = - 1
	
	dust.emitting = true
	dust.gravity.x = -1* dash_direction * 50
	player.dash(dash_direction)
	dash_cooldown.start()

	pass
	
#what happens when the player exits this state
func Exit() -> void:
	player.velocity = Vector2.ZERO
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> State:
	if player.stats.hp <= 0:
		return dead
	#player.velocity.x = dash_direction * player.stats.move_speed * 4
	#player.update_direction(dash_direction != 1)
	#if dash_direction == 1:
		#if player.global_position.x > init_position + dash_distance:
			#return walking
	#else:
		#if player.global_position.x < init_position - dash_distance:
			#return walking

	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> State:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("DropDown"):
		return slam
	return null
func go_to_walking() -> void:
	state_machine.ChangeState(walking)

func can_dash_again() -> void:
	player.can_dash = true
