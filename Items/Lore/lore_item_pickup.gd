class_name LoreItemPickup extends Item
## A hand-placed lore item. Grants its LoreItemData once, ever. Removes itself on load if the
## item was already found or its requirement (campaign progress) isn't met yet.
## Never auto-collected: in range, Interact asks the HUD to show the item
## (EventBus.lore_item_inspected); it's claimed once the player confirms the pickup there
## (EventBus.lore_item_pickup_confirmed).

@export var lore_item: LoreItemData
@export var bob_speed: float = 2.0
@export var bob_height: float = 3.0
## Degrees per second the sprite turns around its vertical axis (a coin-like turn, so the
## pixels stay crisp). 0 = still.
@export var spin_speed: float = 0.0
@export_group("Claim")
@export var rise_height: float = 16.0
@export var claim_duration: float = 0.4
@export_group("")

@onready var sprite: Sprite2D = $Sprite2D
@onready var key_prompt: KeyBoardHelper = $KeyboardPressHelper

var _bob_time: float = 0.0
var _claimed: bool = false
var _in_range: bool = false
var _base_scale_x: float = 1.0

func extra_ready_functions() -> void:
	key_prompt.set_up("E")
	key_prompt.hide()
	if lore_item == null:
		push_warning("LoreItemPickup '%s' has no lore_item" % name)
		queue_free()
		return
	if not Lore.can_obtain(lore_item):
		queue_free()
		return
	if lore_item.icon:
		sprite.texture = lore_item.icon
	_base_scale_x = sprite.scale.x
	EventBus.lore_item_pickup_confirmed.connect(_on_event_bus_lore_item_pickup_confirmed)
	# Placed by hand, so it's already resting where it belongs.
	_landed = true

func extra_process_functions(delta: float) -> void:
	if _claimed:
		return
	_bob_time += delta
	position.y += sin(_bob_time * bob_speed) * bob_height * delta
	if spin_speed != 0.0:
		sprite.scale.x = _base_scale_x * cos(deg_to_rad(_bob_time * spin_speed))

func _unhandled_input(event: InputEvent) -> void:
	if _claimed or not _in_range or get_tree().paused:
		return
	if event.is_action_pressed("Interact"):
		get_viewport().set_input_as_handled()
		EventBus.lore_item_inspected.emit(lore_item)

## Rare and placed on purpose, so it never despawns.
func initiate_despawn() -> void:
	pass

## Saved right away, so dying mid-animation can't lose it. The rest is visual.
func _collect() -> void:
	if _claimed:
		return
	_claimed = true
	key_prompt.hide()
	play_collected_sound()
	if Lore.add(lore_item):
		EventBus.lore_item_found.emit(lore_item)
	lifetime_timer.stop()
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - rise_height, claim_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, claim_duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

## The magnet area is the interaction range here; nothing is pulled in.
func _on_magnet_area_body_entered(body: Node2D) -> void:
	if body == _player and not _claimed:
		_in_range = true
		key_prompt.show()

func _on_magnet_area_body_exited(body: Node2D) -> void:
	if body == _player:
		_in_range = false
		key_prompt.hide()

func _on_event_bus_lore_item_pickup_confirmed(item: LoreItemData) -> void:
	if item == lore_item and is_inside_tree():
		_collect()
