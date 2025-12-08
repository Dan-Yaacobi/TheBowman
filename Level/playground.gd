class_name PlayGround extends Node2D

signal wave_reset
signal new_wave

@onready var player_spawn: PlayerSpawn = $PlayerSpawn

@onready var label: Label = $WaveSign/WaveBackground/Label
@onready var summon_timer: Timer = $SummonTimer
@onready var falling_death: Area2D = $FallingDeath
@onready var tiles: TilesControl = $Tiles

@onready var upgrade_buttons: Node2D = $UpgradeButtons

@onready var upgrade_button_1: UpgradeButton = $UpgradeButtons/UpgradeButton
@onready var upgrade_button_2: UpgradeButton = $UpgradeButtons/UpgradeButton2
@onready var upgrade_button_3: UpgradeButton = $UpgradeButtons/UpgradeButton3
@onready var upgrades: UpgradeBuckets = $UpgradeButtons/Upgrades

@export var enemies: Enemies
@export var wave_data: WaveData
@export var level_logic: LevelDifficultyLogic = LevelDifficultyLogic.new()
@export var summon_objects: SummonObjects
@export_custom(PROPERTY_HINT_NONE,"suffix:%") var summon_object_chance: int

var active_towers: Array[Tower]
var player: Player
var enemies_killed: int
var summoned_enemies: Array[Enemy]
var summon_count: int = 0
var stop_waves: bool = false
var hard_mode: bool = false
var can_summon_object: bool = false
var summoned_an_object: bool = false

func _ready() -> void:
	summon_timer.timeout.connect(summon_enemy)
	upgrade_button_1.choose_button.pressed.connect(new_wave_difficulty)
	upgrade_button_2.choose_button.pressed.connect(new_wave_difficulty)
	upgrade_button_3.choose_button.pressed.connect(new_wave_difficulty)
	upgrade_buttons.disable()
	
func _process(delta: float) -> void:
	if summon_timer.is_stopped():
		summon_timer.start()

func _unhandled_input(event: InputEvent) -> void:
	if player != null:
		if event.is_action_pressed("SkipTimer") and player.get_parent() == self:
			summon_enemy()

func summon_enemy() -> void:
	if player != null and not stop_waves:
		if not wave_data.boss_wave:
			if wave_data.current_wave > 5:
				try_to_summon_object()
		summon()

func try_to_summon_object() -> void:
	if can_summon_object:
		var try_summon_object: int = randi_range(1,100)
		if try_summon_object < summon_object_chance:
			summon_object()
			can_summon_object = false
const CLOUD_ENEMY = preload("uid://d2ag7d2j5mctf")

func summon() -> void:
	if summoned_enemies.size() + enemies_killed < wave_data.total_enemies:
		
		var enemy_position: Vector2 = player.global_position + Vector2(randi_range(-100,100),randi_range(-80,-100))
		var enemy: Enemy = enemies.get_enemy(wave_data.current_wave)# init_enemy(enemy_position,,player)
		enemy.global_position = enemy_position
		summoned_enemies.append(enemy)
		enemy.died.connect(killed_enemy)
		summon_count += 1
		add_child(enemy)
		#if enemy != null:
			#if enemy is Spider:
				#enemy.global_position.x = player.global_position.x
				#
			#if wave_data.current_wave % 10 == 0:
				#wave_data.spawn_time = 0.1
				#if summon_count == 1:
					#enemy.stats.shooter = true
				#else:
					#enemy.disable_drops()
			#add_child(enemy)
			

		
func summon_spider() -> void:
	return
	#var spider_enemy: Enemy = init_enemy(Vector2.ZERO,enemies.spiders[0].enemy,player)
	#spider_enemy.global_position.x = player.global_position.x
	#spider_enemy.global_position.y = -100
	#add_child(spider_enemy)
	
func killed_enemy(_enemy) -> void:
	_enemy.died.disconnect(killed_enemy)
	summoned_enemies.erase(_enemy)
	enemies_killed += 1
	if enemies_killed == wave_data.total_enemies:
		await get_tree().create_timer(0.5).timeout
		between_waves()
	update_label()

func update_label() -> void:
	label.text = "Wave: " + str(wave_data.current_wave)# + "\n" + " Enemies Left: " + str(wave_data.total_enemies - enemies_killed)

