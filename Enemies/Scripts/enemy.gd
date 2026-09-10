class_name Enemy extends GameEntity

@export var stats: EnemyData
@onready var hit_box: EnemyHitBox = $HitBox
@onready var sprite: Sprite2D = $Sprite2D
@onready var hurt_box: HurtBox = $HurtBox
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine
@onready var enemy_health_bar: Control = get_node_or_null("EnemyHealthBar")

const ITEM_PICK_UP = preload("res://Items/ItemPickUp.tscn")
const HIT_PARTICLES = preload("res://Enemies/EnemyEffects/EnemyHit/HitParticles.tscn")
const STUN_ARROW_EFFECT = preload("res://Player/Abilities/ShootAbilities/StunAbility/StunArrowEffect.tscn")

signal died(enemy: Enemy)
signal took_damage

var direction: Vector2
var no_drops: bool = true # Enemy currently dont drop items

var added_hit_effect: bool = false
var hit_particle_effect: CPUParticles2D

var animation_player: AnimationPlayer
var damaged_animation_player : AnimationPlayer

var current_hp: int
var knockback_velocity: Vector2 = Vector2.ZERO

var is_dead: bool = false

var invincible: bool = false
var stunned: bool = false
func _ready() -> void:
	current_hp = stats.max_hp
	hurt_box.base_damage = stats.touch_damage
	hurt_box.knockback_power = stats.knockback
	hurt_box.successful_hit.connect(knockback)
	debuff_handler.set_entity(self)
	hit_box.Damaged.connect(hit)
	hit_box.set_enemy(self)
	extra_ready_functions()
	sprite.texture = stats.skin
	if stats.has_health_bar:
		enemy_health_bar.get_child(1).setup(stats.max_hp)
	init_effects()
	init_damage_modifiers()
	sprite.scale = stats.texture_scale
	_wire_hit_effects(hurt_box, false)

func init_damage_modifiers() -> void:
	stats.damage_taken_multiplier = Stat.new()
	stats.damage_taken_multiplier.base_value = 1.0
	
	stats.damage_dealt_multiplier = Stat.new()
	stats.damage_dealt_multiplier.base_value = 1.0

func init_effects() -> void:
	for effect in stats.effects:
		var new_effect = effect.instantiate()
		add_child(new_effect)

func full_health() -> bool:
	return current_hp == stats.max_hp
	
func face_the_player() -> void:
	if stats.facing_player:
		sprite.flip_h = PlayerManager.player.global_position.x > global_position.x

func heal(_amount: int) -> void:
	current_hp = mini(current_hp + _amount, stats.max_hp)
	handle_health_bar(-_amount)
	show_heal(_amount, Color.LIME_GREEN)

func show_heal(_amount: int, _color: Color) -> void:
	CombatTextSpawner.spawn(global_position, str(_amount),_color)

func extra_ready_functions() -> void:
	pass

func set_data(_data: EnemyData) -> void:
	if _data:
		stats = _data.duplicate(true)

func is_damaged() -> bool:
	return current_hp < stats.max_hp
	
func calculate_direction_to_player(offset: Vector2 = Vector2.ZERO) -> Vector2:
	return (PlayerManager.player.global_position + offset - global_position).normalized()

func calculate_distance_to_player() -> float:
	return PlayerManager.player.global_position.distance_to(global_position)
	
func hit(_hurt_box: HurtBox) -> void:
	
	take_damage(_hurt_box)
	extra_hit_functions(_hurt_box)
	knockback(_hurt_box)
	take_hit_effect()	

func extra_hit_functions(_hurt_box: HurtBox) -> void:
	pass
	
func take_hit_effect() -> void:
	if not added_hit_effect:
		added_hit_effect = true
		hit_particle_effect = HIT_PARTICLES.instantiate()
		add_child(hit_particle_effect)
		
	if hit_particle_effect != null:
		hit_particle_effect.restart()

func set_damage_taken_multiplier(_amount: float, _type: Stat.buff_type) -> void:
	var id: int = CustomVariables.ENEMY_DMG_TAKEN_MULT_ID
	stats.damage_taken_multiplier.add_buff(id,_amount,_type)

func remove_damage_taken_multiplier(_amount: float, _type: Stat.buff_type) -> void:
	var id: int = CustomVariables.ENEMY_DMG_TAKEN_MULT_ID
	stats.damage_taken_multiplier.reduce_buff_amount(id,_amount,_type)

func set_damage_dealt_multiplier(_amount: float, _type: Stat.buff_type) -> void:
	var id: int = CustomVariables.ENEMY_DMG_DEALT_MULT_ID
	stats.damage_dealt_multiplier.add_buff(id,_amount,_type)
	hurt_box.damage_multiplier = stats.damage_dealt_multiplier.value()
	
