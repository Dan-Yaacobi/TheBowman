class_name Icicle extends Node2D
## Hangs above its island and shakes as a warning, then drops.
## Shatters on the first island it reaches and leaves an ice patch there.

enum Phase {WAITING, HANGING, FALLING}

@export var damage: int = 2
@export var knockback: float = 200.0
@export var start_speed: float = 40.0
@export var max_speed: float = 700.0
## Seconds to go from start_speed to max_speed
@export var ramp_time: float = 0.9
## Higher = slower start, sharper ramp
@export var ramp_curve: float = 2.5
## Sideways jitter in pixels at the end of the hang
@export var shake_strength: float = 1.5
## Safety: free the icicle if it falls this long without landing
@export var max_fall_time: float = 3.0
## Sheet of icicle variants; each icicle shows a random frame
@export var texture_data: TextureData
@export_group("Frostbite")
@export var frostbite_scene: PackedScene
@export var frostbite_duration: float = 1.5
## Share of move speed removed while frostbitten
@export var frostbite_slow: float = 0.5
@export_group("Ice")
@export var ice_patch_scene: PackedScene
@export var ice_lifetime: float = 3.0

@onready var hurt_box: HurtBox = $HurtBox
@onready var ground_detector: Area2D = $GroundDetector
@onready var visual: Sprite2D = $Visual
@onready var target_mark: Node2D = $TargetMark
@onready var shadow: ColorRect = $TargetMark/Shadow
@onready var frost_drip: CPUParticles2D = $FrostDrip

var _phase: Phase = Phase.WAITING
var _time: float = 0.0
var _hang_time: float = 1.0
var _target: Island
var _landed: bool = false

func _ready() -> void:
	hurt_box.base_damage = damage
	hurt_box.knockback_power = knockback
	hurt_box.add_after_effect(_apply_frostbite)
	if texture_data:
		var variant: AtlasTexture = texture_data.get_random_sprite()
		if variant:
			visual.texture = variant
	_set_dangerous(false)
	ground_detector.body_entered.connect(_on_ground_detector_body_entered)
	ProjectileGlow.attach(self)

## Hang at start for hang_time seconds, then drop straight down onto target
func drop_onto(target: Island, start: Vector2, hang_time: float) -> void:
	if not is_node_ready():
		await ready
	_target = target
	global_position = start
	_hang_time = maxf(hang_time, 0.01)
	_time = 0.0
	_phase = Phase.HANGING
	target_mark.visible = true
	frost_drip.emitting = true
	_update_mark()

func _physics_process(delta: float) -> void:
	match _phase:
		Phase.HANGING:
			_time += delta
			var progress: float = clampf(_time / _hang_time, 0.0, 1.0)
			visual.position.x = randf_range(-1.0, 1.0) * shake_strength * progress
			_update_mark()
			if _time >= _hang_time:
				_start_fall()
		Phase.FALLING:
			_time += delta
			if _time >= max_fall_time:
				queue_free()
				return
			var t: float = clampf(_time / ramp_time, 0.0, 1.0)
			var speed: float = lerpf(start_speed, max_speed, ease(t, ramp_curve))
			global_position += Vector2.DOWN * speed * delta
			_update_knockback_dir()
			_update_mark()

func _start_fall() -> void:
	_phase = Phase.FALLING
	_time = 0.0
	visual.position = Vector2.ZERO
	frost_drip.emitting = false
	_set_dangerous(true)

func _set_dangerous(value: bool) -> void:
	hurt_box.set_deferred("monitoring", value)

# A shadow on the target island grows and darkens as the drop nears
func _update_mark() -> void:
	if not is_instance_valid(_target):
		target_mark.visible = false
		return
	target_mark.global_position = _target.global_position
	var progress: float = 1.0
	if _phase == Phase.HANGING:
		progress = clampf(_time / _hang_time, 0.0, 1.0)
	var mat: ShaderMaterial = shadow.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("progress", progress)

func _update_knockback_dir() -> void:
	var side: float = signf(PlayerManager.player.global_position.x - global_position.x)
	if side == 0.0:
		side = 1.0 if randf() < 0.5 else -1.0
	hurt_box.knockback_dir = Vector2(side, -0.3).normalized()

func _apply_frostbite(target: GameEntity, _hurt_box: Node2D, _result: DamageResult) -> void:
	if frostbite_scene == null or not target is Player:
		return
	var debuff: FrostBiteDebuff = frostbite_scene.instantiate()
	debuff.set_slow_strength(frostbite_slow)
	target.apply_debuff(debuff, CustomVariables.FROSTBITE_DEBUFF_ID, frostbite_duration, 1)

func _on_ground_detector_body_entered(body: Node2D) -> void:
	if _landed or _phase != Phase.FALLING or not body is Island:
		return
	_landed = true
	_freeze_island(body as Island)
	queue_free()

func _freeze_island(island: Island) -> void:
	var existing: IcePatch = IcePatch.find_on(island)
	if existing:
		existing.refresh()
		return
	if ice_patch_scene == null:
		return
	var patch: IcePatch = ice_patch_scene.instantiate()
	patch.lifetime = ice_lifetime
	patch.position = island.objects_spawn_markers.position
	island.call_deferred("add_child", patch)
