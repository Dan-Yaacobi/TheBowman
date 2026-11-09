class_name DataConsent extends Control
## First-launch screen asking whether gameplay stats may be sent.
## Blocks the start menu until answered. The answer can be changed later in Settings.

signal answered(accepted: bool)

@onready var yes_button: Button = %YesButton
@onready var no_button: Button = %NoButton

func _ready() -> void:
	yes_button.pressed.connect(_on_yes_button_pressed)
	no_button.pressed.connect(_on_no_button_pressed)
	visible = RunTracker.uploader.needs_consent()

func _on_yes_button_pressed() -> void:
	_answer(true)

func _on_no_button_pressed() -> void:
	_answer(false)

func _answer(accepted: bool) -> void:
	RunTracker.uploader.set_consent(accepted)
	hide()
	answered.emit(accepted)
