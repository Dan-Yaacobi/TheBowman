class_name IcePatch extends Node2D
## A temporary sheet of ice: grows in, makes the ground slippery, then melts away.
## Add it as a child of whatever it covers (e.g. an island) so it moves with it.

## How long the ice lasts; 0 = forever
@export var lifetime: float = 3.0
## Seconds for the sheet to spread to full width
@export var grow_time: float = 0.25
## Seconds for the sheet to shrink away at the end
@export var melt_time: float = 0.5

@onready var slippery_surface: SlipperySurface = $SlipperySurface
@onready var sheet: ColorRect = $Sheet

var _life: float = 0.0
var _material: ShaderMaterial

func _ready() -> void:
	_material = sheet.material as ShaderMaterial
	_update_visual()

func _physics_process(delta: float) -> void:
	_life += delta
	_update_visual()
	if lifetime > 0.0 and _life >= lifetime:
		queue_free()

## Restart the lifetime without growing in again (e.g. iced a second time)
func refresh() -> void:
	_life = minf(_life, grow_time)

## The active patch on a node, if any
static func find_on(target: Node) -> IcePatch:
	for child: Node in target.get_children():
		if child is IcePatch and not child.is_queued_for_deletion():
			return child
	return null

func _update_visual() -> void:
	if _material == null:
		return
	var amount: float = 1.0
	if grow_time > 0.0:
		amount = minf(amount, _life / grow_time)
	if lifetime > 0.0 and melt_time > 0.0:
		amount = minf(amount, (lifetime - _life) / melt_time)
	_material.set_shader_parameter("ice_amount", clampf(amount, 0.0, 1.0))
