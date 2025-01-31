class_name PlayerSlamState extends State

@onready var idle: PlayerIdleState = $"../Idle"
@onready var ground_detector: Area2D = $GroundDetector
@onready var dead: PlayerDeadState = $"../Dead"

var hit_somthing: bool = false
func _ready() -> void:
	ground_detector.body_shape_entered.connect(hit_ground)
	pass

#what happens when the player enters this state
func Enter() -> void:
	ground_detector.body_entered.connect(hit_enemy)
	player.took_hit.connect(stop_slamming)
	player.set_pushback_values(Vector2.ZERO,0)
	player.jump_action.jump_flip = false
	player.body.rotation = 0
	player.update_animation("Jump")
	hit_somthing = false
	player.velocity = Vector2.ZERO
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	ground_detector.body_entered.disconnect(hit_enemy)
	player.took_hit.disconnect(stop_slamming)
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> State:

	
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> State:
	if player.velocity.y == 0:
		return idle
	if hit_somthing:
		return idle

	if player.stats.hp <= 0:
		return dead
		
	player.velocity.y += 20

	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> State:
	return null

func stop_slamming() -> void:
	hit_somthing = true
	player.velocity.y = 0
	
func hit_enemy(b) -> void:
	if b is Enemy:
		if not b.stats.boss:
			b.take_damage(100)
		hit_somthing = true
	pass
	
func hit_ground(_v1,_v2,_v3,_v4) -> void:
	hit_somthing = true
