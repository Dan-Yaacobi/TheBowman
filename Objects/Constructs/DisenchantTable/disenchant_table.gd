class_name DisenchantTable extends NPC
## Hub construct. Interacting with items in the run tally lays them on the table and breaks them
## one by one; each item's resources fly to the HUD and are paid when they land.
## Interacting again while it runs skips to the end. The game doesn't pause.
## With an empty tally, interacting shows lifetime progress toward the next milestone instead.
## Runes on the table light up one per milestone reached (placeholder visuals).

## Placeholder look of a tallied item on the table (the tally only knows slot and rarity).
@export var slot_icons: Dictionary[EquipmentData.slots, Texture2D] = {}
## Where the first item sits. The rest fill rows to the right and upward.
@export var items_origin: Marker2D
@export var info_label: Label
## Runes are built here in code, one per milestone, left to right.
@export var runes_origin: Node2D

@export_group("Runes")
@export var rune_spacing: float = 6.0
@export var rune_size: float = 1.5
@export var rune_unlit_color: Color = Color(0.2, 0.16, 0.25, 1.0)
@export var rune_lit_color: Color = Color(0.75, 0.55, 1.0, 1.0)

@export_group("Layout")
@export var item_scale: float = 0.25
@export var columns: int = 6
@export var item_spacing: Vector2 = Vector2(9.0, -7.0)
## How much of the rarity color tints a placeholder icon.
@export_range(0.0, 1.0) var rarity_tint: float = 0.45

@export_group("Timing")
@export var appear_duration: float = 0.2
## Time between two items breaking. The whole sequence is about count × this.
@export var break_interval: float = 0.18
@export var break_duration: float = 0.15
## Flight time of resource icons to the HUD. Each item is paid when its icons land.
@export var fly_duration: float = 0.55
@export var info_duration: float = 2.2
## Longer, so the new bonus can be read.
@export var milestone_info_duration: float = 3.5

## Tallied items being broken, in tally order.
var _items: Array[Disenchanting.FoundItem] = []
## Rolled yield per item (Dictionary[CustomVariables.items, int]), null until it breaks.
## Rolled at break time against the lifetime count it will be paid at, so a milestone
## reached mid-sequence boosts exactly the items after it.
var _rewards: Array = []
var _sprites: Array[Sprite2D] = []
## Items paid so far. Everything from here on is still owed to the player.
var _paid: int = 0
var _running: bool = false
var _sequence_tween: Tween
var _info_tween: Tween
var _runes: Array[Polygon2D] = []
## Set when a milestone is reached during the sequence, so the end shows it instead of progress.
var _milestone_text: String = ""

func extra_ready_functions() -> void:
	info_label.modulate.a = 0.0
	_build_runes()
	EventBus.disenchant_milestone_reached.connect(_on_event_bus_disenchant_milestone_reached)

## Keeps the state machine in Interacted for one frame; _return_to_idle() hands control back.
func holds_interaction() -> bool:
	return true

func action(_index: int) -> void:
	if _running:
		_skip()
	elif Disenchanting.get_count() > 0:
		_start()
	else:
		_show_info(_progress_text(), info_duration)
	# Back to Idle right away, so the next interact press (skip) reaches action() again.
	_return_to_idle.call_deferred()

func _return_to_idle() -> void:
	if npc_state_machine.curr_state is NPCInteractedState:
		npc_state_machine.ChangeState($NpcStateMachine/Idle)

## Leaving mid-sequence (scene change) pays out everything still owed.
func _exit_tree() -> void:
	if _running:
		_skip()

# --- Sequence -------------------------------------------------------------

func _start() -> void:
	_running = true
	_paid = 0
	# The items cover the prompt; it comes back when the table is clear.
	keyboard_press_helper.hide()
	_milestone_text = ""
	_items = Disenchanting.tally.duplicate()
	_rewards.clear()
	_rewards.resize(_items.size())
	_lay_out_items()

	# Parallel timeline: break i at t_i, pay i when its icons land at t_i + fly_duration.
	_sequence_tween = create_tween().set_parallel(true)
	for i: int in _items.size():
		var break_time: float = appear_duration + i * break_interval
		_sequence_tween.tween_callback(_break_item.bind(i)).set_delay(break_time)
		_sequence_tween.tween_callback(_pay_next).set_delay(break_time + fly_duration)
	_sequence_tween.chain().tween_callback(_finish)

