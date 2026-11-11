class_name PlayerDashState extends State

@export var base_dash_cooldown: float = 2.0
@export var max_agility_reduce_dash_cd: int = 50
## Two "up" presses within this many seconds dash upward.
@export var up_double_tap_window: float = 0.25
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
## Set by idle/walking on an up double tap; makes this dash go straight up.
var force_up: bool = false
## Time of the last "up" press, for double-tap detection.
var _last_up_press_msec: int = -100000

func init() -> void:
	player.dash_finished.connect(go_to_walking)
	dash_cooldown.timeout.connect(can_dash_again)
	
func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	for ability in  PlayerManager.player.get_abilities(PlayerAbility.TriggerType.DASH):
		ability.activate_ability()
	EventBus.dash_preformed.emit()
	player.disable_jump()
	started_on_floor = player.is_on_floor()
	player.dashes_spent += 1
	dash_direction = get_dash_direction() # Change this to calculate_direction_to_cursor() for 360 cursor dash
	force_up = false
	dust.emitting = true

	player.velocity = dash_direction * player.stats.dash_power.value()
	var tween = player.create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "velocity", dash_direction * player.stats.dash_power.value()*0.1,0.2)
	tween.finished.connect(go_to_walking)
	dash_cooldown.wait_time = PlayerManager.player.stats.dash_cooldown.value()
	dash_cooldown.start()
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	player.enable_jump()
	EventBus.dash_ended.emit()
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

## Every dash restarts the cooldown; when it runs out, all dashes come back at once.
func can_dash_again() -> void:
	player.dashes_spent = 0
	dash_cooldown.stop()
	
func get_dash_direction() -> Vector2:
	var direction: Vector2
	if force_up or Input.is_action_pressed("up"):
		direction = Vector2(0,-1)
	elif state_machine.prev_state is PlayerIdleState:
		direction = Vector2(player.body.facing_direction, 0)
	elif state_machine.prev_state is PlayerWalkingState:
		direction = Vector2(player.direction, 0)
	return direction
		
## True on the second "up" press inside up_double_tap_window. A double tap uses up both presses.
func is_up_double_tap(event: InputEvent) -> bool:
	if not event.is_action_pressed("up"):
		return false
	var now: int = Time.get_ticks_msec()
	if now - _last_up_press_msec <= roundi(up_double_tap_window * 1000.0):
		_last_up_press_msec = -100000
		return true
	_last_up_press_msec = now
	return false

func calculate_direction_to_cursor() -> Vector2:
	var mouse_pos = player.get_global_mouse_position()
	var direction = mouse_pos - PlayerManager.player.global_position
	return direction.normalized()
