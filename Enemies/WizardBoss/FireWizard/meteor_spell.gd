class_name MeteorSpell extends WizardSpellState

@export var meteor_scene: PackedScene
@export var meteor_count: int = 3
## Time between casts; keep it at least as long as the Cast animation
@export var interval: float = 0.8
## Seconds into the Cast animation when the meteor is released
@export var release_delay: float = 0.35
@export var height_marker_id: StringName = &"meteor_height"

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
	if _casts_started < meteor_count and _elapsed >= _next_cast:
		_restart_cast_animation()
		_release_at = _elapsed + release_delay
		_casts_started += 1
		_next_cast += interval
	if _fired < _casts_started and _elapsed >= _release_at:
		_fire_meteor()
		_fired += 1

func is_finished() -> bool:
	return _fired >= meteor_count and _elapsed >= _next_cast

func _restart_cast_animation() -> void:
	if wizard.animation_player:
		wizard.animation_player.stop()
	wizard.update_animation(cast_animation)

func _fire_meteor() -> void:
	if meteor_scene == null:
		return
	var player_pos: Vector2 = PlayerManager.player.global_position
	var marker: NamedMarker = wizard.get_marker(height_marker_id)
	var start_y: float = marker.global_position.y if marker else wizard.global_position.y
	var meteor: Meteor = meteor_scene.instantiate()
	EventBus.summon_effect.emit(meteor)
	meteor.launch(Vector2(player_pos.x, start_y))
