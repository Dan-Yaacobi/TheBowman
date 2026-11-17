class_name Snowflake extends Enemy
## One flake of a SnowflakeSwarm. Orbits the swarm centre; when sent, winds up with the ram line
## (tracks the player, then locks), rams in a straight line and shatters after hitting or missing.
## Dies to one hit.

enum Mode { ORBIT, WINDUP, CHARGE }

## How quickly an orbiting flake catches up with its spot (higher = snappier)
const ORBIT_FOLLOW: float = 12.0

var swarm: SnowflakeSwarm
var _mode: Mode = Mode.ORBIT
var _time_left: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _aim_locked: bool = false
var _line: RamTelegraph


func extra_ready_functions() -> void:
	_line = RamTelegraph.new()
	add_child(_line)
	hurt_box.successful_hit.connect(_on_hurt_box_successful_hit)


func is_orbiting() -> bool:
	return _mode == Mode.ORBIT


func start_ram() -> void:
	_mode = Mode.WINDUP
	_time_left = swarm.swarm_data.windup_time
	_aim_locked = false
	_direction = calculate_direction_to_player()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(swarm):
		shatter()
		return
	var data: SnowflakeSwarmData = swarm.swarm_data
	match _mode:
		Mode.ORBIT:
			var spot: Vector2 = swarm.orbit_position_for(self)
			global_position = global_position.lerp(spot, minf(ORBIT_FOLLOW * delta, 1.0))
		Mode.WINDUP:
			_time_left -= delta
			if not _aim_locked:
				_direction = calculate_direction_to_player()
				_aim_locked = _time_left <= data.aim_lock_time
			global_position -= _direction * data.windup_pullback_speed * delta
			var progress: float = 1.0 - _time_left / maxf(data.windup_time, 0.01)
			_line.show_aim(global_position, _direction, data.ram_speed * data.ram_time, progress, _aim_locked)
			if _time_left <= 0.0:
				_line.hide_aim()
				_mode = Mode.CHARGE
				_time_left = data.ram_time
		Mode.CHARGE:
			_time_left -= delta
			global_position += _direction * data.ram_speed * delta
			if _time_left <= 0.0:
				shatter()


func _on_hurt_box_successful_hit(_hurt_box: HurtBox, _hit_box: Area2D, _result: DamageResult) -> void:
	if _mode == Mode.CHARGE:
		shatter()


## Breaks apart on its own (after a ram). Plays the death effect but isn't a kill.
func shatter() -> void:
	if is_dead:
		return
	is_dead = true
	activate_death_ability()
	queue_free()
