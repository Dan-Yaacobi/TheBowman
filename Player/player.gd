class_name Player extends CharacterBody2D

signal died
signal money_changed
signal combo(amount: int)
signal took_hit
signal critical_hit
signal dash_finished

@onready var body: PlayerBody = $PlayerBody
@onready var player_state_machine: PlayerStateMachine = $PlayerStateMachine
@onready var jump_reset: Area2D = $JumpReset
@onready var jump_action: JumpAction = $JumpAction
@onready var camera: Camera2D = $Camera2D
@onready var hit_box: HitBox = $HitBox

@onready var damaged_particles: CPUParticles2D = $DamagedParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var special_ability_cooldown: Timer = $SpecialAbilityCooldown
@onready var combo_timer: Timer = $ComboActivated/ComboTimer
@onready var combo_effect: CPUParticles2D = $ComboActivated/ComboEffect
@onready var combo_activated_effect: CPUParticles2D = $ComboActivated/ComboActivatedEffect
@onready var upgrades: Upgrades = $Upgrades

@onready var slow: Slow = $Debuffs/Slow
@onready var idle_state: PlayerIdleState = $PlayerStateMachine/Idle
@onready var invincibility_timer: Timer = $InvincibilityTimer

@onready var grapple_hook: GrappleHook = $GrappleHook
@onready var grappling_state: PlayerGrapplingState = $PlayerStateMachine/Grappling
@onready var hook: Hook = $GrappleHook/Hook
@onready var idle: PlayerIdleState = $PlayerStateMachine/Idle

@onready var spawn_handler: SpawnHandler = $SpawnHandler
var can_hook: bool = true

@export var stats: PlayerStats
@export var talents: PlayerTalents

@export_subgroup("Buffs")
@export var hit_effects: Dictionary[OnHitEffect,int] = {}
@export var perfect_shot_effects: Dictionary[OnPerfectShotEffect,int] = {}
@onready var buff_handler: BuffHandler = $BuffHandler

const PERMA_EFFECT: int = -1
const HEALTH_GAIN_EFFECT = preload("res://Weapons/Effects/LeechLife/HealthGainEffect.tscn")
var health_bar: HealthBar
var total_buffs: TotalBuffs
var special_ability_cd: Sprite2D
var direction: float
var direction_side: bool = false
var current_weapon: Weapon
var knockback_power: Dictionary = {"direction": Vector2.ZERO,
 "power": 0}
var special_ability_available: bool = true

var dropping_down: bool = false

var combo_counter: int = 48
var combo_buff: bool = false

var base_stats: PlayerStats
var bonus_stats: PlayerStats
var current_minions: Array[Companion] = []

var invincible: bool = false

@onready var main_hand: PlayerMainHand = $PlayerMainHand
@onready var off_hand: PlayerOffHand = $PlayerOffHand
@onready var off_hand_shoulder: Node2D = $OffHandShoulder

var shooting: bool = false
var perfect_shot_counter: int = 0
var current_arrow: Arrow

var current_portal: Portal
var can_dash: bool = true

func _ready() -> void:
	stats.player = self
	player_state_machine.Initialize(self)
	jump_reset.body_shape_entered.connect(jump_action.reset_jumps)
	stats.hp = stats.stamina
	init_bow()
	special_ability_cooldown.timeout.connect(can_use_special_ability)
	health_bar.init_health(stats.stamina)
	combo_timer.timeout.connect(end_combo_buff)
	init_base_stats()
	init_bonus_stats()
	reset_to_base_stats()
	invincibility_timer.timeout.connect(invincibility_over)
	hit_box.Damaged.connect(hit_player)
	off_hand.connect_hands(main_hand, off_hand_shoulder)
	main_hand.connect_hands(off_hand)
	EventBus.invisible_hands.connect(show_hands)
	EventBus.leeched.connect(leech_heal)
	buff_handler.set_entity(self)