func between_waves() -> void:
	wave_data.current_wave += 1
	enemies_killed = 0
	if wave_data.boss_wave:
		summon_object()
	stop_waves = true
	clear_bullets()
	player.can_use_special_ability()

	upgrade_buttons.get_upgrades(wave_data.current_wave)
	upgrade_buttons.enable()

func clear_bullets() -> void:
	for child in get_children():
		if child is EnemyBullet:
			child.queue_free()
			
func new_wave_difficulty() -> void:
	can_summon_object = true
	upgrade_buttons.disable()
	stop_waves = false	
	new_wave.emit()
	update_label()
	summon_count = 0
	wave_data.calc_total_enemies()
	#wave_data.targets_spawn = level_logic.calculate_logic_targets(wave_data.current_wave,enemies.target_enemies.size())
	#wave_data.bird_spawn = level_logic.calculate_logic_birds(wave_data.current_wave,enemies.bird_enemies.size())
	#wave_data.spider_spawn = level_logic.calculate_logic_spiders(wave_data.current_wave,enemies.spiders.size())
	#wave_data.double_spawn_chance += 0.05
	
	#for i in wave_data.targets_spawn.size():
		#enemies.target_enemies[i].spawn_chance = wave_data.targets_spawn[i]
		#
	#for i in wave_data.bird_spawn.size():
		#enemies.bird_enemies[i].spawn_chance = wave_data.bird_spawn[i]
	#
	#for i in wave_data.spider_spawn.size():
		#enemies.spiders[i].spawn_chance = wave_data.spider_spawn[i]
		#
	#enemies.spawn_time = wave_data.spawn_time
	#
	#if wave_data.current_wave % 10 == 0:
		#wave_data.boss_wave = true
		#wave_data.total_enemies = 2
		#update_label()
	#elif wave_data.current_wave % 5 == 0:
		#wave_data.boss_wave = true
		#wave_data.total_enemies = 1
		#update_label()
	#else:
		#wave_data.boss_wave = false

func set_scene(_player: Player) -> void:
	if _player != null:
		player = _player
		upgrade_buttons.player = _player
		_player.show_buffs()
		visible = true
		tiles.collision_enabled = true
		_player.global_position = player_spawn.global_position
		_player.stats.in_menu = false
		_player.set_camera(Rect2i(Vector2(-100000,-100000),Vector2(10000000,10000000)),16)
		new_wave_difficulty()
		update_label()
		summon_timer.wait_time = wave_data.spawn_time
		summon_timer.timeout.connect(summon_enemy)
		falling_death.monitoring = true
		set_towers()

func exit_scene(_player: Player) -> void:
	summon_timer.timeout.disconnect(summon_enemy)
	visible = false
	tiles.collision_enabled = false
	kill_all_enemies()
	enemies_killed = 0
	wave_reset.emit(wave_data.current_wave)
	falling_death.monitoring = false
	_player.reset_minions()
	_player.hide_buffs()
	
func kill_all_enemies() -> void:
	for enemy in summoned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	clear_bullets()
			
	summoned_enemies.clear()
	clear_tower_targets()
	
func set_towers() -> void:
	const TOWER = preload("res://Tower/Tower.tscn")
	for tower in active_towers:
		tower.queue_free()
		active_towers.erase(tower)
		
	for tower_data in player.stats.towers:
		if tower_data.position != Vector2.ZERO:
			var _tower: Tower = TOWER.instantiate()
			add_child(_tower)
			_tower.data = tower_data
			_tower.set_tower()
			active_towers.append(_tower)

func clear_tower_targets() -> void:
	for tower in active_towers:
		tower.clear_all_targets()

func summon_object() -> void:
	var new_object: FallingObject  = summon_objects.get_object(player)
	var summon_position: Vector2 = Vector2.ZERO
	if not wave_data.boss_wave:
		summon_position = player.global_position + Vector2([1,-1].pick_random() * 50, - 100)
	new_object.global_position = summon_position
	add_child(new_object)

func _on_falling_death_body_entered(body: Node2D) -> void:
	if body is FallingObject:
		body.queue_free()
	elif body is Player:
		body.stats.hp = 0
	elif body is Arrow:
		body.missed()
	pass # Replace with function body.
