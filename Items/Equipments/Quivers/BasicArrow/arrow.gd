class_name Arrow extends CharacterBody2D

@onready var sprite: ArrowSprite = $Sprite2D
#@onready var cpu_particles: CPUParticles2D = $CPUParticles2D
@onready var hurt_box: HurtBox = $HurtBox
@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var after_image_spawner: AfterimageSpawner = $AfterImageSpawner

@export var dmg_variance_strength: float = 0.5
@export var dmg_variance_skew: float = 2.0 

const WALL_HIT_EFFECT = preload("uid://cjafbvkr7l5xk")
const CRIT = preload("uid://dvpa8tuvsardc")
const HIT_SOUND = preload("uid://bomaal61jofg4")

var hit_effects: Array[OnHitEffect] = []
var shoot_abilities: Array = []

var direction: Vector2
var regular_shot: bool = true
var can_pierce: bool = false

var fired: bool = false
var enabled: bool = false
var perfect_shot: bool = false
var shot_power_mod: float = 0
var damage: int
var knockback: float
var gravity: float = 50

var succesfuly_hit: bool = false
var possible_pierce: int = 1
var pierce_count: int = 0

var can_pass_walls: bool = false
var crit_chance: float = 0.0
var crit: bool = false
var arrow_shot_power: float
var texture: Texture2D

func _ready() -> void:
	
	print("ready")
	hurt_box.monitorable = false
	hurt_box.monitoring = false
	hurt_box.body_shape_entered.connect(hit_wall)
	
	hurt_box.add_before_effect(arrow_setup)
	hit_effects += PlayerManager.player.use_effects()
	hurt_box.set_collision_layer_value(5, true)
	visible_on_screen_notifier.screen_exited.connect(missed)
	set_texture(texture)
	hurt_box.successful_hit.connect(hit)

func arrow_setup(_entity: GameEntity) -> void:
	hurt_box.damage = damage
	hurt_box.knockback_power = knockback
	hurt_box.knockback_dir = velocity.normalized()
	
func hit(_hurt_box,_hit_box) -> void:
	if _hit_box is EnemyHitBox:
		var body = _hit_box.enemy
		if regular_shot:
			if crit:
				crit_effect(body)
			for ability in shoot_abilities:
				ability.activate_ability(body,self)
			succesfuly_hit = true
			EventBus.arrow_enemy_hit.emit(perfect_shot, self, body)
	pierce_count += 1
	clear_shot()
			
func crit_effect(_body: Enemy) -> void:
	var _crit_effect = CRIT.instantiate()
	_crit_effect.global_position = _body.global_position
	EventBus.summon_effect.emit(_crit_effect)

func calc_dmg(shot_power: float) -> void:
	var crit_bonus = 1.0
	if randf_range(0, 100) < crit_chance:
		crit = true
		crit_bonus = PlayerManager.player.stats.crit_modifier.value()

	var is_perfect: bool = shot_power >= 1.0
	var perfect_bonus = PlayerManager.player.stats.perfect_shot_bonus.value() if is_perfect else 1.0

	var variance_mult: float = 1.0
	if not is_perfect:
		var floor_mult: float = 1.0 - dmg_variance_strength * (1.0 - shot_power)
		var roll: float = pow(randf(), dmg_variance_skew)
		variance_mult = lerpf(floor_mult, 1.0, roll)

	damage = floor((PlayerManager.player.stats.arrow_damage.value() + 4) * shot_power * perfect_bonus * crit_bonus * variance_mult)
	
func calc_knockback(shot_power: float) -> void:
	if PlayerManager.player.stats.can_knockback <= 0:
		var perfect_bonus = PlayerManager.player.stats.perfect_shot_bonus.value() if shot_power >= 1.0 else 1.0
		knockback = PlayerManager.player.stats.pushback_power.value() * shot_power * perfect_bonus + log(velocity.length())
	else:
		knockback = 0

func missed() -> void:
	if regular_shot and not succesfuly_hit:
		EventBus.arrow_missed.emit()
	await get_tree().create_timer(0.5).timeout
	queue_free()

func clear_shot() -> void:
	EventBus.arrow_hit_sound.emit()
	if pierce_count >= possible_pierce:
		hurt_box.set_deferred("monitoring",false)
		hurt_box.set_deferred("monitorable",false)
		await get_tree().create_timer(0.05, true, false, true).timeout
		queue_free()

func wall_clear_shot() -> void:
	queue_free()

func _physics_process(delta: float) -> void:
	if fired:
		after_image_spawner.activate(arrow_shot_power)
		if not enabled:
			enabled = true
			enable_arrow()
			#cpu_particles.emitting = true
		rotate_arrow(velocity.angle())
		#cpu_particles.direction = velocity
		var arrow_weight = PlayerManager.player.stats.arrow_weight.value()
		velocity.y += gravity * remap(arrow_weight, 0.0, 30, 1.0, 3.0) * delta
	move_and_slide()

func set_shot_power_mod(_shot_power: float) -> void:
	shot_power_mod = pow(_shot_power, 2)

func rotate_arrow(angle: float) -> void:
	rotation = angle

func enable_arrow(_enable: bool = true) -> void:
	hurt_box.monitoring = _enable
	hurt_box.monitorable = _enable

func hit_wall(_val1, _val2, _val3, _val4) -> void:
	if fired and _val2 is Island and not can_pass_walls:
		EventBus.arrow_hit_wall_sound.emit()
		sprite.call_deferred("reparent", _val2)
		sprite.hit = true
		if regular_shot and not succesfuly_hit:
			EventBus.arrow_missed.emit()
		wall_clear_shot()

func set_texture(_texture: Texture) -> void:
	sprite.texture = _texture
