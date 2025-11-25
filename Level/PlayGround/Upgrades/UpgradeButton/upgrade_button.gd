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
		upgrade_icon.texture = node.normal_texture
		current_stat.text = node.tool_tip
		

		#texture_normal = upgrade_node.normal_texture
		#texture_pressed = upgrade_node.pressed_texture
		#texture_hover = upgrade_node.hover_texture
		#if upgrade_node.ability_chosen:
			#tooltip_text = upgrade_node.tool_tip2 + "\n"
		#else:
			#tooltip_text = upgrade_node.tool_tip + "\n" 
		#if not upgrade_node.is_ability:
			#tooltip_text += "Current: " + node.get_current(player)
		#if not pressed.is_connected(upgrade):
			#pressed.connect(upgrade)
		
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
