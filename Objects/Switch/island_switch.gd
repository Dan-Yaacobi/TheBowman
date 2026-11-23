class_name IslandSwitch extends Node2D
## A switch islands listen to (Island.switches). Turned on by an arrow, a sword hit and/or the
## interact key, each allowed separately. Placeholder art: a light post, dim when off.

signal switched(on: bool)

@export var by_arrow: bool = true
@export var by_sword: bool = true
## Interact key while standing next to it (shows the E prompt).
@export var by_interact: bool = false
## On: once on it stays on. Off: every activation flips it.
@export var stays_on: bool = true
@export var starts_on: bool = false
@export var on_color: Color = Color(1.0, 0.95, 0.6)
@export var off_color: Color = Color(0.45, 0.45, 0.5)
## Ignores activations this soon after the last one (one sword swing hits more than once).
@export var cooldown: float = 0.3

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: HitBox = $HitBox
@onready var interaction_area: Area2D = $InteractionArea
@onready var key_prompt: KeyBoardHelper = $KeyboardPressHelper

var is_on: bool = false
var _player_in_range: bool = false
var _cooldown_left: float = 0.0


func _ready() -> void:
	is_on = starts_on
	_show_state()
	key_prompt.set_up("E")
	key_prompt.hide()
	hit_box.Damaged.connect(_on_hit_box_damaged)
	hit_box.monitorable = by_arrow or by_sword
	interaction_area.monitoring = by_interact
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)


func _process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if by_interact and _player_in_range and event.is_action_pressed("Interact"):
		get_viewport().set_input_as_handled()
		activate()


func activate() -> void:
	if _cooldown_left > 0.0 or (stays_on and is_on):
		return
	_cooldown_left = cooldown
	is_on = true if stays_on else not is_on
	_show_state()
	EventBus.camera_shake.emit(1.0, 20.0)
	switched.emit(is_on)
	if stays_on:
		key_prompt.hide()


func _show_state() -> void:
	sprite.modulate = on_color if is_on else off_color


## Arrows are hurt boxes on an Arrow; the sword's is part of the player.
func _on_hit_box_damaged(hurt_box: HurtBox, _raw_damage: int = 0, _result: DamageResult = null) -> void:
	if hurt_box == null:
		return
	var from_arrow: bool = hurt_box.get_parent() is Arrow
	var from_sword: bool = not from_arrow and PlayerManager.player != null \
		and PlayerManager.player.is_ancestor_of(hurt_box)
	if (from_arrow and by_arrow) or (from_sword and by_sword):
		activate()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = true
		if not (stays_on and is_on):
			key_prompt.show()


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false
		key_prompt.hide()
