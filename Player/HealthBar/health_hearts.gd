class_name HealthHearts extends Control

@export var heart_scene: PackedScene  # a Control with sibling children "HealthBar" and "GhostBar"

@export_group("Readability")
## HP number turns this color when you're on your last heart.
@export var low_hp_color: Color = Color(1.0, 0.3, 0.25)
@export var hp_color: Color = Color(0.95, 0.89, 0.75)
@export var heart_lost_color: Color = Color(1.0, 0.15, 0.1)
@export var heart_lost_text: String = "-1 MAX HEART"

@onready var hearts_container: FlowContainer = $FlowContainer
@onready var hp_label: Label = $HPLabel

var hearts: Array[HealthBar] = []
var max_hp: int = 0
var hp: int = 0

func init_health(_max_hp: int, _first_time: bool = true) -> void:
	if _first_time:
		max_hp = _max_hp
	else:
		max_hp = PlayerManager.player.initial_max_hp
	hp = max_hp
	_rebuild_hearts()
	_refresh_all()
	_update_label()


func reduce_health(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	var remaining: int = amount
	for i in range(hearts.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var taken: int = mini(hearts[i].health, remaining)
		if taken > 0:
			hearts[i].reduce_health(taken)
			remaining -= taken
	_update_label()


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	var remaining: int = amount
	for i in hearts.size():
		if remaining <= 0:
			break
		var heart_max: int = _heart_max_hp(i)
		var missing: int = heart_max - hearts[i].health
		var given: int = mini(missing, remaining)
		if given > 0:
			hearts[i].heal(given)
			remaining -= given
	_update_label()


func gain_heart_container(_heal: bool = false) -> void:
	max_hp += CustomVariables.HP_PER_HEART
	if not _heal:
		hp = mini(hp, max_hp)
	else:
		hp = max_hp
	_rebuild_hearts()
	_refresh_all()
	_update_label()


## Call this on a fall — permanently removes one heart container for the run.
func lose_heart_container() -> int:
	if hearts.is_empty():
		return max_hp
	_play_heart_lost(hearts.back().get_parent() as Control)
	max_hp = maxi(max_hp - CustomVariables.HP_PER_HEART, 0)
	hp = mini(hp, max_hp)
	_rebuild_hearts()
	_refresh_all()
	_update_label()
	return max_hp


func _rebuild_hearts() -> void:
	for heart in hearts:
		heart.get_parent().queue_free()
	hearts.clear()
	
	var heart_count: int = ceili(float(max_hp) / CustomVariables.HP_PER_HEART)
	for i in heart_count:
		var heart_instance: Control = heart_scene.instantiate()
		hearts_container.add_child(heart_instance)
		var bar: HealthBar = heart_instance.get_node("HealthBar")
		bar.init_health(CustomVariables.HP_PER_HEART)
		hearts.append(bar)

func _refresh_all() -> void:
	var remaining: int = hp
	for i in hearts.size():
		var heart_max: int = _heart_max_hp(i)
		var heart_hp: int = clampi(remaining, 0, heart_max)
		hearts[i].set_instant(heart_hp, heart_max)
		remaining -= heart_hp
		


func _heart_max_hp(index: int) -> int:
	var start: int = index * CustomVariables.HP_PER_HEART
	return clampi(max_hp - start, 0, CustomVariables.HP_PER_HEART)


func _update_label() -> void:
	hp_label.text = "%d / %d" % [hp, max_hp]
	hp_label.add_theme_color_override("font_color", low_hp_color if hp <= CustomVariables.HP_PER_HEART else hp_color)
	# Sit right after the bottom row of hearts (the first row; extra rows stack upward).
	var heart_width: float = _heart_width()
	var row_size: int = mini(hearts.size(), maxi(1, floori(hearts_container.size.x / heart_width)))
	hp_label.position.x = hearts_container.position.x + row_size * heart_width + 8.0
	hp_label.position.y = hearts_container.position.y + hearts_container.size.y - heart_width / 2.0 - hp_label.size.y / 2.0


func _heart_width() -> float:
	if not hearts.is_empty():
		return maxf((hearts[0].get_parent() as Control).custom_minimum_size.x, 1.0)
	return 64.0


## The heart a fall took cracks off: flashes red, swells, then drops away, with a rising label.
func _play_heart_lost(heart: Control) -> void:
	if heart == null:
		return
	var start: Vector2 = heart.global_position
	var copy: Control = heart_scene.instantiate()
	add_child(copy)
	copy.global_position = start
	copy.pivot_offset = copy.custom_minimum_size / 2.0
	(copy.get_node("HealthBar") as HealthBar).init_health(CustomVariables.HP_PER_HEART)
	copy.modulate = heart_lost_color
	var tween: Tween = copy.create_tween()
	tween.tween_property(copy, "scale", Vector2.ONE * 1.5, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.25)
	tween.set_parallel(true)
	tween.tween_property(copy, "global_position", start + Vector2(0.0, 60.0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(copy, "rotation", 0.6, 0.6)
	tween.tween_property(copy, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(copy.queue_free)

	var text: Label = Label.new()
	text.text = heart_lost_text
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_size_override("font_size", 32)
	text.add_theme_color_override("font_color", heart_lost_color)
	text.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.05))
	text.add_theme_constant_override("outline_size", 8)
	add_child(text)
	text.global_position = start + Vector2(0.0, -44.0)
	var text_tween: Tween = text.create_tween()
	text_tween.tween_property(text, "global_position:y", text.global_position.y - 40.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	text_tween.parallel().tween_property(text, "modulate:a", 0.0, 0.6).set_delay(1.0)
	text_tween.tween_callback(text.queue_free)

