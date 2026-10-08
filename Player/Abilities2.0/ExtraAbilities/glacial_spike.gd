class_name GlacialSpike extends Node2D

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var hurt_box: HurtBox = $HurtBox
@onready var tip: Marker2D = $Tip
const FREEZE_DEBUFF = preload("uid://dewhg80xib8vt")

func _ready() -> void:
	hurt_box.add_before_effect(apply_freeze)
	@warning_ignore("narrowing_conversion")
	hurt_box.base_damage = PlayerManager.player.stats.arrow_damage.value()
	var base_position: Vector2 = hurt_box.position
	var duration: float = animation_player.get_animation("Rise").length / animation_player.speed_scale

	animation_player.play("Rise")
	_move_hurt_box(tip.position, duration)
	await animation_player.animation_finished
	if not is_inside_tree():
		return

	animation_player.play_backwards("Rise")
	_move_hurt_box(base_position, duration)
	await animation_player.animation_finished
	queue_free()

func apply_freeze(_target: GameEntity, _var2) -> void:
	if _target is Enemy:
		var debuff: Debuff = FREEZE_DEBUFF.instantiate()
		var duration = PlayerManager.player.stats.freeze_duration.value()
		_target.debuff_handler.add_debuff(debuff,CustomVariables.FREEZE_DEBUFF_ID,duration,1)
		_target.end_debuff(CustomVariables.FROSTBITE_DEBUFF_ID)
	
func _move_hurt_box(target: Vector2, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(hurt_box, "position", target, duration)
