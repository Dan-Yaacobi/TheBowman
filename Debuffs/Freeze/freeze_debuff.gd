class_name FreezeDebuff extends Debuff

func start_debuff_effect() -> void:
	one_shot = true
	apply_debuff_effect()
	
func apply_debuff_effect() -> void:
	entity.stun()
	
func extra_end_debuff_methods() -> void:
	entity.end_stun()
	var host: Node2D = get_parent() as Node2D
	if host and is_instance_valid(entity) and not (entity is Enemy and (entity as Enemy).is_dead):
		EffectSprite.spawn(&"freeze_shatter", host.to_global(host_rect().get_center()))

## The ice block grows or shrinks to cover the frozen body.
func _attach_status_sprite() -> void:
	super()
	var host: Node2D = get_parent() as Node2D
	if _status_sprite == null or host == null:
		return
	var body: Vector2 = host_rect().size * host.global_scale.abs()
	var block: Vector2 = Vector2(36, 44) * _status_sprite.sheet.world_scale
	_status_sprite.size_mult = clampf(maxf(body.x / block.x, body.y / block.y) * 1.1, 0.6, 3.0)

func status_sheet_name() -> StringName:
	return &"status_frozen"

func status_spot() -> StatusSpot:
	return StatusSpot.CENTER