func upgrade_stat(stat: String, amount) -> void:
	for key in upgrades.upgrades_dict.keys():
		if key == stat:
			upgrades.call_deferred(upgrades.upgrades_dict[stat],amount)

func add_ability(ability_type_name: String, ability) -> void:
	upgrades.call_deferred(upgrades.new_abilities_dict[ability_type_name],ability)

func add_display_buff(buff: PlayerUpgrade) -> void:
	if buff:
		total_buffs.add_display_buff(buff)
		
func hide_buffs() -> void:
	total_buffs.visible = false
	
func show_buffs() -> void:
	total_buffs.visible = true

func get_buff_tooltip(_id: int) -> String:
	
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

	
func init_base_stats() -> void:
	base_stats = stats.duplicate()	

func init_stats_with_bonus() -> void:
	stats = bonus_stats.duplicate()

func init_bonus_stats() -> void:
	bonus_stats = stats.duplicate()
	
func _process(_delta: float) -> void:
	if stats.hp > 0:
		direction = Input.get_axis("Left","Right")
	else:
		direction = 0

func _unhandled_input(event: InputEvent) -> void:
	if stats.hp > 0:
		if event.is_action_pressed("up"):
			if current_portal:
				current_portal.enter()
		if event.is_action_pressed("Menu"):
			EventBus.changed_scene.emit(GameWorlds.worlds.Main_Menu)
		
		if event.is_action_pressed("Jump"):
			jump_action.request_jump()

		if event.is_action_released("Jump"):
			jump_action.release_jump()

		if event.is_action_pressed("shoot",true):
			shoot()
		
		
		if event.is_action_pressed("special"):
			special_ability()
		
		if event.is_action_pressed("grapple"):
			grapple()
	
func special_ability() -> void:
	if current_weapon.weapon_data.special_ability != null:
		if special_ability_available and current_weapon.weapon_data.special_ability.can_use(self):
			current_weapon.weapon_data.special_ability.activate_special_ability(self)
			#current_weapon.regular_attack = false
			special_ability_available = false
			special_ability_cooldown.start()
	
func shoot() -> void:
	EventBus.start_shooting.emit()
	#current_weapon.regular_attack = true
	#for ability in stats.shoot_abilities:
		#ability.activate_ability(self)

func grapple() -> void:
	if not player_state_machine.curr_state is PlayerGrapplingState:
		grapple_hook.activate_hook()
		hook.call_deferred("reparent",get_parent())

func _on_hook_body_entered(_body: Node2D) -> void:
	if _body is Island:
		hook.is_active = false
		player_state_machine.ChangeState(grappling_state)
		grappling_state.hook_pos = hook.global_position
		hook.call_deferred("reparent",_body)
		jump_action.set_jumps()
		
func show_hands(yes: bool) -> void:
	main_hand.visible = yes
	off_hand.visible = yes
	
func can_use_special_ability() -> void:
	special_ability_available = true
	special_ability_cooldown.stop()
	pass
	
func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	special_ability_indictaor()
	move_and_slide()

func apply_knockback(_direction: Vector2, force: float) -> void:
	velocity += _direction.normalized() * force
	
func update_direction(_new_side: bool) -> void:
	if _new_side != direction_side:
		direction_side = _new_side
		body.change_direction(_new_side)
		main_hand.change_direction()
		off_hand_shoulder.position.x *= -1
		off_hand.position = off_hand_shoulder.position

func update_body_animation(_anim: String) -> void:
	body.update_animation(_anim)

func apply_gravity(delta) -> void:
		if velocity.y > 0:
			velocity.y += stats.down_gravity*delta
		else:
			velocity.y += stats.up_gravity*delta

func get_current_weapon() -> Weapon:
	return current_weapon

func change_to_new_bow(_new_bow: PackedScene) -> void:
	if _new_bow != null:
		stats.weapon_scene = _new_bow
		init_bow()
		
func set_hands_new_bow() -> void:
	var bow_data = current_weapon.weapon_data
	main_hand.new_arrow(bow_data.arrow)
	off_hand.new_bow(bow_data)
	
