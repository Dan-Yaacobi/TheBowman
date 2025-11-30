class_name Enemy extends CharacterBody2D

@export var stats: EnemyData
@export var item_drops: Array[DropData]

static var player: Player

const ITEM_PICK_UP = preload("res://Items/ItemPickUp.tscn")
const HIT_PARTICLES = preload("res://Enemies/EnemyEffects/EnemyHit/HitParticles.tscn")
const STUN_ARROW_EFFECT = preload("res://Player/Abilities/ShootAbilities/StunAbility/StunArrowEffect.tscn")

signal died(enemy: Enemy)
signal took_damage
var poisoned_timer: Timer
var stunned_timer: Timer
var stunned_effect: CPUParticles2D
var enemy_scene: PackedScene
var direction: Vector2
var poisoned_state: bool = false
var stunned_state: bool = false
var poisoned_damage: int = 0
var temp_move_speed: int
var no_drops: bool = false

var added_hit_effect: bool = false
var hit_particle_effect: CPUParticles2D

var animation_player: AnimationPlayer
var no_push_back: bool = false

var hard_mode: bool = false

func _ready() -> void:
	pass

func get_player(_player: Player) -> void:
	if _player != null:
		player = _player
	
func calculate_direction_to_player() -> Vector2:
	var _direction: Vector2
	_direction = player.global_position - global_position
	return _direction.normalized()

func hit(hurt_box: HurtBox) -> void:
	if hurt_box is ArrowHurtBox:
		var arrow: Arrow = hurt_box.arrow
		
		arrow.clear_shot()
		#arrow.reset_specials()
		if arrow.stun:
			apply_stun(arrow.stun_duration)

	if not no_push_back:
		push_back(hurt_box.knockback_dir,hurt_box.knockback)
	take_damage(hurt_box.damage)
	take_hit_effect()	
	
func apply_stun(stun_duration) -> void:
	if not stats.boss:
		var stun: EnemyEffect = Stunned.new()
		stun.set_stun_duration(stun_duration)
		self.stats.debuffs.append(stun)
		var stun_effect = STUN_ARROW_EFFECT.instantiate()
		stun_effect.global_position = global_position
		get_parent().call_deferred("add_child", stun_effect)
	
func take_hit_effect() -> void:
	if not added_hit_effect:
		added_hit_effect = true
		hit_particle_effect = HIT_PARTICLES.instantiate()
		add_child(hit_particle_effect)
		
	if hit_particle_effect != null:
		hit_particle_effect.restart()
		
func take_damage(_dmg: int) -> void:
	stats.hp -= _dmg
	took_damage.emit()
	update_animation("Damaged")
	
	if stats.shooter and not stats.boss:
		#stats.shooter = false
		if not animation_player.animation_finished.is_connected(shooter_damaged_animation_finished):
			animation_player.animation_finished.connect(shooter_damaged_animation_finished)
	else:
		if not animation_player.animation_finished.is_connected(regular_damaged_animation_finished):
			animation_player.animation_finished.connect(regular_damaged_animation_finished)
			
	if stats.hp <= 0:
		activate_death_ability()
		enemy_died()
		drop_item()

func shooter_damaged_animation_finished(anim_name: String) -> void:
	if anim_name == "Damaged":
		update_animation("Move")
		await get_tree().create_timer(0.5).timeout
		
		stats.shooter = true


func regular_damaged_animation_finished(anim_name: String) -> void:
	if anim_name == "Damaged":
		update_animation("Move")
	
func activate_death_ability() -> void:
	if stats.death_ability.size() > 0:
		for ability in stats.death_ability:
			if ability != null:
				ability.activate_ability(self)

func enemy_died() -> void:
	died.emit(self)
	queue_free()
	
func push_back(_direction: Vector2 = -direction, power: int = stats.move_speed*2) -> void:
	if not stunned_state:
		if not (stats.boss and stats.shooter):
			velocity = _direction * power
			

func player_hit(body: CharacterBody2D) -> void:
	if body is Player:
		if body.stats.hp > 0 and not body.invincible:
			body.hit_player(stats.touch_damage)
			body.set_pushback_values(direction,stats.knockback)
			push_back(-direction,stats.move_speed)

func drop_item() -> void:
	if not no_drops:
		for drop in item_drops:
			if drop.drop_chance():
				spawn_drop(drop)

func spawn_drop(drop) -> void:
	var item = ITEM_PICK_UP.instantiate()
	item.assign_item(drop.item_data)
	item.global_position = global_position
	item.inititalize(player)
	get_parent().call_deferred("add_child", item)

func disable_drops() -> void:
	no_drops = true
	
func activate_debuffs() -> void:
	for debuff in stats.debuffs:
		debuff.activate_enemy_effect(self)
		stats.debuffs.erase(debuff)
		
func take_poisoned_damage() -> void:
	take_damage(poisoned_damage)
	
func poisoned(_damage: int) -> void:
	poisoned_state = true
	poisoned_damage = _damage
	stats.move_speed /= 3
	poisoned_timer.timeout.connect(take_poisoned_damage)

func stunned(duration: float) -> void:
	stunned_state = true
	temp_move_speed = stats.move_speed
	stats.move_speed = 0
	stunned_timer.wait_time = duration
	stunned_timer.timeout.connect(stun_release)
	
func stun_release() -> void:
	stunned_state = false
	stunned_effect.emitting = false
	stats.move_speed = temp_move_speed

func update_animation(_animation: String) -> void:
	if animation_player != null:
		animation_player.play(_animation)
	pass
