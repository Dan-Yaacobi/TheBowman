class_name PlayGround extends Node2D

signal wave_reset

@onready var label: Label = $HFlowContainer/Label
@onready var summon_timer: Timer = $SummonTimer
@onready var falling_death: Area2D = $FallingDeath
@onready var tiles: TilesControl = $Tiles
@onready var current_money: CurrentMoney = $CurrentMoney

@export var enemies: Enemies
@export var wave_data: WaveData
@export var level_logic: LevelDifficultyLogic = LevelDifficultyLogic.new()

var player: Player
var enemies_killed: int
var summoned_enemies: Array[Enemy]

func _ready() -> void:
	summon_timer.timeout.connect(summon_enemy)
	falling_death.body_entered.connect(death)
	
func _process(delta: float) -> void:
	if summon_timer.is_stopped():
		summon_timer.start()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("SkipTimer"):
		summon_enemy()

func init_enemy(_position: Vector2, scene: PackedScene, _player: Player) -> Enemy:
	var new_enemy: Enemy = scene.instantiate()
	new_enemy.get_player(_player)
	new_enemy.global_position = _position
	return new_enemy

func summon_enemy() -> void:
	if player != null:
		if not wave_data.boss_wave:
			var try_double_summon: float = randf_range(0,100)
			if try_double_summon <= wave_data.double_spawn_chance:
				summon()
		summon()
		
		if enemies_killed >= wave_data.total_enemies:
			enemies_killed = 0
			wave_data.current_wave += 1
			new_wave_difficulty()
			update_label()
			
func summon() -> void:
	if summoned_enemies.size() + enemies_killed < wave_data.total_enemies:
		var enemy_position: Vector2 = player.global_position + Vector2(randi_range(-100,100),randi_range(-80,-100))
		var demo_enemy: Enemy = init_enemy(enemy_position,enemies.get_enemy(wave_data.current_wave),player)
		add_child(demo_enemy)
		
		summoned_enemies.append(demo_enemy)
		demo_enemy.died.connect(killed_enemy)

func killed_enemy(_enemy) -> void:
	_enemy.died.disconnect(killed_enemy)
	summoned_enemies.erase(_enemy)
	enemies_killed += 1
	update_label()
	
func update_label() -> void:
	label.text = "Current Wave: " + str(wave_data.current_wave) + "\n" + " Enemies Left: " + str(wave_data.total_enemies - enemies_killed)

func new_wave_difficulty() -> void:
	update_label()
	wave_data.spawn_time_update()
	wave_data.calc_total_enemies()
	wave_data.enemies_spawn = level_logic.calculate_logic(wave_data.current_wave,enemies.enemies_array.size())
	wave_data.double_spawn_chance += 1
	for i in wave_data.enemies_spawn.size():
		enemies.enemies_array[i].spawn_chance = wave_data.enemies_spawn[i]
	enemies.spawn_time = wave_data.spawn_time
	
	if wave_data.current_wave % 10 == 0:
		wave_data.boss_wave = true
		wave_data.total_enemies = 2
		update_label()
	elif wave_data.current_wave % 5 == 0:
		wave_data.boss_wave = true
		wave_data.total_enemies = 1
		update_label()
	else:
		wave_data.boss_wave = false
func death(b) -> void:
	if b is Player:
		b.dead()

func set_scene(_player: Player) -> void:
	if _player != null:
		player = _player
		visible = true
		tiles.collision_enabled = true
		_player.global_position = Vector2(0,-8)
		_player.stats.in_menu = false
		_player.set_camera(Rect2i(Vector2(-100000,-100000),Vector2(10000000,10000000)),16)
		new_wave_difficulty()
		update_label()
		summon_timer.wait_time = enemies.spawn_time
		summon_timer.timeout.connect(summon_enemy)
		falling_death.body_entered.connect(death)
		if not player.money_changed.is_connected(update_money):
			player.money_changed.connect(update_money)
		update_money(player.stats.money)

func update_money(amount) -> void:
	current_money.update_current_money(amount)
	
func exit_scene(_player) -> void:
	falling_death.body_entered.disconnect(death)
	summon_timer.timeout.disconnect(summon_enemy)
	visible = false
	tiles.collision_enabled = false
	kill_all_enemies()
	enemies_killed = 0
	wave_reset.emit(wave_data.current_wave)
	pass

func kill_all_enemies() -> void:
	for enemy in summoned_enemies:
		enemy.free()
	summoned_enemies.clear()
	pass

func change_wave(wave_num: int) -> void:
	wave_data.current_wave = wave_num
	wave_reset.emit(wave_num)