func init_bow() -> void:
	current_weapon = stats.weapon_scene.instantiate()
	set_hands_new_bow()

	#current_weapon.combo_loss.connect(combo_lost)
	#current_weapon.combo_gained.connect(combo_gained)
	#current_weapon.init_weapon(self,current_weapon)
	
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

func hit_player(_hurt_box: HurtBox) -> void:
	if not invincible:
		start_invincibilty()
		took_hit.emit()
		damaged_particles.emitting = true
		stats.hp -= _hurt_box.damage
		health_bar.reduce_health(_hurt_box.damage)
		apply_knockback(_hurt_box.knockback_dir,_hurt_box.knockback)
		display_combat_text(_hurt_box.damage, Color.RED)
		
func start_invincibilty() -> void:
	hit_box.set_collision_layer_value(1,false)
	hit_box.set_collision_mask_value(3,false)
	modulate.a = 0.5
	invincible = true
	invincibility_timer.wait_time = stats.invinc_duration + get_stamina() * 0.02
	invincibility_timer.start()
	pass
	
func invincibility_over() -> void:
	invincible = false
	hit_box.set_collision_layer_value(1,true)
	hit_box.set_collision_mask_value(3,true)
	self.modulate.a = 1
	hit_box.monitoring = true
	
func heal(amount: int) -> void:
	if stats.hp + amount <= get_stamina():
		stats.hp += amount
		health_bar.heal(amount)
		display_combat_text(amount, Color.GREEN)
		
func display_combat_text(amount: int, color: Color) -> void:
	CombatTextSpawner.spawn(global_position, str(amount),color)

func leech_heal(amount: int,enemy_position: Vector2) -> void:
	var health_gain_effect: HealthGainEffect = HEALTH_GAIN_EFFECT.instantiate()
	health_gain_effect.set_positions(self,enemy_position)
	health_gain_effect.heal_amount = amount
	get_parent().call_deferred("add_child", health_gain_effect)
	
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
	special_ability_cd.update_time_left(t_left)

func slow_player(slow_time: float,effect: Node2D) -> void:
	slow.slow_player(slow_time,effect)

func buy(price: int) -> bool:
	if stats.money >= price:
		stats.money -= price
		return true
	return false

func add_shoot_ability(_ability: PlayerShootAbility) -> void:
	if _ability:
		stats.shooting_abilities.append(_ability)

func add_sword_ability(_ability: PlayerSwordAbility) -> void:
	if _ability:
		stats.sword_abilities.append(_ability)

func enable_jump() -> void:
	jump_action.can_jump = true

func disable_jump() -> void:
	jump_action.can_jump = false
	
############# COMBO METHODS #############
func combo_lost() -> void:
	combo_counter = 0
	combo.emit(combo_counter)
	pass

func combo_gained() -> void:
	combo_counter += 1
	if stats.max_combo < combo_counter:
		stats.max_combo = combo_counter
		
	if combo_counter %stats.combo_to_activate == 0:
		combo_bonus_activate()
	combo.emit(combo_counter)
	pass

func combo_bonus_activate() -> void:
	combo_activated_effect.emitting = true
	combo_buff = true
	combo_timer.wait_time = stats.combo_duration
	combo_timer.start()
	combo_effect.emitting = true
	current_weapon.weapon_data.combo_buff_activated = true

func end_combo_buff() -> void:
	if combo_buff:
		combo_buff = false
		combo_effect.emitting = false
		current_weapon.weapon_data.combo_buff_activated = false

############# IS METHODS #############
func is_idle() -> bool:
	return player_state_machine.curr_state is PlayerIdleState
	
func is_dash() -> bool:
	return player_state_machine.curr_state is PlayerDashState

func is_moving() -> bool:
	return direction != 0
############# GET METHODS #############
func get_strength() -> int:
	return stats.strength
	
func get_agility() -> int:
	return stats.agility
	
func get_stamina() -> int:
	return stats.stamina

