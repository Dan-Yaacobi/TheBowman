class_name Enemy extends CharacterBody2D

@export var stats: EnemyData

@onready var debuff_handler: DebuffHandler = $DebuffHandler

const ITEM_PICK_UP = preload("res://Items/ItemPickUp.tscn")
const HIT_PARTICLES = preload("res://Enemies/EnemyEffects/EnemyHit/HitParticles.tscn")
const STUN_ARROW_EFFECT = preload("res://Player/Abilities/ShootAbilities/StunAbility/StunArrowEffect.tscn")

signal died(enemy: Enemy)
signal took_damage

var direction: Vector2

var poisoned_state: bool = false
var bleed_state: bool = false

var base_move_speed: int
var no_drops: bool = false

var added_hit_effect: bool = false
var hit_particle_effect: CPUParticles2D

var animation_player: AnimationPlayer
var damaged_animation_player : AnimationPlayer

var can_move: bool = true

## Push back variables ##
var no_push_back: bool = false
var pushed_back: bool = false
var pushback_dir: Vector2
var pushback_power: float

var hard_mode: bool = false

var current_hp: int
func _ready() -> void:
	current_hp = stats.max_hp
	extra_ready_functions()
	pass

func extra_ready_functions() -> void:
	pass

func set_data(_data: EnemyData) -> void:
	if _data:
		stats = _data

func calculate_direction_to_player() -> Vector2:
	return (PlayerManager.player.global_position - global_position).normalized()

func hit(hurt_box: HurtBox) -> void:
	if not no_push_back:
		push_back(hurt_box.knockback_dir,hurt_box.knockback)
		
	take_damage(hurt_box.damage)
	take_hit_effect()	

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
		
func take_damage(_dmg: int) -> void:
	current_hp -= _dmg
	damaged_animation_player.play("Damaged")
	
	if current_hp <= 0:
		activate_death_ability()
		enemy_died()
		drop_item(CoinDropLogic.drop_logic(stats.avg_coins_dropped))

func activate_death_ability() -> void:
	if stats.death_ability.size() > 0:
		for ability in stats.death_ability:
			if ability != null:
				ability.activate_ability(self)

func enemy_died() -> void:
	died.emit(self)
	EventBus.enemy_died.emit(self)
	queue_free()
	
func push_back(_direction: Vector2 = -direction, power: float = stats.move_speed.value()) -> void:
	if not (stats.boss and stats.shooter):

		pushed_back = true
		pushback_dir = -direction
		pushback_power = power

func player_hit(body: CharacterBody2D) -> void:
	if body is Player:
		if body.stats.hp > 0 and not body.invincible:
			body.hit_player(stats.touch_damage)
			body.set_pushback_values(direction,stats.knockback)
			push_back(direction,stats.move_speed.value())

func drop_item(_drops: Array[ItemData]) -> void:
	for drop in _drops:
		spawn_drop(drop)
	#if not no_drops:
		#for drop in item_drops:
			#if drop.drop_chance():
				#spawn_drop(drop)

func spawn_drop(drop: ItemData) -> void:
	var item = ITEM_PICK_UP.instantiate()
	item.assign_item(drop)
	item.global_position = global_position
	item.inititalize(PlayerManager.player)
	EventBus.summon_effect.emit(item)

func disable_drops() -> void:
	no_drops = true
	
func update_animation(_animation: String, _position: float = 0.0) -> void:
	if animation_player != null:
		animation_player.play_section(_animation, _position)

func alter_moving(_stop: bool) -> void:
	stats.move_speed.zero = _stop
