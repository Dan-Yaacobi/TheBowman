class_name BurningTrail extends Node2D
@onready var burned_effect: CPUParticles2D = $BurnedEffect
const BURN_DEBUFF = preload("uid://caiebherwxilx")
const BURN_PATCH = preload("uid://dh8ohtbhjpxti")
var arrow: Arrow
var tick: int = 0
var patch_damage: int

func set_arrow(_arrow: Arrow) -> void:
	if _arrow:
		arrow = _arrow
		patch_damage = floori(arrow.damage / 3)
		burned_effect.emitting = true

func _physics_process(_delta: float) -> void:
	set_direction(arrow.velocity)
	tick += 1
	if tick % 3 == 0:
		spawn_patch()

func set_direction(direction: Vector2) -> void:
	rotation = direction.angle() - PI / 2
	burned_effect.gravity = direction.normalized() * burned_effect.gravity.length()

func spawn_patch() -> void:
	var patch: BurnPatch = BURN_PATCH.instantiate()
	patch.global_position = global_position
	EventBus.summon_effect.emit(patch)
	patch.setup(patch_damage, func(enemy: Enemy):
		apply_burn(enemy)
	)

func apply_burn(_enemy: Enemy) -> void:
	if _enemy:
		var burn_debuff: BurnDebuff = BURN_DEBUFF.instantiate()
		burn_debuff.fire_damage = patch_damage
		_enemy.debuff_handler.add_debuff(burn_debuff, 6, 12)
