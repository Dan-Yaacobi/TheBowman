class_name Player extends GameEntity

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
@onready var active_ability_cooldown: Timer = $ActiveAbilityCooldown

@onready var slow: Slow = $Debuffs/Slow
@onready var idle_state: PlayerIdleState = $PlayerStateMachine/Idle
@onready var invincibility_timer: Timer = $InvincibilityTimer

@onready var grapple_hook: GrappleHook = $GrappleHook
@onready var grappling_state: PlayerGrapplingState = $PlayerStateMachine/Grappling
@onready var hook: Hook = $GrappleHook/Hook
@onready var idle: PlayerIdleState = $PlayerStateMachine/Idle
@onready var quiver: Sprite2D = $PlayerBody/Quiver
@onready var dead: PlayerDeadState = $PlayerStateMachine/Dead

@onready var spawn_handler: SpawnHandler = $SpawnHandler
var can_hook: bool = true
@export var target_dummy_tutorial_passed: bool = false

@export var stats: PlayerStats
@export var talents: PlayerTalents

@export_subgroup("Buffs")
@export var hit_effects: Dictionary[OnHitEffect,int] = {}
@export var perfect_shot_effects: Dictionary[OnPerfectShotEffect,int] = {}
@onready var buff_handler: BuffHandler = $BuffHandler

const PERMA_EFFECT: int = -1
const HEALTH_GAIN_EFFECT = preload("res://Weapons/Effects/LeechLife/HealthGainEffect.tscn")
var health_bar: HealthBar
var direction: float
var direction_side: bool = false
var current_weapon: Weapon
var knockback_power: Dictionary = {"direction": Vector2.ZERO,
 "power": 0}
var active_ability_available: bool = true
var dropping_down: bool = false

var base_stats: PlayerStats
var current_minions: Array[Companion] = []

var invincible: bool = false

@onready var main_hand: PlayerMainHand = $PlayerMainHand
@onready var off_hand: PlayerOffHand = $PlayerOffHand
@onready var off_hand_shoulder: Node2D = $OffHandShoulder

var shooting: bool = false
var current_arrow: Arrow

var current_portal: Portal
var can_dash: bool = true

var equipment_interacted: Equipment = null

var knockback: Vector2 = Vector2.ZERO
const KNOCKBACK_FRICTION: float = 300.0 


var equipped_nodes: Dictionary = {
	EquipmentData.slots.BOW: null,
	EquipmentData.slots.ARROW: null,
	EquipmentData.slots.RING: null,
}
var sprite: Sprite2D

func _ready() -> void:
	stats.player = self
	player_state_machine.Initialize(self)
	jump_reset.body_shape_entered.connect(jump_action.reset_jumps)
	stats.hp = stats.max_hp
	health_bar.init_health(stats.max_hp)
	invincibility_timer.timeout.connect(invincibility_over)
	hit_box.Damaged.connect(take_damage)
	off_hand.connect_hands(main_hand, off_hand_shoulder)
	main_hand.connect_hands(off_hand)
	EventBus.invisible_hands.connect(show_hands)
	EventBus.leeched.connect(leech_heal)
	buff_handler.set_entity(self)
	EventBus.equipment_interaction_enter.connect(equipment_interaction_begin)
	EventBus.equipment_interaction_exit.connect(equipment_interaction_end)
	EventBus.enemy_died.connect(count_enemy_death)
	EventBus.arrow_enemy_hit.connect(add_shot_streak)
	EventBus.arrow_missed.connect(reset_shot_streak)
	EventBus.apply_player_knockback.connect(apply_knockback)
	EventBus.active_ability_ready.connect(active_ability_ready)
	quiver.hide()
	#reset_equipment()
	sprite = body.sprite
	debuff_handler.set_entity(self)
	activate_passive_abilities() 


var enemies_killed: int = 0

func count_enemy_death(_enemy: Enemy) -> void:
	enemies_killed+=1

func reset_equipment() -> void:
	for node_key in equipped_nodes.keys():
		equipped_nodes[node_key] = null
		var current = get_equipped_in_slot(node_key)

		if current:
			current.unequip(stats)
	off_hand.hide_bow()
	quiver.hide()
	stats.bow = null
	stats.ring = null
	stats.arrow = null
	
func kill(_death_screen: bool = true) -> void:
	if not player_state_machine.curr_state == dead:
		dead.display_death_screen = _death_screen
		player_state_machine.ChangeState(dead)

func activate_passive_abilities() -> void:
	for ability in get_abilities(PlayerAbility.TriggerType.PASSIVE):
		ability.on_equipped()
	
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

		if event.is_action_pressed("Jump"):
			jump_action.request_jump()

		if event.is_action_released("Jump"):
			jump_action.release_jump()

		if event.is_action_pressed("shoot",true):
			if stats.bow and stats.arrow:
				shoot()
			
		if event.is_action_pressed("active"):
			use_active_ability()

func shoot() -> void:
	EventBus.start_shooting.emit()
	
func use_active_ability() -> void:
	if stats.active_ability == null:
		return
	if stats.active_ability.is_passive:
		return
	if not active_ability_available:
		return
	EventBus.active_ability_used.emit(stats.active_ability.cooldown)
	stats.active_ability.activate(self)
	active_ability_available = false
	
func active_ability_ready() -> void:
	active_ability_available = true

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
	
