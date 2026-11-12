class_name MawAbility extends PlayerAbility
## The Maw: a starving bow that grows by devouring the souls of enemies killed while it's equipped.
## Souls live on this ability (one per rolled bow), so unequipping and re-equipping keeps them.
##   Starving: weaker arrows.        Fed: perfect kills bite the nearest enemy.
##   Gorged: stronger arrows.        Awakened: perfect hits devour enemies below the HP threshold
##                                   (bosses take double damage from that hit instead).
## Precision scrolls scale the positive stage bonuses and the bite, not the Starving penalty.

enum Stage { STARVING, FED, GORGED, AWAKENED }
const STAGE_NAMES: Array[String] = ["Starving", "Fed", "Gorged", "Awakened"]
const STAGE_COLORS: Array[Color] = [Color(0.6, 0.6, 0.65), Color(0.75, 0.55, 1.0), Color(0.85, 0.4, 1.0), Color(1.0, 0.35, 0.75)]

@export_group("Souls")
## Souls needed to reach Fed, Gorged and Awakened. Placeholders: tune by playtesting.
@export var stage_thresholds: Array[int] = [20, 60, 150]
@export var souls_per_enemy: int = 1
@export var souls_per_elite: int = 5
@export var souls_per_boss: int = 15
@export_group("Effects")
## Arrow damage change per stage (0.25 = +25%).
@export var stage_damage: Array[float] = [-0.3, 0.0, 0.25, 0.5]
## Bite: share of the killing hit dealt to the nearest enemy.
@export var bite_share: float = 0.5
@export var bite_radius: float = 200.0
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
		CombatTextSpawner.spawn(player.global_position + Vector2(0, -40), "The Maw: " + STAGE_NAMES[_stage], STAGE_COLORS[_stage])
	_update_counter()

## Bite: a perfect kill lashes the nearest other enemy.
func _on_event_bus_arrow_enemy_hit(perfect: bool, arrow: Arrow, target: Enemy) -> void:
	if _stage < Stage.FED or not perfect or not is_instance_valid(target) or not target.is_dead:
		return
	if not is_instance_valid(arrow) or not target.is_inside_tree():
		return
	var victim: Enemy = _nearest_other(target)
	if victim == null:
		return
	var bite: int = maxi(1, roundi(arrow.hurt_box.damage * bite_share * power()))
	victim.take_damage(null, bite, null, STAGE_COLORS[_stage])
	var link: ContagionBandAbility.ContagionLink = ContagionBandAbility.ContagionLink.new()
	link.from = target.global_position
	link.to = victim.global_position
	link.color = STAGE_COLORS[_stage]
	EventBus.summon_effect.emit(link)

func _nearest_other(from: Enemy) -> Enemy:
	var best: Enemy = null
	var best_dist: float = INF
	for enemy: Enemy in MinorHitHelpers.enemies_in_radius(from.get_world_2d(), from.global_position, bite_radius):
		if enemy == from or enemy.is_dead:
			continue
		var dist: float = enemy.global_position.distance_squared_to(from.global_position)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best

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
	if is_instance_valid(_counter):
		_counter.show_souls(souls, STAGE_COLORS[_stage])

func get_tooltip() -> String:
	var next: String = ""
	if _stage < Stage.AWAKENED:
		next = ", next stage at %d" % stage_thresholds[_stage]
	return "Devours souls of the slain and grows stronger. %s (%d souls%s)" % [STAGE_NAMES[_stage], souls, next]

func get_tooltip_color() -> Color:
	return STAGE_COLORS[_stage]

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT

## Soul count above the archer, in the stage's color.
class SoulCounter extends Label:
	func _ready() -> void:
		position = Vector2(-20, -52)
		size = Vector2(40, 12)
		horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_theme_font_size_override("font_size", 8)
		add_theme_constant_override("outline_size", 2)
		add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		z_index = 5

	func show_souls(count: int, color: Color) -> void:
		text = str(count)
		add_theme_color_override("font_color", color)

## From Gorged on, arrows carry a faint soul tint.
class SoulTrail extends ArrowEffect:
	const TINT: Color = Color(1.0, 0.8, 1.2)
	var ability: MawAbility

	func apply_effect(_arrow: Arrow) -> void:
		if _arrow and ability and ability.stage() >= Stage.GORGED:
			_arrow.modulate = TINT
