class_name Imp extends Enemy
## Rushes the player; on contact it latches on and drags them toward the nearest island edge.
## While it holds on, the player can't walk, dash, jump or slam, but can still draw and swing:
## killing it is the way out. Lets go when the player falls, or when it's stunned/captured.

enum Mode { RUSH, LATCHED, RECOVER }

var imp_data: ImpData
var _mode: Mode = Mode.RUSH
var _latch_offset: Vector2 = Vector2.ZERO
var _time_left: float = 0.0
var _recover_dir: Vector2 = Vector2.UP


func extra_ready_functions() -> void:
	imp_data = stats as ImpData
	EventBus.player_fell.connect(_on_event_bus_player_fell)


func _exit_tree() -> void:
	_let_go()


func is_latched() -> bool:
	return _mode == Mode.LATCHED


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var player: Player = PlayerManager.player
	if player == null:
		return
	match _mode:
		Mode.RUSH:
			face_the_player()
			global_position += calculate_direction_to_player() * imp_data.rush_speed * delta
			# Not while the player is invincible (e.g. just respawned): gives them a moment to fight back
			if not player.invincible and _is_touching_player():
				_latch(player)
		Mode.LATCHED:
			global_position = player.global_position + _latch_offset
		Mode.RECOVER:
			global_position += _recover_dir * imp_data.recover_speed * delta
			_time_left -= delta
			if _time_left <= 0.0:
				_mode = Mode.RUSH


func _latch(player: Player) -> void:
	_mode = Mode.LATCHED
	_latch_offset = (global_position - player.global_position).limit_length(10.0)
	player.add_grab(self, imp_data.drag_speed)


func _let_go() -> void:
	if _mode == Mode.LATCHED and PlayerManager.player:
		PlayerManager.player.remove_grab(self)
	_mode = Mode.RUSH


## Thrown off: flies up and away for recover_time, then rushes again.
func _throw_off() -> void:
	if _mode != Mode.LATCHED:
		return
	_let_go()
	_mode = Mode.RECOVER
	_time_left = imp_data.recover_time
	_recover_dir = (Vector2.UP + Vector2(randf_range(-1.0, 1.0), 0.0)).normalized()


func _on_event_bus_player_fell(_lost_heart: bool) -> void:
	_throw_off()


func stun(_electric: bool = false) -> void:
	_throw_off()
	super(_electric)


func attempt_capture(_new_parent: Node2D) -> bool:
	_throw_off()
	return super(_new_parent)


## Latches even when the hit itself doesn't land (player invulnerable).
func _is_touching_player() -> bool:
	for area: Area2D in hurt_box.get_overlapping_areas():
		if area is HitBox and area.get_parent() == PlayerManager.player:
			return true
	return false
