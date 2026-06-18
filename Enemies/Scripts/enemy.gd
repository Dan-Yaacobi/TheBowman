class_name Enemy extends CharacterBody2D

@export var stats: EnemyData

@onready var debuff_handler: DebuffHandler = $DebuffHandler
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
var no_drops: bool = false

var added_hit_effect: bool = false
var hit_particle_effect: CPUParticles2D

var animation_player: AnimationPlayer
var damaged_animation_player : AnimationPlayer

var current_hp: int
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_threshold: float = 0.2
var knockback_decay: float = 0.05

var is_dead: bool = false

var _damage_multiplier: float = 1.0

func _ready() -> void:
	current_hp = stats.max_hp
	hurt_box.damage = stats.touch_damage
	hurt_box.knockback_power = stats.knockback
	hurt_box.successful_hit.connect(knockback)
	debuff_handler.set_enemy(self)
	hit_box.set_enemy(self)
	extra_ready_functions()
	if stats.has_health_bar:
		enemy_health_bar.get_child(1).setup(stats.max_hp)

func full_health() -> bool:
	return current_hp == stats.max_hp

func heal(_amount: int) -> void:
	current_hp = mini(current_hp + _amount, stats.max_hp)
	handle_health_bar(-_amount)
	show_damage(_amount, Color.LIME_GREEN)
	
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
	take_damage(_hurt_box.damage)
	extra_hit_functions(_hurt_box)
	knockback(_hurt_box)
	take_hit_effect()	

func extra_hit_functions(_hurt_box: HurtBox) -> void:
	pass
	
func apply_debuff(_debuff: Debuff, _duration: float, _ticks: int) -> void:
	debuff_handler.add_debuff(_debuff, _duration, _ticks)

func show_damage(_damage: int, color: Color) -> void:
	CombatTextSpawner.spawn(global_position, str(_damage),color)

func take_hit_effect() -> void:
	if not added_hit_effect:
		added_hit_effect = true
		hit_particle_effect = HIT_PARTICLES.instantiate()
		add_child(hit_particle_effect)
		
	if hit_particle_effect != null:
		hit_particle_effect.restart()
		
func set_damage_multiplier(_multiplier: float) -> void:
	_damage_multiplier = _multiplier
	
func take_damage(_dmg: int) -> void:
	if is_dead:
		return
		
	current_hp -= roundi(_dmg * _damage_multiplier)
	
	handle_health_bar(_dmg)	
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
	
func knockback(_hurt_box: HurtBox) -> void:
	if stats.can_be_knockedback:
		knockback_velocity += _hurt_box.knockback_dir * _hurt_box.knockback_power

func drop_item() -> void:
	var drop_chance: float = min(
		stats.drop_chance + PlayerManager.player.stats.extra_drop_chance.value(),
		100)
	for item in stats.equip_amount:
		EventBus.try_drop.emit(global_position, drop_chance,stats.rarity_skew)
	EventBus.drop_coins.emit(global_position, stats.avg_coins_dropped)

	
func disable_drops() -> void:
	no_drops = true
	
func update_animation(_animation: String, _position: float = 0.0) -> void:
	if animation_player != null:
		animation_player.play_section(_animation, _position)

func can_be_stunned() -> bool:
	return not stats.stun_immune
	
func shoot() -> void:
	var bullet = bullet_set_up()
	get_parent().add_child(bullet)

func bullet_set_up() -> Node2D:
	if stats.bullet != null:
		var new_bullet: EnemyBullet = stats.bullet.instantiate()
		new_bullet.direction = calculate_direction_to_player()
		new_bullet.global_position = global_position
		new_bullet.data.knockback = stats.knockback
		new_bullet.data.move_speed = stats.bullet_speed
		return new_bullet
	return null
	
func stun(_stop: bool) -> void:
	state_machine.cause_pause(_stop)
	set_physics_process(!_stop)
	if not _stop:
		knockback_velocity = Vector2.ZERO
