class_name GoldenAppleEvent extends Event

## Snitch-style chase: hit the golden apple 5 times before time runs out.
## When time runs out it escapes. The exit portal is available the whole time.
## Kill rewards spawn by the exit portal, so gear never lands out over the void.

const TITLE_TEXT: String = "Golden Apple"
const CAUGHT_TEXT: String = "Caught it!"
const ESCAPED_TEXT: String = "It got away..."

@export var golden_apple: GoldenApple
@export var chase_duration: float = 25.0

@onready var falling_death: FallingDeath = $FallingDeath
@onready var hud: ChallengeHUD = $ChallengeHUD
@onready var exit_portal: EventPortal = $EventPortal

var _world: GameWorld = null
var _world_respawn_position: Vector2 = Vector2.ZERO
var _zoomed_out: bool = false
var _chasing: bool = false
var _time_left: float = 0.0

func _ready() -> void:
	hud.hide()
	set_process(false)

func on_event_entered() -> void:
	# Falling inside the event should respawn here, not back in the rift
	_world = get_parent() as GameWorld
	if _world:
		_world_respawn_position = _world.respawn_position
		_world.respawn_position = get_event_spawn()
	PlayerManager.player.camera.zoom_out()
	_zoomed_out = true
	_start_chase()

func on_event_exited() -> void:
	_chasing = false
	set_process(false)
	if is_instance_valid(_world):
		_world.respawn_position = _world_respawn_position
	if _zoomed_out:
		PlayerManager.player.camera.zoom_in()
		_zoomed_out = false

func _start_chase() -> void:
	if not is_instance_valid(golden_apple):
		return
	golden_apple.died.connect(_on_golden_apple_died, CONNECT_ONE_SHOT)
	_chasing = true
	_time_left = chase_duration
	hud.show_title(TITLE_TEXT)
	hud.on_challenge_started()
	_update_hud()
	set_process(true)

func _process(delta: float) -> void:
	_time_left = maxf(_time_left - delta, 0.0)
	_update_hud()
	if _time_left <= 0.0:
		_end_chase(false)
		if is_instance_valid(golden_apple):
			golden_apple.escape()

func _update_hud() -> void:
	var hits: int = golden_apple.hits_taken() if is_instance_valid(golden_apple) else 0
	var max_hits: int = golden_apple.stats.max_hp if is_instance_valid(golden_apple) else 0
	hud.set_progress("Hits %d/%d   %ds" % [hits, max_hits, ceili(_time_left)])

func _end_chase(caught: bool) -> void:
	if not _chasing:
		return
	_chasing = false
	set_process(false)
	hud.show_result(caught, CAUGHT_TEXT if caught else ESCAPED_TEXT)
	report_finished(caught)

func _on_golden_apple_died(_apple: Enemy) -> void:
	if not _chasing:
		return
	_end_chase(true)
	spawn_rewards(exit_portal.global_position)
