class_name Player extends CharacterBody2D

signal died
signal money_changed
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

@onready var slow: Slow = $Debuffs/Slow
@onready var idle_state: PlayerIdleState = $PlayerStateMachine/Idle
@onready var invincibility_timer: Timer = $InvincibilityTimer

@onready var grapple_hook: GrappleHook = $GrappleHook
@onready var grappling_state: PlayerGrapplingState = $PlayerStateMachine/Grappling
@onready var hook: Hook = $GrappleHook/Hook
@onready var idle: PlayerIdleState = $PlayerStateMachine/Idle
@onready var quiver: Sprite2D = $PlayerBody/Quiver

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

var equipment_interacted: Equipment = null

var abilities: Dictionary = {
	PlayerAbility.TriggerType.PASSIVE: [],
	PlayerAbility.TriggerType.SHOOT: [],
	PlayerAbility.TriggerType.JUMP: [],
	PlayerAbility.TriggerType.DASH: [],
}
var equipped_nodes: Dictionary = {
	EquipmentData.slots.BOW: null,
	EquipmentData.slots.ARROW: null,
	EquipmentData.slots.RING: null,
}

func _ready() -> void:
	stats.player = self
	player_state_machine.Initialize(self)
	jump_reset.body_shape_entered.connect(jump_action.reset_jumps)
	stats.hp = stats.max_hp
	#init_bow()
	special_ability_cooldown.timeout.connect(can_use_special_ability)
	health_bar.init_health(stats.max_hp)
	invincibility_timer.timeout.connect(invincibility_over)
	hit_box.Damaged.connect(hit_player)
	off_hand.connect_hands(main_hand, off_hand_shoulder)
	main_hand.connect_hands(off_hand)
	EventBus.invisible_hands.connect(show_hands)
	EventBus.leeched.connect(leech_heal)
	buff_handler.set_entity(self)
	EventBus.equipment_interaction_enter.connect(equipment_interaction_begin)
	EventBus.equipment_interaction_exit.connect(equipment_interaction_end)
	
	EventBus.arrow_enemy_hit.connect(add_shot_streak)
	EventBus.arrow_missed.connect(reset_shot_streak)
	
	set_new_bow()
	set_arrow_scene()
	set_new_arrow()
func add_display_buff(buff: PlayerUpgrade) -> void:
	if buff:
		total_buffs.add_display_buff(buff)
		
func hide_buffs() -> void:
	total_buffs.visible = false
	
func show_buffs() -> void:
	total_buffs.visible = true

func get_buff_tooltip(_id: int) -> String:
	return ""
	
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
			return
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

func is_equipment_interaction() -> bool:
	return equipment_interacted != null
	
func equipment_interaction_begin(equip: Equipment) -> void:
	if equip:
		equipment_interacted = equip

func equipment_interaction_end(_equip: Equipment) -> void:
	equipment_interacted = null
	
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
			velocity.y = min(velocity.y, stats.max_down_gravity)
		else:
			velocity.y += stats.up_gravity*delta

func get_current_weapon() -> Weapon:
	return current_weapon

func set_new_bow() -> void:
	if stats.bow:
		off_hand.set_new_bow(stats.bow)

func set_new_arrow() -> void:
	main_hand.arrow_texture = stats.arrow.equipped_texture

func set_new_quiver(_texture: Texture2D) -> void:
	if _texture:
		quiver.texture = _texture
		
func set_arrow_scene() -> void:
	if stats.arrow_scene:
		main_hand.new_arrow(stats.arrow_scene)
		
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
		apply_knockback(_hurt_box.knockback_dir,_hurt_box.knockback_power)
		display_combat_text(_hurt_box.damage, Color.RED)
		
func start_invincibilty() -> void:
	modulate.a = 0.5
	invincible = true
	invincibility_timer.wait_time = stats.invinc_duration.value()
	invincibility_timer.start()
	pass
	
func invincibility_over() -> void:
	invincible = false
	self.modulate.a = 1
	hit_box.monitoring = true

func can_heal(amount: int) -> bool:
	var amount_healed: int = min(amount, stats.max_hp - stats.hp)
	return amount_healed > 0
	
