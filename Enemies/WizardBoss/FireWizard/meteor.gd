class_name Meteor extends Node2D

@export var damage: int = 4
@export var knockback: float = 300.0
@export var start_speed: float = 40.0
@export var max_speed: float = 700.0
## Seconds to go from start_speed to max_speed
@export var ramp_time: float = 0.9
## Higher = slower start, sharper ramp
@export var ramp_curve: float = 2.5
## Upward lift added to the sideways knockback (0 = purely horizontal)
@export var knockback_lift: float = 0
@export var impact_scene: PackedScene
@export var island_burn_scene: PackedScene
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var screen_exited_timer: Timer = $VisibleOnScreenNotifier2D/ScreenExitedTimer

@onready var hurt_box: HurtBox = $HurtBox
@onready var ground_detector: Area2D = $GroundDetector

var _time: float = 0.0
var _launched: bool = false
var _impacted: bool = false

func _ready() -> void:
	hurt_box.base_damage = damage
	hurt_box.knockback_power = knockback
	visible_on_screen_notifier_2d.screen_exited.connect(screen_exit)
	screen_exited_timer.timeout.connect(queue_free)
	visible_on_screen_notifier_2d.screen_entered.connect(screen_enter)
	hurt_box.successful_hit.connect(impact)

func launch(start: Vector2) -> void:
	if not is_node_ready():
		await ready
	global_position = start
	_time = 0.0
	_launched = true

func _physics_process(delta: float) -> void:
	if not _launched or _impacted:
		return
	_time += delta
	var t: float = clampf(_time / ramp_time, 0.0, 1.0)
	var speed: float = lerpf(start_speed, max_speed, ease(t, ramp_curve))
	global_position += Vector2.DOWN * speed * delta
	_update_knockback_dir()

func _update_knockback_dir() -> void:
	var side: float = signf(PlayerManager.player.global_position.x - global_position.x)
	if side == 0.0:
		side = 1.0 if randf() < 0.5 else -1.0
	hurt_box.knockback_dir = Vector2(side, -knockback_lift).normalized()

func screen_exit() -> void:
	screen_exited_timer.start()

func screen_enter() -> void:
	screen_exited_timer.stop()

func impact(_hurt_box: HurtBox, _hit_box: Area2D, _result: DamageResult) -> void:
	if _impacted:
		return
	#_impacted = true
	# TODO: instantiate impact scene on the player
	#queue_free()

func _on_ground_detector_body_shape_entered(_body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if _impacted or not _body is Island:
		return
	_impacted = true
	var island_burn = island_burn_scene.instantiate()
	island_burn.position = _body.objects_spawn_markers.position
	_body.call_deferred("add_child", island_burn)
	queue_free()
