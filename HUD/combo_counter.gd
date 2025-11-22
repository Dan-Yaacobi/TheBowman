class_name ComboCounter extends Label

@onready var combo_animation: AnimationPlayer = $ComboAnimation

func update_combo(amount: int) -> void:
	text = "Combo: " + str(amount)
	if amount == 0:
		combo_animation.play("Lost")
	elif amount > 0:
		if amount >= 10:
			if amount >= 25:
				combo_animation.play("Gained25")
			else:
				combo_animation.play("Gained10")
		else:
			combo_animation.play("Gained")
