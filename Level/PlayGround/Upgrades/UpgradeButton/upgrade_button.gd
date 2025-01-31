class_name UpgradeButton extends TextureButton

signal upgrade_chosen(upgrade: PlayerUpgrade)

@onready var current_stat: Label = $CurrentStat
@onready var particles: CPUParticles2D = $CPUParticles2D

var node: PlayerUpgrade
var player: Player

func set_button_upgrade(upgrade_node: PlayerUpgrade, _player: Player) -> void:
	if upgrade_node != null and _player != null:
		player = _player
		node = upgrade_node
		particles.color = upgrade_node.color
		texture_normal = upgrade_node.normal_texture
		texture_pressed = upgrade_node.pressed_texture
		texture_hover = upgrade_node.hover_texture
		tooltip_text = upgrade_node.tool_tip + "\n" 
		if not upgrade_node.is_ability:
			tooltip_text += "Current: " + node.get_current(player)
		if not pressed.is_connected(upgrade):
			pressed.connect(upgrade)
		#current_stat.text = "Current: " + node.get_current(player)

func upgrade() -> void:
	upgrade_chosen.emit(node)
	node.upgrade(player)
	player.stats.upgrd_points += 1
	pass
