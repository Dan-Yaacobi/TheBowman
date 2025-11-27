class_name CombatText extends Node2D

const COMBAT_TEXT = preload("res://General Nodes/CombatText/CombatText.tscn")

@onready var combat_text: Label = $CombatText

@export var float_speed := 10.0
@export var fade_speed := 2.0

var text: String
var appear: bool = false

func _ready() -> void:
	scale *= randf_range(0.8,1.2)
	visible = false
	
func _process(delta: float) -> void:
	if appear:
		position.y -= delta * float_speed
		modulate.a = max(modulate.a - delta * fade_speed, 0.0)
		if modulate.a == 0:
			queue_free()

func start() -> void:
	appear = true
	visible = true
	set_text(text)

func crit() -> void:
	pass
	
func set_text(_text: String) -> void:
	combat_text.text = _text

func set_text_color(color: Color) -> void:
	if color:
		combat_text.add_theme_color_override("font_color", color)
		
		
		
