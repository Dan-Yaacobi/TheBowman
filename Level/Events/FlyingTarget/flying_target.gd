class_name FlyingTarget extends CharacterBody2D

signal target_hit(target: FlyingTarget)

@onready var wings: AnimatedSprite2D = $Wings
@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: HitBox = $HitBox

@export var move_speed: float = 60.0
@export var start_position: Vector2
@export var end_position: Vector2

var _heading_to_end: bool = true
var _moving: bool = false
var _is_hit: bool = false

func _ready() -> void:
	hit_box.Damaged.connect(take_hit)
	set_route(start_position, end_position)

## Places the target at `from` and starts flying back and forth to `to`. Global positions.
func set_route(from: Vector2, to: Vector2) -> void:
	start_position = from
	end_position = to
	global_position = from
	_heading_to_end = true
	_moving = true

## Changes flight speed and wing animation speed by a percentage (20 = 20% faster, -20 = 20% slower).
func scale_speed(percent: float) -> void:
	var factor: float = 1.0 + percent / 100.0
	move_speed *= factor
	wings.speed_scale *= factor

func _physics_process(delta: float) -> void:
	if not _moving:
		return
	var target_point: Vector2 = end_position if _heading_to_end else start_position
	var to_target: Vector2 = target_point - global_position
	if to_target.length() <= move_speed * delta:
		_heading_to_end = not _heading_to_end
		target_point = end_position if _heading_to_end else start_position
		to_target = target_point - global_position
	velocity = to_target.normalized() * move_speed
	move_and_slide()

func take_hit(_var1, _var2, _var3) -> void:
	if _is_hit:
		return
	_is_hit = true
	_moving = false
	target_hit.emit(self)
