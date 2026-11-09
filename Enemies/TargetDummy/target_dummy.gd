class_name TargetDummy extends Enemy
## A training target that never dies. The tutorial (Level/Tutorial) uses it for the bow lessons.

@onready var perfect_shot_misson_label: Label = $PerfectShotMissonLabel
@onready var progress_label: Label = $ProgressLabel
@onready var finish_label: Label = $FinishLabel


func extra_ready_functions() -> void:
	# Leftovers from the old dummy tutorial; the labels stay hidden.
	perfect_shot_misson_label.hide()
	progress_label.hide()
	finish_label.hide()
