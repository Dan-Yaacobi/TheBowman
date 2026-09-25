class_name Chest extends GameObject

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func break_item(_hurt_box: HurtBox,_raw_damage: int = 0, _result: DamageResult = null) -> void:
	if data.interactable and not got_hit:
		got_hit = true
		animation_player.play("Open")
		await animation_player.animation_finished
		drop_items()
		queue_free()
