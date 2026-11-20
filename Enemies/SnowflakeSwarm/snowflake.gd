class_name Snowflake extends Enemy
## One flake of a SnowflakeSwarm. Orbits the swarm centre; when sent, winds up with the ram line
## (tracks the player, then locks), rams in a straight line and shatters after hitting or missing.
## A flake that shatters on its own is reformed by the swarm; one hit from the player kills it for good.

enum Mode { ORBIT, WINDUP, CHARGE }

## How quickly an orbiting flake catches up with its spot (higher = snappier)
const ORBIT_FOLLOW: float = 12.0
## Seconds a reformed flake takes to grow to full size
const REFORM_TIME: float = 0.25

var swarm: SnowflakeSwarm
## Set by the swarm before it joins the tree: grows in instead of popping into place
var reforming: bool = false
var _mode: Mode = Mode.ORBIT
var _time_left: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _aim_locked: bool = false
var _line: RamTelegraph


func extra_ready_functions() -> void:
	_line = RamTelegraph.new()
	add_child(_line)
	animation_player = $Sprite2D/AnimationPlayer
	hurt_box.successful_hit.connect(_on_hurt_box_successful_hit)
	if reforming:
		var full_scale: Vector2 = sprite.scale
		sprite.scale = Vector2.ZERO
		create_tween().tween_property(sprite, ^"scale", full_scale, REFORM_TIME) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A reformed flake joins the world deferred, so it can't be sent to ram until it's ready.
func is_orbiting() -> bool:
	return _mode == Mode.ORBIT and is_node_ready()


func start_ram() -> void:
	_mode = Mode.WINDUP
	_time_left = swarm.swarm_data.windup_time
	_aim_locked = false
	_direction = calculate_direction_to_player()
	# Stretch the wind-up animation over however long the wind-up is tuned to last
	var windup_length: float = animation_player.get_animation(&"Windup").length
	animation_player.play(&"Windup", -1, windup_length / maxf(swarm.swarm_data.windup_time, 0.01))


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
				animation_player.play(&"Spin")
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
	if is_instance_valid(swarm):
		swarm.queue_respawn()
	_break_apart()


## Killed by the player: shatters the same way instead of vanishing on the spot.
func enemy_died() -> void:
	died.emit(self)
	EventBus.enemy_died.emit(self)
	_break_apart()


## Plays the shatter, then frees itself. Its boxes go off first so the shards can't hit or be hit.
func _break_apart() -> void:
	_line.hide_aim()
	$HurtBox/CollisionShape2D.set_deferred("disabled", true)
	$HitBox/CollisionShape2D.set_deferred("disabled", true)
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	animation_player.play(&"Shatter")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()
