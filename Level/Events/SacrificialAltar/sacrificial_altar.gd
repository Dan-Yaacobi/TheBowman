class_name SacrificialAltar extends NPC

signal sacrificed

## The altar never takes the last heart container.
@export var refuse_line: String = "The well stirs, then stills. You have nothing left to give."
## Heart containers one offering costs. Set by the event from the biome (set_heart_cost).
@export var heart_cost: int = 1

const COST_WORDS: Array[String] = ["", "one", "two", "three", "four", "five"]

var _sacrificing: bool = false

## Sets the price and rewrites the well's line and button to match.
func set_heart_cost(cost: int) -> void:
	heart_cost = maxi(cost, 1)
	data = data.duplicate()
	var word: String = COST_WORDS[heart_cost] if heart_cost < COST_WORDS.size() else str(heart_cost)
	var hearts: String = "one of your hearts" if heart_cost == 1 else "%s of your hearts" % word
	data.fixed_line = "Give it %s, and it will give you something worth carrying." % hearts
	var labels: Array[String] = ["Offer a Heart" if heart_cost == 1 else "Offer %d Hearts" % heart_cost]
	data.action_button_labels = labels

func action(_index: int) -> void:
	match _index:
		0:
			_sacrifice()

func _sacrifice() -> void:
	if _sacrificing or action_taken:
		return
	var player: Player = PlayerManager.player
	if _heart_containers(player) <= heart_cost:
		chat_box.show_line(refuse_line)
		return
	_sacrificing = true
	for i: int in heart_cost:
		player.lose_heart()
	action_taken = true
	_play_animation("used")
	show_post_action_line()
	sacrificed.emit()
	_sacrificing = false

func _heart_containers(player: Player) -> int:
	return ceili(float(player.max_hp_value()) / CustomVariables.HP_PER_HEART)

func on_interaction_opened() -> void:
	if not action_taken:
		_play_animation("interact")

func on_interaction_closed() -> void:
	if not action_taken:
		_play_animation("idle")
