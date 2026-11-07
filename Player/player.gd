class_name Player extends GameEntity

signal item_amount_changed(amount: int, item: CustomVariables.items)
signal money_changed
signal took_hit
signal critical_hit
signal dash_finished
## A hit was dodged (dodge_chance) and dealt no damage.
signal dodged
## A hit was blocked by a hit shield (Second Skin) and dealt no damage.
signal shield_blocked
## Every sword swing, once its hit area is set up (Cleave Wave).
signal sword_swung

@onready var body: PlayerBody = $PlayerBody
@onready var player_state_machine: PlayerStateMachine = $PlayerStateMachine
@onready var jump_reset: Area2D = $JumpReset
@onready var jump_action: JumpAction = $JumpAction
@onready var camera: Camera2D = $Camera2D
@onready var hit_box: HitBox = $HitBox
@onready var off_hand: PlayerOffHand = $PlayerOffHand
@onready var main_hand: PlayerMainHand = $PlayerMainHand

@onready var damaged_particles: CPUParticles2D = $DamagedParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var active_ability_cooldown: Timer = $ActiveAbilityCooldown

@onready var slow: Slow = $Debuffs/Slow
@onready var idle_state: PlayerIdleState = $PlayerStateMachine/Idle
@onready var invincibility_timer: Timer = $InvincibilityTimer

@onready var idle: PlayerIdleState = $PlayerStateMachine/Idle
@onready var quiver: Sprite2D = $PlayerBody/Quiver
@onready var dead: PlayerDeadState = $PlayerStateMachine/Dead
@onready var nearby_enemies_detector: Area2D = $NearbyEnemiesDetector
@onready var sword_attack: SwordAttackState = $PlayerStateMachine/SwordAttack
@onready var swing_cooldown: Timer = $PlayerBody/SwingCooldown

@onready var spawn_handler: SpawnHandler = $SpawnHandler
@export var target_dummy_tutorial_passed: bool = false

@export var stats: PlayerStats
@export var fall_animation_threshold: float = 20.0
@export_subgroup("Buffs")
@export var hit_effects: Dictionary[OnHitEffect,int] = {}
@export var perfect_shot_effects: Dictionary[OnPerfectShotEffect,int] = {}
@onready var buff_handler: BuffHandler = $BuffHandler
@onready var color_levels: ColorLevels = $ColorLevels

const HEALTH_GAIN_EFFECT = preload("uid://d06bmrun6hlne")
const PERMA_EFFECT: int = -1
var health_bar: HealthHearts
var direction: float
var direction_side: bool = false
var knockback_power: Dictionary = {"direction": Vector2.ZERO,
 "power": 0}
var active_ability_available: bool = true
var dropping_down: bool = false

var base_stats: PlayerStats

var invincible: bool = false
## Chance (0-1) that a hit passes through harmlessly. Set by abilities (Shadow Ring).
var dodge_chance: float = 0.0
const DODGE_INVINCIBILITY: float = 0.3
## Each shield blocks one whole hit (Second Skin).
var hit_shields: int = 0
## Knockback taken from hits while airborne is multiplied by this (Steady Footing).
var air_knockback_taken: float = 1.0
## Falls that cost no heart (Safety Net). FallingDeath spends them.
var free_falls: int = 0
## Dashes used since the dash cooldown last finished. Dashing is allowed while below stats.max_dashes.
var dashes_spent: int = 0


var shooting: bool = false
var current_arrow: Arrow

var current_portal: Portal
var can_dash: int = 0

var equipment_interacted: Equipment = null

var knockback: Vector2 = Vector2.ZERO
const KNOCKBACK_FRICTION: float = 300.0 


var equipped_nodes: Dictionary = {
	EquipmentData.slots.BOW: null,
	EquipmentData.slots.ARROW: null,
	EquipmentData.slots.RING: null,
}
var sprite: Sprite2D
var initial_max_hp: int

var nearby_enemies: Array[Enemy]
var enemies_killed: int = 0
var can_swing: int = 0
var aim_direction: Vector2 = Vector2.ZERO
## Surfaces currently changing ground grip (e.g. SlipperySurface) -> their traction
var _traction_sources: Dictionary[Node, float] = {}
var in_jump: bool = false
var fall_after_jump: bool = false

