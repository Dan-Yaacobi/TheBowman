class_name MawAbility extends PlayerAbility
## The Maw: a starving bow that grows by devouring the souls of enemies killed while it's equipped.
## Souls live on this ability (one per rolled bow), so unequipping and re-equipping keeps them.
##   Starving: weaker arrows.
##   Fed: perfect kills bite the nearest enemy.
##   Gorged: stronger arrows that trail souls; bites hit the 2 nearest enemies.
##   Awakened: strongest arrows; perfect hits devour enemies below the HP threshold
##             (bosses take double damage from that hit instead).
## Precision scrolls scale the positive stage bonuses and the bite, not the Starving penalty.

enum Stage { STARVING, FED, GORGED, AWAKENED }
const STAGE_NAMES: Array[String] = ["Starving", "Fed", "Gorged", "Awakened"]
const STAGE_COLORS: Array[Color] = [Color(0.6, 0.6, 0.65), Color(0.75, 0.55, 1.0), Color(0.85, 0.4, 1.0), Color(1.0, 0.35, 0.75)]

@export_group("Souls")
## Souls needed to reach Fed, Gorged and Awakened. Placeholders: tune by playtesting.
@export var stage_thresholds: Array[int] = [10, 30, 70]
@export var souls_per_enemy: int = 1
@export var souls_per_elite: int = 5
@export var souls_per_boss: int = 15
@export_group("Effects")
## Arrow damage change per stage (0.25 = +25%).
@export var stage_damage: Array[float] = [-0.3, 0.0, 0.25, 0.5]
## Bite: share of the killing hit dealt to the nearest enemy.
@export var bite_share: float = 0.5
@export var bite_radius: float = 200.0
## Enemies one bite hits, per stage (Starving, Fed, Gorged, Awakened).
@export var bite_targets: Array[int] = [0, 1, 2, 2]
## Devour: enemies below this share of their HP are devoured by a perfect hit (Awakened).
@export var devour_threshold: float = 0.2
@export_group("")

var souls: int = 0
var _stage: Stage = Stage.STARVING
var _buff_id: int = "maw/stage_damage".hash()
var _counter: SoulCounter
var _trail: SoulTrail
var _equipped: bool = false

