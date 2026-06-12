class_name BossArena1 extends GameWorld

@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var boss_spawner: BossSpawner = $BossSpawner
@onready var boss_island: BossIsland = $BossIsland
@onready var portal: Portal = $Portal
@onready var loot_manager: LootManager = $LootManager

var boss_died: bool = false

func _ready() -> void:
	boss_spawner.boss_spawned.connect(add_enemy)

func set_world() -> void:
	loot_manager.set_up()
	EventBus.summon_effect.connect(summon_effect)
	EventBus.equipment_dropped.connect(drop_equipment)
	
func exit_world() -> void:
	loot_manager.unset_up()
	EventBus.summon_effect.disconnect(summon_effect)
	EventBus.equipment_dropped.disconnect(drop_equipment)

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
	
func drop_equipment(equip_data: EquipmentData, _position: Vector2, _existing_equip: Equipment = null) -> void:
	var new_equip: Equipment
	if _existing_equip:
		new_equip = _existing_equip
	else:
		new_equip = equip_data.equipment_scene.instantiate()
		new_equip.data = equip_data

	new_equip.global_position = _position
	if not new_equip.get_parent():
		call_deferred("add_child",new_equip)
	else:
		new_equip.call_deferred("reparent", self)
		
func summon_effect(effect: Node2D) -> void:
	call_deferred("add_child", effect)
