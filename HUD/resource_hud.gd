class_name ResourceHud extends Control

@onready var coin: ItemHud = $HBoxContainer5/Coin
@onready var wood: ItemHud = $HBoxContainer5/Wood
@onready var essence: ItemHud = $HBoxContainer5/Essence
@onready var sky_shard: ItemHud = $HBoxContainer5/SkyShard
## Run tally for the disenchanting table. Hidden until the table is built.
@onready var found_items: ItemHud = $HBoxContainer5/FoundItems

@export_group("Flying icons")
## At most this many icons fly per reward, however big the amount.
@export var max_flying_icons: int = 3
@export var flying_icon_size: Vector2 = Vector2(18, 18)
## Icons start this small at the source and grow to full size during the burst.
@export var flying_start_scale: float = 0.4
## Icons first burst outward this far (screen px), then home in on the counter.
@export var burst_radius: float = 40.0
## Share of the flight spent bursting out.
@export_range(0.0, 0.9) var burst_share: float = 0.3

@onready var _huds: Dictionary[CustomVariables.items, ItemHud] = {
	CustomVariables.items.COIN: coin,
	CustomVariables.items.WOOD: wood,
	CustomVariables.items.ESSENCE: essence,
	CustomVariables.items.SKYSHARD: sky_shard,
}
func _ready() -> void:
	EventBus.found_items_changed.connect(_on_event_bus_found_items_changed)
	EventBus.resource_flight_started.connect(_on_event_bus_resource_flight_started)
	_refresh_all.call_deferred()

func _refresh_all() -> void:
	var items: Dictionary = PlayerManager.player.stats.items
	for item: CustomVariables.items in _huds:
		update_amount(int(items.get(item, 0)), item, false)
	_update_found_items(Disenchanting.get_count(), false)
		
## Pass animate = false when filling in saved values on load.
func update_amount(amount: int, item: CustomVariables.items, animate: bool = true) -> void:
	var hud: ItemHud = _huds.get(item)
	if hud == null:
		push_warning("ResourceHud has no ItemHud for item %s" % item)
		return
	hud.set_amount(amount, animate)

func _on_event_bus_found_items_changed(count: int) -> void:
	_update_found_items(count, true)

func _update_found_items(count: int, animate: bool) -> void:
	found_items.visible = Disenchanting.is_active()
	found_items.set_amount(count, animate and found_items.visible)

# --- Flying icons ---------------------------------------------------------

func _on_event_bus_resource_flight_started(item: CustomVariables.items, amount: int, from_world: Vector2, duration: float) -> void:
	var hud: ItemHud = _huds.get(item)
	if hud == null or amount <= 0:
		return
	var start: Vector2 = get_viewport().get_canvas_transform() * from_world
	for i: int in mini(amount, max_flying_icons):
		_fly_icon(hud, start, duration)

func _fly_icon(hud: ItemHud, start: Vector2, duration: float) -> void:
	var icon: TextureRect = TextureRect.new()
	icon.texture = hud.texture
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# top_level: screen coordinates, without this HUD's scale.
	icon.top_level = true
	icon.size = flying_icon_size
	icon.pivot_offset = flying_icon_size / 2.0
	add_child(icon)
	var half: Vector2 = flying_icon_size / 2.0
	icon.position = start - half
	icon.scale = Vector2.ONE * flying_start_scale
	var burst_to: Vector2 = start + Vector2.from_angle(randf() * TAU) * randf_range(0.4, 1.0) * burst_radius - half

	var tween: Tween = icon.create_tween()
	tween.tween_property(icon, "position", burst_to, duration * burst_share) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(icon, "scale", Vector2.ONE, duration * burst_share)
	# The counter's position is read when homing starts, so it stays right if the HUD moves.
	tween.tween_method(_home_icon.bind(icon, hud), 0.0, 1.0, duration * (1.0 - burst_share)) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(icon.queue_free)

## Moves from where the burst ended to the counter's icon, shrinking slightly on the way.
func _home_icon(t: float, icon: TextureRect, hud: ItemHud) -> void:
	if not icon.has_meta(&"from"):
		icon.set_meta(&"from", icon.position)
	var from: Vector2 = icon.get_meta(&"from")
	# Through the global transform, so the HUD's scale is included (get_global_rect ignores it).
	var target_center: Vector2 = hud.texture_rect.get_global_transform() * (hud.texture_rect.size / 2.0)
	var target: Vector2 = target_center - icon.size / 2.0
	icon.position = from.lerp(target, t)
	icon.scale = Vector2.ONE * lerpf(1.0, 0.7, t)

