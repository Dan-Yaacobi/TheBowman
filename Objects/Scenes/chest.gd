class_name Chest extends GameObject
## A reward chest. The player opens it with the interact key while standing next to it.
## The "Open" animation drives the lid, the light beam, the sparkles and calls drop_items().

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_area: Area2D = $InteractionArea
@onready var key_prompt: KeyBoardHelper = $KeyboardPressHelper

## Schematic drop chance (%). Negative = use Crafting.BASE_SCHEMATIC_CHANCE.
@export var schematic_chance_override: float = -1.0
@export var open_shake_strength: float = 1.5
@export var open_shake_fade: float = 20.0

var _player_in_range: bool = false
var _opened: bool = false

func _ready() -> void:
	super()
	key_prompt.set_up("E")
	key_prompt.hide()
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if _opened or not _player_in_range:
		return
	if event.is_action_pressed("Interact"):
		get_viewport().set_input_as_handled()
		open()

func open() -> void:
	if _opened:
		return
	_opened = true
	key_prompt.hide()
	interaction_area.set_deferred(&"monitoring", false)
	EventBus.camera_shake.emit(open_shake_strength, open_shake_fade)
	animation_player.play("Open")

## Called from the "Open" animation, on the frame the chest bursts with light.
func drop_items() -> void:
	EventBus.drop_item.emit(CustomVariables.items.COIN, global_position, 100, avg_coin_drop)
	EventBus.try_drop.emit(global_position, 100)
	Crafting.try_drop_schematic(global_position, schematic_chance_override)

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Player and not _opened:
		_player_in_range = true
		key_prompt.show()

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false
		key_prompt.hide()
