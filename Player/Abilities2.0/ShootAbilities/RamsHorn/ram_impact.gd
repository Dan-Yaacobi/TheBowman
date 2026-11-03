class_name RamImpact extends HurtBox
## Rides on a knocked-back enemy and hits other enemies it flies into, like a billiard ball.
## Every enemy it hits gets its own RamImpact (weaker), so hits chain.
## Lives while the carrier is still flying; the lifetime is only a safety guard.

const ENEMY_MASK: int = 28

## Below this knockback speed the enemy stops counting as a projectile (never below its own knockback threshold).
@export var min_carry_speed: float = 25.0
@export var max_lifetime: float = 0.8

var carrier: Enemy
var chain_left: int = 0
var falloff: float = 0.6
var hit_enemies: Array[Enemy] = []
var _age: float = 0.0
var _dust: CPUParticles2D

static func attach(_carrier: Enemy, _damage: int, _knockback: float, _chain_left: int, _falloff: float, _already_hit: Array[Enemy]) -> RamImpact:
	if _carrier == null or _carrier.is_dead or _carrier.hit_box == null or _carrier.hit_box.collision == null:
		return null
	for child in _carrier.get_children():
		if child is RamImpact:
			child.queue_free()
	var impact: RamImpact = RamImpact.new()
	impact.carrier = _carrier
	impact.base_damage = maxi(1, _damage)
	impact.knockback_power = _knockback
	impact.chain_left = _chain_left
	impact.falloff = _falloff
	impact.hit_enemies = _already_hit.duplicate()
	impact.hit_enemies.append(_carrier)
	impact.collision_layer = 0
	impact.collision_mask = ENEMY_MASK
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = _carrier.hit_box.collision.shape
	shape.transform = _carrier.hit_box.collision.transform
	impact.add_child(shape)
	impact.position = _carrier.hit_box.position
	_carrier.add_child(impact)
	return impact

func _ready() -> void:
	super._ready()
	successful_hit.connect(_on_successful_hit)
	_dust = CPUParticles2D.new()
	_dust.amount = 12
	_dust.lifetime = 0.35
	_dust.local_coords = false
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_dust.emission_sphere_radius = 6.0
	_dust.gravity = Vector2(0, 40)
	_dust.initial_velocity_min = 5.0
	_dust.initial_velocity_max = 15.0
	_dust.scale_amount_min = 1.5
	_dust.scale_amount_max = 3.0
	_dust.color = Color(0.72, 0.6, 0.42, 0.8)
	add_child(_dust)

func _physics_process(delta: float) -> void:
	_age += delta
	if not is_instance_valid(carrier) or carrier.is_dead or _age > max_lifetime:
		queue_free()
		return
	if _age > 0.05 and carrier.knockback_velocity.length() < maxf(min_carry_speed, carrier.stats.knockback_threshold):
		queue_free()

func AreaEnetered(a: Area2D) -> void:
	if not a is EnemyHitBox:
		return
	var enemy: Enemy = (a as EnemyHitBox).get_enemy()
	if enemy == null or enemy in hit_enemies:
		return
	hit_enemies.append(enemy)
	super.AreaEnetered(a)

func _on_successful_hit(_hurt_box: HurtBox, hit: Area2D, _result: DamageResult) -> void:
	if chain_left <= 0 or not hit is EnemyHitBox:
		return
	var enemy: Enemy = (hit as EnemyHitBox).get_enemy()
	RamImpact.attach(enemy, roundi(base_damage * falloff), knockback_power * falloff, chain_left - 1, falloff, hit_enemies)
