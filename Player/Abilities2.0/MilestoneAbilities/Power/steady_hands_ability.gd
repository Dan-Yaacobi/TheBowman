class_name SteadyHandsAbility extends PlayerPassiveAbility
## Power milestone. Each perfect shot that hits an enemy widens the perfect window a bit.
## A miss or a non-perfect release resets it.

const COUNTED_META: StringName = &"steady_hands_counted"
const BUFF_KEY: String = "milestone/steady_hands"

## Perfect window bonus per perfect hit (0.1 = +10%).
@export var bonus_per_stack: float = 0.1
@export var max_stacks: int = 5

var _stacks: int = 0

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if not player.main_hand.release.is_connected(_on_release):
		player.main_hand.release.connect(_on_release)
	if not EventBus.arrow_enemy_hit.is_connected(_on_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.connect(_on_arrow_enemy_hit)
	if not EventBus.arrow_missed.is_connected(_reset):
		EventBus.arrow_missed.connect(_reset)

func on_unequipped() -> void:
	var player: Player = PlayerManager.player
	if player.main_hand.release.is_connected(_on_release):
		player.main_hand.release.disconnect(_on_release)
	if EventBus.arrow_enemy_hit.is_connected(_on_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.disconnect(_on_arrow_enemy_hit)
	if EventBus.arrow_missed.is_connected(_reset):
		EventBus.arrow_missed.disconnect(_reset)
	_reset()

func _on_release() -> void:
	if PlayerManager.player.main_hand.shot_power < 1.0:
		_reset()

func _on_arrow_enemy_hit(perfect: bool, arrow: Arrow, _target: Enemy) -> void:
	# One stack per arrow, even when it pierces through several enemies.
	if not perfect or not is_instance_valid(arrow) or arrow.has_meta(COUNTED_META):
		return
	arrow.set_meta(COUNTED_META, true)
	_set_stacks(mini(_stacks + 1, max_stacks))

func _reset() -> void:
	_set_stacks(0)

func _set_stacks(count: int) -> void:
	_stacks = count
	var window: Stat = PlayerManager.player.stats.perfect_shot_window
	window.remove_buff_completly(BUFF_KEY.hash(), Stat.buff_type.MULTIPLICATIVE)
	if _stacks > 0:
		window.add_buff(BUFF_KEY.hash(), bonus_per_stack * _stacks, Stat.buff_type.MULTIPLICATIVE)

func get_tooltip() -> String:
	return "Each perfect hit widens your perfect window by %d%% (up to %d), until you miss" % [roundi(bonus_per_stack * 100.0), max_stacks]
