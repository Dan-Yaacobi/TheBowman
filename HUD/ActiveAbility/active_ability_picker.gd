class_name ActiveAbilityPicker extends Control

@onready var button_1: ActiveAbilityButton = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Button1
@onready var button_2: ActiveAbilityButton = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Button2
@onready var button_3: ActiveAbilityButton = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Button3

func _ready() -> void:
	hide()
	EventBus.show_active_ability_picker.connect(setup)

func setup(_pool: Array[ActiveAbility]) -> void:
	show()
	get_tree().paused = true
	var pool_copy: Array[ActiveAbility] = _pool.duplicate()
	pool_copy.shuffle()
	var buttons: Array[ActiveAbilityButton] = [button_1, button_2, button_3]
	for i in range(min(3, pool_copy.size())):
		buttons[i].setup(pool_copy[i])
		buttons[i].ability_chosen.connect(_on_ability_chosen)

func _on_ability_chosen(_ability: ActiveAbility) -> void:
	PlayerManager.player.stats.active_ability = _ability
	_ability.on_equipped(PlayerManager.player)
	EventBus.active_ability_equipped.emit(_ability)
	get_tree().paused = false
	var buttons: Array[ActiveAbilityButton] = [button_1, button_2, button_3]
	for button in buttons:
		if button.ability_chosen.is_connected(_on_ability_chosen):
			button.ability_chosen.disconnect(_on_ability_chosen)
	hide()
