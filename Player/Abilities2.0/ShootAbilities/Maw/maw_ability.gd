class_name MawAbility extends PlayerAbility
## The Maw: a starving bow that grows by devouring the souls of enemies killed while it's equipped.
## Souls live on this ability (one per rolled bow), so unequipping and re-equipping keeps them.
##   Starving: weaker arrows.
##   Fed: perfect kills bite the nearest enemy.
##   Gorged: stronger arrows that trail souls; every perfect hit bites, kill or not.
##   Awakened: strongest arrows; a perfect hit on an enemy below the HP threshold bites
##             that enemy itself; bites devour enemies below the threshold (bosses take a
##             double bite instead). Every heal_every_kills kills heal the archer.
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
@export var souls_per_golem: int = 3
@export_group("Effects")
## Arrow damage change per stage (0.25 = +25%).
@export var stage_damage: Array[float] = [-0.3, 0.0, 0.25, 0.5]
## Bite: share of the killing hit dealt to the nearest enemy.
@export var bite_share: float = 0.5
@export var bite_radius: float = 200.0
## First stage where any perfect hit bites, not only perfect kills.
@export var bite_on_hit_stage: Stage = Stage.GORGED
## Devour: enemies below this share of their HP are devoured by a bite (Awakened).
@export var devour_threshold: float = 0.2
## Awakened: kills needed per heal, and how much each heal restores.
@export var heal_every_kills: int = 10
@export var kill_heal_amount: int = 1
@export_group("")

var souls: int = 0
## Awakened kills since the last heal.
var _kills_toward_heal: int = 0
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

## Kept for the BEFORE_HIT registration; everything happens on arrow_enemy_hit.
func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	pass

