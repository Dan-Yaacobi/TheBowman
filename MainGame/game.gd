class_name Game extends Node2D

@onready var game_manager: GameManager = $GameManager

const CLOUD = preload("res://MainGame/Clouds/Cloud.tscn")
@onready var game_music: AudioStreamPlayer2D = $GameMusic
@onready var cloud_timer: Timer = $CloudTimer
@onready var hud: HUD = $Hud

@onready var sky: ColorRect = $CanvasLayer/ColorRect
@export var base_top_color: Color = Color(0.2, 0.4, 0.8, 1.0)
@export var base_bottom_color: Color = Color(0.6, 0.851, 1.0)

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
	cloud_timer.timeout.connect(summon_cloud)
	cloud_timer.start()
	add_child(PlayerManager.player)
	EventBus.change_sky_color.connect(change_sky_colors)
	
func summon_cloud() -> void:
	var new_cloud: Cloud = CLOUD.instantiate()
	new_cloud.global_position = PlayerManager.player.global_position + Vector2(-500, randf_range(-200, -50))
	
	var depth = randf_range(0.3, 1.0)
	new_cloud.scale = Vector2.ONE * depth
	new_cloud.move_speed = lerp(10.0, 40.0, depth)
	
	add_child(new_cloud)
	cloud_timer.wait_time = randf_range(1, 5)
	
func music_on_off() -> void:
	if music_on:
		game_music.play()
	else:
		game_music.stop()

func change_sky_colors(sky_colors: SkyColors) -> void:
	var mat: ShaderMaterial = sky.material as ShaderMaterial
	if mat == null:
		push_warning("Sky ColorRect has no ShaderMaterial")
		return
	mat.set_shader_parameter("color_top", sky_colors.top_color)
	mat.set_shader_parameter("color_bottom", sky_colors.bottom_color)
