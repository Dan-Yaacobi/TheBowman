class_name TwinFletchAbility extends PlayerPassiveAbility
## Power milestone. Every Nth arrow you fire is followed by a second arrow with the same power.
## The second arrow carries your on-hit effects but doesn't count toward streaks.

@export var every_nth: int = 10
## Gap between the two arrows, so they read as two shots.
@export var delay: float = 0.08

var _count: int = 0

func on_equipped() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if not main_hand.release.is_connected(_on_release):
		main_hand.release.connect(_on_release)

func on_unequipped() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if main_hand.release.is_connected(_on_release):
		main_hand.release.disconnect(_on_release)
	_count = 0

func _on_release() -> void:
	var player: Player = PlayerManager.player
	var main_hand: PlayerMainHand = player.main_hand
	# Same rule release_arrow() uses to decide whether the arrow was fired or dropped.
	var min_power: float = 0.99 if player.stats.only_perfect else main_hand.min_shot_power
	if main_hand.shot_power < min_power:
		return
	_count += 1
	if _count < every_nth:
		return
	_count = 0
	var timer: SceneTreeTimer = main_hand.get_tree().create_timer(delay, false)
	timer.timeout.connect(_fire_twin.bind(main_hand.hand_direction, main_hand.shot_power))

func _fire_twin(direction: Vector2, shot_power: float) -> void:
	var player: Player = PlayerManager.player
	if not is_instance_valid(player) or player.is_dead():
		return
	var main_hand: PlayerMainHand = player.main_hand
	var twin: Arrow = main_hand.fire_at(direction, shot_power, main_hand.arrow_position.global_position, main_hand.get_hit_abilities(), false)
	twin.regular_shot = false

func get_tooltip() -> String:
	return "Every %dth arrow fires a second arrow" % every_nth
