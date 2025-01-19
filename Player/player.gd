class_name Player extends CharacterBody2D

signal died
signal money_changed

@onready var hand: Hand = $Hand
@onready var body: Body = $Body
@onready var player_state_machine: Node2D = $PlayerStateMachine
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

@onready var special_ability_cd: Sprite2D = $SpecialAbilityCD
@onready var time_left_label: Label = $SpecialAbilityCD/TimeLeftLabel

@export var gravity: int
@export var stats: PlayerStats

var direction: float
var direction_side: bool = false
var current_weapon: Weapon
var knockback_power: Dictionary = {"direction": Vector2.ZERO,
 "power": 0}
var special_ability_available: bool = true

var regular_mana_cost: int = 1
var unlimited_mana_effect: CPUParticles2D

func _ready() -> void:
	player_state_machine.Initialize(self)
	jump_reset.body_shape_entered.connect(jump_action.reset_jumps)
	stats.hp = stats.max_hp
	init_bow()
	stats.menu_speed = stats.move_speed * 2
	mana_bar.set_mana_bar_stats(current_weapon.weapon_data.mana_rate,current_weapon.weapon_data.shoot_cost)
	death_animation_timer.wait_time = body.animation_player.get_animation("Dead").length
	death_animation_timer.timeout.connect(reset)
	special_ability_cooldown.timeout.connect(can_use_special_ability)
	unlimited_mana_timer.timeout.connect(end_unlimited_mana)
	
func _process(delta: float) -> void:
	direction = Input.get_axis("Left","Right")
	#print("current scene is: ", get_parent(), " position ", global_position)
	
func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Jump"):
		jump_action.jump()
		for ability in stats.jump_abilities:
			ability.activate_ability()

	if event.is_action_pressed("shoot",true):
		if mana_bar.use_mana(regular_mana_cost):
			var mouse_pos = get_global_mouse_position()
			shoot_action.shoot(mouse_pos)
			for ability in stats.shoot_abilities:
				ability.activate_ability()

	if event.is_action_pressed("special ability"):
		if stats.special_ability != null:
			if special_ability_available and mana_bar.use_mana(current_weapon.weapon_data.spcl_ablty_cost_mltplr):
				stats.special_ability.activate_special_ability(self)
				special_ability_available = false
				special_ability_cooldown.start()
				
	if event.is_action_pressed("GodMode") and self.get_parent() is MainMenu:
		stats.money += 10000
		money_changed.emit(stats.money)
		
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
	stats.special_ability = current_weapon.weapon_data.special_ability
	hand.sprite.frame = current_weapon.weapon_data.sprite_frame
	current_weapon.init_weapon(self,current_weapon)
	
	if current_weapon.weapon_data.special_ability_cooldown <= 0:
		special_ability_cooldown.wait_time = 1
	else:
		special_ability_cooldown.wait_time = current_weapon.weapon_data.special_ability_cooldown

	
func hit_player(damage: int) -> void:
	stats.hp -= damage
	damaged_particles.emitting = true
	if stats.hp <= 0:
		dead()

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

func dead() -> void:
	body.change_animation("Dead")
	hand.visible = false
	collision_shape.set_deferred("disabled", true)
	death_animation_timer.start()
	
func reset() -> void:
	body.change_animation("Idle")
	collision_shape.set_deferred("disabled", false)
	stats.hp = stats.max_hp
	died.emit("Menu")
	hand.visible = true
	
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
