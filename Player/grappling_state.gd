class_name PlayerGrapplingState extends State

@onready var idle: PlayerIdleState = $"../Idle"
@onready var slam: PlayerSlamState = $"../Slam"
@onready var dead: PlayerDeadState = $"../Dead"
@onready var dash: PlayerDashState = $"../Dash"
@onready var hook: Hook = $"../../GrappleHook/Hook"

var hook_pos: Vector2

func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	player.can_hook = false
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	player.can_hook = true
	hook.disable()
	pass

#what happens during process update in this state
func Process(_delta: float) -> State:
	player.velocity = player.stats.move_speed * 3 * (hook_pos - player.global_position).normalized()
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> State:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("Jump") or _event.is_action_pressed("grapple"):
		hook.disable()
		return idle
	
	return null
	
