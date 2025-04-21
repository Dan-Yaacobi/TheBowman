class_name ShooterHand extends Node2D

@onready var shooter_hand_sprite: Sprite2D = $ShooterHandSprite
@onready var shoot_timer: Timer = $"../../ShootTimer"
@onready var tower: Tower = $"../.."

func _ready() -> void:
	shoot_timer.timeout.connect(shoot)
	
func _physics_process(delta: float) -> void:
	if tower.target != null:
		set_hand_direction()
		if shoot_timer.is_stopped():
			shoot_timer.start()
	else:
		shoot_timer.stop()
		rotation = 0

func shoot() -> void:
	if tower.data.arrow != null:
		var new_arrow: Arrow = tower.data.arrow.instantiate()
		var offset: Vector2 = Vector2([1,-1].pick_random()*randf_range(0.01,0.02),[1,-1].pick_random()*randf_range(0.01,0.02))
		new_arrow.direction = tower.direction + offset
		new_arrow.regular_shot = false
		new_arrow.global_position = global_position
		
		tower.get_parent().call_deferred("add_child",new_arrow)
		new_arrow.rotate(set_arrow_rotation())

func set_hand_direction() -> void:
	rotation = tower.direction.angle() - PI/2
	
func set_arrow_rotation() -> float:
	var angle_rotation: float = 0.0
	if tower.target != null:
		angle_rotation = (global_position - tower.target.global_position).angle()
	return angle_rotation
