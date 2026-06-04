class_name Arrow extends CharacterBody2D

signal arrow_missed
signal crit_hit

@onready var sprite: ArrowSprite = $Sprite2D
@onready var cpu_particles: CPUParticles2D = $CPUParticles2D
@onready var hurt_box: ArrowHurtBox = $HurtBox

const WALL_HIT_EFFECT = preload("res://Weapons/Effects/WallHitEffect/WallHitEffect.tscn")
const HIT_SOUND = preload("res://Weapons/Effects/HitSound/HitSound.tscn")

var hit_effects: Array[OnHitEffect] = []
var shoot_abilities: Array = []

var direction: Vector2
var regular_shot: bool = true
var can_pierce: bool = false

var fired: bool = false
var perfect_shot: bool = false
var shot_power_mod: float = 0
var damage: int
var knockback: float
var gravity: float = 50

var succesfuly_hit: bool = false

func _ready() -> void:
	cpu_particles.emitting = false
	hurt_box.monitorable = false
	hurt_box.monitoring = false
	hurt_box.body_shape_entered.connect(hit_wall)
	hurt_box.set_arrow(self)
	hurt_box.successful_hit.connect(clear_shot)
	hit_effects += PlayerManager.player.use_effects()
	hurt_box.set_collision_layer_value(5, true)

func hit(body) -> void:
	if body is Enemy:
		if regular_shot:
			EventBus.arrow_hit_enemy.emit(self)
			for hit_effect in hit_effects:
				hit_effect.apply_effect(body, self)
			for ability in shoot_abilities:
				ability.activate_ability(self)
			succesfuly_hit = true
			clear_shot()

func calc_dmg(shot_power: float) -> void:
	var perfect_bonus = PlayerManager.player.stats.perfect_shot_bonus.value() if shot_power >= 1.0 else 1.0
	damage = floor((PlayerManager.player.stats.arrow_damage.value() + 4) * shot_power * perfect_bonus)

func calc_knockback(shot_power: float) -> void:
	var perfect_bonus = PlayerManager.player.stats.perfect_shot_bonus.value() if shot_power >= 1.0 else 1.0
	knockback = PlayerManager.player.stats.pushback_power.value() * shot_power * perfect_bonus + log(velocity.length())

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
		var arrow_weight = PlayerManager.player.stats.arrow_weight.value()
		velocity.y += gravity * remap(arrow_weight, 0.0, 100.0, 1.0, 5.0) * delta
	move_and_slide()

func set_shot_power_mod(_shot_power: float) -> void:
	shot_power_mod = pow(_shot_power, 2)

func rotate_arrow(angle: float) -> void:
	rotation = angle

func enable_arrow() -> void:
	hurt_box.monitoring = true
	hurt_box.monitorable = true

func hit_wall(_val1, _val2, _val3, _val4) -> void:
	if fired and _val2 is Island:
		sprite.call_deferred("reparent", _val2)
		sprite.hit = true
		wall_clear_shot()

func set_texture(_texture: Texture) -> void:
	sprite.texture = _texture
