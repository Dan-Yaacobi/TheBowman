class_name BoulderShard extends Node2D
## A piece of a shattered boulder. Flies in an arc and damages enemies (the wizard) it touches.

## Safety: free the shard if it flies this long without hitting anything
@export var max_lifetime: float = 2.0
@export var spin_speed: float = 12.0

@onready var visual: Sprite2D = $Visual
@onready var hurt_box: HurtBox = $HurtBox
@onready var ground_detector: Area2D = $GroundDetector

## Set before adding to the tree; the shard shows the boulder's texture
var texture: Texture2D
var _velocity: Vector2 = Vector2.ZERO
var _gravity: float = 500.0
var _time: float = 0.0
var _launched: bool = false

func _ready() -> void:
	if texture:
		visual.texture = texture
	visual.rotation = randf() * TAU
	hurt_box.successful_hit.connect(_on_hurt_box_successful_hit)
	ground_detector.body_entered.connect(_on_ground_detector_body_entered)

func launch(start: Vector2, velocity: Vector2, gravity: float, damage: int) -> void:
	if not is_node_ready():
		await ready
	global_position = start
	_velocity = velocity
	_gravity = gravity
	hurt_box.base_damage = damage
	_launched = true

func _physics_process(delta: float) -> void:
	if not _launched:
		return
	_time += delta
	if _time >= max_lifetime:
		queue_free()
		return
	_velocity.y += _gravity * delta
	global_position += _velocity * delta
	visual.rotation += spin_speed * signf(_velocity.x) * delta

func _on_hurt_box_successful_hit(_hurt_box: HurtBox, _hit_box: Area2D, _result: DamageResult) -> void:
	queue_free()

# Only on the way down, so shards leaving a boulder that broke near an island still fly
func _on_ground_detector_body_entered(body: Node2D) -> void:
	if body is Island and _velocity.y > 0.0:
		queue_free()
