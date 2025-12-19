class_name UpgradeButton extends Control

signal upgrade_chosen(upgrade: PlayerUpgrade)

@onready var choose_button: Button = $ChooseButton
@onready var current_stat: Label = $CurrentStat
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var upgrade_icon: TextureRect = $UpgradeIcon

var node: PlayerUpgrade
var player: Player

func _ready() -> void:
	disable()
	
func set_button_upgrade(upgrade_node: PlayerUpgrade, _player: Player) -> void:
	if upgrade_node != null and _player != null:
		player = _player
		node = upgrade_node
		particles.color = node.color
		upgrade_icon.texture = node.texture
		current_stat.text = node.tool_tip
		
func enable() -> void:
	visible = true
	choose_button.disabled = false
	pass

func disable() -> void:
	visible = false
	choose_button.disabled = true
	pass
	
func upgrade() -> void:
	node.upgrade(player)
	await Engine.get_main_loop().process_frame
	player.stats.upgrd_points += 1
	player.add_display_buff(node)
	upgrade_chosen.emit(node)
	pass

func _on_choose_button_pressed() -> void:
	upgrade()
