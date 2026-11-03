class_name SwordOpenerMinor extends MinorAbility
## Enemies hit by your sword take +value% arrow damage for a short time, shown with a slash mark on them.

const OPENED_UNTIL_META: StringName = &"sword_opened_until"
@export var duration: float = 2.0

func on_equipped() -> void:
	if not EventBus.sword_hit.is_connected(_on_sword_hit):
		EventBus.sword_hit.connect(_on_sword_hit)

func on_unequipped() -> void:
	if EventBus.sword_hit.is_connected(_on_sword_hit):
		EventBus.sword_hit.disconnect(_on_sword_hit)

func _on_sword_hit(target: Node2D) -> void:
	var enemy: Enemy = target as Enemy
	if enemy == null or enemy.is_dead:
		return
	enemy.set_meta(OPENED_UNTIL_META, Time.get_ticks_msec() / 1000.0 + duration)
	SlashMark.show_on(enemy, duration)

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	if enemy == null or hurt_box == null or MinorHitHelpers.arrow_of(hurt_box) == null:
		return
	if enemy.get_meta(OPENED_UNTIL_META, 0.0) > Time.get_ticks_msec() / 1000.0:
		MinorHitHelpers.add_damage_for_hit(hurt_box, value / 100.0 * power())

func get_tooltip() -> String:
	return "Enemies hit by your sword take +%d%% arrow damage for %.0fs" % [value, duration]

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT

func get_tooltip_color() -> Color:
	return Color.SILVER

## A short steel slash mark on an opened enemy, fading over the window.
class SlashMark extends Node2D:
	var duration: float = 2.0

	static func show_on(enemy: Enemy, _duration: float) -> void:
		for child in enemy.get_children():
			if child is SlashMark:
				child.queue_free()
		var mark: SlashMark = SlashMark.new()
		mark.duration = _duration
		enemy.add_child(mark)

	func _ready() -> void:
		z_index = 4
		for offset in [Vector2(-3, 0), Vector2(3, 0)]:
			var line: Line2D = Line2D.new()
			line.width = 1.5
			line.default_color = Color(0.95, 0.94, 0.85)
			line.points = PackedVector2Array([Vector2(-4, -6) + offset, Vector2(4, 6) + offset])
			add_child(line)
		var tween: Tween = create_tween()
		tween.tween_interval(duration * 0.7)
		tween.tween_property(self, "modulate:a", 0.0, duration * 0.3)
		tween.tween_callback(queue_free)
