class_name ConstructSite extends Node2D
## A hub construct that has to be built before it works.
## Unbuilt: the construct shows as a faint ghost and is fully disabled. While the player can
## afford it, the ghost pulses with a warm glow; re-checked on every resource change.
## Built: the construct becomes solid and active. Saved through MetaProgress.

signal built

## Saved in the save file. Never rename once players have saves.
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var cost: Dictionary[CustomVariables.items, int] = {}

@export var construct: CanvasItem
## The floating window (its own scene, as a child of this site).
@export var build_prompt: BuildPrompt
## Shows the build prompt while the player is inside it.
@export var proximity_area: Area2D

@export_group("Look")
@export var ghost_color: Color = Color(0.7, 0.85, 1.0, 0.35)
@export var build_duration: float = 0.6
## Peak tint of the "you can build this" pulse (values above 1 brighten).
@export var affordable_glow_color: Color = Color(1.6, 1.4, 0.8, 0.8)
## Seconds for one fade in or out of the pulse.
@export var affordable_pulse_time: float = 0.7

var _player_near: bool = false
var _glow_tween: Tween
var _glowing: bool = false

func _ready() -> void:
	build_prompt.setup(self)
	if MetaProgress.is_built(id):
		_set_built(false)
		return
	_set_ghost()
	proximity_area.body_entered.connect(_on_body_entered)
	proximity_area.body_exited.connect(_on_body_exited)
	PlayerManager.player.item_amount_changed.connect(_on_player_item_amount_changed)
	_update_glow()

## Called by the build prompt's button. Returns true if it was built.
func try_build() -> bool:
	if not MetaProgress.build(id, cost, PlayerManager.player):
		return false
	_set_built(true)
	built.emit()
	return true

func can_afford() -> bool:
	return MetaProgress.can_pay(cost, PlayerManager.player.stats)

func _set_ghost() -> void:
	construct.modulate = ghost_color
	construct.process_mode = Node.PROCESS_MODE_DISABLED

func _set_built(animate: bool) -> void:
	_stop_glow()
	var player: Player = PlayerManager.player
	if player and player.item_amount_changed.is_connected(_on_player_item_amount_changed):
		player.item_amount_changed.disconnect(_on_player_item_amount_changed)
	construct.process_mode = Node.PROCESS_MODE_INHERIT
	if animate:
		build_prompt.close()
	else:
		build_prompt.hide()
	proximity_area.set_deferred(&"monitoring", false)
	if animate:
		var tween: Tween = create_tween()
		tween.tween_property(construct, "modulate", Color.WHITE, build_duration)
	else:
		construct.modulate = Color.WHITE

func _update_glow() -> void:
	var should_glow: bool = can_afford()
	if should_glow == _glowing:
		return
	if should_glow:
		_start_glow()
	else:
		_stop_glow()
		construct.modulate = ghost_color

func _start_glow() -> void:
	_glowing = true
	if _glow_tween:
		_glow_tween.kill()
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(construct, "modulate", affordable_glow_color, affordable_pulse_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_property(construct, "modulate", ghost_color, affordable_pulse_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_glow() -> void:
	_glowing = false
	if _glow_tween:
		_glow_tween.kill()
		_glow_tween = null

func _on_player_item_amount_changed(_amount: int, _item: CustomVariables.items) -> void:
	_update_glow()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_near = true
		build_prompt.open()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_near = false
		build_prompt.close()