func _on_event_bus_enemy_died(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or enemy is FlyingTarget or enemy is GoldenApple:
		return
	var gain: int = souls_per_enemy
	var boss: Boss = enemy as Boss
	if boss:
		gain = souls_per_boss if boss.arena != null else souls_per_elite
	elif enemy is RockGolem:
		gain = souls_per_golem
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
	_count_kill_for_heal()

func _count_kill_for_heal() -> void:
	if _stage != Stage.AWAKENED or heal_every_kills <= 0:
		return
	_kills_toward_heal += 1
	if _kills_toward_heal < heal_every_kills:
		return
	_kills_toward_heal = 0
	var player: Player = PlayerManager.player
	if player.heal(kill_heal_amount):
		CombatTextSpawner.spawn(player.global_position + Vector2(0, -40), "The Maw feeds", STAGE_COLORS[Stage.AWAKENED])

## Bite: a perfect kill (from Gorged on, any perfect hit) lashes the nearest other enemy.
## Awakened bites devour anything under the HP threshold; bosses take a double bite instead.
func _on_event_bus_arrow_enemy_hit(perfect: bool, arrow: Arrow, target: Enemy) -> void:
	if _stage < Stage.FED or not perfect or not is_instance_valid(target):
		return
	if not target.is_dead and _stage < bite_on_hit_stage:
		return
	if not is_instance_valid(arrow) or not target.is_inside_tree():
		return
	var bite: int = maxi(1, roundi(arrow.hurt_box.damage * bite_share * power()))
	# Awakened: a weakened survivor gets bitten itself, even with no one else around.
	var victims: Array[Enemy] = []
	if _stage == Stage.AWAKENED and not target.is_dead and _can_devour(target):
		victims.append(target)
	else:
		victims = _nearest_others(target, 1)
	for victim: Enemy in victims:
		var color: Color = STAGE_COLORS[_stage]
		var damage: int = bite
		if _stage == Stage.AWAKENED and _can_devour(victim):
			if victim is Boss:
				damage *= 2
			else:
				damage = victim.current_hp + 1000
				CombatTextSpawner.spawn(victim.global_position + Vector2(0, -16), "Devoured", color)
		var jaws: MawBite = MawBite.new()
		jaws.global_position = victim.global_position + Vector2(0, -8)
		jaws.devour = damage > bite
		EventBus.summon_effect.emit(jaws)
		if victim != target:
			var link: ContagionBandAbility.ContagionLink = ContagionBandAbility.ContagionLink.new()
			link.from = target.global_position
			link.to = victim.global_position
			link.color = Color(color, 0.6)
			link.thickness = 2.0
			EventBus.summon_effect.emit(link)
		victim.take_damage(null, damage, null, color)

func _can_devour(victim: Enemy) -> bool:
	return float(victim.current_hp) <= float(victim.stats.max_hp) * devour_threshold

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
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Devours the souls of the slain and grows stronger.")
	lines.append("")
	lines.append("~ %s ~" % STAGE_NAMES[_stage].to_upper())
	if _stage < Stage.AWAKENED:
		lines.append("%d / %d souls to %s" % [souls, stage_thresholds[_stage], STAGE_NAMES[_stage + 1]])
	else:
		lines.append("%d souls, fully awakened" % souls)
	for stage_index: int in Stage.size():
		lines.append("")
		var marker: String = "> " if stage_index == _stage else ""
		var heading: String = "%s%s" % [marker, STAGE_NAMES[stage_index]]
		if stage_index > 0:
			heading += " (%d souls)" % _stage_threshold(stage_index)
		lines.append(heading)
		for part: String in _stage_parts(stage_index):
			lines.append("   - " + part)
	return "\n".join(lines)

## Souls needed to reach a stage (Starving = 0).
func _stage_threshold(stage_index: int) -> int:
	return 0 if stage_index == 0 else stage_thresholds[mini(stage_index - 1, stage_thresholds.size() - 1)]

## What a stage adds over the one before, with the current numbers
## (positive bonuses scaled like the ability itself).
func _stage_parts(stage_index: int) -> PackedStringArray:
	var damage: float = stage_damage[mini(stage_index, stage_damage.size() - 1)]
	if damage > 0.0:
		damage *= power()
	var parts: PackedStringArray = PackedStringArray()
	parts.append("%+d%% damage" % roundi(damage * 100.0) if not is_zero_approx(damage) else "normal damage")
	if stage_index == Stage.FED:
		parts.append("perfect kills bite the nearest enemy for %d%% of the hit" % roundi(bite_share * power() * 100.0))
	if stage_index == bite_on_hit_stage and stage_index > Stage.FED:
		parts.append("every perfect hit bites, kill or not")
	if stage_index == Stage.AWAKENED:
		parts.append("perfect hits on enemies under %d%% HP bite them, and bites devour them (bosses take a double bite)" % roundi(devour_threshold * 100.0))
		parts.append("every %d kills heal you for %d" % [heal_every_kills, kill_heal_amount])
	return parts

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

## The bite: the Maw's fleshy jaws gape over the victim and snap shut.
## Drawn in code to echo the bow: crimson gums, bone fangs, near-black outline.
class MawBite extends Node2D:
	const OPEN_TIME: float = 0.09
	const SNAP_TIME: float = 0.07
	const HOLD_TIME: float = 0.12
	const FADE_TIME: float = 0.18
	const WIDTH: float = 22.0
	const OUTLINE: Color = Color(0.08, 0.03, 0.04)
	const GUM: Color = Color(0.55, 0.1, 0.16)
	const GUM_LIGHT: Color = Color(0.8, 0.25, 0.3)
	const FANG: Color = Color(0.95, 0.9, 0.78)
	const FANG_SHADE: Color = Color(0.7, 0.62, 0.52)
	## Devour bites are bigger and splash harder.
	var devour: bool = false
	## 0 = closed, 1 = fully open
	var gape: float = 0.0

	func _ready() -> void:
		z_index = 6
		scale = Vector2.ONE * (1.35 if devour else 1.0)
		var tween: Tween = create_tween()
		tween.tween_property(self, "gape", 1.0, OPEN_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "gape", 0.0, SNAP_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(_on_snap)
		tween.tween_interval(HOLD_TIME)
		tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
		tween.tween_callback(queue_free)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _on_snap() -> void:
		EventBus.camera_shake.emit(1.5 if devour else 0.8, 10.0)
		var splash: CPUParticles2D = CPUParticles2D.new()
		splash.one_shot = true
		splash.explosiveness = 1.0
		splash.amount = 18 if devour else 10
		splash.lifetime = 0.4
		splash.spread = 180.0
		splash.gravity = Vector2(0, 260)
		splash.initial_velocity_min = 40.0
		splash.initial_velocity_max = 90.0
		splash.scale_amount_min = 1.0
		splash.scale_amount_max = 2.5
		splash.color = GUM_LIGHT
		splash.emitting = true
		add_child(splash)
		var pop: Tween = create_tween()
		pop.tween_property(self, "scale", scale * 1.2, 0.04)
		pop.tween_property(self, "scale", scale, 0.08)

	func _draw() -> void:
		var open: float = 4.0 + gape * 12.0
		_draw_jaw(-open, 1.0)
		_draw_jaw(open, -1.0)

	## One jaw: a curved gum with fangs pointing toward the middle.
	## side = 1 for the upper jaw (fangs point down), -1 for the lower.
	func _draw_jaw(y: float, side: float) -> void:
		var half: float = WIDTH / 2.0
		var curve: float = 5.0 * side
		var gum: PackedVector2Array = PackedVector2Array([
			Vector2(-half - 3.0, y - curve * 0.2),
			Vector2(-half * 0.5, y - curve * 0.9 - 4.0 * side),
			Vector2(half * 0.5, y - curve * 0.9 - 4.0 * side),
			Vector2(half + 3.0, y - curve * 0.2),
			Vector2(half * 0.5, y + 1.0 * side),
			Vector2(-half * 0.5, y + 1.0 * side),
		])
		var outline: PackedVector2Array = gum.duplicate()
		outline.append(gum[0])
		draw_colored_polygon(gum, GUM)
		draw_line(Vector2(-half * 0.6, y - curve * 0.6 - 1.5 * side), Vector2(half * 0.6, y - curve * 0.6 - 1.5 * side), GUM_LIGHT, 1.5)
		var fang_count: int = 5
		for i: int in fang_count:
			var t: float = (float(i) + 0.5) / float(fang_count)
			var x: float = lerpf(-half, half, t)
			var length: float = 7.0 if i == 0 or i == fang_count - 1 else 5.0
			var fang: PackedVector2Array = PackedVector2Array([
				Vector2(x - 2.0, y + 0.5 * side),
				Vector2(x + 2.0, y + 0.5 * side),
				Vector2(x, y + length * side),
			])
			draw_colored_polygon(fang, FANG)
			draw_line(Vector2(x + 1.0, y + 0.5 * side), Vector2(x, y + length * side), FANG_SHADE, 1.0)
			var fang_outline: PackedVector2Array = fang.duplicate()
			fang_outline.append(fang[0])
			draw_polyline(fang_outline, OUTLINE, 1.0)
		draw_polyline(outline, OUTLINE, 1.0)
