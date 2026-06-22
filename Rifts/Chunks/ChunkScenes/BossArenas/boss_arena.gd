class_name BossArena1 extends GameWorld

@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var boss_spawner: BossSpawner = $BossSpawner
@onready var boss_island: BossIsland = $BossIsland
@onready var portal: Portal = $Portal
@onready var loot_manager: LootManager = $LootManager

var boss_died: bool = false
var boss_health_bar: HealthBar

func _ready() -> void:
	boss_spawner.boss_spawned.connect(add_enemy)
	
func extra_set_world_functions() -> void:
	loot_manager.set_up()
	EventBus.boss_health_bar.connect(set_boss_health_bar)
	EventBus.request_boss_health_bar.emit()
	
func extra_exit_world_functions() -> void:
	loot_manager.unset_up()
	PlayerManager.player.camera.zoom_in()
	EventBus.hide_boss_health_bar.emit()

func set_boss_health_bar(_bar: HealthBar) -> void:
	if _bar:
		boss_health_bar = _bar

func on_world_ready() -> void:
	PlayerManager.player.camera.zoom_out()
	portal.disable()
	await get_tree().create_timer(0.5).timeout
	if boss_spawner:
		boss_spawner.spawn(PlayerManager.player.stats.rift_level, boss_health_bar)
		
func spawn_position() -> Vector2:
	return player_spawn.global_position

func boss_dead(_boss: Enemy) -> void:
	portal.enable()
	
func add_enemy(_enemy: Enemy) -> void:
	if _enemy:
		current_enemies.append(_enemy)
		if _enemy.get_parent():
			_enemy.call_deferred("reparent", self)
		else:
			call_deferred("add_child",_enemy)
		if _enemy is Boss:
			_enemy.died.connect(boss_dead)
