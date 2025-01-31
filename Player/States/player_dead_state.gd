class_name PlayerDeadState extends State

@onready var death_animation_timer: Timer = $"../../DeathAnimationTimer"
@onready var idle: PlayerIdleState = $"../Idle"

var death_done: bool = false
func _ready() -> void:
	death_animation_timer.timeout.connect(reset)
	pass

#what happens when the player enters this state
func Enter() -> void:
	player.hand.visible = false
	death_animation_timer.wait_time = player.body.animation_player.get_animation("Dead").length
	death_animation_timer.start()
	death_done = false
	player.update_animation("Dead")
	player.collision_shape.set_deferred("disabled", true)
	
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	player.hand.visible = true
	player.reset_to_base_stats()
	player.died.emit("Menu")
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> State:
	player.velocity = Vector2.ZERO
	if death_done:
		return idle
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> State:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> State:
	return null
	
func reset() -> void:
	player.collision_shape.set_deferred("disabled", false)
	player.stats.hp = player.stats.max_hp
	player.health_bar._set_health(player.stats.max_hp)
	player.body.reset_animations()
	death_done = true