func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	knockback = knockback.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)
	velocity += knockback
	move_and_slide()
	velocity -= knockback

func is_equipment_interaction() -> bool:
	return equipment_interacted != null
	
func equipment_interaction_begin(equip: Equipment) -> void:
	if equip:
		equipment_interacted = equip

func equipment_interaction_end(_equip: Equipment) -> void:
	equipment_interacted = null


func apply_knockback(_direction: Vector2, force: float, continuous: bool = false) -> void:
	if continuous:
		knockback = _direction.normalized() * force
	else:
		knockback += _direction.normalized() * force

func reset_knockback() -> void:
	knockback = Vector2.ZERO
	
func update_direction(_new_side: bool) -> void:
	if _new_side != direction_side and not main_hand.is_swinging():
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
	set_arrow_scene()
	if stats.arrow_texture_override:
		main_hand.arrow_texture = stats.arrow_texture_override
	else:
		main_hand.arrow_texture = stats.arrow.equipped_texture

func set_new_quiver(_texture: Texture2D) -> void:
	if _texture:
		quiver.texture = _texture
		quiver.show()
		
func set_arrow_scene() -> void:
	if stats.arrow_scene:
		main_hand.new_arrow(stats.arrow_scene)

func can_summon() -> bool:
	return current_minions.size() < stats.max_minions

func reset_minions() -> void:
	for minion in current_minions:
		minion.queue_free()
		current_minions.erase(minion)

func emit_crit() -> void:
	critical_hit.emit()

func _handle_take_damage(_hurt_box: HurtBox, raw_damage: int) -> void:
	if not invincible:
		took_hit.emit()
		EventBus.damaged_flash.emit()
		damaged_particles.emitting = true
		var dmg_taken: int = 0
		if _hurt_box:
			start_invincibilty()
			dmg_taken = _hurt_box.damage
			apply_knockback(-_hurt_box.knockback_dir,_hurt_box.knockback_power)
			show_damage(_hurt_box.damage, Color.RED)
		else:
			dmg_taken = raw_damage
			
		stats.hp -= dmg_taken
		health_bar.reduce_health(dmg_taken)

		if stats.hp <= 0:
			kill()

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

func increase_max_hp(_amount: int, _heal: bool) -> void:
	stats.max_hp += _amount
	health_bar.increase_max_hp(stats.max_hp)
	if _heal:
		heal(999)

	
func heal(amount: int, _flash: bool = true) -> bool:
	var amount_healed: int = min(amount, stats.max_hp - stats.hp)
	if can_heal(amount):
		stats.hp += amount_healed
		health_bar.heal(amount_healed)
		if _flash:
			EventBus.healed_flash.emit()
			show_damage(amount_healed, Color.GREEN)
		return true
	return false
	
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

func slow_player(slow_time: float,effect: Node2D) -> void:
	slow.slow_player(slow_time,effect)

func buy(price: int) -> bool:
	if stats.money >= price:
		collect_money(-price)
		return true
	return false
	
func register_ability(ability: PlayerAbility) -> void:
	_get_ability_array(ability.trigger_type).append(ability)
	ability.on_equipped()

func unregister_ability(ability: PlayerAbility) -> void:
	_get_ability_array(ability.trigger_type).erase(ability)
	ability.on_unequipped()

func get_abilities(trigger: PlayerAbility.TriggerType) -> Array:
	return _get_ability_array(trigger)
	
func _get_ability_array(trigger: PlayerAbility.TriggerType) -> Array:
	match trigger:
		PlayerAbility.TriggerType.PASSIVE: return stats.passive_abilities
		PlayerAbility.TriggerType.SHOOT: return stats.shooting_abilities
		PlayerAbility.TriggerType.JUMP: return stats.jump_abilities
		PlayerAbility.TriggerType.DASH: return stats.dash_abilities
		PlayerAbility.TriggerType.RELEASE: return stats.release_abilities
		_: return []
		
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

func get_shoot_abilities() -> Array[PlayerAbility]:
	return stats.shooting_abilities

func get_weapon_size() -> float:
	return stats.sword_size.value()


func get_sword_cd() -> float:
	return max(stats.base_sword_cooldown.value(),0.5)

func get_sword_size() -> float:
	return stats.sword_size.value()

func get_sword_abilities() -> Array[PlayerAbility]:
	return stats.sword_abilities

func get_sword() -> Sword:
	return main_hand.sword
	
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

func get_curr_shot_power() -> float:
	return main_hand.shot_power
	
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
		_equip.reparent(self)

func unequip_item(_slot: EquipmentData.slots) -> void:
	var item: Equipment = equipped_nodes[_slot]
	if item:
		EventBus.equipment_dropped.emit(item.data, global_position, item)
	equipped_nodes[_slot] = null
	
func get_equipped_node_in_slot(_slot: EquipmentData.slots) -> Equipment:
	if _slot >= 0:
		var node = equipped_nodes[_slot]
		if is_instance_valid(node):
			return node
	return null
	

func set_sword_size(amount: float) -> void:
	stats.sword_size_mod = amount
	
func set_sword_cd(amount: float) -> void:
	stats.sword_cooldown_mod = amount

func set_shooting(_val: bool) -> void:
	shooting = _val

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

## STREAK ##
func add_shot_streak(_perfect: bool, _arrow: Arrow, _enemy: Enemy) -> void:
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
