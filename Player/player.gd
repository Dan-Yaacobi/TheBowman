class_name Player extends CharacterBody2D

signal died
signal money_changed
signal combo(amount: int)
signal took_hit
signal critical_hit
signal back_to_menu(scene: String)

@onready var hand: Hand = $Hand
@onready var body: Body = $Body
@onready var player_state_machine: PlayerStateMachine = $PlayerStateMachine
@onready var jump_reset: Area2D = $JumpReset
@onready var jump_action: JumpAction = $JumpAction
@onready var shoot_action: ShootAction = $ShootAction
@onready var hit_box: Area2D = $HitBox
@onready var camera: Camera2D = $Camera2D
@onready var mana_bar: ManaBar = $ManaBar
@onready var damaged_particles: CPUParticles2D = $DamagedParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var death_animation_timer: Timer = $DeathAnimationTimer
@onready var special_ability_cooldown: Timer = $SpecialAbilityCooldown
@onready var unlimited_mana_timer: Timer = $UnlimitedManaTimer
@onready var combo_timer: Timer = $ComboActivated/ComboTimer
@onready var combo_effect: CPUParticles2D = $ComboActivated/ComboEffect
@onready var combo_activated_effect: CPUParticles2D = $ComboActivated/ComboActivatedEffect
@onready var charge_timer: Timer = $ChargeTimer

@onready var upgrades: Upgrades = $Upgrades
@onready var mega_shot_effect: CPUParticles2D = $MegaShotEffect

@onready var special_ability_cd: Sprite2D = $SpecialAbilityCD
@onready var time_left_label: Label = $SpecialAbilityCD/TimeLeftLabel
@onready var health_bar: HealthBar = $HealthBar

@onready var total_buffs: TotalBuffs = $TotalBuffs
@onready var slow: Slow = $Debuffs/Slow
@onready var idle_state: PlayerIdleState = $PlayerStateMachine/Idle

@export var gravity: int
@export var stats: PlayerStats

const HEALTH_GAIN_EFFECT = preload("res://Weapons/Effects/LeechLife/HealthGainEffect.tscn")

var direction: float
var direction_side: bool = false
var current_weapon: Weapon
var knockback_power: Dictionary = {"direction": Vector2.ZERO,
 "power": 0}
var special_ability_available: bool = true

var regular_mana_cost: int = 1
var unlimited_mana_effect: CPUParticles2D

var dropping_down: bool = false

var combo_counter: int = 48
var combo_buff: bool = false

var base_stats: PlayerStats
var bonus_stats: PlayerStats
var current_minions: Array[Companion] = []

var mega_shot_activated: bool = false

func _ready() -> void:
	
	stats.player = self
	player_state_machine.Initialize(self)
	jump_reset.body_shape_entered.connect(jump_action.reset_jumps)
	stats.hp = stats.max_hp
	init_bow()
	charge_timer.timeout.connect(activate_mega_shot)
	mana_bar.set_mana_bar_stats(current_weapon.weapon_data.mana_rate,current_weapon.weapon_data.shoot_cost)
	special_ability_cooldown.timeout.connect(can_use_special_ability)
	unlimited_mana_timer.timeout.connect(end_unlimited_mana)
	health_bar.init_health(stats.max_hp)
	combo_timer.timeout.connect(end_combo_buff)
	init_base_stats()
	init_bonus_stats()
	reset_to_base_stats()
	mega_shot_effect.stop()
	
func upgrade_stat(stat: String, amount) -> void:
	for key in upgrades.upgrades_dict.keys():
		if key == stat:
			upgrades.call_deferred(upgrades.upgrades_dict[stat],amount)

func add_ability(ability_type_name: String, ability) -> void:
	upgrades.call_deferred(upgrades.new_abilities_dict[ability_type_name],ability)

func add_display_buff(buff: PlayerUpgrade) -> void:
	if buff != null:
		total_buffs.add_display_buff(buff)
		
func hide_buffs() -> void:
	total_buffs.visible = false
	
func show_buffs() -> void:
	total_buffs.visible = true

func get_buff_tooltip(id: int) -> String:
	
	return ""
func reset_to_base_stats() -> void:
	base_stats.money = stats.money
	base_stats.upgrd_points = stats.upgrd_points
	
	for ability in stats.jump_abilities:
		ability.deactivate_ability(self)
	for ability in stats.shoot_abilities:
		ability.deactivate_ability(self)
	for ability in stats.arrow_abilities:
		ability.deactivate_ability(self)
	for ability in stats.slam_abilities:
		ability.deactivate_ability(self)
	stats = base_stats.duplicate()
	stats.menu_speed = base_stats.move_speed * 2
	