var max_speed: float = 1.0 ## 1.0 means maximum is double speed
var C: int = 200 ## controls how fast you upgrade movement speed via agility

## asymptotic increase towards max speed
func get_move_speed() -> float:
	return stats.move_speed.value() * (1.0 + max_speed * get_agility() / (get_agility() + C))
	
func get_pull_speed() -> float:
	return stats.pull_speed + get_agility()*0.01

func get_strength_shot_modifier() -> float:
	return get_strength() + stats.basic_shot_power

func get_arrow_ability() -> Array[ArrowAbility]:
	return stats.arrow_abilities

func get_perfect_shots_amount() -> int:
	return perfect_shot_counter

func get_shoot_abilities() -> Array[PlayerShootAbility]:
	return stats.shooting_abilities

func get_weapon_size() -> float:
	return stats.sword_size

func get_stat_points() -> int:
	return stats.stat_points

func get_sword_cd() -> float:
	return max(stats.base_sword_cooldown - stats.sword_cooldown_mod,1.0)

func get_sword_size() -> float:
	return stats.sword_size + stats.sword_size_mod

func get_sword_abilities() -> Array[PlayerSwordAbility]:
	return stats.sword_abilities

func get_sword() -> Sword:
	return main_hand.sword
	
func get_gold_bonus() -> int:
	return stats.extra_gold
############# SET METHODS #############

func set_gold_bonus(_amount: int) -> void:
	stats.extra_gold += _amount

func set_sword_size(amount: float) -> void:
	stats.sword_size_mod = amount
	
func set_sword_cd(amount: float) -> void:
	stats.sword_cooldown_mod = amount

func set_shooting(_val: bool) -> void:
	shooting = _val
	
func set_perfect_shots(was_perfect: bool) -> void:
	if was_perfect:
		perfect_shot_counter += 1
	else:
		perfect_shot_counter = 0

func set_strength(amount: int) -> void:
	stats.strength += amount
	
func set_agility(amount: int) -> void:
	stats.agility += amount
	
func set_stamina(amount: int) -> void:
	stats.stamina += amount
	stats.hp = stats.stamina
	health_bar.init_health(stats.stamina)

func use_stat_point() -> bool:
	if stats.stat_points > 0:
		stats.stat_points -= 1
		return true
	return false

## If amount is not provided, the effect is considered permanent. Otherwise amount means how many times the effect can be consumed.
func add_hit_effect(_effect: OnHitEffect, _amount: int = PERMA_EFFECT) -> void:
	if hit_effects.has(_effect):
		if _amount > 0:
			hit_effects[_effect] += _amount
	else:
		hit_effects[_effect] = _amount
func remove_hit_effect(_effect: OnHitEffect) -> void:
	if hit_effects.has(_effect):
		hit_effects.erase(_effect)
	
func use_effects() -> Array[OnHitEffect]:
	var _effects: Array[OnHitEffect] = []
	for key in hit_effects.keys():
		if hit_effects[key] > 0 and hit_effects[key] != PERMA_EFFECT:
			hit_effects[key] -= 1
			if hit_effects[key] == 0:
				hit_effects.erase(key)
		_effects.append(key)
	return _effects

func add_perfect_shot_effect(_effect: OnPerfectShotEffect, _amount: int = PERMA_EFFECT) -> void:
	if perfect_shot_effects.has(_effect):
		if _amount > 0:
			perfect_shot_effects[_effect] += _amount
		else:
			perfect_shot_effects[_effect] = _amount

func use_perfect_shot_effects() -> Array[OnPerfectShotEffect]:
	var _effects: Array[OnPerfectShotEffect] = []
	for key in perfect_shot_effects.keys():
		if perfect_shot_effects[key] > 0 and perfect_shot_effects[key] != PERMA_EFFECT:
			perfect_shot_effects[key] -= 1
			if perfect_shot_effects[key] == 0:
				perfect_shot_effects.erase(key)
		_effects.append(key)
	return _effects
