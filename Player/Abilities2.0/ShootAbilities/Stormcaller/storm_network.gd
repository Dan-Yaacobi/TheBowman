class_name StormNetwork extends Node2D
## Owns the Stormcaller rods (max 3, a new one replaces the oldest) and runs their effect each physics frame:
## 1 rod: small zaps on its enemy. 2 rods: a lightning line that damages anything crossing it.
## 3 rods: all three stunned plus anything inside or crossing the triangle, then the rods are spent.

const STUN_DEBUFF_PATH: String = "res://Debuffs/Stun/StunDebuff.tscn"
const ENEMY_HITBOX_MASK: int = 4
const LINE_COLOR: Color = Color(0.45, 0.8, 1.0, 0.9)
const LINE_GLOW: Color = Color(0.3, 0.6, 1.0, 0.35)

const MAX_RODS: int = 3

var zap_damage: int = 2
var zap_interval: float = 0.6
var line_damage: int = 3
## Seconds before the same enemy can be hurt by the line again.
var line_hit_cooldown: float = 0.5
var line_width: float = 6.0
var stun_duration: float = 1.5
## Rods fall out after this long (keeps a lone rod from zapping forever).
var rod_lifetime: float = 10.0

var rods: Array[StormRod] = []
var _zap_timer: float = 0.0
var _line_hits: Dictionary[Enemy, float] = {}
var _line: Line2D
var _glow: Line2D
var _redraw_timer: float = 0.0

func _ready() -> void:
	z_index = 3
	top_level = true
	_glow = _make_line(4.0, LINE_GLOW)
	_line = _make_line(1.0, LINE_COLOR)

func add_rod(enemy: Enemy) -> void:
	for rod in rods:
		if rod.is_alive() and rod.enemy == enemy:
			rod.age = 0.0
			rod.spark()
			return
	rods.append(StormRod.plant(enemy))
	while rods.size() > MAX_RODS:
		rods.pop_front().spend()
	_prune()
	if rods.size() >= MAX_RODS:
		_trigger_triangle()

func _physics_process(delta: float) -> void:
	for rod in rods:
		if rod.is_alive():
			rod.age += delta
			if rod.age > rod_lifetime:
				rod.spend()
	_prune()
	match rods.size():
		1:
			_line.visible = false; _glow.visible = false
			_zap_timer += delta
			if _zap_timer >= zap_interval:
				_zap_timer = 0.0
				_hurt(rods[0].enemy, zap_damage)
				rods[0].spark()
		2:
			_zap_timer = 0.0
			_update_line(delta)
			_damage_line_crossers(rods[0].tip(), rods[1].tip())
		_:
			_line.visible = false; _glow.visible = false

func _prune() -> void:
	rods = rods.filter(func(r: StormRod) -> bool: return r.is_alive())
	for enemy in _line_hits.keys():
		if not is_instance_valid(enemy):
			_line_hits.erase(enemy)

func _update_line(delta: float) -> void:
	_line.visible = true; _glow.visible = true
	_redraw_timer -= delta
	if _redraw_timer > 0.0:
		return
	_redraw_timer = 0.05
	var points: PackedVector2Array = _jagged(rods[0].tip(), rods[1].tip())
	_line.points = points
	_glow.points = points

func _damage_line_crossers(from: Vector2, to: Vector2) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	var shape: SegmentShape2D = SegmentShape2D.new()
	shape.a = from; shape.b = to
	for enemy in _query_enemies(shape, line_width):
		if enemy == rods[0].enemy or enemy == rods[1].enemy:
			continue
		if now - _line_hits.get(enemy, -INF) < line_hit_cooldown:
			continue
		_line_hits[enemy] = now
		_hurt(enemy, line_damage)

func _trigger_triangle() -> void:
	var corners: PackedVector2Array = PackedVector2Array([rods[0].tip(), rods[1].tip(), rods[2].tip()])
	var stunned: Array[Enemy] = []
	for rod in rods:
		stunned.append(rod.enemy)
	var shape: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
	shape.points = corners
	for enemy in _query_enemies(shape, line_width):
		if not enemy in stunned:
			stunned.append(enemy)
	for enemy in stunned:
		_stun(enemy)
	_flash_triangle(corners)
	for rod in rods:
		rod.spend()
	rods.clear()

func _query_enemies(shape: Shape2D, margin: float) -> Array[Enemy]:
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.margin = margin
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = ENEMY_HITBOX_MASK
	var found: Array[Enemy] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(params, 64):
		var area: EnemyHitBox = hit.collider as EnemyHitBox
		if area and area.get_enemy() and not area.get_enemy().is_dead and not area.get_enemy() in found:
			found.append(area.get_enemy())
	return found

func _hurt(enemy: Enemy, amount: int) -> void:
	if not is_instance_valid(enemy) or enemy.is_dead:
		return
	enemy.take_damage(null, amount)
	enemy.show_damage(amount, Color(0.6, 0.85, 1.0))
	enemy.take_hit_effect()

func _stun(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or enemy.is_dead or not enemy.can_be_stunned():
		return
	var stun: StunDebuff = load(STUN_DEBUFF_PATH).instantiate()
	stun.can_stack = false
	enemy.apply_debuff(stun, CustomVariables.STUN_DEBUFF_ID, stun_duration, 1)

func _flash_triangle(corners: PackedVector2Array) -> void:
	var tri: Polygon2D = Polygon2D.new()
	tri.polygon = corners
	tri.color = Color(0.5, 0.8, 1.0, 0.45)
	add_child(tri)
	var edge: Line2D = _make_line(2.0, Color(0.85, 0.95, 1.0))
	edge.points = PackedVector2Array([corners[0], corners[1], corners[2], corners[0]])
	edge.visible = true
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(tri, "modulate:a", 0.0, 0.4)
	tween.tween_property(edge, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(tri.queue_free)
	tween.tween_callback(edge.queue_free)
	EventBus.camera_shake.emit(1.0, 10.0)

func _make_line(width: float, color: Color) -> Line2D:
	var line: Line2D = Line2D.new()
	line.width = width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.visible = false
	add_child(line)
	return line

func _jagged(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = maxi(3, int(from.distance_to(to) / 10.0))
	var normal: Vector2 = (to - from).orthogonal().normalized()
	for i in segments + 1:
		var t: float = i / float(segments)
		var point: Vector2 = from.lerp(to, t)
		if i != 0 and i != segments:
			point += normal * randf_range(-3.0, 3.0)
		points.append(point)
	return points
