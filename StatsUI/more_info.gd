class_name MoreInfoButton extends TextureButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var label_1: Label = $TextureRect/Label
@onready var label_2: Label = $TextureRect/Label2
@onready var label_3: Label = $TextureRect/Label3

var closed: bool = false
#
func _ready() -> void:
	close()

func open() -> void:
	visible = true
	if closed:
		animation_player.play("Open")
		closed = not closed

func close() -> void:
	if not closed:
		animation_player.play("Close")
		closed = not closed
		
func _on_toggled(_toggled_on: bool) -> void:
	if closed:
		open()
	else:
		close()

func set_colors(color1: Color, color2: Color, color3: Color) -> void:
	print(color1, " " , color2, " ", color3)
	label_1.set("theme_override_colors/font_color", color1)
	label_2.set("theme_override_colors/font_color", color2)
	label_3.set("theme_override_colors/font_color", color3)
