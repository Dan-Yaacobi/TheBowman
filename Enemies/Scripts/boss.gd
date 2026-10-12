class_name Boss extends Enemy

signal health_changed(current: int)

var arena: BossArena

func begin_fight(_arena: BossArena) -> void:
	arena = _arena
	EventBus.boss_fight_started.emit(self)
	_on_fight_began()

func _on_fight_began() -> void:
	pass

func handle_health_bar(_dmg: int = 0) -> void:
	health_changed.emit(current_hp)
