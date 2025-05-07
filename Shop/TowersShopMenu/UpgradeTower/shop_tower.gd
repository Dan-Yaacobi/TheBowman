class_name ShopTower extends Control

@onready var right_button: TextureButton = $RightButton
@onready var left_button: TextureButton = $LeftButton
@onready var upgrade_1: TowerUpgradeButton = $Upgrade1
@onready var upgrade_2: TowerUpgradeButton = $Upgrade2
@onready var upgrade_3: TowerUpgradeButton = $Upgrade3
@onready var upgrade_4: TowerUpgradeButton = $Upgrade4
@onready var tower_label: Label = $TowerLabel
@onready var tower: Tower = $Tower
@onready var rotate_animation: AnimationPlayer = $RotateAnimation
@onready var appear_animation: AnimationPlayer = $AppearAnimation
@onready var buy_tower: BuyTower = $"../BuyTower"

var current_tower: int = 0
var player: Player
var total_towers: int

func _ready() -> void:
	right_button.pressed.connect(right)
	left_button.pressed.connect(left)
	buy_tower.bought.connect(update)
	visible = false
	
func set_player(_player: Player) -> void:
	if _player != null:
		player = _player
		total_towers = player.stats.towers.size()

func update() -> void:
	if player!= null:
		if player.stats.towers.size() == 1:
			visible = true
			appear_animation.play("Appear")
		set_upgrades()

func set_upgrades() -> void:
	if player != null:
		if player.stats.towers.size() > 0:
			total_towers = player.stats.towers.size()
			tower_label.text = "Tower #" + str(current_tower + 1)
			var curr_tower: TowerData = player.stats.towers[current_tower]
			upgrade_1.set_stat_tooltip(upgrade_1.stat,curr_tower.range)
			upgrade_2.set_stat_tooltip(upgrade_2.stat,curr_tower.damage_timer)
			upgrade_3.set_stat_tooltip(upgrade_3.stat,curr_tower.level)
			upgrade_4.set_ability_tooltip(upgrade_4.stat,curr_tower.speciality)

func right() -> void:
	current_tower += 1
	if current_tower > total_towers - 1:
		current_tower = 0
	rotate_animation.play("RotateRight")
	disable_arrow_buttons()
	await rotate_animation.animation_finished
	set_upgrades()
	enable_arrow_buttons()
	
func left() -> void:
	current_tower -= 1
	if current_tower < 0:
		current_tower = total_towers - 1
	rotate_animation.play("RotateLeft")
	disable_arrow_buttons()
	await rotate_animation.animation_finished
	set_upgrades()
	enable_arrow_buttons()
	

func disable_arrow_buttons() -> void:
	right_button.disabled = true
	left_button.disabled = true

func enable_arrow_buttons() -> void:
	right_button.disabled = false
	left_button.disabled = false
