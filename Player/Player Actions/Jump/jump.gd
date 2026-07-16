class_name JumpAction extends Node2D

@onready var player: Player = $".."
@onready var jump_particles: CPUParticles2D = $JumpParticles

const DROP_CLEAR_DISTANCE: float = 32.0
const BUFFER_WINDOW = 0.1
const MAX_HOLD = 0.3

var dropping: bool = false
var drop_start_y: float = 0.0
var jumps: int = 1
var hold_time: float = 0.0
var is_holding: bool = false
var buffer_timer: float = 0.0
var can_jump: bool = true


func _ready() -> void:
	jumps = player.stats.max_jumps

func _physics_process(delta: float) -> void:
	if is_holding:
		hold_time += delta
	if buffer_timer > 0:
		buffer_timer -= delta
		try_jump()
	if dropping and player.position.y > drop_start_y + DROP_CLEAR_DISTANCE:
		dropping = false
		
func request_jump() -> void:
	if Input.is_action_pressed("Down"):
		drop_through_platform()
		return
	buffer_timer = BUFFER_WINDOW

func drop_through_platform() -> void:
	if not player.is_on_floor() or dropping:
		return
	dropping = true
	drop_start_y = player.position.y
	player.position.y += 2.0
	
func handle_jumps() -> void:
	jumps -= 1
	jump_particles.restart()

func reset_jumps(_var1, _var2, _var3, _var4) -> void:
	if _var2 is TileMapLayer or _var2 is PhysicsBody2D:
		set_jumps()
	if _var2 is Island:
		call_deferred("_try_dip", _var2)

func _try_dip(island: Island) -> void:
	if player.is_on_floor():
		island._on_player_interact()

func set_jumps() -> void:
	jumps = player.stats.max_jumps

func try_jump() -> void:
	if buffer_timer <= 0:
		return
	if jumps > 0 and can_jump:
		jump()
		handle_jumps()
		for ability in player.stats.jump_abilities:
			ability.activate_ability(player)
		buffer_timer = 0.0
		
func jump() -> void:
	player.velocity.y = - player.stats.jump_height.value()
	hold_time = 0.0
	is_holding = true

func release_jump() -> void:
	is_holding = false
	if player.velocity.y < 0:
		var hold_ratio = clampf(hold_time / MAX_HOLD, 0.0, 1.0)
		player.velocity.y *= lerpf(0.2, 1.0, hold_ratio)
