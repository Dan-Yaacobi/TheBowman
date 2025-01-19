class_name ItemPickUp extends Node2D

@export var item_data: ItemData
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D
@onready var timer: Timer = $Timer

var player: Player
var move_speed: float = 50
var moving: bool = false

func inititalize(_player) -> void:
	if _player != null:
		player = _player
		
func assign_item(_item_data: ItemData) -> void:
	item_data = _item_data
	
func _ready() -> void:
	area_2d.body_entered.connect(item_picked_up)
	sprite_2d.texture = item_data.image
	sprite_2d.scale *= item_data.image_size
	for effect in item_data.effects:
		effect.activate_ability(self)
	timer.timeout.connect(start_moving)
	timer.start()
	spawn_offset()
func spawn_offset() -> void:
	global_position += Vector2(randi_range(-20,20),randi_range(-20,20))

func start_moving() -> void:
	moving = true
	
func _physics_process(delta: float) -> void:
	if moving:
		global_position += calculate_direction_to_player() * move_speed * delta
		move_speed *= 1.05


func random_direction() -> Vector2:
	var dirc: Vector2
	dirc = Vector2(randf_range(-1,1),randf_range(-1,1))
	return dirc
	
func calculate_direction_to_player() -> Vector2:
	var _direction: Vector2
	_direction = player.global_position - global_position
	return _direction.normalized()

func item_picked_up(body) -> void:
	if body is Player:
		body.collect_money(item_data.value)
		queue_free()
