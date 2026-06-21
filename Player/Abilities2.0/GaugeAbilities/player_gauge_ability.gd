class_name PlayerGaugeAbility extends PlayerPassiveAbility

var max_gauge: int
var gauge_texture: Texture
var gauge_tint: Color

func on_equipped() -> void:
	connect_gauge()
	EventBus.setup_gauge.emit(max_gauge, gauge_texture, gauge_tint)

func on_unequipped() -> void:
	EventBus.disable_gauge.emit()
	disconnect_gauge()

func fill_gauge(_amount: float = 1.0) -> void:
	EventBus.fill_gauge.emit(_amount)

func connect_gauge() -> void:
	pass

func disconnect_gauge() -> void:
	pass
	
func set_gauge_color() -> void:
	pass

func set_gauge_sprite() -> void:
	pass
