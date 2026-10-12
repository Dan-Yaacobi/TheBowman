class_name WizardTeleportState extends EnemyState

enum Phase {OUT, HIDDEN, IN}

@export var idle_state: EnemyState
@export var out_animation: String = "Cast"
@export var in_animation: String = "Cast"
@export var hidden_duration: float = 0.3

var wizard: WizardBoss
var _phase: Phase = Phase.OUT
var _elapsed: float = 0.0
var _next_spell: WizardSpellState

func init() -> void:
	wizard = enemy as WizardBoss

func Enter() -> void:
	_next_spell = wizard.next_spell()
	wizard.set_targetable(false)
	_start_phase(Phase.OUT)

func Exit() -> void:
	wizard.sprite.visible = true
	wizard.set_targetable(true)

func Physics(delta: float) -> EnemyState:
	_elapsed += delta
	match _phase:
		Phase.OUT:
			if _elapsed >= _anim_length(out_animation):
				wizard.sprite.visible = false
				_start_phase(Phase.HIDDEN)
		Phase.HIDDEN:
			if _elapsed >= hidden_duration:
				_relocate()
				wizard.sprite.visible = true
				_start_phase(Phase.IN)
		Phase.IN:
			if _elapsed >= _anim_length(in_animation):
				return _next_spell if _next_spell else idle_state
	return null

func _start_phase(phase: Phase) -> void:
	_phase = phase
	_elapsed = 0.0
	match phase:
		Phase.OUT:
			wizard.update_animation(out_animation)
		Phase.IN:
			wizard.update_animation(in_animation)

func _relocate() -> void:
	var point: Marker2D
	if _next_spell:
		point = _next_spell.pick_point(wizard.teleport_points, wizard.current_point)
	else:
		point = WizardSpellState.random_point(wizard.teleport_points, wizard.current_point)
	if point:
		wizard.global_position = point.global_position
		wizard.current_point = point

func _anim_length(anim_name: String) -> float:
	if wizard.animation_player and wizard.animation_player.has_animation(anim_name):
		return wizard.animation_player.get_animation(anim_name).length
	return 0.0
