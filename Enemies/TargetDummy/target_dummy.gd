class_name TargetDummy extends Enemy
@onready var perfect_shot_misson_label: Label = $PerfectShotMissonLabel
@onready var progress_label: Label = $ProgressLabel
@onready var finish_label: Label = $FinishLabel
@export var perfects_needed: int = 3
var total_perfects: int = 0
var sword_hit_performed: bool = false
var dash_performed: bool = false
var _bob_time: float = 5.0
var _label_origin: float = 0.0

enum TutorialPhase { SHOOT, SWORD, DASH, DONE }
var phase: TutorialPhase = TutorialPhase.SHOOT

func extra_ready_functions() -> void:
	_label_origin = perfect_shot_misson_label.position.y
	if not PlayerManager.player.target_dummy_tutorial_passed:
		perfect_shot_misson_label.show()
		progress_label.show()
		progress_label.text = "Perfect Shots: 0/" + str(perfects_needed)
		EventBus.arrow_enemy_hit.connect(hit_target_dummy)
	else:
		perfect_shot_misson_label.hide()
		progress_label.hide()
	finish_label.hide()

func _process(delta: float) -> void:
	if perfect_shot_misson_label.visible:
		_bob_time += delta
		perfect_shot_misson_label.position.y = _label_origin + sin(_bob_time * 2.5) * 4.0

func hit_target_dummy(_perfect: bool, _arrow: Arrow, _target: Enemy) -> void:
	if phase != TutorialPhase.SHOOT:
		return
	if _perfect:
		total_perfects += 1
		progress_label.text = "Perfect Shots: " + str(total_perfects) + "/" + str(perfects_needed)
		if total_perfects >= perfects_needed:
			EventBus.arrow_enemy_hit.disconnect(hit_target_dummy)
			_advance_to_sword()

func succesful_sword_hit(_enemy: Enemy) -> void:
	if phase != TutorialPhase.SWORD:
		return
	EventBus.sword_hit.disconnect(succesful_sword_hit)
	_advance_to_dash()

func succesful_preformed() -> void:
	if phase != TutorialPhase.DASH:
		return
	EventBus.dash_preformed.disconnect(succesful_preformed)
	_complete_tutorial()

func _advance_to_sword() -> void:
	phase = TutorialPhase.SWORD
	EventBus.sword_hit.connect(succesful_sword_hit)
	perfect_shot_misson_label.text = "Now try a sword hit!\nRight Mouse Button"
	progress_label.hide()

func _advance_to_dash() -> void:
	phase = TutorialPhase.DASH
	EventBus.dash_preformed.connect(succesful_preformed)
	perfect_shot_misson_label.text = "Now dash!\nPress Shift and aim with cursor"

func _complete_tutorial() -> void:
	phase = TutorialPhase.DONE
	perfect_shot_misson_label.hide()
	finish_label.show()
	PlayerManager.player.target_dummy_tutorial_passed = true
	EventBus.tutorial_done.emit()
