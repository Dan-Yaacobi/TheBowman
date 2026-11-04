class_name Hurricane extends Node2D

@export var base_speed: float = 40.0
@export var wander_strength: float = 0.7
@export var wander_frequency: float = 0.15
@export var lifetime: float = 8.0
@onready var hurt_box: HurtBox = $HurtBox
@export var orbit_speed: float = 1.5       # radians/sec
@export var orbit_squash: float = 0.35     # vertical compression (1.0 = circle, lower = flatter oval)
@export_group("Damage")
## Seconds between grinding ticks.
@export var tick_interval: float = 0.5
## Each tick, enemies spinning in the hurricane take base_damage x this.
@export var orbit_tick_mult: float = 0.3
## Each tick, enemies it can't pick up (capture immune) take base_damage x this while inside it.
@export var immune_tick_mult: float = 0.6
@export var tick_color: Color = Color.LIGHT_CYAN

var direction: Vector2 = Vector2.RIGHT
var _base_heading: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()
var _age: float = 0.0
var after_hit_abilities: Array
var before_hit_abilities: Array
var knockback_power: float
var enemies_picked: Dictionary[GameEntity, Dictionary] = {}  # value = {radius, angle}
## Damage of the perfect arrow that made this hurricane. 0 = fall back to the arrow_damage stat.
var base_damage: int = 0
var _tick_time: float = 0.0

func _ready() -> void:
	_base_heading = direction.angle()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = wander_frequency
	_noise.seed = randi()
	lifetime = PlayerManager.player.stats.hurricane_duration.value()
	for ability in after_hit_abilities:
		hurt_box.add_after_effect(ability.activate_ability)
	for ability in before_hit_abilities:
		hurt_box.add_before_effect(ability.activate_ability)

	if base_damage <= 0:
		base_damage = roundi(PlayerManager.player.stats.arrow_damage.value())
	hurt_box.base_damage = base_damage
	hurt_box.add_after_effect(pick_enemy)
	

func _process(delta: float) -> void:
	_age += delta
	if lifetime > 0.0 and _age >= lifetime:
		_release_all()
		queue_free()
		return

	var wander: float = _noise.get_noise_1d(_age) * wander_strength
	var actual_heading: float = _base_heading + wander
	var velocity: Vector2 = Vector2.RIGHT.rotated(actual_heading) * base_speed
	global_position += velocity * delta

	for enemy in enemies_picked.keys():
		if not is_instance_valid(enemy):
			continue
		var orbit: Dictionary = enemies_picked[enemy]
		orbit.angle += orbit_speed * delta
		var local_offset: Vector2 = Vector2(
			cos(orbit.angle) * orbit.radius,
			sin(orbit.angle) * orbit.radius * orbit_squash
		)
		enemy.global_position = global_position + local_offset
		enemy.z_index = -1 if sin(orbit.angle) < 0 else 1

	_tick_time += delta
	if _tick_time >= tick_interval:
		_tick_time -= tick_interval
		_grind()

## Damages everything spinning in the hurricane, and hits enemies it can't lift harder.
func _grind() -> void:
	for enemy in enemies_picked.keys():
		if is_instance_valid(enemy) and not enemy.is_dead:
			enemy.take_damage(null, maxi(1, roundi(base_damage * orbit_tick_mult)), null, tick_color)
	for area in hurt_box.get_overlapping_areas():
		var hit_box: EnemyHitBox = area as EnemyHitBox
		if hit_box == null:
			continue
		var enemy: Enemy = hit_box.get_enemy()
		if enemy and not enemy.is_dead and enemy.stats.capture_immune:
			enemy.take_damage(null, maxi(1, roundi(base_damage * immune_tick_mult)), null, tick_color)
func pick_enemy(entity: GameEntity, _parent: Node2D, _result: DamageResult) -> void:
	if not entity is Enemy:
		return
	if enemies_picked.has(entity):
		return
	_capture_enemy(entity)

func _capture_enemy(entity: Enemy) -> void:
	if entity.captured_by != null:
		return
	if entity.attempt_capture(self):
		var offset: Vector2 = entity.global_position - global_position
		var target_radius: float = offset.length()
		enemies_picked[entity] = {
			"radius": 0.0,
			"angle": offset.angle()
		}
		if not entity.tree_exiting.is_connected(_on_captured_entity_freed.bind(entity)):
			entity.tree_exiting.connect(_on_captured_entity_freed.bind(entity), CONNECT_ONE_SHOT)

		var tween: Tween = create_tween()
		tween.tween_method(
			func(r: float): if enemies_picked.has(entity): enemies_picked[entity].radius = r,
			0.0, target_radius, 0.3
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
func release_enemy(entity: GameEntity) -> void:
	enemies_picked.erase(entity)
	if not is_instance_valid(entity):
		return
	if entity.captured_by == self:
		entity.release_capture()

func _release_all() -> void:
	for enemy in enemies_picked.keys().duplicate():
		if not is_instance_valid(enemy):
			enemies_picked.erase(enemy)
			continue
		release_enemy(enemy)

func _on_captured_entity_freed(entity: GameEntity) -> void:
	enemies_picked.erase(entity)