func _ready() -> void:
	stats.player = self
	player_state_machine.Initialize(self)
	initial_max_hp = stats.max_hp
	MetaProgress.apply_to(stats)
	refresh_max_hp()
	invincibility_timer.timeout.connect(invincibility_over)
	hit_box.Damaged.connect(take_damage)
	hit_box.Damaged.connect(body.apply_touch_effects)
	EventBus.invisible_hands.connect(show_hands)
	EventBus.leeched.connect(leech_heal)
	buff_handler.set_entity(self)
	EventBus.equipment_interaction_enter.connect(equipment_interaction_begin)
	EventBus.equipment_interaction_exit.connect(equipment_interaction_end)
	EventBus.enemy_died.connect(count_enemy_death)
	EventBus.color_level_changed.connect(_on_color_level_changed)
	EventBus.arrow_enemy_hit.connect(add_shot_streak)
	EventBus.arrow_missed.connect(reset_shot_streak)
	EventBus.apply_player_knockback.connect(apply_knockback)
	EventBus.active_ability_ready.connect(active_ability_ready)
	quiver.hide()
	sprite = body.sprite
	debuff_handler.set_entity(self)
	activate_passive_abilities()
	MetaProgress.apply_abilities(self)
	SaveService.register(&"resources", _save_resources, _load_resources)
	main_hand.drawing_arrow.connect(_on_main_hand_drawing)
	main_hand.release.connect(_on_main_hand_released)
	off_hand.rest(body.off_hand_shoulder)
	main_hand.set_anchor(body.main_hand_shoulder)
	swing_cooldown.timeout.connect(_on_swing_cooldown_timeout)
	jump_action.jumped.connect(_on_jumped)
	jump_action.landed.connect(_on_landed)
	body.animation_player.animation_finished.connect(_on_body_animation_finished)
func _save_resources() -> Dictionary:
	var out: Dictionary = {}
	for item: CustomVariables.items in stats.items:
		out[CustomVariables.items.keys()[item]] = stats.items[item]
	return out

func _load_resources(data: Dictionary) -> void:
	for key: String in data:
		if CustomVariables.items.has(key):
			stats.items[CustomVariables.items[key]] = int(data[key])
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
		SaveService.save_game()
		player_state_machine.ChangeState(dead)

func activate_passive_abilities() -> void:
	for ability in get_abilities(PlayerAbility.TriggerType.PASSIVE):
		ability.on_equipped()
	
func _process(_delta: float) -> void:
	if stats.hp > 0 and not is_dead():
		direction = Input.get_axis("Left","Right")
	else:
		direction = 0
	_update_aim_and_facing()
	_update_animations()

func _unhandled_input(event: InputEvent) -> void:
	if is_dead():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F7:
			collect_item(CustomVariables.items.WOOD, 50)
			collect_item(CustomVariables.items.COIN, 50)
			collect_item(CustomVariables.items.ESSENCE, 50)
			collect_item(CustomVariables.items.SKYSHARD, 50)
		if event.keycode == KEY_F6:
			EventBus.drop_item.emit(CustomVariables.items.COLOR_SCROLL, global_position + Vector2(40, -10), 100.0, 1)
		if event.keycode == KEY_F8:
			Crafting.try_drop_schematic(global_position + Vector2(40, -10), 100.0)
		if event.keycode == KEY_F10:
			Crafting.crafted_this_run = false
			print("forge unlocked")
		if event.keycode == KEY_F9:
			var track: UpgradeTrack = MetaProgress.tracks[0]
			var bought: bool = MetaProgress.purchase(track, self)
			print("bought: %s | level: %d | arrow damage: %s" % [bought, MetaProgress.get_level(track), stats.arrow_damage.value()])
	
	if stats.hp > 0:
		if event.is_action_pressed("test"):
			$IslandAttack.activate_attack()
			
		if event.is_action_pressed("up"):
			if current_portal:
				current_portal.enter()

		if event.is_action_pressed("Jump"):
			jump_action.request_jump()

		if event.is_action_released("Jump"):
			jump_action.release_jump()
			
		if event.is_action_pressed("shoot"):
			if stats.bow and stats.arrow:
				shoot()

		if event.is_action_released("shoot"):
			release_shot()
			
		if event.is_action_pressed("active"):
			use_active_ability()
		
		if event.is_action_pressed("Gauge Activate"):
			EventBus.request_gauge.emit()
			
func shoot() -> void:
	if is_swinging():
		return
	main_hand.start_draw()