func on_equipped() -> void:
	_equipped = true
	var player: Player = PlayerManager.player
	if not EventBus.enemy_died.is_connected(_on_event_bus_enemy_died):
		EventBus.enemy_died.connect(_on_event_bus_enemy_died)
	if not EventBus.arrow_enemy_hit.is_connected(_on_event_bus_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.connect(_on_event_bus_arrow_enemy_hit)
	if not is_instance_valid(_counter):
		_counter = SoulCounter.new()
		player.add_child(_counter)
	if _trail == null:
		_trail = SoulTrail.new()
		_trail.ability = self
	if not _trail in player.stats.arrow_visual_effects:
		player.stats.arrow_visual_effects.append(_trail)
	_stage = _stage_for(souls)
	_apply_stage_buff()
	_update_counter()

func on_unequipped() -> void:
	_equipped = false
	var player: Player = PlayerManager.player
	if EventBus.enemy_died.is_connected(_on_event_bus_enemy_died):
		EventBus.enemy_died.disconnect(_on_event_bus_enemy_died)
	if EventBus.arrow_enemy_hit.is_connected(_on_event_bus_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.disconnect(_on_event_bus_arrow_enemy_hit)
	player.stats.arrow_damage.remove_buff_completly(_buff_id, Stat.buff_type.MULTIPLICATIVE)
	player.stats.arrow_visual_effects.erase(_trail)
	if is_instance_valid(_counter):
		_counter.queue_free()
	_counter = null

func refresh_power() -> void:
	if _equipped:
		_apply_stage_buff()

func stage() -> Stage:
	return _stage

## Devour runs before the hit lands, while the enemy's HP is still the old value.
func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _stage != Stage.AWAKENED:
		return
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	var arrow: Arrow = MinorHitHelpers.arrow_of(hurt_box)
	if enemy == null or arrow == null or not arrow.perfect_shot or enemy.is_dead:
		return
	if float(enemy.current_hp) > float(enemy.stats.max_hp) * devour_threshold:
		return
	if enemy is Boss:
		MinorHitHelpers.add_damage_for_hit(hurt_box, 1.0)
		return
	# Enough to finish anything below the threshold.
	MinorHitHelpers.add_damage_for_hit(hurt_box, 1000.0)
	CombatTextSpawner.spawn(enemy.global_position + Vector2(0, -16), "Devoured", STAGE_COLORS[Stage.AWAKENED])

func _on_event_bus_enemy_died(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or enemy is FlyingTarget or enemy is GoldenApple:
		return
	var gain: int = souls_per_enemy
	var boss: Boss = enemy as Boss
	if boss:
		gain = souls_per_boss if boss.arena != null else souls_per_elite
	souls += gain
	var new_stage: Stage = _stage_for(souls)
	if new_stage != _stage:
		_stage = new_stage
		_apply_stage_buff()
		var player: Player = PlayerManager.player
		CombatTextSpawner.spawn(player.global_position + Vector2(0, -56), "The Maw: " + STAGE_NAMES[_stage], STAGE_COLORS[_stage])
		EventBus.camera_shake.emit(2.0, 12.0)
		var burst: SoulBurst = SoulBurst.new()
		burst.color = STAGE_COLORS[_stage]
		burst.global_position = player.global_position + Vector2(0, -12)
		EventBus.summon_effect.emit(burst)
	_update_counter()
	if is_instance_valid(_counter):
		_counter.pulse()

## Bite: a perfect kill lashes the nearest other enemy.
func _on_event_bus_arrow_enemy_hit(perfect: bool, arrow: Arrow, target: Enemy) -> void:
	if _stage < Stage.FED or not perfect or not is_instance_valid(target) or not target.is_dead:
		return
	if not is_instance_valid(arrow) or not target.is_inside_tree():
		return
	var count: int = bite_targets[mini(_stage, bite_targets.size() - 1)]
	var bite: int = maxi(1, roundi(arrow.hurt_box.damage * bite_share * power()))
	for victim: Enemy in _nearest_others(target, count):
		victim.take_damage(null, bite, null, STAGE_COLORS[_stage])
		var link: ContagionBandAbility.ContagionLink = ContagionBandAbility.ContagionLink.new()
		link.from = target.global_position
		link.to = victim.global_position
		link.color = STAGE_COLORS[_stage]
		link.thickness = 3.5
		EventBus.summon_effect.emit(link)

## Up to count living enemies near from, closest first.
func _nearest_others(from: Enemy, count: int) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for enemy: Enemy in MinorHitHelpers.enemies_in_radius(from.get_world_2d(), from.global_position, bite_radius):
		if enemy != from and not enemy.is_dead:
			found.append(enemy)
	found.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return a.global_position.distance_squared_to(from.global_position) < b.global_position.distance_squared_to(from.global_position))
	return found.slice(0, count)

func _stage_for(count: int) -> Stage:
	var result: int = 0
	for threshold: int in stage_thresholds:
		if count >= threshold:
			result += 1
	return mini(result, Stage.AWAKENED) as Stage

func _apply_stage_buff() -> void:
	var stat: Stat = PlayerManager.player.stats.arrow_damage
	stat.remove_buff_completly(_buff_id, Stat.buff_type.MULTIPLICATIVE)
	var amount: float = stage_damage[mini(_stage, stage_damage.size() - 1)]
	if amount > 0.0:
		amount *= power()
	if not is_zero_approx(amount):
		stat.add_buff(_buff_id, amount, Stat.buff_type.MULTIPLICATIVE)

func _update_counter() -> void:
	if not is_instance_valid(_counter):
		return
	var floor_souls: int = 0 if _stage == Stage.STARVING else stage_thresholds[_stage - 1]
	var next_souls: int = stage_thresholds[_stage] if _stage < Stage.AWAKENED else -1
	_counter.show_souls(STAGE_NAMES[_stage], souls, floor_souls, next_souls, STAGE_COLORS[_stage])

func get_tooltip() -> String:
	var next: String = ""
	if _stage < Stage.AWAKENED:
		next = ", next stage at %d" % stage_thresholds[_stage]
	return "Devours souls of the slain and grows stronger. %s (%d souls%s)" % [STAGE_NAMES[_stage], souls, next]

func get_tooltip_color() -> Color:
	return STAGE_COLORS[_stage]

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT

## Stage name, soul count toward the next stage and a progress bar, above the archer.
class SoulCounter extends Node2D:
	const BAR_SIZE: Vector2 = Vector2(40, 4)
	var _label: Label
	var _fill: float = 0.0
	var _color: Color = Color.WHITE
	var _pulse: float = 0.0

	func _ready() -> void:
		position = Vector2(0, -50)
		z_index = 5
		_label = Label.new()
		_label.position = Vector2(-40, -16)
		_label.size = Vector2(80, 14)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 11)
		_label.add_theme_constant_override("outline_size", 4)
		_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		add_child(_label)

	func show_souls(stage_name: String, count: int, floor_souls: int, next_souls: int, color: Color) -> void:
		_color = color
		_label.add_theme_color_override("font_color", color)
		if next_souls < 0:
			_label.text = "%s  %d" % [stage_name, count]
			_fill = 1.0
		else:
			_label.text = "%s  %d/%d" % [stage_name, count, next_souls]
			_fill = clampf(float(count - floor_souls) / float(maxi(next_souls - floor_souls, 1)), 0.0, 1.0)
		queue_redraw()

	## A quick bump when a soul is eaten.
	func pulse() -> void:
		_pulse = 1.0

	func _process(delta: float) -> void:
		if _pulse > 0.0:
			_pulse = maxf(_pulse - delta * 4.0, 0.0)
			scale = Vector2.ONE * (1.0 + 0.25 * _pulse)

	func _draw() -> void:
		var rect: Rect2 = Rect2(-BAR_SIZE / 2.0, BAR_SIZE)
		draw_rect(rect.grow(1.0), Color(0, 0, 0, 0.8))
		draw_rect(Rect2(rect.position, Vector2(BAR_SIZE.x * _fill, BAR_SIZE.y)), _color)

## A one-shot ring of soul particles for a stage-up.
class SoulBurst extends CPUParticles2D:
	func _ready() -> void:
		one_shot = true
		explosiveness = 1.0
		amount = 28
		lifetime = 0.7
		spread = 180.0
		gravity = Vector2(0, -40)
		initial_velocity_min = 50.0
		initial_velocity_max = 110.0
		damping_min = 60.0
		damping_max = 90.0
		scale_amount_min = 1.5
		scale_amount_max = 3.0
		z_index = 4
		emitting = true
		get_tree().create_timer(lifetime + 0.2, false).timeout.connect(queue_free)

## From Gorged on, arrows glow with souls and leave a particle trail.
class SoulTrail extends ArrowEffect:
	const TINT: Color = Color(1.25, 0.8, 1.5)
	var ability: MawAbility

	func apply_effect(_arrow: Arrow) -> void:
		if _arrow == null or ability == null or ability.stage() < Stage.GORGED:
			return
		_arrow.modulate = TINT
		var trail: CPUParticles2D = CPUParticles2D.new()
		trail.local_coords = false
		trail.amount = 14
		trail.lifetime = 0.35
		trail.gravity = Vector2(0, -20)
		trail.spread = 25.0
		trail.direction = Vector2.LEFT
		trail.initial_velocity_min = 5.0
		trail.initial_velocity_max = 15.0
		trail.scale_amount_min = 1.0
		trail.scale_amount_max = 2.0
		trail.color = Color(0.85, 0.45, 1.0, 0.8)
		_arrow.add_child(trail)
