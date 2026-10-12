class_name BossArena extends GameWorld

@export var boss: Boss
@export var boss_visible_before_fight: bool = false
@export var intro_fade_duration: float = 1.5
@export var fight_start_delay: float = 0.5

@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var portal: Portal = $Portal
@onready var loot_manager: LootManager = $LootManager
@onready var boss_incoming_label: Label = $BossIncomingLabel

func _ready() -> void:
	_set_boss_dormant(true)

func extra_set_world_functions() -> void:
	loot_manager.set_up()
	has_respawns = true
	respawn_position = spawn_position()

func extra_exit_world_functions() -> void:
	loot_manager.unset_up()
	PlayerManager.player.camera.zoom_in()
	EventBus.hide_boss_health_bar.emit()
	queue_free()

func spawn_position() -> Vector2:
	return player_spawn.global_position

func on_world_ready() -> void:
	portal.disable()
	await _play_intro()
	if not is_inside_tree():
		return
	PlayerManager.player.camera.zoom_out()
	await get_tree().create_timer(fight_start_delay).timeout
	if not is_inside_tree():
		return
	_start_fight()

func _play_intro() -> void:
	boss_incoming_label.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(boss_incoming_label, "modulate:a", 0.0, intro_fade_duration)
	await tween.finished

func _start_fight() -> void:
	if not is_instance_valid(boss):
		return
	current_enemies.append(boss)
	boss.died.connect(_on_boss_died, CONNECT_ONE_SHOT)
	_set_boss_dormant(false)
	boss.begin_fight(self)

func _set_boss_dormant(dormant: bool) -> void:
	if not is_instance_valid(boss):
		return
	boss.process_mode = Node.PROCESS_MODE_DISABLED if dormant else Node.PROCESS_MODE_INHERIT
	boss.visible = boss_visible_before_fight or not dormant

func _on_boss_died(_boss: Enemy) -> void:
	portal.enable()
