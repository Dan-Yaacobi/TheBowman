class_name Boss extends Enemy

signal health_changed(current: int)

const HIT_FLASH_COLOR: Color = Color(2.5, 2.5, 2.5, 1.0)
const HIT_FLASH_DURATION: float = 0.15

var arena: BossArena
var _hit_flash_tween: Tween

func begin_fight(_arena: BossArena) -> void:
	arena = _arena
	EventBus.boss_fight_started.emit(self)
	_on_fight_began()

func _on_fight_began() -> void:
	pass

func handle_health_bar(_dmg: int = 0) -> void:
	health_changed.emit(current_hp)

## Bosses without a damaged state just flash, so every damage source (DoT included) still shows it.
func _causes_flinch(_hurt_box: HurtBox) -> bool:
	return damaged_state == null or super(_hurt_box)

## Bosses flash instead of entering a damaged state, so hits never interrupt their attack pattern.
func enter_damaged_state() -> void:
	if damaged_state:
		super()
		return
	if _hit_flash_tween:
		_hit_flash_tween.kill()
	sprite.self_modulate = HIT_FLASH_COLOR
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(sprite, "self_modulate", Color.WHITE, HIT_FLASH_DURATION)
