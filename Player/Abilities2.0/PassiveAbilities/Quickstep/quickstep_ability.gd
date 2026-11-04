class_name QuickstepAbility extends PlayerPassiveAbility
## Perfect shots give a short burst of move speed, shown with a wind trail on the player.

## Move speed bonus (0.35 = +35%).
@export var speed_bonus: float = 0.35
@export var duration: float = 1.5

var _buff_id: int = -1
## Bumped on every refresh; only the newest timer may end the buff.
var _token: int = 0
var _trail: CPUParticles2D

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if _buff_id < 0:
		_buff_id = CustomVariables.get_buff_id()
	if not player.main_hand.release.is_connected(_on_release):
		player.main_hand.release.connect(_on_release)
	if not is_instance_valid(_trail):
		_trail = _make_trail()
		player.add_child(_trail)

func on_unequipped() -> void:
	var player: Player = PlayerManager.player
	if player.main_hand.release.is_connected(_on_release):
		player.main_hand.release.disconnect(_on_release)
	_end()
	if is_instance_valid(_trail):
		_trail.queue_free()
	_trail = null

func _on_release() -> void:
	var player: Player = PlayerManager.player
	if player.main_hand.shot_power < 1.0:
		return
	player.stats.move_speed.remove_buff_completly(_buff_id, Stat.buff_type.MULTIPLICATIVE)
	player.stats.move_speed.add_buff(_buff_id, speed_bonus * power(), Stat.buff_type.MULTIPLICATIVE)
	_token += 1
	_trail.emitting = true
	player.get_tree().create_timer(duration, false).timeout.connect(_on_timer_done.bind(_token))

## Timers only guard the exit: a newer perfect shot pushes the end back.
func _on_timer_done(token: int) -> void:
	if token == _token:
		_end()

func _end() -> void:
	PlayerManager.player.stats.move_speed.remove_buff_completly(_buff_id, Stat.buff_type.MULTIPLICATIVE)
	if is_instance_valid(_trail):
		_trail.emitting = false

func _make_trail() -> CPUParticles2D:
	var trail: CPUParticles2D = CPUParticles2D.new()
	trail.emitting = false
	trail.local_coords = false
	trail.amount = 24
	trail.lifetime = 0.35
	trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	trail.emission_rect_extents = Vector2(4, 10)
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 5.0
	trail.scale_amount_min = 1.0
	trail.scale_amount_max = 2.5
	trail.color = Color(0.9, 0.97, 1.0, 0.55)
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	trail.color_ramp = fade
	return trail

func get_tooltip() -> String:
	return "Perfect shots give +%d%% move speed for %.1fs" % [roundi(speed_bonus * power() * 100.0), duration]

func get_tooltip_color() -> Color:
	return Color(0.9, 0.97, 1.0)

func get_type() -> TriggerType:
	return TriggerType.PASSIVE
