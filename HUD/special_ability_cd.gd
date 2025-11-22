class_name SpecialAbilityCD extends Sprite2D

@onready var time_left_label: Label = $TimeLeftLabel

func update_time_left(t_left) -> void:
	time_left_label.text = str(round_to_dec(t_left,1))

func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
