class_name RockGolem extends Enemy
## Ground enemy that sits on an island looking like a rock.
## Wakes when the player gets close or hits it.

## Stat buff id for the dormant damage reduction
const DORMANT_ARMOR_ID: int = 120
## The body sits this many texture pixels left of the frame centre.
## The sprite offset is mirrored on flip so the body doesn't jump when turning.
const BODY_OFFSET_X: float = 5.0

## Islands' collision layer (5)
const ISLAND_MASK: int = 16

@export var gravity: float = 600.0

@onready var punch_hurt_box: HurtBox = $PunchHurtBox
@onready var _fist_shape: CollisionShape2D = $PunchHurtBox/CollisionShape2D

var golem_data: RockGolemData
var is_dormant: bool = true
## Set by a hit while dormant; the dormant state reads it to wake up
var was_hit_while_dormant: bool = false
## Horizontal speed the current state wants; knockback is added on top
var move_x: float = 0.0
## The island it last stood on
var current_island: Island
## Set by the idle state for the jump state to use
var jump_target: Island
## Counts down in the idle state; set when a jump ends
var jump_cooldown_left: float = 0.0
## Counts down in the idle state; set when a punch ends
var punch_cooldown_left: float = 0.0
## While true the jump state moves the golem along its arc; gravity and knockback are off
var is_leaping: bool = false
## Seconds awake since its last landed punch or throw; at throw_delay it throws a boulder
var time_without_hit: float = 0.0
var _last_floor_y: float = 0.0
var _flash_tween: Tween


func extra_ready_functions() -> void:
	golem_data = stats as RockGolemData
	if golem_data == null:
		push_error("RockGolem needs RockGolemData as its stats")
	animation_player = $Sprite2D/AnimationPlayer
	_last_floor_y = global_position.y
	punch_hurt_box.base_damage = golem_data.punch_damage
	punch_hurt_box.knockback_power = golem_data.punch_knockback
	# Share the body's damage multipliers so damage buffs/curses apply to the punch too
	punch_hurt_box.damage_multiplier = hurt_box.damage_multiplier
	punch_hurt_box.add_before_effect(_aim_punch_knockback)
	punch_hurt_box.successful_hit.connect(_on_punch_hurt_box_successful_hit)
	# Deferred so the dormant state's damage reduction is added after
	# init_damage_modifiers() builds the multiplier stat
	state_machine.Initialize.call_deferred(self)


func face_the_player() -> void:
	if stats.facing_player and PlayerManager.player:
		face_x(PlayerManager.player.global_position.x)


func face_x(x: float) -> void:
	sprite.flip_h = x < global_position.x
	sprite.offset.x = -BODY_OFFSET_X if sprite.flip_h else BODY_OFFSET_X
	# The fist is always in front
	_fist_shape.position.x = absf(_fist_shape.position.x) * facing_sign()


func facing_sign() -> float:
	return -1.0 if sprite.flip_h else 1.0


## Runs just before the punch lands: launch forward and up instead of along the overlap.
func _aim_punch_knockback(_entity: GameEntity, _hurt_box: HurtBox) -> void:
	var dir: Vector2 = golem_data.punch_launch_direction
	punch_hurt_box.knockback_dir = Vector2(dir.x * facing_sign(), dir.y).normalized()


func _on_punch_hurt_box_successful_hit(_hurt_box: HurtBox, _hit_box: Area2D, _result: DamageResult) -> void:
	time_without_hit = 0.0


func wants_to_throw() -> bool:
	return golem_data.boulder_scene != null \
		and time_without_hit >= golem_data.throw_delay \
		and calculate_distance_to_player() <= golem_data.throw_range


## Lobs a boulder at where the player is standing (or straight at them over the void).
func throw_boulder() -> void:
	time_without_hit = 0.0
	var hand: Vector2 = golem_data.throw_hand_offset * scale
	hand.x *= facing_sign()
	var start: Vector2 = global_position + hand
	var landing: Vector2 = PlayerManager.player.global_position
	var island: Island = get_player_island()
	if island:
		landing.y = island.get_top_y()
	var boulder: Boulder = golem_data.boulder_scene.instantiate()
	boulder.damage = golem_data.boulder_damage
	boulder.knockback = golem_data.boulder_knockback
	EventBus.summon_effect.emit(boulder)
	boulder.launch(start, landing, golem_data.boulder_flight_time, self, island)


## Player is on this island, close enough horizontally and at about the same height.
func is_player_in_punch_range() -> bool:
	if current_island == null or get_player_island() != current_island:
		return false
	var offset: Vector2 = PlayerManager.player.global_position - global_position
	return absf(offset.x) <= golem_data.punch_range \
		and absf(offset.y) <= golem_data.punch_height_tolerance


