class_name Game extends Node2D

const CLOUD = preload("res://MainGame/Clouds/Cloud.tscn")
@onready var game_music: AudioStreamPlayer2D = $GameMusic
@onready var platform_shop: PlatformShop = $PlatformShop
@onready var abilities_shop: AbilitiesShop = $AbilitiesShop
@onready var bows_shop: BowsShop = $BowsShop
@onready var shop: Shop = $Shop
@onready var main_menu: MainMenu = $MainMenu
@onready var play_ground: PlayGround = $PlayGround
@onready var tower_upgrade_menu: TowerUpgradeMenu = $TowerUpgradeMenu
@onready var rift: Rift = $Rift
@onready var scenes_dic: Dictionary = {
"Menu": main_menu,
"PlayGround": play_ground,
"Shop": shop,
"BowsShop": bows_shop,
"AbilitiesShop": abilities_shop,
"PlatformShop": platform_shop,
"TowerUpgrade": tower_upgrade_menu,
"Rift": rift
}
@onready var cloud_timer: Timer = $CloudTimer
@onready var hud: HUD = $Hud


@export var music_on: bool = true :
	set(val):
		music_on = val
		music_on_off()

const PLAYER = preload("res://Player/Player.tscn")

var player: Player
var last_scene: Node

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	EventBus.changed_scene.connect(change_scene)
	cloud_timer.timeout.connect(summon_cloud)
	#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	player = PlayerManager.player
	player.health_bar = hud.get_health_bar()
	player.total_buffs = hud.get_total_buffs()
	player.special_ability_cd = hud.get_special_ability_cd()
	
	#player.died.connect(change_scene)
	add_child(player)
	
	#platform_shop.changed_scene.connect(change_scene)
	#main_menu.changed_scene.connect(change_scene)
	#shop.changed_scene.connect(change_scene)
	#bows_shop.changed_scene.connect(change_scene)
	#abilities_shop.changed_scene.connect(change_scene)
	#player.back_to_menu.connect(change_scene)
	
	#player.reparent(main_menu)
	#main_menu.set_scene(player)
	
	last_scene = main_menu
	main_menu.playground = play_ground
	cloud_timer.start()
	for child in get_children():
		if child != last_scene and child.has_method("exit_scene"):
			child.call_deferred("exit_scene",player)
	
	change_scene("Menu")
	hud.visible = false
	main_menu.visible = false
	await get_tree().create_timer(0.4).timeout
	RenderingServer.set_default_clear_color(Color.from_string("64c5f2",Color.AQUA))
	player.visible = true
	hud.visible = true
	main_menu.visible = true
	
func change_scene(new_scene: String) -> void:
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
	new_cloud.global_position = player.global_position + Vector2([1,-1].pick_random() * 500,randf_range(-20,-100))
	add_child(new_cloud)
	cloud_timer.wait_time = randf_range(1,5)
	pass
	
func music_on_off() -> void:
	if music_on:
		game_music.play()
	else:
		game_music.stop()
	pass
