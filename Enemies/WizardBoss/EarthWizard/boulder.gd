class_name Boulder extends Node2D
## Lobbed in an arc by the earth wizard or the rock golem; hits the player with knockback and
## breaks on landing. A perfect arrow shatters it into shards that fly back at the thrower.
## The shards leave with a fixed speed, so they only reach the thrower while the boulder is
## still close to it.

@export var damage: int = 2
@export var knockback: float = 220.0
@export var gravity: float = 400.0
## Visual spin in radians per second
@export var spin_speed: float = 6.0
## Safety: free the boulder if it flies this long without landing
@export var max_lifetime: float = 4.0
## How fast the white hit flash fades (per second)
@export var flash_fade_speed: float = 8.0
## Dust burst played where it lands or shatters
@export var break_scene: PackedScene
@export_group("Shards")
@export var shard_scene: PackedScene
@export var shard_count: int = 5
@export var shard_damage: int = 4
## How far the shards can fly (pixels); sets their launch speed
@export var shard_range: float = 120.0
@export var shard_gravity: float = 500.0
## Angle between neighbouring shards, in degrees
@export var shard_spread_deg: float = 6.0
## Where on the thrower the shards aim, relative to its origin
@export var wizard_aim_offset: Vector2 = Vector2(0, -5)

@onready var visual: Sprite2D = $Visual
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: BoulderHitBox = $HitBox
@onready var ground_detector: Area2D = $GroundDetector
@onready var target_mark: Node2D = $TargetMark
@onready var shadow: ColorRect = $TargetMark/Shadow

var _velocity: Vector2 = Vector2.ZERO
var _thrower: Node2D
var _target: Island
var _landing_x: float = 0.0
var _flight_time: float = 1.0
var _time: float = 0.0
var _flash: float = 0.0
var _launched: bool = false
var _done: bool = false

func _ready() -> void:
	hurt_box.base_damage = damage
	hurt_box.knockback_power = knockback
	hurt_box.successful_hit.connect(_on_hurt_box_successful_hit)
	hit_box.struck.connect(_on_hit_box_struck)
	ground_detector.body_entered.connect(_on_ground_detector_body_entered)

## While held (e.g. in the rock golem's hands) it hits nothing and can't be hit.
## Safe to call before the boulder is in the tree.
func set_held(held: bool) -> void:
	for path: String in ["HurtBox", "HitBox", "GroundDetector"]:
		var area: Area2D = get_node(path) as Area2D
		if is_inside_tree():
			area.set_deferred("monitoring", not held)
			area.set_deferred("monitorable", not held)
		else:
			area.monitoring = not held
			area.monitorable = not held

## Fly from start so it reaches landing after flight_time seconds.
## target = the island under the landing spot, for the warning shadow (null = no shadow)
func launch(start: Vector2, landing: Vector2, flight_time: float, thrower: Node2D, target: Island) -> void:
	if not is_node_ready():
		await ready
	set_held(false)
	global_position = start
	_flight_time = maxf(flight_time, 0.1)
	_velocity = (landing - start) / _flight_time - Vector2(0.0, 0.5 * gravity * _flight_time)
	_thrower = thrower
	_target = target
	_landing_x = landing.x
	_time = 0.0
	_launched = true
	target_mark.visible = is_instance_valid(_target)
	_update_mark()

func _physics_process(delta: float) -> void:
	if not _launched or _done:
		return
	_time += delta
	if _time >= max_lifetime:
		queue_free()
		return
	_velocity.y += gravity * delta
	global_position += _velocity * delta
	visual.rotation += spin_speed * signf(_velocity.x) * delta
	_flash = maxf(_flash - flash_fade_speed * delta, 0.0)
	visual.modulate = Color(1, 1, 1).lerp(Color(2.5, 2.5, 2.5), _flash)
	_update_mark()

func _update_mark() -> void:
	if not is_instance_valid(_target):
		target_mark.visible = false
		return
	target_mark.global_position = Vector2(_landing_x, _target.global_position.y - 3.0)
	var mat: ShaderMaterial = shadow.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("progress", clampf(_time / _flight_time, 0.0, 1.0))

func _on_hit_box_struck(attacker: HurtBox) -> void:
	if _done:
		return
	var arrow: Arrow = attacker.get_parent() as Arrow if attacker else null
	if arrow and arrow.perfect_shot:
		_shatter()
	else:
		_flash = 1.0

func _on_hurt_box_successful_hit(_hurt_box: HurtBox, _hit_box: Area2D, _result: DamageResult) -> void:
	_break()

# Only on the way down, so it never lands on the island it was thrown from
func _on_ground_detector_body_entered(body: Node2D) -> void:
	if _done or not body is Island or _velocity.y <= 0.0:
		return
	_break()

func _shatter() -> void:
	if shard_scene and is_instance_valid(_thrower):
		var aim: Vector2 = _thrower.global_position + wizard_aim_offset
		var base: Vector2 = _shard_velocity(aim)
		for i: int in shard_count:
			var offset: float = (i - (shard_count - 1) * 0.5) * deg_to_rad(shard_spread_deg)
			var shard: BoulderShard = shard_scene.instantiate()
			shard.texture = visual.texture
			EventBus.summon_effect.emit(shard)
			shard.launch(global_position, base.rotated(offset), shard_gravity, shard_damage)
	_break()

# Fixed launch speed (set by shard_range); the low arc that hits aim if it is in reach,
# otherwise the longest throw toward it, which falls short
func _shard_velocity(aim: Vector2) -> Vector2:
	var speed: float = sqrt(maxf(shard_range, 1.0) * shard_gravity)
	var dx: float = aim.x - global_position.x
	var x: float = maxf(absf(dx), 0.01)
	var up: float = global_position.y - aim.y
	var s2: float = speed * speed
	var disc: float = s2 * s2 - shard_gravity * (shard_gravity * x * x + 2.0 * up * s2)
	var angle: float = PI / 4.0
	if disc >= 0.0:
		angle = atan2(s2 - sqrt(disc), shard_gravity * x)
	var side: float = signf(dx) if dx != 0.0 else 1.0
	return Vector2(cos(angle) * side, -sin(angle)) * speed

func _break() -> void:
	if _done:
		return
	_done = true
	if break_scene:
		var fx: Node2D = break_scene.instantiate()
		fx.position = global_position
		EventBus.summon_effect.emit(fx)
	queue_free()
