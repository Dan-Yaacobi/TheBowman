class_name LightningChain extends Node2D

const STUN_DEBUFF = preload("uid://c1gcykybdcokh")
const LIGHTNING_CHAIN = preload("uid://bf4okr84ysm2p")

@export var max_chains: int = 3
@export var chain_radius: float = 200.0
@export var damage: int = 12

@onready var search_area: Area2D = $SearchArea
@onready var chain_timer: Timer = $ChainTimer

var _already_hit: Array[Enemy] = []
var _from_position: Vector2 = Vector2.ZERO
var _target: Enemy = null
var chains_left: int = 0

func setup(_from: Vector2, _new_target: Enemy, _chains: int, _hit_list: Array[Enemy]) -> void:
	_from_position = _from
	_target = _new_target
	chains_left = _chains
	_already_hit = _hit_list.duplicate()
	_already_hit.append(_new_target)

func _ready() -> void:
	if not is_instance_valid(_target):
		queue_free()
		return
	global_position = _target.global_position
	_apply_stun(_target)
	_target.take_damage(null, damage)
	_target.show_damage(damage, Color.YELLOW)
	_target.take_hit_effect()
	EffectSprite.spawn(&"lightning_strike", _target.global_position)
	_draw_lightning(_from_position, _target.global_position)
	chain_timer.start()

func _on_chain_timer_timeout() -> void:
	_try_chain()

func _apply_stun(_enemy: Enemy) -> void:
	var stun: StunDebuff = STUN_DEBUFF.instantiate()
	stun.can_stack = false
	_enemy.apply_debuff(stun,CustomVariables.STUN_DEBUFF_ID, PlayerManager.player.stats.stun_duration.value(), 1)

func _draw_lightning(_from: Vector2, _to: Vector2) -> void:
	var local_from: Vector2 = _from - global_position
	var local_to: Vector2 = _to - global_position
	var points: Array[Vector2] = []
	var segments: int = 8
	for i: int in segments + 1:
		var t: float = i / float(segments)
		var point: Vector2 = local_from.lerp(local_to, t)
		if i != 0 and i != segments:
			point += Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
		points.append(point)
	var glow: Line2D = Line2D.new()
	glow.width = 4.0
	glow.default_color = Color(1.0, 0.5, 0.0, 0.4)
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	for point: Vector2 in points:
		glow.add_point(point)
	add_child(glow)
	var core: Line2D = Line2D.new()
	core.width = 1.0
	core.default_color = Color(1.0, 0.9, 0.3, 1.0)
	core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core.end_cap_mode = Line2D.LINE_CAP_ROUND
	for point: Vector2 in points:
		core.add_point(point)
	add_child(core)

func _try_chain() -> void:
	if chains_left <= 0:
		queue_free()
		return
	var next_target: Enemy = null
	var closest_distance: float = INF
	# Searched by hitbox, not body: wizard bosses' bodies aren't on the Enemies layer.
	for enemy: Enemy in MinorHitHelpers.enemies_in_radius(get_world_2d(), global_position, _search_radius()):
		if not _already_hit.has(enemy):
			var dist: float = global_position.distance_to(enemy.global_position)
			if dist < closest_distance:
				closest_distance = dist
				next_target = enemy
	if not next_target:
		queue_free()
		return
	var next_chain: LightningChain = LIGHTNING_CHAIN.instantiate()
	next_chain.setup(global_position, next_target, chains_left - 1, _already_hit)
	next_chain.damage = damage
	EventBus.summon_effect.emit(next_chain)
	queue_free()

## The SearchArea's circle sets the jump range, so tuning stays in the scene.
func _search_radius() -> float:
	var shape: CollisionShape2D = search_area.get_child(0) as CollisionShape2D
	var circle: CircleShape2D = shape.shape as CircleShape2D if shape else null
	return circle.radius * absf(search_area.global_scale.x) if circle else chain_radius