func _physics_process(delta: float) -> void:
	if not is_dormant:
		time_without_hit += delta
	if is_leaping:
		return
	velocity.y += gravity * delta
	_decay_knockback(delta)
	velocity.x = move_x + knockback_velocity.x
	move_and_slide()
	_update_ground()


func _update_ground() -> void:
	if is_on_floor():
		_last_floor_y = global_position.y
		var island: Island = _get_floor_island()
		if island:
			current_island = island
	elif not is_dead and global_position.y > _last_floor_y + golem_data.fall_death_depth:
		_die_from_fall()


func _get_floor_island() -> Island:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision.get_normal().y < -0.5 and collision.get_collider() is Island:
			return collision.get_collider() as Island
	return null


## Knocked into the void: dies like other enemies, no drops.
func _die_from_fall() -> void:
	is_dead = true
	enemy_died()


## The island the player is standing on or above, or null over the void.
func get_player_island() -> Island:
	if PlayerManager.player == null:
		return null
	var from: Vector2 = PlayerManager.player.global_position
	var to: Vector2 = from + Vector2(0.0, golem_data.player_ground_search_depth)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, ISLAND_MASK)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit["collider"] as Island


## Player's x, kept inside the walkable part of the current island.
func get_walk_target_x() -> float:
	var target_x: float = PlayerManager.player.global_position.x
	if current_island == null:
		return global_position.x
	return clamp_to_island(current_island, target_x)


## x kept edge_margin away from the island's ends (the middle if the island is too narrow).
func clamp_to_island(island: Island, x: float) -> float:
	var span: Vector2 = island.get_top_span()
	var left: float = span.x + golem_data.edge_margin
	var right: float = span.y - golem_data.edge_margin
	if left > right:
		return (span.x + span.y) * 0.5
	return clampf(x, left, right)


func can_jump_to(island: Island) -> bool:
	var offset: Vector2 = island.get_top_center() - global_position
	return absf(offset.x) <= golem_data.jump_reach_x \
		and offset.y >= -golem_data.jump_reach_up \
		and offset.y <= golem_data.jump_reach_down


## The island to jump to next on the way to target: target itself when in reach,
## otherwise the reachable island closest to it. Null if nothing gets it closer.
func get_next_island(target: Island) -> Island:
	if target == null or current_island == null or target == current_island:
		return null
	if can_jump_to(target):
		return target
	var best: Island = null
	var best_distance: float = current_island.global_position.distance_to(target.global_position)
	for node: Node in get_tree().get_nodes_in_group(Island.GROUP):
		var island: Island = node as Island
		if island == null or island == current_island or not island.is_solid() or not can_jump_to(island):
			continue
		var distance: float = island.global_position.distance_to(target.global_position)
		if distance < best_distance:
			best = island
			best_distance = distance
	return best


## Where to land on island: next to the player if they're on it, else the middle.
func get_landing_point(island: Island) -> Vector2:
	var x: float = island.get_top_center().x
	if island == get_player_island():
		x = PlayerManager.player.global_position.x
	return Vector2(clamp_to_island(island, x), island.get_top_y())


func _decay_knockback(delta: float) -> void:
	var weight: float = 1.0 - exp(-stats.knockback_decay * 60.0 * delta)
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, weight)
	if knockback_velocity.length() <= stats.knockback_threshold:
		knockback_velocity = Vector2.ZERO


func knockback(_hurt_box: HurtBox, _hit_box, _result) -> void:
	if is_dormant or not stats.can_be_knockedback:
		return
	var resistance: float = golem_data.knockback_resistance if golem_data else 0.0
	knockback_velocity += _hurt_box.knockback_dir * _hurt_box.knockback_power * (1.0 - resistance)


func extra_hit_functions(_hurt_box: HurtBox) -> void:
	if is_dormant:
		was_hit_while_dormant = true
	_flash()


func _flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	sprite.modulate = Color(2.5, 2.5, 2.5)
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


## Too heavy to flinch; hits only flash and push it.
func enter_damaged_state() -> void:
	pass


func is_debuff_immune() -> bool:
	return is_dormant or debuff_immune


func can_be_stunned() -> bool:
	return not is_dormant and not stats.stun_immune


func set_dormant(_dormant: bool) -> void:
	is_dormant = _dormant
	# A dormant rock doesn't hurt on touch
	hurt_box.set_deferred("monitoring", not _dormant)
