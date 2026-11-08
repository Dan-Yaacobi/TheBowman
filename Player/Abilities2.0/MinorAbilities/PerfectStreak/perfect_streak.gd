class_name PerfectStreakMinor extends MinorAbility
## After 3 perfect shots in a row that hit an enemy, your next arrow explodes on hit (the Explode on Kill explosion).
## A missed or non-perfect shot breaks the streak. Once full, the charge is only spent when an armed arrow
## actually hits: armed arrows that miss leave it ready for the next shot.
## Streak pips above the archer show progress. value = explosion damage.

const EXPLOSION_PATH: String = "res://Player/Abilities2.0/MinorAbilities/ExplodeOnKill/Explosion.tscn"
const EXPLOSIVE_META: StringName = &"perfect_streak_explosive"
const COUNTED_META: StringName = &"perfect_streak_counted"

@export var streak_needed: int = 3

var _streak: int = 0
var _pips: StreakPips
## The arrow carrying the charge while it's in flight. Only one at a time.
var _armed_arrow: Arrow

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if not player.main_hand.release.is_connected(_on_release):
		player.main_hand.release.connect(_on_release)
	if not EventBus.arrow_enemy_hit.is_connected(_on_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.connect(_on_arrow_enemy_hit)
	if not EventBus.arrow_missed.is_connected(_on_arrow_missed):
		EventBus.arrow_missed.connect(_on_arrow_missed)
	if not is_instance_valid(_pips):
		_pips = StreakPips.new()
		_pips.needed = streak_needed
		player.add_child(_pips)

func on_unequipped() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if main_hand.release.is_connected(_on_release):
		main_hand.release.disconnect(_on_release)
	if EventBus.arrow_enemy_hit.is_connected(_on_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.disconnect(_on_arrow_enemy_hit)
	if EventBus.arrow_missed.is_connected(_on_arrow_missed):
		EventBus.arrow_missed.disconnect(_on_arrow_missed)
	if is_instance_valid(_pips):
		_pips.queue_free()

## Arms the arrow once the streak is full. Perfect releases don't count yet: only their hits do.
func _on_release() -> void:
	var player: Player = PlayerManager.player
	if _streak >= streak_needed:
		if not is_instance_valid(_armed_arrow) and is_instance_valid(player.current_arrow):
			_armed_arrow = player.current_arrow
			_armed_arrow.set_meta(EXPLOSIVE_META, true)
	elif player.main_hand.shot_power < 1.0:
		_set_streak(0)

func _on_arrow_enemy_hit(perfect: bool, arrow: Arrow, _target: Enemy) -> void:
	# One count per arrow (piercing arrows hit several times); the explosive arrow itself never counts.
	if not perfect or not is_instance_valid(arrow) or arrow.has_meta(EXPLOSIVE_META) or arrow.has_meta(COUNTED_META):
		return
	arrow.set_meta(COUNTED_META, true)
	_set_streak(mini(_streak + 1, streak_needed))

func _on_arrow_missed() -> void:
	if _streak < streak_needed:
		_set_streak(0)

func _set_streak(count: int) -> void:
	_streak = count
	if is_instance_valid(_pips):
		_pips.set_count(_streak)

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var arrow: Arrow = MinorHitHelpers.arrow_of(_activator)
	if arrow == null or not arrow.has_meta(EXPLOSIVE_META) or _target == null:
		return
	arrow.remove_meta(EXPLOSIVE_META)
	_armed_arrow = null
	_set_streak(0)
	var explosion: Explosion = load(EXPLOSION_PATH).instantiate()
	explosion.global_position = _target.global_position
	explosion.set_damage(roundi(value * power()))
	EventBus.summon_effect.emit(explosion)

func get_tooltip() -> String:
	return "After %d perfect hits in a row, your next arrow explodes for %d damage" % [streak_needed, roundi(value * power())]

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT

func get_tooltip_color() -> Color:
	return Color.ORANGE

## Streak progress above the archer: one pip per perfect shot, glowing when the next arrow is explosive.
class StreakPips extends Node2D:
	var needed: int = 3
	var count: int = 0

	func _ready() -> void:
		position = Vector2(0, -34)
		z_index = 5
		visible = false

	func set_count(_count: int) -> void:
		count = _count
		visible = count > 0
		queue_redraw()

	func _draw() -> void:
		var full: bool = count >= needed
		var spacing: float = 4.0
		var start_x: float = -(needed - 1) * spacing / 2.0
		for i in needed:
			var color: Color = Color(1.0, 0.6, 0.15) if full else (Color(1.0, 0.9, 0.5) if i < count else Color(0.15, 0.12, 0.08, 0.6))
			draw_rect(Rect2(start_x + i * spacing - 1.5, -1.5, 3.0, 3.0), color)
