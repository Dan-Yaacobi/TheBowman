@tool
class_name Pedestal extends Node2D

@onready var bow_sprite: Sprite2D = $PedestalBow/BowSprite
@onready var buy_bow_menu: BuyBowMenu = $BuyBowMenu
@export var bow: PackedScene
@export var sprite: Texture2D:
	set(value):
		sprite = value
		if Engine.is_editor_hint():
			call_deferred("_update_sprite")
		else:
			_update_sprite()
@onready var island: Island = $Island
@onready var player_detector: Area2D = $PlayerDetector
@onready var particles: CPUParticles2D = $CPUParticles2D

var current_bow: Weapon

func _ready() -> void:
	_update_sprite()
	if not Engine.is_editor_hint():
		particles.emitting = false
		if bow:
			current_bow = bow.instantiate()
			buy_bow_menu.set_up(current_bow.weapon_data)
		buy_bow_menu.buy_button.pressed.connect(_bought_bow)

func _update_sprite() -> void:
	if not bow_sprite:
		return
	bow_sprite.texture = sprite

func _bought_bow() -> void:
	PlayerManager.player.change_to_new_bow(bow)
	
func _on_player_detector_body_entered(_body: Node2D) -> void:
	buy_bow_menu.appear()
	particles.emitting = true
	
func _on_player_detector_body_exited(_body: Node2D) -> void:
	buy_bow_menu.disappear()
	particles.emitting = false
	
func enable() -> void:
	island.enable()
	player_detector.monitoring = true
	pass
	
func disable() -> void:
	island.disable()
	player_detector.monitoring = false
	pass
