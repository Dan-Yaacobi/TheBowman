class_name Game extends Node2D

@onready var game_music: AudioStreamPlayer2D = $GameMusic

@onready var platform_shop: PlatformShop = $PlatformShop
@onready var abilities_shop: AbilitiesShop = $AbilitiesShop
@onready var bows_shop: BowsShop = $BowsShop
@onready var shop: Shop = $Shop
@onready var main_menu: MainMenu = $MainMenu
@onready var play_ground: PlayGround = $PlayGround
@onready var scenes_dic: Dictionary = {"Menu" : main_menu, "PlayGround": play_ground,
"Shop": shop, "BowsShop": bows_shop, "AbilitiesShop": abilities_shop,"PlatformShop":platform_shop}

@export var music_on: bool = true :
	set(val):
		music_on = val
		music_on_off()

const PLAYER = preload("res://Player/Player.tscn")

var player: Player
var last_scene: Node

func _ready() -> void:
	#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	player = PLAYER.instantiate()
	player.died.connect(change_scene)
	add_child(player)
	
	platform_shop.changed_scene.connect(change_scene)
	main_menu.changed_scene.connect(change_scene)
	shop.changed_scene.connect(change_scene)
	bows_shop.changed_scene.connect(change_scene)
	abilities_shop.changed_scene.connect(change_scene)
	
	player.reparent(main_menu)
	main_menu.set_scene(player)
	last_scene = main_menu

	for child in get_children():
		if child != last_scene and not child is AudioStreamPlayer2D:
			child.call_deferred("exit_scene",player)

func change_scene(new_scene: String) -> void:
	last_scene.call_deferred("exit_scene", player)
	scenes_dic.get(new_scene).call_deferred("set_scene", player)
	player.call_deferred("reparent",scenes_dic.get(new_scene))
	last_scene = scenes_dic.get(new_scene)

func get_playground() -> PlayGround:
	for child in get_children():
		if child is PlayGround:
			return child
	return

func music_on_off() -> void:
	print("changed")
	if music_on:
		game_music.play()
	else:
		game_music.stop()
	pass
