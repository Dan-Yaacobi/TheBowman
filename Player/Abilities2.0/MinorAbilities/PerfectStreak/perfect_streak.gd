class_name PerfectStreakMinor extends MinorAbility
## After 3 perfect shots in a row your next arrow explodes on hit (the Explode on Kill explosion).
## Streak pips above the archer show progress. value = explosion damage.

const EXPLOSION_PATH: String = "res://Player/Abilities2.0/MinorAbilities/ExplodeOnKill/Explosion.tscn"
const EXPLOSIVE_META: StringName = &"perfect_streak_explosive"

@export var streak_needed: int = 3

var _streak: int = 0
var _pips: StreakPips

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if not player.main_hand.release.is_connected(_on_release):
		player.main_hand.release.connect(_on_release)
	if not is_instance_valid(_pips):
		_pips = StreakPips.new()
		_pips.needed = streak_needed
		player.add_child(_pips)

func on_unequipped() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if main_hand.release.is_connected(_on_release):
		main_hand.release.disconnect(_on_release)
	if is_instance_valid(_pips):
		_pips.queue_free()

func _on_release() -> void:
	var player: Player = PlayerManager.player
	if _streak >= streak_needed:
		if is_instance_valid(player.current_arrow):
			player.current_arrow.set_meta(EXPLOSIVE_META, true)
		_streak = 0
	elif player.main_hand.shot_power >= 1.0:
		_streak += 1
	else:
		_streak = 0
	_pips.set_count(_streak)

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var arrow: Arrow = MinorHitHelpers.arrow_of(_activator)
	if arrow == null or not arrow.has_meta(EXPLOSIVE_META) or _target == null:
		return
	arrow.remove_meta(EXPLOSIVE_META)
	var explosion: Explosion = load(EXPLOSION_PATH).instantiate()
	explosion.global_position = _target.global_position
	explosion.set_damage(roundi(value * power()))
	EventBus.summon_effect.emit(explosion)

func get_tooltip() -> String:
	return "After %d perfect shots in a row, your next arrow explodes for %d damage" % [streak_needed, value]

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
