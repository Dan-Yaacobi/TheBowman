class_name ThunderStrike extends CPUParticles2D

@onready var area: Area2D = $Area2D
@onready var monitoring_timer: Timer = $MonitoringTimer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var stun_duration: float

func _ready() -> void:
	area.body_entered.connect(thunder_hit)
	area.monitoring = true
	monitoring_timer.wait_time = lifetime
	monitoring_timer.timeout.connect(stop_monitoring)
	monitoring_timer.start()
	audio_stream_player_2d.play()
	audio_stream_player_2d.finished.connect(queue_free)
func thunder_hit(body) -> void:
	if body is Enemy and body != null:
		var stun: EnemyEffect = Stunned.new()
		stun.set_stun_duration(stun_duration)
		body.stats.debuffs.append(stun)

func stop_monitoring() -> void:
	area.monitoring = false
