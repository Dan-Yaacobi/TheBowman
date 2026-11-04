class_name SecondSkinAbility extends PlayerPassiveAbility
## Health milestone. A shield bubble blocks one hit, then comes back after a while without taking damage.

## Seconds without taking damage before the bubble returns.
@export var recharge_time: float = 30.0

var _bubble: ShieldBubble

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if is_instance_valid(_bubble):
		return
	_bubble = ShieldBubble.new()
	_bubble.name = "SecondSkinBubble"
	_bubble.player = player
	_bubble.recharge_time = recharge_time
	player.add_child(_bubble)

func on_unequipped() -> void:
	if is_instance_valid(_bubble):
		_bubble.remove()
	_bubble = null

func get_tooltip() -> String:
	return "A shield blocks one hit, and returns after %ds without taking damage" % roundi(recharge_time)

## Owns the shield's state: gives the player a hit shield while up, draws the bubble,
## and restarts the recharge whenever the player takes damage.
class ShieldBubble extends Node2D:
	const BUBBLE_COLOR: Color = Color(0.65, 0.85, 1.0, 0.55)
	const RIM_COLOR: Color = Color(0.85, 0.95, 1.0, 0.9)
	const RADIUS: float = 15.0

	var player: Player
	var recharge_time: float = 30.0
	var _up: bool = false
	var _recharge: Timer

	func _ready() -> void:
		position = Vector2(-2, 2)
		z_index = 2
		_recharge = Timer.new()
		_recharge.one_shot = true
		_recharge.process_callback = Timer.TIMER_PROCESS_PHYSICS
		_recharge.timeout.connect(_raise)
		add_child(_recharge)
		player.shield_blocked.connect(_on_shield_blocked)
		player.took_hit.connect(_on_took_hit)
		_raise()

	## Takes the shield away cleanly before freeing.
	func remove() -> void:
		if _up:
			player.hit_shields = maxi(0, player.hit_shields - 1)
		_up = false
		queue_free()

	func _raise() -> void:
		if _up:
			return
		_up = true
		player.hit_shields += 1
		visible = true
		scale = Vector2(0.6, 0.6)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _on_shield_blocked() -> void:
		if not _up:
			return
		_up = false
		_recharge.start(recharge_time)
		var tween: Tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.12)
		tween.tween_callback(func() -> void:
			visible = false
			scale = Vector2.ONE)

	## Real damage while the shield is down pushes the recharge back.
	func _on_took_hit() -> void:
		if not _up:
			_recharge.start(recharge_time)

	func _process(_delta: float) -> void:
		if visible:
			queue_redraw()

	func _draw() -> void:
		var pulse: float = 0.85 + 0.15 * sin(Time.get_ticks_msec() / 250.0)
		draw_circle(Vector2.ZERO, RADIUS, Color(BUBBLE_COLOR, BUBBLE_COLOR.a * 0.35 * pulse))
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, Color(RIM_COLOR, RIM_COLOR.a * pulse), 1.0)
