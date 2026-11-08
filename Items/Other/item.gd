class_name Item extends Node2D

@export var magnet_force: float = 400.0
@export var collect_radius: float = 16.0
@export var life_time: float = 30.0
@export var arc_height: float = 40.0
@export var arc_duration: float = 0.5

@export_subgroup("Collecting")
@export var item_type: CustomVariables.items
@export var text: String
@export var color: Color
@export var collected_sound: AudioStream
@export var collected_volume_db: float = -6.0

@export_subgroup("Dropping")
## Played when the item is dropped into the world (enemies, chests, rewards).
@export var dropped_sound: AudioStream
@export var dropped_volume_db: float = -10.0

@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var landing_detector: Area2D = $LandingDetector
@onready var magnet_area: Area2D = $MagnetArea

var _player: Player = null
var _magnetized: bool = false
var _landed: bool = false
var _tween: Tween = null

func _ready() -> void:
	_player = PlayerManager.player
	visible_on_screen_notifier.screen_exited.connect(initiate_despawn)
	visible_on_screen_notifier.screen_entered.connect(stop_despawn)
	lifetime_timer.wait_time = life_time
	lifetime_timer.timeout.connect(queue_free)
	landing_detector.body_shape_entered.connect(_on_landing_detector_body_shape_entered)
	extra_ready_functions()
	
func extra_ready_functions() -> void:
	pass
	
func launch(_target: Vector2) -> void:
	_landed = false
	var origin: Vector2 = global_position
	var scatter_x: float = randf_range(-21.0, 21.0)
	var destination: Vector2 = origin + Vector2(scatter_x, 0.0)
	_tween = create_tween()
	var mid: Vector2 = (origin + destination) / 2.0 + Vector2(0, -arc_height)
	_tween.tween_method(_move_along_arc.bind(origin, mid, destination), 0.0, 1.0, arc_duration)
	_tween.tween_callback(_on_arc_complete)

	
func _move_along_arc(t: float, start: Vector2, mid: Vector2, end: Vector2) -> void:
	if _landed:
		return
	var a: Vector2 = start.lerp(mid, t)
	var b: Vector2 = mid.lerp(end, t)
	global_position = a.lerp(b, t)

func _on_arc_complete() -> void:
	_landed = true

func _on_landing_detector_body_shape_entered(_body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if _landed:
		return
	_landed = true
	if _tween:
		_tween.kill()

func _process(delta: float) -> void:
	extra_process_functions(delta)
	if not _landed or not _magnetized or _player == null:
		return
	if global_position.distance_to(_player.global_position) <= collect_radius:
		_collect()
		return
	global_position = global_position.move_toward(_player.global_position, magnet_force * delta)

func extra_process_functions(_delta: float) -> void:
	pass
	
func play_dropped_sound() -> void:
	if dropped_sound:
		EventBus.play_any.emit(dropped_sound, 0.9, 1.1, dropped_volume_db)

func play_collected_sound() -> void:
	if collected_sound:
		EventBus.play_any.emit(collected_sound, 0.95, 1.05, collected_volume_db)

func _collect() -> void:
	play_collected_sound()
	_player.collect_item(item_type, 1)
	CombatTextSpawner.spawn(global_position, text, color)
	queue_free()

func initiate_despawn() -> void:
	lifetime_timer.start()

func stop_despawn() -> void:
	lifetime_timer.stop()

func _on_magnet_area_body_entered(body: Node2D) -> void:
	if body == _player:
		_magnetized = true

func _on_magnet_area_body_exited(body: Node2D) -> void:
	if body == _player:
		_magnetized = false
