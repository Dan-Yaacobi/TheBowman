class_name LoreItemPickup extends Item
## A hand-placed lore item. Grants its LoreItemData once, ever: if it was already found,
## it removes itself on load. The flavor line is shown by the HUD (EventBus.lore_item_found).

@export var lore_item: LoreItemData
@export var bob_speed: float = 2.0
@export var bob_height: float = 3.0
@export_group("Claim")
@export var rise_height: float = 16.0
@export var claim_duration: float = 0.4
@export_group("")

@onready var sprite: Sprite2D = $Sprite2D

var _bob_time: float = 0.0
var _claimed: bool = false

func extra_ready_functions() -> void:
	if lore_item == null:
		push_warning("LoreItemPickup '%s' has no lore_item" % name)
		queue_free()
		return
	if Lore.has_found(lore_item.id):
		queue_free()
		return
	if lore_item.icon:
		sprite.texture = lore_item.icon
	# Placed by hand, so it's already resting where it belongs.
	_landed = true

func extra_process_functions(delta: float) -> void:
	if _claimed:
		return
	_bob_time += delta
	position.y += sin(_bob_time * bob_speed) * bob_height * delta

## Rare and placed on purpose, so it never despawns.
func initiate_despawn() -> void:
	pass

## Saved right away, so dying mid-animation can't lose it. The rest is visual.
func _collect() -> void:
	if _claimed:
		return
	_claimed = true
	if Lore.add(lore_item):
		EventBus.lore_item_found.emit(lore_item)
	lifetime_timer.stop()
	_magnetized = false
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - rise_height, claim_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, claim_duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
