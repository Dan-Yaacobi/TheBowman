class_name ThunderStrike extends CPUParticles2D

@onready var area: Area2D = $Area2D
@onready var monitoring_timer: Timer = $MonitoringTimer

@export var stun_duration: float

const STUN_DEBUFF = preload("uid://c1gcykybdcokh")

func _ready() -> void:
	area.body_entered.connect(thunder_hit)
	area.monitoring = true
	monitoring_timer.wait_time = lifetime
	monitoring_timer.timeout.connect(stop_monitoring)
	monitoring_timer.start()

func thunder_hit(body) -> void:
	if body is Enemy:
		var stun: StunDebuff = STUN_DEBUFF.instantiate()
		body.apply_debuff(stun,stun_duration,1)

func stop_monitoring() -> void:
	area.monitoring = false
