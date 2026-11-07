class_name DisenchantTable extends NPC
## Hub construct. Interacting with items in the run tally disenchants them one by one: each item
## is a rarity-colored spark rising off the slab while the table pulses, and its resources fly
## to the HUD and are paid when they land.
## Interacting again while it runs skips to the end. The game doesn't pause.
## With an empty tally, interacting shows lifetime progress toward the next milestone instead.
## The carved runes on the table light up one per milestone reached.

@export var table_sprite: Sprite2D
## Middle of the slab's top. Sparks rise from random points along it.
@export var spark_origin: Marker2D
@export var info_label: Label
## Centre of the carved runes on the sprite. One cover per rune is built here in code,
## left to right, darkening the runes not lit yet.
@export var runes_origin: Node2D

@export_group("Runes")
## Carved runes on the sprite. One lights per milestone reached (repeats count), until all are lit.
@export var rune_count: int = 4
## In the sprite's pixels (the covers are children of the scaled sprite).
@export var rune_spacing: float = 11.0
@export var rune_size: Vector2 = Vector2(6.0, 9.0)
## Covers an unreached rune, so it reads as dark carved stone.
@export var rune_unlit_color: Color = Color(0.22, 0.23, 0.26, 0.85)
## Flash when a rune lights up, fading out to reveal the glowing rune in the art.
@export var rune_flash_color: Color = Color(0.7, 1.0, 1.0, 0.9)

@export_group("Effect")
## Sparks spread this wide (world px) along the slab, centred on spark_origin.
@export var spark_width: float = 18.0
## The table brightens to this for a moment on each item.
@export var pulse_color: Color = Color(1.15, 1.2, 1.35, 1.0)
@export var pulse_duration: float = 0.12

@export_group("Timing")
## Pause before the first item.
@export var start_delay: float = 0.1
## Time between two items. The whole sequence is about count × this.
@export var break_interval: float = 0.18
## Flight time of resource icons to the HUD. Each item is paid when its icons land.
@export var fly_duration: float = 0.55
@export var info_duration: float = 2.2
## Longer, so the new bonus can be read.
@export var milestone_info_duration: float = 3.5

## Tallied items being broken, in tally order.
var _items: Array[Disenchanting.FoundItem] = []
## Rolled yield per item (Dictionary[CustomVariables.items, int]), null until it breaks.
var _rewards: Array = []
var _pulse_tween: Tween
## Items paid so far. Everything from here on is still owed to the player.
var _paid: int = 0
var _running: bool = false
var _sequence_tween: Tween
var _info_tween: Tween
var _runes: Array[Polygon2D] = []
var _rune_lit: Array[bool] = []
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
	_milestone_text = ""
	_items = Disenchanting.tally.duplicate()
	_rewards.clear()
	_rewards.resize(_items.size())

	# Parallel timeline: item i at t_i, paid when its icons land at t_i + fly_duration.
	_sequence_tween = create_tween().set_parallel(true)
	for i: int in _items.size():
		var break_time: float = start_delay + i * break_interval
		_sequence_tween.tween_callback(_break_item.bind(i)).set_delay(break_time)
		_sequence_tween.tween_callback(_pay_next).set_delay(break_time + fly_duration)
	_sequence_tween.chain().tween_callback(_finish)

func _break_item(index: int) -> void:
	var at: Vector2 = spark_origin.global_position + Vector2(randf_range(-0.5, 0.5) * spark_width, 0.0)
	var rewards: Dictionary[CustomVariables.items, int] = _get_rewards(index)
	for item: CustomVariables.items in rewards:
		EventBus.resource_flight_started.emit(item, rewards[item], at, fly_duration)
	_spawn_spark(at, CustomVariables.rarity_color(_items[index].rarity))
	_pulse_table()

func _get_rewards(index: int) -> Dictionary[CustomVariables.items, int]:
	if _rewards[index] == null:
		_rewards[index] = Disenchanting.roll_yield(_items[index])
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
	_items.clear()
	_rewards.clear()
	Disenchanting.finish_disenchanting()
	if _milestone_text != "":
		_show_info(_milestone_text, milestone_info_duration)
	else:
		_show_info(_progress_text(), info_duration)

## A few rarity-colored motes drifting up off the slab.
func _spawn_spark(at: Vector2, color: Color) -> void:
	var spark: CPUParticles2D = CPUParticles2D.new()
	spark.one_shot = true
	spark.emitting = false
	spark.amount = 6
	spark.lifetime = 0.6
	spark.explosiveness = 0.8
	spark.direction = Vector2.UP
	spark.spread = 25.0
	spark.gravity = Vector2(0.0, -20.0)
	spark.initial_velocity_min = 10.0
	spark.initial_velocity_max = 22.0
	spark.scale_amount_min = 1.0
	spark.scale_amount_max = 1.5
	var fade: Gradient = Gradient.new()
	fade.set_color(0, color)
	fade.set_color(1, Color(color, 0.0))
	spark.color_ramp = fade
	add_child(spark)
	spark.global_position = at
	spark.finished.connect(spark.queue_free)
	spark.emitting = true

## Brief brightening of the whole table.
func _pulse_table() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	table_sprite.modulate = pulse_color
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(table_sprite, "modulate", Color.WHITE, pulse_duration)

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
	return "Disenchanted %d / %d\nNext: %s" % [lifetime, Disenchanting.get_next_threshold(), next.get_description()]

func _on_event_bus_disenchant_milestone_reached(_level: int, milestone: DisenchantMilestone) -> void:
	_milestone_text = "Milestone reached!\n%s" % milestone.get_description()
	# Shown right away when skipping too; _finish() shows it again after a full sequence.
	if not _running:
		_show_info(_milestone_text, milestone_info_duration)
	_update_runes(true)

# --- Runes (visual growth) -----------------------------------------------

func _build_runes() -> void:
	var count: int = rune_count
	var start_x: float = -(count - 1) * rune_spacing / 2.0
	var half: Vector2 = rune_size / 2.0
	for i: int in count:
		var rune: Polygon2D = Polygon2D.new()
		rune.polygon = PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
		rune.position = Vector2(start_x + i * rune_spacing, 0.0)
		runes_origin.add_child(rune)
		_runes.append(rune)
		_rune_lit.append(false)
	_update_runes(false)

## Uncovers one rune per milestone reached. Newly lit runes flash.
func _update_runes(animate: bool) -> void:
	var level: int = Disenchanting.get_milestone_level()
	for i: int in _runes.size():
		var rune: Polygon2D = _runes[i]
		var lit: bool = i < level
		var target: Color = Color(rune_flash_color, 0.0) if lit else rune_unlit_color
		if animate and lit and not _rune_lit[i]:
			rune.color = rune_flash_color
			rune.scale = Vector2.ONE * 1.6
			var tween: Tween = rune.create_tween().set_parallel(true)
			tween.tween_property(rune, "color", target, 0.8)
			tween.tween_property(rune, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			rune.color = target
		_rune_lit[i] = lit
