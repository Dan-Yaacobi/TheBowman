class_name CursePicker extends CanvasLayer

signal confirmed(curses: Array[ChallengeCurse])
signal cancelled

@onready var cancel_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/CancelButton
@onready var start_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/StartButton
@onready var curse_list: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/CurseList
@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $CenterContainer/PanelContainer/VBoxContainer/DescriptionLabel
@onready var reward_list: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/RewardList

var _rewards: Array[EventReward] = []

var _offered: Array[ChallengeCurse] = []
var _boxes: Array[CheckBox] = []

func _ready() -> void:
	hide()
	start_button.pressed.connect(_on_start_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func open(challenge: ChallengeDef, curses: Array[ChallengeCurse]) -> void:
	title_label.text = challenge.display_name
	description_label.text = challenge.description
	_offered = curses
	_rewards = challenge.rewards

	for child: Node in curse_list.get_children():
		child.queue_free()
	_boxes.clear()

	for curse: ChallengeCurse in curses:
		var box: CheckBox = CheckBox.new()
		box.text = "%s: %s" % [curse.display_name, curse.description]
		box.icon = curse.icon
		box.toggled.connect(_on_curse_toggled)
		curse_list.add_child(box)
		_boxes.append(box)

	_refresh_rewards()
	show()
	start_button.grab_focus()

func _on_start_pressed() -> void:
	var selected: Array[ChallengeCurse] = []
	for i: int in _boxes.size():
		if _boxes[i].button_pressed:
			selected.append(_offered[i])
	hide()
	confirmed.emit(selected)

func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()
	
func close() -> void:
	hide()
func _on_curse_toggled(_pressed: bool) -> void:
	_refresh_rewards()

func _selected_weight() -> int:
	var weight: int = 0
	for i: int in _boxes.size():
		if _boxes[i].button_pressed:
			weight += _offered[i].reward_weight
	return weight

func _max_weight() -> int:
	var weight: int = 0
	for curse: ChallengeCurse in _offered:
		weight += curse.reward_weight
	return weight

func _refresh_rewards() -> void:
	for child: Node in reward_list.get_children():
		reward_list.remove_child(child)
		child.queue_free()

	var weight: int = _selected_weight()
	var counts: Dictionary[String, int] = {}
	var next_min: int = -1

	for reward: EventReward in _rewards:
		if reward.can_grant(weight):
			var text: String = reward.get_preview_text()
			counts[text] = counts.get(text, 0) + 1
		elif next_min < 0 or reward.min_weight < next_min:
			next_min = reward.min_weight

	for text: String in counts:
		var line: String = text if counts[text] == 1 else "%s x%d" % [text, counts[text]]
		_add_reward_line(line, false)

	if next_min >= 0 and next_min <= _max_weight():
		var needed: int = next_min - weight
		var suffix: String = "" if needed == 1 else "s"
		for reward: EventReward in _rewards:
			if reward.min_weight == next_min:
				_add_reward_line("+%d curse%s: %s" % [needed, suffix, reward.get_preview_text()], true)

func _add_reward_line(text: String, locked: bool) -> void:
	var label: Label = Label.new()
	label.text = text
	if locked:
		label.modulate = Color(1.0, 1.0, 1.0, 0.4)
	reward_list.add_child(label)
