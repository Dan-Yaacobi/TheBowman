class_name WizardTeleportState extends EnemyState

enum Phase {CAST, FADE_OUT, HIDDEN, FADE_IN}

@export var idle_state: EnemyState
@export var cast_animation: String = "Cast"
@export var arrive_animation: String = "Idle"
@export var fade_duration: float = 0.35
## Extra time the landing sparkles show before he appears
@export var arrival_delay: float = 0.6
@export var sparkle_scene: PackedScene

var wizard: WizardBoss
var _phase: Phase = Phase.CAST
var _elapsed: float = 0.0
var _next_spell: WizardSpellState
var _destination: Marker2D
var _arrival_fx: LingeringEffect

func init() -> void:
	wizard = enemy as WizardBoss
	if idle_state == null:
		push_error("%s has no idle_state set" % name)

func Enter() -> void:
	_next_spell = wizard.next_spell()
	_destination = _pick_destination()
	_start_phase(Phase.CAST)

func Exit() -> void:
	wizard.set_fade(0.0)
	wizard.set_targetable(true)
	_stop_arrival_fx()

func Physics(delta: float) -> EnemyState:
	_elapsed += delta
	match _phase:
		Phase.CAST:
			if _elapsed >= _anim_length(cast_animation):
				_start_phase(Phase.FADE_OUT)
		Phase.FADE_OUT:
			wizard.set_fade(_fade_progress())
			if _elapsed >= fade_duration:
				_start_phase(Phase.HIDDEN)
		Phase.HIDDEN:
			if _elapsed >= arrival_delay:
				_relocate()
				_start_phase(Phase.FADE_IN)
		Phase.FADE_IN:
			wizard.set_fade(1.0 - _fade_progress())
			if _elapsed >= fade_duration:
				return _next_spell if _next_spell else idle_state
	return null

func _start_phase(phase: Phase) -> void:
	_phase = phase
	_elapsed = 0.0
	match phase:
		Phase.CAST:
			wizard.update_animation(cast_animation)
		Phase.FADE_OUT:
			wizard.set_targetable(false)
			if _destination:
				_arrival_fx = _spawn_fx(_destination.global_position)
		Phase.FADE_IN:
			_stop_arrival_fx()
			wizard.update_animation(arrive_animation)

func _fade_progress() -> float:
	if fade_duration <= 0.0:
		return 1.0
	return clampf(_elapsed / fade_duration, 0.0, 1.0)

func _pick_destination() -> Marker2D:
	if _next_spell:
		return _next_spell.pick_point(wizard.teleport_points, wizard.current_point)
	return WizardSpellState.random_point(wizard.teleport_points, wizard.current_point)

func _relocate() -> void:
	if _destination:
		wizard.global_position = _destination.global_position
		wizard.current_point = _destination

func _spawn_fx(pos: Vector2) -> LingeringEffect:
	if sparkle_scene == null:
		return null
	var parent: Node2D = wizard.get_parent() as Node2D
	var fx: LingeringEffect = sparkle_scene.instantiate()
	fx.modulate = wizard.element_color
	# Position before entering the tree so the first particles don't spawn at the origin
	fx.position = parent.to_local(pos)
	parent.add_child(fx)
	return fx

func _stop_arrival_fx() -> void:
	if is_instance_valid(_arrival_fx):
		_arrival_fx.stop()
	_arrival_fx = null

func _anim_length(anim_name: String) -> float:
	if wizard.animation_player and wizard.animation_player.has_animation(anim_name):
		return wizard.animation_player.get_animation(anim_name).length
	return 0.0
