class_name StatsUI extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var points: Label = $Points
@onready var stats_node: Control = $StatsNode
@onready var more_info: MoreInfoButton = $MoreInfo
@onready var stat_1: StatControl = $StatsNode/Stat
@onready var stat_2: StatControl = $StatsNode/Stat2
@onready var stat_3: StatControl = $StatsNode/Stat3

func ready() -> void:
	close()
	points.text = "Points: " + str(0)
	
func set_up_signals() -> void:
	for stat in stats_node.get_children():
		if stat is StatControl:
			stat.trying_to_upgrade.connect(update_points)

func open() -> void:
	points.text = "Points: " + str(PlayerManager.player.get_stat_points())
	visible = true
	animation_player.play("Open")
	more_info.set_colors(stat_1.text_color,stat_2.text_color,stat_3.text_color)

func close() -> void:
	animation_player.play("Close")
	more_info.close()

func update_points(_stat: CustomVariables.stats, stat_control: StatControl) -> void:
	if PlayerManager.player.use_stat_point():
		points.text = "Points: " + str(PlayerManager.player.get_stat_points())
		
		if _stat == CustomVariables.stats.Strength:
			PlayerManager.player.set_strength(1)
		elif _stat == CustomVariables.stats.Agility:
			PlayerManager.player.set_agility(1)
		elif _stat == CustomVariables.stats.Stamina:
			PlayerManager.player.set_stamina(1)
		stat_control.update_stat_value()
	