func release_shot() -> void:
	main_hand.release_draw()
	
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

func show_hands(yes: bool) -> void:
	main_hand.visible = yes
	off_hand.visible = yes
	
func _on_main_hand_drawing() -> void:
	shooting = true
	off_hand.hold(main_hand, main_hand.arrow_position, main_hand.bow_grip)		
func _on_main_hand_released() -> void:
	shooting = false
	off_hand.rest(body.off_hand_shoulder)

func reset_hands() -> void:
	shooting = false
	main_hand.reset()
	off_hand.rest(body.off_hand_shoulder)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	knockback = knockback.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)
	velocity += knockback
	move_and_slide()
	velocity -= knockback
	_check_island_contact()

## Reports each island the first time the player stands on it (run tally).
func _check_island_contact() -> void:
	if not is_on_floor():
		return
	for i: int in get_slide_collision_count():
		var island: Island = get_slide_collision(i).get_collider() as Island
		if island and not island.stepped_on:
			island.stepped_on = true
			EventBus.island_stepped_on.emit(island)

## Ground grip: 1 = normal, lower = slippery. The weakest active source wins.
func get_ground_traction() -> float:
	var traction: float = 1.0
	for source: Node in _traction_sources.keys():
		if not is_instance_valid(source):
			_traction_sources.erase(source)
			continue
		traction = minf(traction, _traction_sources[source])
	return traction

func add_traction_source(source: Node, traction: float) -> void:
	_traction_sources[source] = traction

func remove_traction_source(source: Node) -> void:
	_traction_sources.erase(source)

func get_move_acceleration() -> float:
	if is_on_floor():
		return stats.ground_acc * get_ground_traction()
	return stats.air_acc

func get_move_deceleration() -> float:
	if is_on_floor():
		return stats.ground_dec * get_ground_traction()
	return stats.air_dec

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
	if _new_side != direction_side and not is_swinging():
		direction_side = _new_side
		body.change_direction(_new_side)
		main_hand.set_facing(_new_side)
		off_hand.set_facing(_new_side)
		
func _update_aim_and_facing() -> void:
	var aim: Vector2 = get_global_mouse_position() - main_hand.global_position
	aim_direction = aim
	main_hand.set_aim(aim)
	if is_swinging():
		return
	if main_hand.is_drawing() or is_idle():
		if aim.x > 4.0:
			update_direction(false)
		elif aim.x < -4.0:
			update_direction(true)
	elif is_walking():
		update_direction(direction < 0)
		
func apply_gravity(delta) -> void:
		if velocity.y > 0:
			velocity.y += stats.down_gravity*delta
			velocity.y = min(velocity.y, stats.max_down_gravity)
		else:
			velocity.y += stats.up_gravity*delta

func set_new_bow() -> void:
	if stats.bow:
		off_hand.set_new_bow(stats.bow)

func set_new_arrow() -> void:
	set_arrow_scene()
	if stats.arrow_texture_override:
		main_hand.arrow_texture = stats.arrow_texture_override
	else:
		if stats.arrow:
			main_hand.arrow_texture = stats.arrow.equipped_texture

## Visible height (pixels) every quiver sprite is fitted to on the back, so quivers whose art
## doesn't fill the canvas show at the same size as the rest.
const QUIVER_ART_HEIGHT: float = 60.0
var _quiver_base_scale: Vector2 = Vector2.ZERO

func set_new_quiver(_texture: Texture2D) -> void:
	if _texture:
		if _quiver_base_scale == Vector2.ZERO:
			_quiver_base_scale = quiver.scale
		quiver.texture = _texture
		_fit_quiver(_texture)
		quiver.show()

## Scales the quiver so its visible art matches QUIVER_ART_HEIGHT and centers that art on the node.
func _fit_quiver(_texture: Texture2D) -> void:
	var used: Rect2i = _texture.get_image().get_used_rect()
	if used.size.y <= 0:
		quiver.scale = _quiver_base_scale
		quiver.offset = Vector2.ZERO
		return
	quiver.scale = _quiver_base_scale * (QUIVER_ART_HEIGHT / used.size.y)
	quiver.offset = _texture.get_size() / 2.0 - Vector2(used.get_center())
		
func set_arrow_scene() -> void:
	if stats.arrow_scene:
		main_hand.new_arrow(stats.arrow_scene)



