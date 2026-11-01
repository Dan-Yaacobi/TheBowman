class_name EarthquakeSpell extends WizardSpellState
## Shakes every island, then quakes on a steady beat.
## Each pulse knocks a grounded player toward the nearer edge of their island.
## Being in the air on the beat dodges it.

@export var dust_scene: PackedScene
@export var pulse_scene: PackedScene
## Seconds of rumble before the first pulse
@export var telegraph_time: float = 1.2
@export var pulses: int = 3
@export var pulse_interval: float = 0.9
## Seconds after the last pulse before he returns to idle
@export var recovery_time: float = 0.5
@export var knockback_force: float = 120.0
## Upward part of the knockback direction (0 = purely sideways)
@export var knockback_lift: float = 0.35
@export_group("Shake")
## Island sprite jitter in pixels at full rumble
@export var rumble_shake: float = 0.6
## Extra jitter that builds right before each pulse, so the beat can be read
@export var pre_pulse_shake: float = 1.6
## Seconds before each pulse that the extra jitter starts building
@export var pre_pulse_window: float = 0.35
## Downward kick of every island sprite on a pulse, in pixels
@export var pulse_jolt: float = 3.0
@export var rumble_camera_shake: float = 1.5
@export var pulse_camera_shake: float = 8.0
## Vertical offset of the falling dust from the island's origin (underside)
@export var dust_offset_y: float = 8.0
## Vertical offset of the pulse burst from the island's origin (surface)
@export var surface_offset_y: float = -3.0

var _pulses_done: int = 0
var _jolt: float = 0.0
var _sprite_bases: Dictionary[Island, Vector2] = {}
var _dust: Array[LingeringEffect] = []

func on_cast_start() -> void:
	_pulses_done = 0
	_jolt = 0.0
	_sprite_bases.clear()
	for island: Island in wizard.get_islands():
		_sprite_bases[island] = island.sprite.position
		_spawn_on(island, dust_scene, dust_offset_y, true)

func Exit() -> void:
	_restore_islands()
	for fx: LingeringEffect in _dust:
		if is_instance_valid(fx):
			fx.stop()
	_dust.clear()
	super()

func cast_process(delta: float) -> void:
	if _pulses_done < pulses and _elapsed >= _pulse_time(_pulses_done):
		_pulse()
		_pulses_done += 1
	_jolt = move_toward(_jolt, 0.0, pulse_jolt * 8.0 * delta)
	var amount: float = _shake_amount()
	_shake_islands(amount)
	if amount > 0.0 and rumble_shake > 0.0:
		EventBus.camera_shake.emit(rumble_camera_shake * minf(amount / rumble_shake, 1.0), 10.0)

func is_finished() -> bool:
	return _pulses_done >= pulses and _elapsed >= _pulse_time(pulses - 1) + recovery_time

func _pulse_time(index: int) -> float:
	return telegraph_time + index * pulse_interval

# Rumble builds during the telegraph; a spike builds before each pulse; fades after the last
func _shake_amount() -> float:
	var last_pulse: float = _pulse_time(pulses - 1)
	if _elapsed > last_pulse:
		var fade: float = 1.0 - (_elapsed - last_pulse) / maxf(recovery_time, 0.01)
		return rumble_shake * clampf(fade, 0.0, 1.0)
	var amount: float = rumble_shake * clampf(_elapsed / maxf(telegraph_time, 0.01), 0.0, 1.0)
	if _pulses_done < pulses and pre_pulse_window > 0.0:
		var until_pulse: float = _pulse_time(_pulses_done) - _elapsed
		if until_pulse < pre_pulse_window:
			amount += pre_pulse_shake * (1.0 - until_pulse / pre_pulse_window)
	return amount

# Only the sprites move, so the ground the player stands on stays steady
func _shake_islands(amount: float) -> void:
	for island: Island in _sprite_bases:
		if not is_instance_valid(island):
			continue
		var jitter: Vector2 = Vector2(randf_range(-amount, amount), randf_range(-amount, amount)).round()
		island.sprite.position = _sprite_bases[island] + jitter + Vector2(0.0, roundf(_jolt))

func _restore_islands() -> void:
	for island: Island in _sprite_bases:
		if is_instance_valid(island):
			island.sprite.position = _sprite_bases[island]
	_sprite_bases.clear()

func _pulse() -> void:
	if _pulses_done > 0:
		_restart_cast_animation()
	_jolt = pulse_jolt
	EventBus.camera_shake.emit(pulse_camera_shake, 10.0)
	for island: Island in _sprite_bases:
		if is_instance_valid(island):
			_spawn_on(island, pulse_scene, surface_offset_y, false)
	_knock_player()

func _knock_player() -> void:
	var player: Player = PlayerManager.player
	if player == null or not player.is_on_floor():
		return
	var island: Island = _island_under(player)
	if island == null:
		return
	var side: float = signf(player.global_position.x - island.global_position.x)
	if side == 0.0:
		side = 1.0 if randf() < 0.5 else -1.0
	EventBus.apply_player_knockback.emit(Vector2(side, -knockback_lift), knockback_force, false)

func _island_under(player: Player) -> Island:
	for i: int in player.get_slide_collision_count():
		var island: Island = player.get_slide_collision(i).get_collider() as Island
		if island:
			return island
	return null

func _spawn_on(island: Island, scene: PackedScene, offset_y: float, keep: bool) -> void:
	if scene == null or not CrumbleSpell._is_solid(island):
		return
	var fx: LingeringEffect = scene.instantiate()
	fx.position = Vector2(0.0, offset_y)
	island.add_child(fx)
	if keep:
		_dust.append(fx)

func _restart_cast_animation() -> void:
	if wizard.animation_player:
		wizard.animation_player.stop()
	wizard.update_animation(cast_animation)
