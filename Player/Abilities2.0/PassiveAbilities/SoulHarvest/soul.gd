class_name Soul extends CharacterBody2D

enum Mode { HOMING, SPIRAL }

@onready var hurt_box: HurtBox = $HurtBox
@onready var spiral_timer: Timer = $SpiralTimer
@onready var player_detector: Area2D = $PlayerDetector
@onready var sprite: Sprite2D = $Sprite2D

@export var homing_speed: float = 200.0
@export var spiral_angular_speed: float = 1.5
@export var spiral_radius_growth: float = 80.0
@export var spiral_lifetime: float = 3.0

var _mode: Mode = Mode.HOMING
var _spiral_angle: float = 0.0
var _spiral_radius: float = 0.0
var _spiral_origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	hurt_box.damage = roundi(PlayerManager.player.stats.arrow_damage.value())
	
func set_homing() -> void:
	_mode = Mode.HOMING

func set_spiral(_start_angle: float) -> void:
	_mode = Mode.SPIRAL
	_spiral_angle = _start_angle
	_spiral_origin = global_position
	spiral_timer.wait_time = spiral_lifetime
	spiral_timer.start()

func _physics_process(delta: float) -> void:
	match _mode:
		Mode.HOMING:
			_process_homing()
		Mode.SPIRAL:
			_process_spiral(delta)

func _process_homing() -> void:
	var player: Player = PlayerManager.player
	if not is_instance_valid(player):
		return
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * homing_speed
	move_and_slide()
	sprite.rotation = velocity.angle()

func _process_spiral(delta: float) -> void:
	_spiral_angle += spiral_angular_speed * delta
	_spiral_radius += spiral_radius_growth * delta
	var new_position: Vector2 = _spiral_origin + Vector2(cos(_spiral_angle), sin(_spiral_angle)) * _spiral_radius
	var move_direction: Vector2 = (new_position - global_position).normalized()
	sprite.rotation = move_direction.angle()
	global_position = new_position

func _on_spiral_timer_timeout() -> void:
	queue_free()

func _on_player_detector_body_entered(body: Node2D) -> void:
	if _mode == Mode.HOMING and body is Player:
		EventBus.fill_gauge.emit(1.0)
		queue_free()
