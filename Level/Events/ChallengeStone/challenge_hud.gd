class_name ChallengeHUD extends CanvasLayer

@export var result_display_time: float = 2.5
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressLabel


func show_challenge(challenge: ChallengeDef) -> void:
	title_label.text = challenge.display_name
	description_label.text = challenge.description
	show()

func on_challenge_started() -> void:
	description_label.hide()
	progress_label.show()

func set_progress(text: String) -> void:
	progress_label.text = text

func show_result(success: bool) -> void:
	progress_label.text = "Challenge Complete" if success else "Challenge Failed"
	var tween: Tween = create_tween()
	tween.tween_interval(result_display_time)
	tween.tween_callback(hide)
