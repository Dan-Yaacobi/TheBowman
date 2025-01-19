class_name ThunderStrike extends CPUParticles2D

@onready var area: Area2D = $Area2D
@onready var monitoring_timer: Timer = $MonitoringTimer

@export var stun_duration: float

func _ready() -> void:
	area.body_entered.connect(thunder_hit)
	area.monitoring = true
	monitoring_timer.wait_time = lifetime
	monitoring_timer.timeout.connect(queue_free)
	monitoring_timer.start()
	
func thunder_hit(body) -> void:
	if body is Enemy and body != null:
		var stun: EnemyEffect = Stunned.new()
		stun.set_stun_duration(stun_duration)
		body.stats.debuffs.append(stun)
