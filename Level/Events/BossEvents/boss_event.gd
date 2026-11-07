class_name BossEvent extends Event

## Boss fight played as a rift event. The exit portal only appears once the boss dies.

@export var boss: Boss
@export var boss_visible_before_fight: bool = false
@export var intro_fade_duration: float = 1.5
@export var fight_start_delay: float = 0.5

@onready var exit_portal: EventPortal = $EventPortal
@onready var boss_incoming_label: Label = $BossIncomingLabel
@onready var falling_death: FallingDeath = $FallingDeath

var _world: GameWorld = null
var _world_respawn_position: Vector2 = Vector2.ZERO
var _zoomed_out: bool = false

func _ready() -> void:
	_set_boss_dormant(true)
	_set_exit_portal_active(false)
	boss_incoming_label.modulate.a = 0.0

func on_event_entered() -> void:
	# Falling inside the event should respawn here, not back in the rift
	_world = get_parent() as GameWorld
	if _world:
		_world_respawn_position = _world.respawn_position
		_world.respawn_position = get_event_spawn()

	await _play_intro()
	if not is_inside_tree():
		return
	PlayerManager.player.camera.zoom_out()
	_zoomed_out = true
	await get_tree().create_timer(fight_start_delay).timeout
	if not is_inside_tree():
		return
	_start_fight()

func on_event_exited() -> void:
	if is_instance_valid(_world):
		_world.respawn_position = _world_respawn_position
	if _zoomed_out:
		PlayerManager.player.camera.zoom_in()
		_zoomed_out = false
	EventBus.hide_boss_health_bar.emit()

func _play_intro() -> void:
	boss_incoming_label.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(boss_incoming_label, "modulate:a", 0.0, intro_fade_duration)
	await tween.finished

func _start_fight() -> void:
	if not is_instance_valid(boss):
		_on_boss_died(null)
		return
	boss.died.connect(_on_boss_died, CONNECT_ONE_SHOT)
	_set_boss_dormant(false)
	boss.begin_fight(null)

func _set_boss_dormant(dormant: bool) -> void:
	if not is_instance_valid(boss):
		return
	boss.process_mode = Node.PROCESS_MODE_DISABLED if dormant else Node.PROCESS_MODE_INHERIT
	boss.visible = boss_visible_before_fight or not dormant

func _set_exit_portal_active(active: bool) -> void:
	exit_portal.visible = active
	exit_portal.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func _on_boss_died(_boss: Enemy) -> void:
	_set_exit_portal_active(true)
	# The fight is won; falling now only respawns the player
	falling_death.costs_heart = false
	spawn_rewards(exit_portal.global_position)
	report_finished(true)
