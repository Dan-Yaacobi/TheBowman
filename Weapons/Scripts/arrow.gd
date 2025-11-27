class_name Arrow extends CharacterBody2D

signal arrow_missed
signal arrow_hit
signal arrow_hit_sound
signal crit_hit
signal leeched(amount: int, enemy_position: Vector2)

@export var data: ArrowData
@export var explosion_chance: int = 20

@onready var cpu_particles: CPUParticles2D = $CPUParticles2D
@onready var hurt_box: HurtBox = $HurtBox

const WALL_HIT_EFFECT = preload("res://Weapons/Effects/WallHitEffect/WallHitEffect.tscn")
const HIT_SOUND = preload("res://Weapons/Effects/HitSound/HitSound.tscn")
const ARROW_EXPLODE = preload("res://Player/Abilities/ShootAbilities/ArrowExplode/ArrowExplode.tscn")
const CRIT = preload("res://Weapons/Effects/CriticalHit/Crit.tscn")
const LEECH_LIFE = preload("res://Weapons/Effects/LeechLife/LeechLife.tscn")

var direction: Vector2
var regular_shot: bool = true

var wall_hit_effect: CPUParticles2D
var hit_sound: AudioStreamPlayer2D
var can_pierce: bool = false
var can_explode: bool = false

var can_crit: bool = false
var crit_chance: int = 10
var crit: bool = false
var succesfuly_hit: bool = false

var can_stun: bool = false
var stun_chance: int = 10
var stun: bool = false
var stun_duration: float = 2

var can_leechlife: bool = false
var leech_chance: int = 10
var leech_life: bool = false
var leech_amount: int = -1

var fired: bool = false
var perfect_shot: bool = false
var shot_power_mod: float = 0

func _ready() -> void:
	hit_sound = HIT_SOUND.instantiate()
	cpu_particles.emitting = false
	hurt_box.monitorable = false
	hurt_box.monitoring = false
	hurt_box.body_shape_entered.connect(hit_wall)

	succesfuly_hit = false
	if data.scale != 0:
		scale *= data.scale
	
func hit(body) -> void:
	if body is Enemy:
		if regular_shot:
			explosion()
			critical_hit()
			stun_hit()
			apply_leech(body)
			succesfuly_hit = true
			arrow_hit.emit()

func calc_dmg(shot_power: float) -> void:
	data.damage = floor((PlayerManager.player.get_strength() + data.base_damage)
	*pow(shot_power, 2))
	
func explosion() -> void:
	if can_explode:
		var try: int = randi_range(1,100)
		if try < explosion_chance:
			var explosion = ARROW_EXPLODE.instantiate()
			explosion.damage = data.damage
			explosion.global_position = global_position
			get_parent().call_deferred("add_child",explosion)
			explosion.call_deferred("start")
		
func missed() -> void:
	if regular_shot and not succesfuly_hit:
		arrow_missed.emit()
	queue_free()

func clear_shot() -> void:
	arrow_hit_sound.emit()
	if not can_pierce:
		queue_free()
		
func wall_clear_shot() -> void:
	arrow_hit_sound.emit()
	queue_free()

var gravity: float = 50

func _physics_process(delta: float) -> void:
	if fired:
		cpu_particles.emitting = true
		rotate_arrow(velocity.angle())
		cpu_particles.direction = velocity
		velocity.y += gravity*delta
	move_and_slide()
	
func set_shot_power_mod(_shot_power: float) -> void:
	shot_power_mod = pow(_shot_power, 2)
	
func rotate_arrow(angle: float) -> void:
	rotation = angle

func enable_arrow() -> void:
	hurt_box.monitoring = true
	hurt_box.monitorable = true
	
func hit_wall(_val1,_val2,_val3,_val4) -> void:
	if fired:
		if _val2 is TileMapLayer:
			wall_hit_effect = WALL_HIT_EFFECT.instantiate()
			if wall_hit_effect.get_parent() == null:
				get_parent().call_deferred("add_child",wall_hit_effect)
			wall_hit_effect.emitting = true
			wall_hit_effect.global_position = global_position
			wall_clear_shot()

func critical_hit() -> void:
	if can_crit:
		var roll_crit: int = randi_range(0,100)
		if roll_crit < crit_chance:
			var crit_effect = CRIT.instantiate()
			crit_effect.global_position = global_position
			get_parent().call_deferred("add_child", crit_effect)
			crit = true
			crit_hit.emit()
			hurt_box.damage = data.damage*2
			
func stun_hit() -> void:
	if can_stun:
		var roll_stun: int = randi_range(0,100)
		if roll_stun < stun_chance:
			stun = true

func apply_leech(enemy: Enemy) -> void:
	if can_leechlife:
		var leech_roll: int = randi_range(0,100)
		if leech_roll < leech_chance:
			var leech_effect: LeechLife = LEECH_LIFE.instantiate()
			leech_effect.global_position = enemy.global_position
			get_parent().call_deferred("add_child",leech_effect)
			leeched.emit(leech_amount,enemy.global_position)
			pass
	
func reset_specials() -> void:
	stun = false
	crit = false