func emit_crit() -> void:
	critical_hit.emit()

func _handle_take_damage(_hurt_box: HurtBox, raw_damage, _result: DamageResult = null, _alter_dmg_color: Color = Color.RED) -> void:
	if not invincible and dodge_chance > 0.0 and randf() < dodge_chance:
		_dodge()
		dodged.emit()
		return
	if not invincible and hit_shields > 0:
		hit_shields -= 1
		_dodge()
		shield_blocked.emit()
		return
	if not invincible:
		took_hit.emit()
		EventBus.damaged_flash.emit()
		damaged_particles.emitting = true
		var dmg_taken: int = 0
		var dmg_color = _alter_dmg_color
		if _hurt_box:
			start_invincibilty()
			dmg_taken = _hurt_box.damage
			var knockback_mult: float = 1.0 if is_on_floor() else air_knockback_taken
			apply_knockback(_hurt_box.knockback_dir, _hurt_box.knockback_power * knockback_mult)
			dmg_color = _hurt_box.combat_text_color
		else:
			dmg_taken = raw_damage
		show_damage(dmg_taken, dmg_color)
		stats.hp -= dmg_taken
		health_bar.reduce_health(dmg_taken)
		if stats.hp <= 0:
			kill()

## Short invincibility so the same contact doesn't hit again on the next frame.
func _dodge() -> void:
	invincible = true
	invincibility_timer.wait_time = DODGE_INVINCIBILITY
	invincibility_timer.start()

func can_start_dash() -> bool:
	return can_dash <= 0 and dashes_spent < stats.max_dashes

## Spends a free fall if there is one. Returns true if the fall costs no heart.
func use_free_fall() -> bool:
	if free_falls <= 0:
		return false
	free_falls -= 1
	return true

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

func max_hp_value() -> int:
	return stats.max_hp + stats.extra_hp
	
func refresh_max_hp() -> void:
	stats.max_hp = initial_max_hp + MetaProgress.get_bonus_hearts() * CustomVariables.HP_PER_HEART
	stats.hp = max_hp_value()
	health_bar.init_health(max_hp_value())
	
func can_heal(amount: int) -> bool:
	var amount_healed: int = min(amount, max_hp_value() - stats.hp)
	return amount_healed > 0

func increase_max_hp(_heal: bool) -> void:
	stats.extra_hp += CustomVariables.HP_PER_HEART
	health_bar.gain_heart_container(_heal)
	if _heal:
		heal(999)

func lose_heart() -> bool:
	health_bar.lose_heart_container()
	if stats.extra_hp <= 0:
		stats.max_hp -= CustomVariables.HP_PER_HEART
		if stats.max_hp <= 0:
			return true
	else:
		stats.extra_hp -= CustomVariables.HP_PER_HEART
	stats.hp = min(stats.hp, max_hp_value())
	return false
	
func heal(amount: int, _flash: bool = true) -> bool:
	var amount_healed: int = min(amount, max_hp_value() - stats.hp)
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
	
func set_camera(tile_limit: Rect2i,tile_size: int) -> void:
	camera.limit_top = tile_limit.position[0] * tile_size
	camera.limit_left = tile_limit.position[1] * tile_size
	camera.limit_right = tile_limit.end[0] * tile_size
	camera.limit_bottom = tile_limit.end[1] * tile_size
	pass

func slow_player(slow_time: float,effect: Node2D) -> void:
	slow.slow_player(slow_time,effect)

func buy(price: int, item: CustomVariables.items) -> bool:
	if stats.items[item] >= price:
		stats.items[item] -= price
		item_amount_changed.emit(stats.items[item],item)
		money_changed.emit(stats.items[CustomVariables.items.COIN])
		return true
	return false
	
func register_ability(ability: PlayerAbility) -> void:
	_get_ability_array(ability.get_type()).append(ability)
	ability.on_equipped()

func unregister_ability(ability: PlayerAbility) -> void:
	_get_ability_array(ability.get_type()).erase(ability)
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
		PlayerAbility.TriggerType.DRAW: return stats.draw_abilities
		PlayerAbility.TriggerType.BEFORE_HIT: return stats.before_hit_abilities
		PlayerAbility.TriggerType.AFTER_HIT: return stats.after_hit_abilities
		_: return []
		
func enable_jump() -> void:
	jump_action.can_jump = true

