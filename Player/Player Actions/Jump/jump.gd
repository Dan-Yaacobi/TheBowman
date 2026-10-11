class_name JumpAction extends Node2D

@onready var player: Player = $".."
@onready var jump_particles: CPUParticles2D = $JumpParticles

const DROP_CLEAR_DISTANCE: float = 32.0
const BUFFER_WINDOW: float = 0.1
const MAX_HOLD: float = 0.3
const COYOTE_TIME: float = 0.1

var dropping: bool = false
var drop_start_y: float = 0.0
var jumps: int = 1
var hold_time: float = 0.0
var is_holding: bool = false
var buffer_timer: float = 0.0
var can_jump: bool = true
var was_on_floor: bool = false
var coyote_timer: float = 0.0


func _ready() -> void:
	jumps = player.stats.max_jumps

func _physics_process(delta: float) -> void:
	# Landing check first, so a buffered jump on the landing frame uses the refilled jumps
	_check_landing()
	_update_coyote(delta)
	if is_holding:
		hold_time += delta
	if buffer_timer > 0:
		buffer_timer -= delta
		try_jump()
	if dropping and player.position.y > drop_start_y + DROP_CLEAR_DISTANCE:
		dropping = false

func _check_landing() -> void:
	var on_floor: bool = player.is_on_floor()
	if on_floor and not was_on_floor:
		coyote_timer = 0.0
		_on_landed()
	elif was_on_floor and not on_floor and player.velocity.y >= 0:
		# Left the ground without jumping (walked off or dropped through)
		coyote_timer = COYOTE_TIME
	was_on_floor = on_floor

func _update_coyote(delta: float) -> void:
	if coyote_timer <= 0:
		return
	coyote_timer -= delta
	if coyote_timer <= 0:
		# Ground jump window expired: lose the ground jump, keep air jumps
		jumps = mini(jumps, player.stats.max_jumps - 1)

func _on_landed() -> void:
	var ground: Object = _get_floor_collider()
	if not _is_valid_ground(ground):
		return
	set_jumps()
	if ground is Island:
		ground._on_player_interact()

func _get_floor_collider() -> Object:
	for i: int in range(player.get_slide_collision_count()):
		var col: KinematicCollision2D = player.get_slide_collision(i)
		if col.get_angle(player.up_direction) <= player.floor_max_angle:
			return col.get_collider()
	return null

func _is_valid_ground(body: Object) -> bool:
	return body is Island or body is TileMapLayer

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
	coyote_timer = 0.0
	player.velocity.y = -player.stats.jump_height.value()
	hold_time = 0.0
	is_holding = true

func release_jump() -> void:
	is_holding = false
	if player.velocity.y < 0:
		var hold_ratio: float = clampf(hold_time / MAX_HOLD, 0.0, 1.0)
		player.velocity.y *= lerpf(0.2, 1.0, hold_ratio)
