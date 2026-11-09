class_name FireNovaSpell extends WizardSpellState
## Teleports in beside the player, shows the blast area growing, then sets off a ring of fire.
## nova_radius and warning_time are the main tuning knobs.

@export var nova_scene: PackedScene
@export var warning_scene: PackedScene
## Blast radius in pixels; the warning circle matches it
@export var nova_radius: float = 80.0
## Seconds from his arrival until the blast
@export var warning_time: float = 1.2
## Seconds he stays after the blast before going idle
@export var recovery_time: float = 0.8
## How far beside the player he appears, toward the middle of the arena
@export var side_offset: float = 30.0
## How far above the player's position he appears
@export var height_offset: float = 8.0
## Marker whose x counts as the middle of the arena
@export var center_marker_id: StringName = &"fireball_center"

var _destination: Marker2D
var _warning: AreaWarning
var _blasted: bool = false

func init() -> void:
	super()
	if _destination:
		return
	# A free-standing point the teleport can target; moved next to the player each cast
	_destination = Marker2D.new()
	_destination.top_level = true
	add_child(_destination)

func pick_point(_points: Array[Marker2D], _current: Marker2D) -> Marker2D:
	var player_pos: Vector2 = PlayerManager.player.global_position
	var center_x: float = 0.0
	var center: NamedMarker = wizard.get_marker(center_marker_id)
	if center:
		center_x = center.global_position.x
	var side: float = signf(center_x - player_pos.x)
	if side == 0.0:
		side = 1.0 if randf() < 0.5 else -1.0
	_destination.global_position = player_pos + Vector2(side * side_offset, -height_offset)
	return _destination

func on_cast_start() -> void:
	_blasted = false
	_free_warning()
	if warning_scene:
		_warning = warning_scene.instantiate()
		EventBus.summon_effect.emit(_warning)
		_warning.start(nova_radius, warning_time, wizard.global_position)

func cast_process(_delta: float) -> void:
	if not _blasted and _elapsed >= warning_time:
		_blast()

func is_finished() -> bool:
	return _blasted and _elapsed >= warning_time + recovery_time

func Exit() -> void:
	super()
	_free_warning()

func _blast() -> void:
	_blasted = true
	_free_warning()
	if nova_scene == null:
		return
	var nova: HellfireNova = nova_scene.instantiate()
	enemy.tag_attack(nova)
	EventBus.summon_effect.emit(nova)
	nova.blast(nova_radius, wizard.global_position)

func _free_warning() -> void:
	if is_instance_valid(_warning):
		_warning.queue_free()
	_warning = null
