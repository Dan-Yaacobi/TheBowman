class_name BoulderSpell extends WizardSpellState
## Lobs boulders in an arc at where the player is standing.

@export var boulder_scene: PackedScene
@export var boulder_count: int = 2
## Time between throws; keep it at least as long as the cast animation
@export var interval: float = 1.3
## Seconds into the cast animation when the boulder leaves his hand
@export var release_delay: float = 0.35
## Seconds from release to landing
@export var flight_time: float = 1.1
## Where the boulder appears, relative to the wizard when he faces right
@export var hand_offset: Vector2 = Vector2(14, -10)
## Half an island's width, used to find the island under the landing spot
@export var island_half_width: float = 21.5

var _casts_started: int = 0
var _fired: int = 0
var _next_cast: float = 0.0
var _release_at: float = 0.0

func on_cast_start() -> void:
	_casts_started = 0
	_fired = 0
	_next_cast = 0.0
	_release_at = 0.0

func cast_process(_delta: float) -> void:
	if _casts_started < boulder_count and _elapsed >= _next_cast:
		_restart_cast_animation()
		_release_at = _elapsed + release_delay
		_casts_started += 1
		_next_cast += interval
	if _fired < _casts_started and _elapsed >= _release_at:
		_throw()
		_fired += 1

func is_finished() -> bool:
	return _fired >= boulder_count and _elapsed >= _next_cast

func _restart_cast_animation() -> void:
	if wizard.animation_player:
		wizard.animation_player.stop()
	wizard.update_animation(cast_animation)

func _throw() -> void:
	if boulder_scene == null:
		return
	var offset: Vector2 = hand_offset
	if wizard.sprite.flip_h:
		offset.x = -offset.x
	var start: Vector2 = wizard.global_position + offset
	var player_pos: Vector2 = PlayerManager.player.global_position
	var island: Island = _island_below(player_pos)
	var landing: Vector2 = player_pos
	if island:
		landing.y = island.global_position.y - 3.0
	var boulder: Boulder = boulder_scene.instantiate()
	enemy.tag_attack(boulder)
	EventBus.summon_effect.emit(boulder)
	boulder.launch(start, landing, flight_time, wizard, island)

# The first island at or below pos (null if the player is over the void)
func _island_below(pos: Vector2) -> Island:
	var best: Island = null
	for island: Island in wizard.get_islands():
		# Skip crumbled islands; the boulder falls through them
		if not CrumbleSpell._is_solid(island):
			continue
		if absf(island.global_position.x - pos.x) > island_half_width:
			continue
		if island.global_position.y < pos.y - 4.0:
			continue
		if best == null or island.global_position.y < best.global_position.y:
			best = island
	return best
