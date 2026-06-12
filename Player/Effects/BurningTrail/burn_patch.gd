class_name BurnPatch extends Node2D
@onready var burn_timer: Timer = $BurnTimer
@onready var hurt_box: HurtBox = $HurtBox

func setup(damage: int, effects_override: Callable) -> void:
	hurt_box.damage = damage
	hurt_box.added_effects_override = effects_override
	burn_timer.timeout.connect(queue_free)
	burn_timer.start()
