class_name Tower extends Node2D

@export var data: TowerData

@onready var shoot_range: Area2D = $ShootRange
@onready var collision_shape: CollisionShape2D = $ShootRange/CollisionShape2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var tower_shooter_sprite: Sprite2D = $TowerShooterSprite
@onready var switch_target_timer: Timer = $SwitchTargetTimer
@onready var tower_arrows: TowerArrows = $TowerArrows
@onready var shooter_hand: ShooterHand = $TowerShooterSprite/ShooterHand
@onready var blind_spot: Area2D = $BlindSpot

var target: Enemy
var direction: Vector2
var targets: Array[Enemy]
var tower_placed: bool = false

func _ready() -> void:
	return
	#shoot_range.body_entered.connect(set_target)
	#shoot_range.body_exited.connect(clear_target)
	#switch_target_timer.timeout.connect(pick_closest_target)
	#blind_spot.body_entered.connect(blind_spot_entered)
	#blind_spot.body_exited.connect(blind_spot_exited)

func _physics_process(_delta: float) -> void:
	if tower_placed:
		if target != null :
			calculate_direction_to_target()
			if switch_target_timer.is_stopped():
				switch_target_timer.start()
		else:
			switch_target_timer.stop()
		
func set_target(b) -> void:
	if b is Enemy:
		if target == null:
			target = b
			calculate_direction_to_target()
			shooter_hand.shoot()
		if not b.died.is_connected(remove_target):
			b.died.connect(remove_target)
		targets.append(b)

func blind_spot_entered(b) -> void:
	targets.erase(b)
	target = null
	if targets.size() > 0:
		target = targets.pick_random()
	targets.append(b)

func blind_spot_exited(b) -> void:
	if target == null:
		target = b
	
func pick_closer_target(curr_target, other_target) -> Enemy:
	if is_instance_valid(curr_target) and is_instance_valid(other_target):
		if abs(global_position - curr_target.global_position) > abs(global_position - other_target.global_position):
			if other_target.global_position.y < curr_target.global_position.y:
				return other_target
	return curr_target
		
func pick_closest_target() -> Enemy:
	var best_target = target
	for _target in targets:
		best_target = pick_closer_target(best_target,_target)
	return best_target
	
func clear_target(b) -> void:
	remove_target(b)
	if b == target:
		target = null
		if targets.size() > 0:
			target = targets.pick_random()

func clear_all_targets() -> void:
	targets.clear()
	target = null
	
func remove_target(b) -> void:
	if b is Enemy:
		targets.erase(b)
		if b.died.is_connected(remove_target):
			b.died.disconnect(remove_target)

func set_tower() -> void:
	data.arrow = tower_arrows.get_arrow(data.level)
	collision_shape.shape.radius *= data.range
	shoot_timer.wait_time = data.damage_timer
	shooter_hand.shooter_hand_sprite.frame = data.level
	global_position = data.position
	if global_position != Vector2.ZERO:
		tower_placed = true


func update_direction(side: bool) -> void:
	tower_shooter_sprite.flip_h = side
	
func calculate_direction_to_target() -> void:
	direction = (target.global_position - global_position).normalized()
	if target.global_position.x > global_position.x:
		update_direction(true)
	else:
		update_direction(false)
	pass
	
func upgrade(_arrow:PackedScene, _bow: Texture) -> void:
	pass

func change_direction() -> void:
	pass
