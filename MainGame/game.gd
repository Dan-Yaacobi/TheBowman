class_name Game extends Node2D

@onready var platform_shop: PlatformShop = $PlatformShop
@onready var abilities_shop: AbilitiesShop = $AbilitiesShop
@onready var bows_shop: BowsShop = $BowsShop
@onready var shop: Shop = $Shop
@onready var main_menu: MainMenu = $MainMenu
@onready var play_ground: PlayGround = $PlayGround
@onready var scenes_dic: Dictionary = {"Menu" : main_menu, "PlayGround": play_ground,
"Shop": shop, "BowsShop": bows_shop, "AbilitiesShop": abilities_shop,"PlatformShop":platform_shop}

const PLAYER = preload("res://Player/Player.tscn")

var player: Player
var last_scene: Node

func _ready() -> void:
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
		if child != last_scene:
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
