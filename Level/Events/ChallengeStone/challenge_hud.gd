class_name ChallengeHUD extends CanvasLayer

@export var result_display_time: float = 2.5
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressLabel


func show_challenge(challenge: ChallengeDef) -> void:
	show_title(challenge.display_name, challenge.description)

## For timed events that aren't shrine challenges (e.g. the Golden Apple).
func show_title(title: String, description: String = "") -> void:
	title_label.text = title
	description_label.text = description
	show()

func on_challenge_started() -> void:
	description_label.hide()
	progress_label.show()

func set_progress(text: String) -> void:
	progress_label.text = text

## result_text overrides the default "Challenge Complete" / "Challenge Failed".
func show_result(success: bool, result_text: String = "") -> void:
	if result_text.is_empty():
		result_text = "Challenge Complete" if success else "Challenge Failed"
	progress_label.text = result_text
	var tween: Tween = create_tween()
	tween.tween_interval(result_display_time)
	tween.tween_callback(hide)