func disable_jump() -> void:
	jump_action.can_jump = false
	
func _on_swing_cooldown_timeout() -> void:
	can_swing -= 1

func can_start_swing() -> bool:
	return can_swing <= 0 and not main_hand.is_drawing()

func is_swinging() -> bool:
	return player_state_machine.curr_state is SwordAttackState
	
############# IS METHODS #############
func is_idle() -> bool:
	return player_state_machine.curr_state is PlayerIdleState
	
func is_dead() -> bool:
	return player_state_machine.curr_state is PlayerDeadState
	
func is_walking() -> bool:
	return player_state_machine.curr_state is PlayerWalkingState
	
func is_dash() -> bool:
	return player_state_machine.curr_state is PlayerDashState

func is_shooting() -> bool:
	return shooting

func is_moving() -> bool:
	return direction != 0
############# GET METHODS #############

var max_speed: float = 1.0 ## 1.0 means maximum is double speed
var C: int = 200 ## controls how fast you upgrade movement speed via agility

## asymptotic increase towards max speed

func get_move_speed() -> float:
	if main_hand.is_overcharging():
		return stats.move_speed.value() * main_hand.overcharge_move_mult
	return stats.move_speed.value()
	
func get_pull_speed() -> float:
	return stats.pull_speed.value()

func get_strength_shot_modifier() -> float:
	return stats.basic_shot_power
	

func get_shoot_abilities() -> Array[PlayerShootAbility]:
	return stats.shooting_abilities

func get_weapon_size() -> float:
	return stats.sword_size.value()


func get_sword_cd() -> float:
	return max(stats.base_sword_cooldown.value(),0.5)

func get_sword_size() -> float:
	return stats.sword_size.value()

func get_sword_abilities() -> Array[PlayerAbility]:
	return stats.sword_abilities


	
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

## 0..1 overcharge fill (Longing); 0 when overcharge isn't active.
func get_curr_overcharge() -> float:
	return main_hand.overcharge if main_hand.overcharge_enabled else 0.0
	
############# SET METHODS #############
## A color scroll raised a level: equipped items of that color re-apply their scaled stats.
func _on_color_level_changed(color: CustomVariables.ItemColor, _level: int) -> void:
	for item: EquipmentData in [stats.bow, stats.arrow, stats.ring]:
		if item and item.color == color:
			item.refresh_power(stats)

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
				set_new_arrow()
			EquipmentData.slots.ARROW:
				stats.arrow = _new_item
				set_new_arrow()
				set_new_quiver(stats.arrow.texture)
			EquipmentData.slots.RING:
				stats.ring = _new_item
				set_new_arrow()
				
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

func collect_item(item: CustomVariables.items, _amount: int) -> void:
	if _amount > 0 and stats.items.has(item):
		stats.items[item] += _amount
		item_amount_changed.emit(stats.items[item], item)
		EventBus.resource_collected.emit(item, _amount)

func get_nearby_enemies() -> Array[Enemy]:
	return nearby_enemies

func _on_nearby_enemies_detector_body_entered(_body: Node2D) -> void:
	if _body is Enemy:
		nearby_enemies.append(_body)
		_body.died.connect(erase_nearby_enemy)

func _on_nearby_enemies_detector_body_exited(_body: Node2D) -> void:
	if _body is Enemy:
		_body.died.disconnect(erase_nearby_enemy)
		erase_nearby_enemy(_body)

func erase_nearby_enemy(_enemy: Enemy) -> void:
	nearby_enemies.erase(_enemy)
	
func _on_jumped() -> void:
	in_jump = true
	fall_after_jump = false
	body.restart_animation("Jump")

func _on_landed() -> void:
	in_jump = false
	fall_after_jump = false

func _on_body_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Jump" or sword_attack.is_attack_animation(anim_name):
		in_jump = false
		fall_after_jump = not is_on_floor()

func _update_animations() -> void:
	var stage: String = main_hand.get_draw_stage()
	off_hand.play_stage(stage, get_pull_speed())
	_update_body_animation(stage)

func _update_body_animation(stage: String) -> void:
	if is_swinging() or in_jump:
		return
	if not is_walking() and not is_idle():
		return
	if not is_on_floor() and (fall_after_jump or velocity.y > fall_animation_threshold):
		body.update_animation("Falling")
		return
	body.play_stance(stage, is_walking(), get_pull_speed())
