class_name UpgradeRow extends PanelContainer
## One upgrade track in the altar menu: name, level, what the next level gives,
## its cost, and the upgrade button. Keeps itself up to date.

## Icon for each resource, shown next to the cost amounts.
@export var item_icons: Dictionary[CustomVariables.items, Texture2D] = {}
@export var icon_size: Vector2 = Vector2(32, 32)
## Cost amounts the player can't afford are tinted this color.
@export var cant_afford_color: Color = Color(0.85, 0.35, 0.3)

@onready var name_label: Label = $HBoxContainer/Info/NameLabel
@onready var level_label: Label = $HBoxContainer/Info/LevelLabel
@onready var effect_label: Label = $HBoxContainer/EffectLabel
@onready var cost_box: HBoxContainer = $HBoxContainer/CostBox
@onready var upgrade_button: Button = $HBoxContainer/UpgradeButton

var track: UpgradeTrack

## Call before or after adding the row to the tree.
func setup(_track: UpgradeTrack) -> void:
	track = _track
	if is_node_ready():
		refresh()

func _ready() -> void:
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	MetaProgress.levels_changed.connect(refresh)
	PlayerManager.player.item_amount_changed.connect(_on_items_changed)
	refresh()

func refresh() -> void:
	if track == null:
		return
	var stats: PlayerStats = PlayerManager.player.stats
	var level: int = MetaProgress.get_level(track)

	name_label.text = track.display_name
	if track.max_level > 0:
		level_label.text = "Lv %d / %d" % [level, track.max_level]
	else:
		level_label.text = "Lv %d" % level

	if track.is_maxed(level):
		effect_label.text = "Maxed"
		_clear_costs()
		upgrade_button.text = "Maxed"
		upgrade_button.disabled = true
		return

	if track.is_milestone(level + 1):
		effect_label.text = "Milestone: new ability"
	else:
		var step: UpgradeStep = track.get_next_step(level)
		effect_label.text = step.get_display_text() if step else ""

	_build_costs(MetaProgress.get_cost(track), stats)
	upgrade_button.text = "Upgrade"
	upgrade_button.disabled = not MetaProgress.can_afford(track, stats)

func _build_costs(cost: Dictionary[CustomVariables.items, int], stats: PlayerStats) -> void:
	_clear_costs()
	for item: CustomVariables.items in cost:
		var amount: int = cost[item]

		var icon: TextureRect = TextureRect.new()
		icon.texture = item_icons.get(item)
		icon.custom_minimum_size = icon_size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cost_box.add_child(icon)

		var label: Label = Label.new()
		label.text = str(amount)
		label.theme_type_variation = &"CostLabel"
		if stats.items.get(item, 0) < amount:
			label.add_theme_color_override(&"font_color", cant_afford_color)
		cost_box.add_child(label)

func _clear_costs() -> void:
	for child: Node in cost_box.get_children():
		cost_box.remove_child(child)
		child.queue_free()

func _on_items_changed(_amount: int, _item: CustomVariables.items) -> void:
	refresh()

func _on_upgrade_pressed() -> void:
	if track == null:
		return
	EventBus.button_click_sound.emit()
	MetaProgress.purchase(track, PlayerManager.player)