func init_base_stats() -> void:
	stats.menu_speed = stats.move_speed * 2
	base_stats = stats.duplicate()	

func init_stats_with_bonus() -> void:
	stats = bonus_stats.duplicate()

func init_bonus_stats() -> void:
	bonus_stats = stats.duplicate()
	
func _process(delta: float) -> void:
	if stats.hp > 0:
		direction = Input.get_axis("Left","Right")
	else:
		direction = 0
	
func _unhandled_input(event: InputEvent) -> void:
	
	if stats.hp > 0:

		if event.is_action_pressed("test"):
			pass

		if event.is_action_pressed("Menu"):
			back_to_menu.emit("Menu")
				
		if event.is_action_pressed("Jump"):
			jump_action.jump()
			for ability in stats.jump_abilities:
				ability.activate_ability(self)
				
		if not stats.can_mega_shot:
			if event.is_action_pressed("shoot",true):
				shoot()
				
		else:
			if event.is_action_pressed("shoot",true):
				shoot()
				
				if charge_timer.wait_time > 0:
					mega_shot_effect.start(charge_timer.wait_time)
					if charge_timer.is_stopped():
						charge_timer.start()
			if event.is_action_released("shoot",true):
				mega_shot_stop()
				if mega_shot_activated:
					mega_shot()

		if event.is_action_pressed("special ability"):
			special_ability()
			
func mega_shot_stop() -> void:
	mega_shot_effect.stop()
	charge_timer.stop()
	
func special_ability() -> void:
	if current_weapon.weapon_data.special_ability != null:
		if special_ability_available and current_weapon.weapon_data.special_ability.can_use(self):
			if mana_bar.use_mana(current_weapon.weapon_data.spcl_ablty_cost_mltplr):
				current_weapon.weapon_data.special_ability.activate_special_ability(self)
				current_weapon.regular_attack = false
				special_ability_available = false
				special_ability_cooldown.start()

func activate_mega_shot() -> void:
	mega_shot_activated = true
	
func deactivate_mega_shot() -> void:
	mega_shot_activated = false
	mega_shot_stop()
	
func mega_shot() -> void:
	var mouse_pos = get_global_mouse_position()
	for ability in stats.shoot_abilities:
		ability.activate_ability(self)
	shoot_action.mega_shot(mouse_pos)
	deactivate_mega_shot()
	pass
	
func shoot() -> void:
	if mana_bar.use_mana(regular_mana_cost):
		current_weapon.regular_attack = true
		var mouse_pos = get_global_mouse_position()
		for ability in stats.shoot_abilities:
			ability.activate_ability(self)
		shoot_action.shoot(mouse_pos)

func combo_lost() -> void:
	combo_counter = 0
	combo.emit(combo_counter)
	pass
	
func combo_gained() -> void:
	combo_counter += 1
	if combo_counter %25 == 0:
		combo_bonus_activate()
	combo.emit(combo_counter)
	pass

func combo_bonus_activate() -> void:
	combo_activated_effect.emitting = true
	combo_buff = true
	combo_timer.start()
	combo_effect.emitting = true
	stats.knockback_resistance += 5
	stats.max_jumps += 3
	current_weapon.weapon_data.special_ability_cooldown /= 2
	current_weapon.weapon_data.combo_buff_activated = true
	current_weapon.weapon_data.mana_rate *= 3
	mana_bar.change_color(Color.PURPLE)
	health_bar._set_health(stats.max_hp)
	pass
	
func end_combo_buff() -> void:
	if combo_buff:
		combo_buff = false
		combo_effect.emitting = false
		current_weapon.weapon_data.combo_buff_activated = false
		current_weapon.weapon_data.special_ability_cooldown *= 2
		current_weapon.weapon_data.mana_rate /= 3
		mana_bar.regular_color()
		stats.knockback_resistance -= 5
		stats.max_jumps -= 3

func start_unlimited_mana() -> void:
	unlimited_mana_timer.start()
	mana_bar.change_color(Color.RED)
	regular_mana_cost = 0
	unlimited_mana_effect.emitting = true
	
func end_unlimited_mana() -> void:
	mana_bar.regular_color()
	regular_mana_cost = 1
	unlimited_mana_effect.emitting = false
	pass

