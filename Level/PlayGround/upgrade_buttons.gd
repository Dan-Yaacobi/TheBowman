extends Node2D

@onready var upgrades: UpgradeBuckets = $Upgrades
@export var bucket_upgrade_chance: int = 0

var upgrade_buttons: Array[UpgradeButton]
var current_button_bucket: int = 1
var current_button_set_up: int = 0

var player: Player
var boss_upgrade_boost: bool = false
var success_boost: float = 1.0
func _ready() -> void:
	for child in get_children():
		if child is UpgradeButton:
			upgrade_buttons.append(child)
			child.upgrade_chosen.connect(remove_chosen_ability_from_bucket)

func get_upgrades(current_wave: int) -> void:
	current_button_set_up = 0
	if (current_wave - 1) % 5 == 0:
		boss_upgrade_boost = true
		
	for i in upgrade_buttons.size():
		current_button_bucket = 1
		var next_bucket = randi_range(0,100)
		
		if boss_upgrade_boost:
			current_button_bucket += 1
			if next_bucket <= bucket_upgrade_chance*2:
				current_button_bucket += 1
				
			boss_upgrade_boost = false
		
		else:
			if next_bucket <= bucket_upgrade_chance * success_boost:
				current_button_bucket += 1
				success_boost = 1
			else:
				success_boost +=0.04
			
			
		upgrade_buttons[current_button_set_up].set_button_upgrade(upgrades.get_bucket_upgrade(current_button_bucket),player)
		current_button_set_up += 1
	

func remove_chosen_ability_from_bucket(upgrade: PlayerUpgrade) -> void:
	if upgrade.is_ability:
		if upgrade.can_choose_once == true:
			upgrades.used_buckets[upgrade.bucket].erase(upgrade)
			upgrades.abilities_bucket[upgrade.bucket].append(upgrade)
	upgrades.refill_buckets()	


func disable() -> void:
	for button in upgrade_buttons:
		button.disable()

func enable() -> void:
	for button in upgrade_buttons:
		button.enable()
