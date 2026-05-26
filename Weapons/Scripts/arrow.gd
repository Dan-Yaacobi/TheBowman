class_name Arrow extends CharacterBody2D

signal arrow_missed
signal crit_hit
signal leeched(amount: int, enemy_position: Vector2)

@export var data: ArrowData
@export var explosion_chance: int = 20
@onready var sprite: ArrowSprite = $Sprite2D

@onready var cpu_particles: CPUParticles2D = $CPUParticles2D
@onready var hurt_box: ArrowHurtBox = $HurtBox

const WALL_HIT_EFFECT = preload("res://Weapons/Effects/WallHitEffect/WallHitEffect.tscn")
const HIT_SOUND = preload("res://Weapons/Effects/HitSound/HitSound.tscn")
const ARROW_EXPLODE = preload("res://Player/Abilities/ShootAbilities/ArrowExplode/ArrowExplode.tscn")
const CRIT = preload("res://Weapons/Effects/CriticalHit/Crit.tscn")
const LEECH_LIFE = preload("res://Weapons/Effects/LeechLife/LeechLife.tscn")

const STUN_DEBUFF = preload("res://Debuffs/Stun/StunDebuff.tscn")
const BLEED_DEBUFF = preload("uid://b0pv21kfxpvci")
const POISON_DEBUFF = preload("res://Debuffs/Poisoned/PoisonDebuff.tscn")

var hit_effects: Array[OnHitEffect] = []

var direction: Vector2
var regular_shot: bool = true

var wall_hit_effect: CPUParticles2D
var hit_sound: AudioStreamPlayer2D
var can_pierce: bool = false
var can_explode: bool = false

var crit_chance: int = 0
var crit: bool = false
var succesfuly_hit: bool = false

var stun_chance: int = 0
var bleed_chance: int = 0
var poison_chance: int = 0
var leech_chance: int = 0

var leech_life: bool = false
var leech_amount: int = 1

var fired: bool = false
var perfect_shot: bool = false
var shot_power_mod: float = 0
var damage: int
var knockback: float

var gravity: float = 50

func _ready() -> void:
	hit_sound = HIT_SOUND.instantiate()
	cpu_particles.emitting = false
	hurt_box.monitorable = false
	hurt_box.monitoring = false
	hurt_box.body_shape_entered.connect(hit_wall)
	hurt_box.set_arrow(self)
	hurt_box.successful_hit.connect(clear_shot)
	succesfuly_hit = false
	if data.scale != 0:
		scale *= data.scale
	
	hit_effects += PlayerManager.player.use_effects()
	hurt_box.set_collision_layer_value(5,true)
	
func hit(body) -> void:
	if body is Enemy:
		if regular_shot:
			EventBus.arrow_hit_enemy.emit(self)
			for hit_effect in hit_effects:
				hit_effect.apply_effect(body,self)
			explosion()
			critical_hit()
			stun_hit(body)
			apply_leech(body)
			bleed_hit(body)
			poison_hit(body)
			succesfuly_hit = true
			clear_shot()
			
func calc_dmg(shot_power: float) -> void:
	var perfect_bonus = 1.8 if shot_power >= 1.0 else 1.0
	damage = floor((PlayerManager.player.get_strength() / 2 + data.base_damage + 4) * shot_power * perfect_bonus)
#func calc_dmg(shot_power: float) -> void:
	#damage = floor((PlayerManager.player.get_strength()/2 + data.base_damage + 4)
	#*pow(shot_power, 2))

func calc_knockback(shot_power: float) -> void:
	var perfect_bonus = 1.8 if shot_power >= 1.0 else 1.0
	knockback = data.pushback_power * shot_power * perfect_bonus + log(velocity.length())
	
#func calc_knockback(shot_power: float) -> void:
	#knockback = data.pushback_power * shot_power + log(velocity.length())

func explosion() -> void:
	if can_explode:
		var try: int = randi_range(1,100)
		if try < explosion_chance:
			var explosion_scene = ARROW_EXPLODE.instantiate()
			explosion_scene.damage = damage
			explosion_scene.global_position = global_position
			get_parent().call_deferred("add_child",explosion_scene)
			explosion_scene.call_deferred("start")
		
func missed() -> void:
	if regular_shot and not succesfuly_hit:
		arrow_missed.emit()
	queue_free()

func clear_shot() -> void:
	EventBus.arrow_hit_sound.emit()
	if not can_pierce:
		queue_free()
		
func wall_clear_shot() -> void:
	EventBus.arrow_hit_sound.emit()
	queue_free()

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
	
	if fired and _val2 is Island:
		#wall_hit_effect = WALL_HIT_EFFECT.instantiate()
		#if wall_hit_effect.get_parent() == null:
			#get_parent().call_deferred("add_child",wall_hit_effect)
		#wall_hit_effect.emitting = true
		#wall_hit_effect.global_position = global_position

		sprite.call_deferred("reparent",_val2)
		sprite.hit = true
		wall_clear_shot()

func poison_hit(_enemy: Enemy) -> void:
	var roll_poison: int = randi_range(0,100)
	if roll_poison < poison_chance:
		var poison_effect: Debuff = POISON_DEBUFF.instantiate()
		_enemy.apply_debuff(poison_effect,10,5)

func critical_hit() -> void:
	var roll_crit: int = randi_range(0,100)
	if roll_crit < crit_chance:
		var crit_effect = CRIT.instantiate()
		crit_effect.global_position = global_position
		get_parent().call_deferred("add_child", crit_effect)
		crit = true
		crit_hit.emit()
		hurt_box.damage = damage*2
			
func stun_hit(_enemy: Enemy) -> void:
	var roll_stun: int = randi_range(0,100)
	if roll_stun < stun_chance:
		var new_stun_debuff = STUN_DEBUFF.instantiate()
		_enemy.apply_debuff(new_stun_debuff,3,1)

func bleed_hit(_enemy: Enemy) -> void:
	var roll_bleed: int = randi_range(0,100)
	if roll_bleed < bleed_chance:
		var new_bleed_debuff = BLEED_DEBUFF.instantiate()
		new_bleed_debuff.set_damage(max(floor(PlayerManager.player.get_strength() / 10),1))
		_enemy.apply_debuff(new_bleed_debuff, 5,5)
		
func apply_leech(enemy: Enemy) -> void:
	var leech_roll: int = randi_range(0,100)
	if leech_roll < leech_chance:
		var leech_effect: LeechLife = LEECH_LIFE.instantiate()
		leech_effect.global_position = enemy.global_position
		get_parent().call_deferred("add_child",leech_effect)
		EventBus.leeched.emit(leech_amount,enemy.global_position)
	
func reset_specials() -> void:
	crit = false
	
