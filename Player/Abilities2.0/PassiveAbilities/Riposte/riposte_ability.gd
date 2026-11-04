class_name RiposteAbility extends PlayerPassiveAbility
## A sword hit makes your next arrow within the window fully drawn and perfect.
## The bow glows while it's ready (the same charged-shot glow as Telegraphed Shot).

@export var window: float = 1.5

## True while the charged shot is ours, so we only ever clear our own charge.
var _armed: bool = false
var _token: int = 0

func on_equipped() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if not EventBus.sword_hit.is_connected(_on_sword_hit):
		EventBus.sword_hit.connect(_on_sword_hit)
	if not main_hand.release.is_connected(_on_release):
		main_hand.release.connect(_on_release)

func on_unequipped() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if EventBus.sword_hit.is_connected(_on_sword_hit):
		EventBus.sword_hit.disconnect(_on_sword_hit)
	if main_hand.release.is_connected(_on_release):
		main_hand.release.disconnect(_on_release)
	if _armed:
		main_hand.next_shot_perfect = false
	_armed = false

func _on_sword_hit(target: Node2D) -> void:
	if not target is Enemy:
		return
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if main_hand.next_shot_perfect and not _armed:
		return
	_armed = true
	main_hand.next_shot_perfect = true
	_token += 1
	main_hand.get_tree().create_timer(window * power(), false).timeout.connect(_on_window_done.bind(_token))

## The timer only guards the exit: a newer sword hit restarts the window.
func _on_window_done(token: int) -> void:
	if token != _token or not _armed:
		return
	_armed = false
	PlayerManager.player.main_hand.next_shot_perfect = false

func _on_release() -> void:
	_armed = false

func get_tooltip() -> String:
	return "A sword hit makes your next arrow within %.1fs perfect" % (window * power())

func get_tooltip_color() -> Color:
	return Color.SILVER

func get_type() -> TriggerType:
	return TriggerType.PASSIVE
