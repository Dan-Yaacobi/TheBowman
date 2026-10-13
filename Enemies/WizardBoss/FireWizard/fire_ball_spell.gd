class_name FireballAoeSpell extends WizardSpellState

@export var fireball_scene: PackedScene
@export var center_marker_id: StringName = &"fireball_center"
## How many full circles he casts before moving on
@export var waves: int = 2
## Fireballs per circle; the angle step is 360 / this
@export var fireballs_per_wave: int = 8
## Time between each fireball within a circle
@export var shot_interval: float = 0.12
## Pause after each circle (the last one doubles as recovery before idle)
@export var wave_interval: float = 0.8
## Angle of the first fireball (0 = right, -90 = up)
@export var start_angle_deg: float = -90.0
@export var clockwise: bool = true
## Shift every other circle by half a step, so the gaps aren't in the same place each time
@export var offset_alternate_waves: bool = true
## Distance from the wizard where fireballs spawn
@export var spawn_radius: float = 12.0

var _wave: int = 0
var _shot: int = 0
var _next_shot: float = 0.0

func on_cast_start() -> void:
	_wave = 0
	_shot = 0
	_next_shot = 0.0

func cast_process(_delta: float) -> void:
	if _wave >= waves or _elapsed < _next_shot:
		return
	if _shot == 0 and _wave > 0:
		_restart_cast_animation()
	_fire(_wave, _shot)
	_shot += 1
	if _shot >= fireballs_per_wave:
		_shot = 0
		_wave += 1
		_next_shot += wave_interval
	else:
		_next_shot += shot_interval

func is_finished() -> bool:
	return _wave >= waves and _elapsed >= _next_shot

func pick_point(points: Array[Marker2D], current: Marker2D) -> Marker2D:
	var marker: NamedMarker = wizard.get_marker(center_marker_id)
	if marker:
		return marker
	return super.pick_point(points, current)

func _fire(wave: int, shot: int) -> void:
	if fireball_scene == null or fireballs_per_wave <= 0:
		return
	var step: float = TAU / float(fireballs_per_wave)
	var angle: float = deg_to_rad(start_angle_deg) + step * float(shot) * (1.0 if clockwise else -1.0)
	if offset_alternate_waves and wave % 2 == 1:
		angle += step * 0.5
	var dir: Vector2 = Vector2.RIGHT.rotated(angle)
	var fireball: FireBall = fireball_scene.instantiate()
	EventBus.summon_effect.emit(fireball)
	fireball.launch(wizard.global_position + dir * spawn_radius, dir)

func _restart_cast_animation() -> void:
	if wizard.animation_player:
		wizard.animation_player.stop()
	wizard.update_animation(cast_animation)