func _lay_out_items() -> void:
	for i: int in _items.size():
		var item: Disenchanting.FoundItem = _items[i]
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = slot_icons.get(item.slot)
		sprite.modulate = Color.WHITE.lerp(CustomVariables.rarity_color(item.rarity), rarity_tint)
		@warning_ignore("integer_division")
		var row: int = i / columns
		sprite.position = Vector2((i % columns) * item_spacing.x, row * item_spacing.y)
		sprite.scale = Vector2.ZERO
		items_origin.add_child(sprite)
		_sprites.append(sprite)
		var tween: Tween = sprite.create_tween()
		tween.tween_property(sprite, "scale", Vector2.ONE * item_scale, appear_duration) \
			.set_delay(i * 0.02).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _break_item(index: int) -> void:
	var sprite: Sprite2D = _sprites[index]
	if not is_instance_valid(sprite):
		return
	var rewards: Dictionary[CustomVariables.items, int] = _get_rewards(index)
	for item: CustomVariables.items in rewards:
		EventBus.resource_flight_started.emit(item, rewards[item], sprite.global_position, fly_duration)
	_spawn_break_burst(sprite.global_position, CustomVariables.rarity_color(_items[index].rarity))
	var tween: Tween = sprite.create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ONE * item_scale * 1.6, break_duration)
	tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0, 0.0), break_duration)
	tween.chain().tween_callback(sprite.queue_free)

func _get_rewards(index: int) -> Dictionary[CustomVariables.items, int]:
	if _rewards[index] == null:
		_rewards[index] = Disenchanting.roll_yield(_items[index], index - _paid)
	return _rewards[index]

func _pay_next() -> void:
	if _paid >= _items.size():
		return
	Disenchanting.claim_next(_get_rewards(_paid))
	_paid += 1

## Pays everything still owed at once and clears the table.
func _skip() -> void:
	if _sequence_tween:
		_sequence_tween.kill()
	while _paid < _items.size():
		_pay_next()
	_finish()

func _finish() -> void:
	if not _running:
		return
	_running = false
	for sprite: Sprite2D in _sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_sprites.clear()
	_items.clear()
	_rewards.clear()
	keyboard_press_helper.show()
	Disenchanting.finish_disenchanting()
	if _milestone_text != "":
		_show_info(_milestone_text, milestone_info_duration)
	else:
		_show_info(_progress_text(), info_duration)

## Placeholder burst: a one-shot puff of rarity-colored pixels.
func _spawn_break_burst(at: Vector2, color: Color) -> void:
	var burst: CPUParticles2D = CPUParticles2D.new()
	burst.one_shot = true
	burst.emitting = false
	burst.amount = 10
	burst.lifetime = 0.35
	burst.explosiveness = 1.0
	burst.direction = Vector2.UP
	burst.spread = 180.0
	burst.gravity = Vector2(0.0, 200.0)
	burst.initial_velocity_min = 30.0
	burst.initial_velocity_max = 60.0
	burst.scale_amount_min = 1.0
	burst.scale_amount_max = 2.0
	burst.color = color
	add_child(burst)
	burst.global_position = at
	burst.finished.connect(burst.queue_free)
	burst.emitting = true

# --- Info -----------------------------------------------------------------

func _show_info(text: String, duration: float) -> void:
	info_label.text = text
	if _info_tween:
		_info_tween.kill()
	_info_tween = create_tween()
	_info_tween.tween_property(info_label, "modulate:a", 1.0, 0.15)
	_info_tween.tween_property(info_label, "modulate:a", 0.0, 0.3).set_delay(duration)

## e.g. "Disenchanted 23 / 25\nNext: +5% Skyshard chance from legendaries".
func _progress_text() -> String:
	var lifetime: int = Disenchanting.lifetime_disenchanted
	var next: DisenchantMilestone = Disenchanting.get_next_milestone()
	if next == null:
		return "Disenchanted %d\nAll milestones reached" % lifetime
	return "Disenchanted %d / %d\nNext: %s" % [lifetime, next.threshold, next.get_description()]

func _on_event_bus_disenchant_milestone_reached(level: int) -> void:
	var milestones: Array[DisenchantMilestone] = Disenchanting.get_milestones()
	if level > 0 and level <= milestones.size():
		_milestone_text = "Milestone reached!\n%s" % milestones[level - 1].get_description()
		# Shown right away when skipping too; _finish() shows it again after a full sequence.
		if not _running:
			_show_info(_milestone_text, milestone_info_duration)
	_update_runes(true)

# --- Runes (placeholder visual growth) ------------------------------------

func _build_runes() -> void:
	var count: int = Disenchanting.get_milestones().size()
	var start_x: float = -(count - 1) * rune_spacing / 2.0
	var r: float = rune_size
	for i: int in count:
		var rune: Polygon2D = Polygon2D.new()
		rune.polygon = PackedVector2Array([Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)])
		rune.position = Vector2(start_x + i * rune_spacing, 0.0)
		runes_origin.add_child(rune)
		_runes.append(rune)
	_update_runes(false)

## Lights one rune per milestone reached. Newly lit runes flash.
func _update_runes(animate: bool) -> void:
	var level: int = Disenchanting.get_milestone_level()
	for i: int in _runes.size():
		var rune: Polygon2D = _runes[i]
		var lit: bool = i < level
		var target: Color = rune_lit_color if lit else rune_unlit_color
		if animate and lit and rune.color != rune_lit_color:
			rune.color = Color(3.0, 3.0, 3.0, 1.0)
			rune.scale = Vector2.ONE * 2.0
			var tween: Tween = rune.create_tween().set_parallel(true)
			tween.tween_property(rune, "color", target, 0.6)
			tween.tween_property(rune, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			rune.color = target
