class_name SnowflakeSwarm extends Enemy
## Invisible centre of a snowflake swarm. Spawns 4-6 flakes that orbit it, follows the player at a
## distance, and sends one flake at a time to ram. Frees itself once every flake is gone.

var swarm_data: SnowflakeSwarmData
## Current orbit rotation; flakes read it to find their spot.
var orbit_angle: float = 0.0
var _flakes: Array[Snowflake] = []
var _ram_wait: float = 0.0
var _spawned_flakes: bool = false


func extra_ready_functions() -> void:
	swarm_data = stats as SnowflakeSwarmData
	_ram_wait = swarm_data.ram_interval


func _physics_process(delta: float) -> void:
	if not _spawned_flakes:
		_spawn_flakes()
		return
	_prune_flakes()
	if _flakes.is_empty():
		queue_free()
		return
	_follow_player(delta)
	orbit_angle = wrapf(orbit_angle + swarm_data.orbit_speed * delta, 0.0, TAU)
	_update_ram(delta)


## Spot of an orbiting flake: evenly spaced around the centre, skipping flakes that left to ram.
func orbit_position_for(flake: Snowflake) -> Vector2:
	var orbiting: Array[Snowflake] = _orbiting_flakes()
	var index: int = maxi(orbiting.find(flake), 0)
	var angle: float = orbit_angle + TAU * index / maxf(orbiting.size(), 1.0)
	return global_position + Vector2.RIGHT.rotated(angle) * swarm_data.orbit_radius


func _spawn_flakes() -> void:
	_spawned_flakes = true
	var count: int = randi_range(swarm_data.min_flakes, swarm_data.max_flakes)
	for i: int in count:
		var flake: Snowflake = swarm_data.flake_scene.instantiate()
		flake.set_data(swarm_data.flake_data)
		flake.swarm = self
		flake.global_position = global_position + Vector2.RIGHT.rotated(TAU * i / count) * swarm_data.orbit_radius
		_flakes.append(flake)
		EventBus.enemy_summoned.emit(flake)


func _prune_flakes() -> void:
	var alive: Array[Snowflake] = []
	for flake: Snowflake in _flakes:
		if is_instance_valid(flake) and not flake.is_dead:
			alive.append(flake)
	_flakes = alive


func _orbiting_flakes() -> Array[Snowflake]:
	var orbiting: Array[Snowflake] = []
	for flake: Snowflake in _flakes:
		if is_instance_valid(flake) and flake.is_orbiting():
			orbiting.append(flake)
	return orbiting


func _follow_player(delta: float) -> void:
	var player: Node2D = PlayerManager.player
	if player == null:
		return
	var target: Vector2 = player.global_position + swarm_data.hover_offset
	var to_target: Vector2 = target - global_position
	var distance: float = to_target.length()
	if distance > swarm_data.hover_distance:
		global_position += to_target / distance * minf(stats.move_speed.value() * delta, distance - swarm_data.hover_distance)


## One flake at a time: waits ram_interval after the last ram ends, then sends a random orbiting flake.
func _update_ram(delta: float) -> void:
	for flake: Snowflake in _flakes:
		if not flake.is_orbiting():
			return
	_ram_wait -= delta
	if _ram_wait > 0.0:
		return
	var orbiting: Array[Snowflake] = _orbiting_flakes()
	if orbiting.is_empty():
		return
	orbiting.pick_random().start_ram()
	_ram_wait = swarm_data.ram_interval