func remove_damage_dealt_multiplier(_amount: float, _type: Stat.buff_type) -> void:
	var id: int = CustomVariables.ENEMY_DMG_DEALT_MULT_ID
	stats.damage_dealt_multiplier.reduce_buff_amount(id,_amount,_type)
	hurt_box.damage_multiplier = stats.damage_dealt_multiplier.value()
	
func _handle_take_damage(_hurt_box: HurtBox, raw_damage: int = 0) -> void:
	
	var final_dmg: int
	if is_dead:
		return
	if _hurt_box:
		final_dmg = roundi(_hurt_box.damage * stats.damage_taken_multiplier.value())
	else:
		final_dmg = raw_damage * stats.damage_taken_multiplier.value()
	current_hp -= roundi(final_dmg)
	frostbitten_hit()
	handle_health_bar(final_dmg)	
	if damaged_animation_player:
		damaged_animation_player.play("Damaged")
	
	if current_hp <= 0:
		is_dead = true
		activate_death_ability()
		enemy_died()
		drop_item()

func handle_health_bar(_dmg: int = 0) -> void:
	if stats.has_health_bar:
		enemy_health_bar.get_child(1).show_damage(current_hp)
		
func activate_death_ability() -> void:
	if stats.death_ability.size() > 0:
		for ability in stats.death_ability:
			if ability != null:
				ability.activate_ability(self)
				
func enemy_died() -> void:
	died.emit(self)
	EventBus.enemy_died.emit(self)
	queue_free()
	
func show_damage(_amount: int, color: Color) -> void:
	var final_amount: int = _amount * stats.damage_taken_multiplier.value()
	CombatTextSpawner.spawn(global_position, str(final_amount),color)
	
func knockback(_hurt_box: HurtBox) -> void:
	if stats.can_be_knockedback:
		knockback_velocity += _hurt_box.knockback_dir * _hurt_box.knockback_power

func drop_item() -> void:
	if not no_drops:
		var drop_chance: float = min(
			stats.drop_chance + PlayerManager.player.stats.extra_drop_chance.value(),
			100)
		for item in stats.equip_amount:
			EventBus.try_drop.emit(global_position, drop_chance,stats.rarity_skew)
	EventBus.drop_coins.emit(global_position, stats.avg_coins_dropped)

		
func disable_drops() -> void:
	no_drops = true
	
func update_animation(_animation: String, _position: float = 0.0) -> void:
	if animation_player != null and _animation != "":
		animation_player.play_section(_animation, _position)

func can_be_stunned() -> bool:
	return not stats.stun_immune
	
func shoot() -> void:
	if !stunned:
		var bullet = bullet_set_up()
		get_parent().add_child(bullet)
	
func bullet_set_up() -> Node2D:
	if stats.bullet != null:
		var new_bullet: EnemyBullet = stats.bullet.instantiate()
		new_bullet.direction = calculate_direction_to_player()
		new_bullet.global_position = global_position
		new_bullet.data.knockback = stats.knockback
		new_bullet.data.move_speed = stats.bullet_speed
		new_bullet.was_fired = true
		new_bullet.data.damage = stats.touch_damage * stats.damage_dealt_multiplier.value()
		_wire_hit_effects(new_bullet.hurt_box, true)
		return new_bullet
	return null
	
func _wire_hit_effects(target_hurt_box: HurtBox, projectile: bool = false) -> void:

	for effect in stats.hit_effects:
		if projectile and not effect.applies_to_projectiles:
			continue
		if not projectile and not effect.applies_to_melee:
			continue
		target_hurt_box.add_effect(effect.apply)
		
func stun(_activate: bool, _electric: bool = false) -> void:
	stunned = _activate
	if _activate:
		stop_animations()
	else:
		continue_animations()
	state_machine.cause_pause(_activate)
	set_physics_process(!_activate)
	if _activate and _electric:
		EventBus.enemy_stunned.emit(self)
	knockback_velocity = Vector2.ZERO
		
func stop_animations() -> void:
	if animation_player:
		animation_player.pause()
	stop_extra_animation_players()

func continue_animations() -> void:
	if animation_player:
		animation_player.play()
	continue_extra_animation_players()
	
func continue_extra_animation_players() -> void:
	pass
func stop_extra_animation_players() -> void:
	pass

func frostbitten_hit() -> void:
	if debuff_handler.has_debuff(CustomVariables.FROSTBITE_DEBUFF_ID):
		EventBus.enemy_frostbitten_hit.emit(self)
