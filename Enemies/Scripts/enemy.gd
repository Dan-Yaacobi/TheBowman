class_name Enemy extends CharacterBody2D

@export var stats: EnemyData
@export var item_drops: Array[DropData]

static var player: Player

const ITEM_PICK_UP = preload("res://Items/ItemPickUp.tscn")
const HIT_PARTICLES = preload("res://Enemies/EnemyEffects/EnemyHit/HitParticles.tscn")

signal died

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
func _ready() -> void:
	pass
	
func get_player(_player: Player) -> void:
	if _player != null:
		player = _player
	
func calculate_direction_to_player() -> Vector2:
	var _direction: Vector2
	_direction = player.global_position - global_position
	return _direction.normalized()

func hit(_arrow: Area2D) -> void:
	if _arrow is Arrow and _arrow != null:
		if not added_hit_effect:
			added_hit_effect = true
			hit_particle_effect = HIT_PARTICLES.instantiate()
			#hit_particle_effect.gravity = _arrow.direction * 150
			add_child(hit_particle_effect)
			
		if hit_particle_effect != null:
			hit_particle_effect.restart()
		push_back(_arrow.direction,_arrow.data.pushback_power)
		take_damage(_arrow.data.damage)
		_arrow.hit()
		_arrow.clear_shot()

func take_damage(_dmg: int) -> void:
	stats.hp -= _dmg
	animation_player.play("Damaged")
	if stats.hp <= 0:
		activate_death_ability()
		enemy_died()
		drop_item()
		
	
func activate_death_ability() -> void:
	if stats.death_ability.size() > 0:
		for ability in stats.death_ability:
			ability.activate_ability(self)

func enemy_died() -> void:
	died.emit(self)
	queue_free()
	
func push_back(_direction: Vector2, power: int) -> void:
	velocity = Vector2.ZERO
	velocity += _direction * power

func player_hit(body: CharacterBody2D) -> void:
	if body is Player:
		body.hit_player(stats.touch_damage)
		body.set_pushback_values(direction,stats.knockback)
		push_back(-direction,stats.move_speed)

func drop_item() -> void:
	if not no_drops:
		for drop in item_drops:
			if drop.drop_chance():
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

func stunned() -> void:
	stunned_state = true
	temp_move_speed = stats.move_speed
	stats.move_speed = 0
	stunned_timer.timeout.connect(stun_release)
	
func stun_release() -> void:
	stunned_state = false
	stunned_effect.emitting = false
	stats.move_speed = temp_move_speed
