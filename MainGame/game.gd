class_name Game extends Node2D

@onready var game_manager: GameManager = $GameManager

const CLOUD = preload("res://MainGame/Clouds/Cloud.tscn")
@onready var game_music: AudioStreamPlayer2D = $GameMusic
@onready var rift: Rift = $Rift
@onready var scenes_dic: Dictionary = {
"Menu": main_menu,
"Rift": rift
}
@onready var cloud_timer: Timer = $CloudTimer
@onready var hud: HUD = $Hud

const MAIN_MENU = preload("uid://cnhbrpo4htp2y")
var main_menu: PackedScene = MAIN_MENU

@export var music_on: bool = true :
	set(val):
		music_on = val
		music_on_off()

var player: Player
var last_scene: Node

func _ready() -> void:
	game_manager.set_game(self)
	game_manager.change_game_world(GameWorlds.worlds.Main_Menu)
	PlayerManager.player.health_bar = hud.get_health_bar()
	PlayerManager.player.total_buffs = hud.get_total_buffs()
	PlayerManager.player.special_ability_cd = hud.get_special_ability_cd()
	add_child(PlayerManager.player)
	return
	#RenderingServer.set_default_clear_color(Color.BLACK)
	#
	##EventBus.changed_scene.connect(change_scene)
	#cloud_timer.timeout.connect(summon_cloud)
	#player = PlayerManager.player

	#add_child(player)
	#
	#last_scene = main_menu
	#main_menu.playground = play_ground
	#cloud_timer.start()
	#for child in get_children():
		#if child != last_scene and child.has_method("exit_scene"):
			#child.call_deferred("exit_scene",player)
	#
	#change_scene("Menu")
	#hud.visible = false
	#main_menu.visible = false
	#await get_tree().create_timer(0.4).timeout
	#RenderingServer.set_default_clear_color(Color.from_string("64c5f2",Color.AQUA))
	#player.visible = true
	#hud.visible = true
	#main_menu.visible = true
	
func change_scene(new_scene: String) -> void:
	return
	if new_scene in scenes_dic:
		get_tree().paused = true

		hud.visible = false
		
		await SceneTransition.fade_out()
		
		last_scene.call_deferred("exit_scene", player)
		scenes_dic.get(new_scene).call_deferred("set_scene", player)
		player.call_deferred("reparent",scenes_dic.get(new_scene))
		last_scene = scenes_dic.get(new_scene)
		
		await get_tree().process_frame
		
		await SceneTransition.fade_in()
		EventBus.invisible_hands.emit(true)
		get_tree().paused = false
		hud.visible = true
		await get_tree().process_frame
		
		#player.player_state_machine.ChangeState(player.idle_state)

func get_playground() -> PlayGround:
	for child in get_children():
		if child is PlayGround:
			return child
	return

func summon_cloud() -> void:
	var new_cloud: Cloud = CLOUD.instantiate()
	new_cloud.global_position = PlayerManager.player.global_position + Vector2([1,-1].pick_random() * 500,randf_range(-20,-100))
	add_child(new_cloud)
	cloud_timer.wait_time = randf_range(1,5)
	pass
	
func music_on_off() -> void:
	if music_on:
		game_music.play()
	else:
		game_music.stop()
	pass
