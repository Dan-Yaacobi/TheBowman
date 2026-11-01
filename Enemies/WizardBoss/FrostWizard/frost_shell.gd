class_name FrostShell extends Node2D
## An ice shell that blocks all damage to the wizard it is attached to.
## Arrow hits crack it (perfect shots crack it more). When it breaks, the wizard's
## current spell is cut short and he is frozen for a moment.

signal broken

## Total cracking needed to break the shell
@export var crack_points: int = 6
@export var perfect_hit_value: int = 3
@export var normal_hit_value: int = 1
## Seconds for the shell to grow in
@export var form_time: float = 0.5
## How fast the white hit flash fades (per second)
@export var flash_fade_speed: float = 6.0
@export_group("Freeze")
@export var freeze_scene: PackedScene
@export var freeze_duration: float = 2.5

@onready var shell_rect: ColorRect = $Shell
@onready var shatter: CPUParticles2D = $Shatter

var _wizard: WizardBoss
var _cracked: int = 0
var _form: float = 0.0
var _flash: float = 0.0
var _broken: bool = false
var _material: ShaderMaterial

func _ready() -> void:
	_material = shell_rect.material as ShaderMaterial
	_update_shader()

## Put the shell on a wizard; from now on his hits go to absorb_hit()
func attach(wizard: WizardBoss) -> void:
	_wizard = wizard
	wizard.shield = self

func _process(delta: float) -> void:
	if _broken:
		return
	if form_time > 0.0:
		_form = minf(_form + delta / form_time, 1.0)
	else:
		_form = 1.0
	_flash = maxf(_flash - delta * flash_fade_speed, 0.0)
	_update_shader()

func absorb_hit(hurt_box: HurtBox) -> void:
	if _broken:
		return
	var arrow: Arrow = (hurt_box.get_parent() as Arrow) if hurt_box else null
	var value: int = perfect_hit_value if arrow and arrow.perfect_shot else normal_hit_value
	_cracked += value
	_flash = 1.0
	_update_shader()
	if _cracked >= crack_points:
		_break()

func _update_shader() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("form", _form)
	_material.set_shader_parameter("cracks", clampf(float(_cracked) / float(maxi(crack_points, 1)), 0.0, 1.0))
	_material.set_shader_parameter("hit_flash", _flash)

func _break() -> void:
	_broken = true
	broken.emit()
	if is_instance_valid(_wizard):
		if _wizard.shield == self:
			_wizard.shield = null
		_wizard.interrupt_spell()
		if freeze_scene:
			var freeze: Debuff = freeze_scene.instantiate()
			_wizard.apply_debuff(freeze, CustomVariables.FREEZE_DEBUFF_ID, freeze_duration, 1)
	shell_rect.visible = false
	shatter.emitting = true
	# Let the shards finish before removing the node
	await get_tree().create_timer(shatter.lifetime + 0.1).timeout
	if is_inside_tree():
		queue_free()
