class_name Chest extends GameObject

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func break_item(_hurt_box: HurtBox) -> void:
	if data.interactable and not got_hit:
		got_hit = true
		animation_player.play("Open")
		await animation_player.animation_finished
		drop_items(0.5)
		queue_free()
