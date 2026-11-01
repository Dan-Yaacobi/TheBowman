class_name FrostRay extends Node2D
## A straight frost beam. The caster drives it: set_aim() points it, set_power() grows it,
## set_active() turns the damage on. Frees itself if its source disappears.

@export var damage: int = 1
## Seconds between hits while the player stays in the beam
@export var tick_interval: float = 0.5
@export_group("Frostbite")
@export var frostbite_scene: PackedScene
@export var frostbite_duration: float = 1.0
## Share of move speed removed while frostbitten
@export var frostbite_slow: float = 0.5

@onready var pivot: Node2D = $Pivot
@onready var beam: ColorRect = $Pivot/Beam
@onready var hurt_box: HurtBox = $Pivot/HurtBox

var _material: ShaderMaterial
var _active: bool = false
var _tick_timer: float = 0.0
var _source: WeakRef

func _ready() -> void:
	_material = beam.material as ShaderMaterial
	hurt_box.base_damage = damage
	hurt_box.knockback_power = 0.0
	hurt_box.add_after_effect(_apply_frostbite)
	hurt_box.set_deferred("monitoring", false)
	set_power(0.0, true)
	# Hidden until the caster aims it, so it never flashes at the wrong angle
	visible = false

## The node that fires the beam; if it is freed, the beam goes with it
func set_source(source: Node) -> void:
	_source = weakref(source)

func set_aim(angle: float) -> void:
	pivot.rotation = angle
	visible = true

func get_aim() -> float:
	return pivot.rotation

func set_power(value: float, charging: bool) -> void:
	if _material == null:
		return
	_material.set_shader_parameter("power", clampf(value, 0.0, 1.0))
	_material.set_shader_parameter("charging", charging)

func set_opacity(value: float) -> void:
	if _material:
		_material.set_shader_parameter("opacity", clampf(value, 0.0, 1.0))

func set_active(value: bool) -> void:
	_active = value
	_tick_timer = 0.0
	hurt_box.set_deferred("monitoring", value)

func _physics_process(delta: float) -> void:
	if _source and not is_instance_valid(_source.get_ref()):
		queue_free()
		return
	if not _active:
		return
	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		_retrigger()

# Toggling monitoring makes anything still inside register as entering again
func _retrigger() -> void:
	hurt_box.monitoring = false
	await get_tree().physics_frame
	if not is_inside_tree() or not _active:
		return
	hurt_box.monitoring = true

func _apply_frostbite(target: GameEntity, _hurt_box: Node2D, _result: DamageResult) -> void:
	if frostbite_scene == null or not target is Player:
		return
	var debuff: FrostBiteDebuff = frostbite_scene.instantiate()
	debuff.set_slow_strength(frostbite_slow)
	target.apply_debuff(debuff, CustomVariables.FROSTBITE_DEBUFF_ID, frostbite_duration, 1)
