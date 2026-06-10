class_name BossArena1 extends GameWorld

@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var boss_spawner: BossSpawner = $BossSpawner
@onready var boss_island: BossIsland = $BossIsland
@onready var portal: Portal = $Portal

var boss_died: bool = false

func _ready() -> void:
	boss_spawner.boss_spawned.connect(add_enemy)
	
func set_world() -> void:
	pass

func exit_world() -> void:
	pass

func add_enemy(_enemy: Enemy) -> void:
	if _enemy:
		add_child(_enemy)
		_enemy.died.connect(boss_dead)

func on_world_ready() -> void:
	if boss_spawner:
		boss_spawner.spawn()
	portal.disable()
	
func spawn_position() -> Vector2:
	return player_spawn.global_position

func boss_dead(_boss: Enemy) -> void:
	portal.enable()
