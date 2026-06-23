class_name PlayerDashState extends State

@export var base_dash_cooldown: float = 2.0
@export var max_agility_reduce_dash_cd: int = 50
@onready var walking: PlayerWalkingState = $"../Walking"
@onready var slam: PlayerSlamState = $"../Slam"
@onready var dead: PlayerDeadState = $"../Dead"
@onready var dust: CPUParticles2D = $Dust
@onready var dash_cooldown: Timer = $DashCooldown

#var dash_direction: int
var dash_direction: Vector2
var done_dash: bool
var init_position: Vector2

var started_on_floor: bool

func init() -> void:
	player.dash_finished.connect(go_to_walking)
	dash_cooldown.timeout.connect(can_dash_again)
	
func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	for ability in  PlayerManager.player.get_abilities(PlayerAbility.TriggerType.DASH):
		ability.activate_ability()
	player.disable_jump()
	started_on_floor = player.is_on_floor()
	player.can_dash = false
	#player.body.update_animation("Jump")
	dash_direction = calculate_direction_to_cursor()
	dust.emitting = true

	player.velocity = dash_direction * player.stats.dash_power.value()
	var tween = player.create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "velocity", dash_direction * player.stats.dash_power.value()*0.1,0.2)
	tween.finished.connect(go_to_walking)
	dash_cooldown.start()
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	player.enable_jump()
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> State:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> State:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> State:
	return null
	
func go_to_walking() -> void:
	state_machine.ChangeState(walking)

func can_dash_again() -> void:
	player.can_dash = true

func calculate_direction_to_cursor() -> Vector2:
	var mouse_pos = player.get_global_mouse_position()
	var direction = mouse_pos - PlayerManager.player.global_position
	return direction.normalized()