func heal(amount: int) -> bool:
	var amount_healed: int = min(amount, stats.max_hp - stats.hp)
	if can_heal(amount):
		stats.hp += amount_healed
		health_bar.heal(amount_healed)
		display_combat_text(amount_healed, Color.GREEN)
		return true
	return false
	
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

func register_ability(ability: PlayerAbility) -> void:
	abilities[ability.trigger_type].append(ability)
	ability.on_equipped()

func unregister_ability(ability: PlayerAbility) -> void:
	abilities[ability.trigger_type].erase(ability)
	ability.on_unequipped()

func get_abilities(trigger: PlayerAbility.TriggerType) -> Array:
	return abilities[trigger]
	
func enable_jump() -> void:
	jump_action.can_jump = true

func disable_jump() -> void:
	jump_action.can_jump = false

############# IS METHODS #############
func is_idle() -> bool:
	return player_state_machine.curr_state is PlayerIdleState
	
func is_dash() -> bool:
	return player_state_machine.curr_state is PlayerDashState

func is_moving() -> bool:
	return direction != 0
############# GET METHODS #############

var max_speed: float = 1.0 ## 1.0 means maximum is double speed
var C: int = 200 ## controls how fast you upgrade movement speed via agility

## asymptotic increase towards max speed

func get_move_speed() -> float:
	return stats.move_speed.value()
	
func get_pull_speed() -> float:
	return stats.pull_speed.value()

func get_strength_shot_modifier() -> float:
	return stats.basic_shot_power
	
func get_arrow_ability() -> Array[ArrowAbility]:
	return stats.arrow_abilities

func get_perfect_shots_amount() -> int:
	return perfect_shot_counter

func get_shoot_abilities() -> Array[PlayerShootAbility]:
	return stats.shooting_abilities

func get_weapon_size() -> float:
	return stats.sword_size.value()


func get_sword_cd() -> float:
	return max(stats.base_sword_cooldown.value(),1.0)

func get_sword_size() -> float:
	return stats.sword_size.value()

func get_sword_abilities() -> Array[PlayerSwordAbility]:
	return stats.sword_abilities

func get_sword() -> Sword:
	return main_hand.sword
	
func get_gold_bonus() -> int:
	return stats.extra_gold
	
func get_equipped_in_slot(_slot: EquipmentData.slots) -> EquipmentData:
	match _slot:
		EquipmentData.slots.BOW:
			return stats.bow
		EquipmentData.slots.ARROW:
			return stats.arrow
		EquipmentData.slots.RING:
			return stats.ring
		_:
			return null


############# SET METHODS #############
func set_equipped_in_slot(_slot: EquipmentData.slots, _new_item: EquipmentData) -> void:
	if _slot != null and _new_item:
		var current = get_equipped_in_slot(_slot)
		if current:
			current.unequip(stats)
		_new_item.equip(stats)
		match _slot:
			EquipmentData.slots.BOW:
				stats.bow = _new_item
				set_new_bow()
			EquipmentData.slots.ARROW:
				stats.arrow = _new_item
				set_new_arrow()
				set_new_quiver(stats.arrow.texture)
			EquipmentData.slots.RING:
				stats.ring = _new_item

func equip_item(_equip: Equipment, _slot: EquipmentData.slots) -> void:
	if _equip and _slot >= 0:
		equipped_nodes[_slot] = _equip

func unequip_item(_slot: EquipmentData.slots) -> void:
	equipped_nodes[_slot] = null
	
func get_equipped_node_in_slot(_slot: EquipmentData.slots) -> Equipment:
	if _slot >= 0:
		var node = equipped_nodes[_slot]
		if is_instance_valid(node):
			return node
	return null
	
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


## STREAK ##

func add_shot_streak(_perfect: bool) -> void:
	stats.shot_streak += 1
	if _perfect:
		add_perfect_shot_streak()
	else:
		reset_perfect_shot_streak()

func add_perfect_shot_streak() -> void:
	stats.perfect_shot_streak += 1

func get_shot_streak() -> int:
	return stats.shot_streak
	
func get_perfect_shot_streak() -> int:
	return stats.perfect_shot_streak

func reset_shot_streak() -> void:
	stats.shot_streak = 0
	reset_perfect_shot_streak()
	
func reset_perfect_shot_streak() -> void:
	stats.perfect_shot_streak = 0

	