func can_use_special_ability() -> void:
	special_ability_available = true
	special_ability_cooldown.stop()
	pass
	
func _physics_process(delta: float) -> void:
	pushed_back(knockback_power["direction"], knockback_power["power"])
	apply_gravity(delta)
	move_and_slide()
	special_ability_indictaor()
	#if dropping_down:
		#drop_down()
		
func update_animation(_animation_name: String) -> void:
	body.change_animation(_animation_name)

func update_direction(_new_side: bool) -> void:
	if _new_side != direction_side:
		direction_side = _new_side
		body.change_side(direction_side)

func apply_gravity(delta) -> void:
		if velocity.y < 100:
			velocity.y += gravity*delta

func get_shoot_direction() -> Vector2:
	return hand.hand_direction.normalized()

func get_current_weapon() -> Weapon:
	return current_weapon

func change_to_new_bow(_new_bow: PackedScene) -> void:
	if _new_bow != null:
		stats.weapon_scene = _new_bow
		init_bow()

func init_bow() -> void:
	#if current_weapon != null:
		#new_bow_buy_effect.emitting = true
		#
	
	current_weapon = stats.weapon_scene.instantiate()
	current_weapon.arrow_hit_sound.connect(shoot_action.arrow_hit_sound)
	current_weapon.combo_loss.connect(combo_lost)
	current_weapon.combo_gained.connect(combo_gained)
	current_weapon.critical_hit.connect(emit_crit)
	current_weapon.leeched.connect(leech_heal)
	hand.sprite.frame = current_weapon.weapon_data.sprite_frame
	current_weapon.init_weapon(self,current_weapon)
	mana_bar.set_mana_bar_stats(current_weapon.weapon_data.mana_rate,current_weapon.weapon_data.shoot_cost)
	
	if current_weapon.weapon_data.special_ability_cooldown <= 0:
		special_ability_cooldown.wait_time = 1
	else:
		special_ability_cooldown.wait_time = current_weapon.weapon_data.special_ability_cooldown

func can_summon() -> bool:
	return current_minions.size() < stats.max_minions

func reset_minions() -> void:
	for minion in current_minions:
		minion.queue_free()
		current_minions.erase(minion)
		
func emit_crit() -> void:
	critical_hit.emit()
	
func hit_player(damage: int) -> void:
	took_hit.emit()
	damaged_particles.emitting = true
	stats.hp -= damage
	health_bar._set_health(stats.hp)
	
func heal(amount: int) -> void:
	if amount < 0:
		if stats.hp - amount > stats.max_hp:
			return
	stats.hp -= amount
	health_bar._set_health(stats.hp)

func leech_heal(amount: int,enemy_position: Vector2) -> void:
	var health_gain_effect: HealthGainEffect = HEALTH_GAIN_EFFECT.instantiate()
	health_gain_effect.set_positions(self,enemy_position)
	health_gain_effect.heal_amount = amount
	get_parent().call_deferred("add_child", health_gain_effect)
	
func pushed_back(_direction: Vector2, _power: int) -> void:
	if knockback_power["power"] < stats.knockback_resistance:
		return
	if knockback_power["power"] > 0:
		knockback_power["power"] -= stats.knockback_resistance
		velocity.x += _direction.x * _power
	pass

func set_pushback_values(_direction: Vector2, _power: int):
	if _direction.x > 0:
		_direction.x = 1
	else:
		_direction.x = -1
	knockback_power["direction"] = _direction
	knockback_power["power"] = _power

func collect_money(amount: int) -> void:
	stats.money += amount
	money_changed.emit(stats.money)

func set_camera(tile_limit: Rect2i,tile_size: int) -> void:
	camera.limit_top = tile_limit.position[0] * tile_size
	camera.limit_left = tile_limit.position[1] * tile_size
	camera.limit_right = tile_limit.end[0] * tile_size
	camera.limit_bottom = tile_limit.end[1] * tile_size
	pass

func special_ability_indictaor() -> void:
	var t_left = special_ability_cooldown.time_left
	var t_total = special_ability_cooldown.wait_time
	special_ability_cd.modulate.a = 1 - t_left/t_total
	time_left_label.text = str(round_to_dec(t_left,1))
	pass
	
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
	
func slow_player(slow_time: float,effect: Node2D) -> void:
	slow.slow_player(slow_time,effect)
