class_name Imp extends Enemy
## Rushes the player. Once close it winds up (stops, pulls back and glows). Its aim follows the
## player, then locks for the last aim_lock_time and flashes: dashing from then on (or during the
## lunge) dodges it. Only the lunge can grab, and never mid-dash.
## A grab drags the player toward the nearest island edge; while it holds on, the player can't
## walk, dash, jump or slam, but can still draw and swing: killing it is the way out.
## Lets go when the player falls, or when it's stunned/captured.

enum Mode { RUSH, WINDUP, LUNGE, LATCHED, RECOVER }

var imp_data: ImpData
var _mode: Mode = Mode.RUSH
var _latch_offset: Vector2 = Vector2.ZERO
var _time_left: float = 0.0
## Recover: flight direction. Windup/lunge: aim toward the player.
var _move_dir: Vector2 = Vector2.UP
## Counts down after the player falls; no grabs until it's done
var _respawn_grace_left: float = 0.0


func extra_ready_functions() -> void:
	imp_data = stats as ImpData
	EventBus.player_fell.connect(_on_event_bus_player_fell)


func _exit_tree() -> void:
	_let_go()


func is_latched() -> bool:
	return _mode == Mode.LATCHED


func is_winding_up() -> bool:
	return _mode == Mode.WINDUP


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var player: Player = PlayerManager.player
	if player == null:
		return
	if _respawn_grace_left > 0.0:
		_respawn_grace_left -= delta
	match _mode:
		Mode.RUSH:
			face_the_player()
			global_position += calculate_direction_to_player() * imp_data.rush_speed * delta
			if calculate_distance_to_player() <= imp_data.grab_range:
				_start_windup()
		Mode.WINDUP:
			_time_left -= delta
			# Aim follows the player until the lock, then stays: the dodge window
			if _time_left > imp_data.aim_lock_time:
				face_the_player()
				_move_dir = calculate_direction_to_player()
				_set_glow(0.6 * (1.0 - _time_left / maxf(imp_data.windup_time, 0.01)))
			else:
				_set_glow(1.0)
			global_position -= _move_dir * imp_data.windup_pullback_speed * delta
			if _time_left <= 0.0:
				_set_glow(0.0)
				_mode = Mode.LUNGE
				_time_left = imp_data.lunge_time
		Mode.LUNGE:
			_time_left -= delta
			global_position += _move_dir * imp_data.lunge_speed * delta
			if _can_grab(player):
				_latch(player)
			elif _time_left <= 0.0:
				_recover(-_move_dir, imp_data.miss_recover_time)
		Mode.LATCHED:
			global_position = player.global_position + _latch_offset
		Mode.RECOVER:
			global_position += _move_dir * imp_data.recover_speed * delta
			_time_left -= delta
			if _time_left <= 0.0:
				_mode = Mode.RUSH


func _start_windup() -> void:
	_mode = Mode.WINDUP
	_time_left = imp_data.windup_time
	_move_dir = calculate_direction_to_player()


## Not while the player is dashing (that's the dodge) or just after they fell and respawned.
## Hit invincibility doesn't count: the lunge's own touch damage would block every grab.
func _can_grab(player: Player) -> bool:
	return _respawn_grace_left <= 0.0 and not player.is_dash() and _is_touching_player()


func _latch(player: Player) -> void:
	_mode = Mode.LATCHED
	var side: float = signf(global_position.x - player.global_position.x)
	_latch_offset = imp_data.grab_offset + Vector2(side * imp_data.grab_side_offset, 0.0)
	player.add_grab(self, imp_data.drag_speed)


func _let_go() -> void:
	if _mode == Mode.LATCHED and PlayerManager.player:
		PlayerManager.player.remove_grab(self)
	_mode = Mode.RUSH


func _recover(direction: Vector2, duration: float) -> void:
	_set_glow(0.0)
	_mode = Mode.RECOVER
	_time_left = duration
	_move_dir = direction.normalized()


## Thrown off: flies up and away for recover_time, then rushes again.
func _throw_off() -> void:
	if _mode == Mode.LATCHED:
		_let_go()
		_recover(Vector2.UP + Vector2(randf_range(-1.0, 1.0), 0.0), imp_data.recover_time)
	elif _mode == Mode.WINDUP or _mode == Mode.LUNGE:
		_set_glow(0.0)
		_mode = Mode.RUSH


## 0 = normal, 1 = full wind-up glow.
func _set_glow(amount: float) -> void:
	sprite.self_modulate = Color.WHITE.lerp(imp_data.windup_glow, clampf(amount, 0.0, 1.0))


func _on_event_bus_player_fell(_lost_heart: bool) -> void:
	_respawn_grace_left = imp_data.respawn_grace
	_throw_off()


func stun(_electric: bool = false) -> void:
	_throw_off()
	super(_electric)


func attempt_capture(_new_parent: Node2D) -> bool:
	_throw_off()
	return super(_new_parent)


## Counts even when the hit itself doesn't land (player invulnerable).
func _is_touching_player() -> bool:
	for area: Area2D in hurt_box.get_overlapping_areas():
		if area is HitBox and area.get_parent() == PlayerManager.player:
			return true
	return false
