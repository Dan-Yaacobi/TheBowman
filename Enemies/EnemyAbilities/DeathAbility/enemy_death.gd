class_name EnemyDeath extends EnemyAbility

const DEATH_PARTICLES = preload("res://Enemies/EnemyAbilities/DeathAbility/DeathParticles.tscn")
@export var death_sound: AudioStream

func activate_ability(_enemy) -> void:
	var death_particles: CPUParticles2D = DEATH_PARTICLES.instantiate()
	death_particles.global_position = _enemy.global_position
	EventBus.summon_effect.emit(death_particles)
	if death_sound:
		EventBus.enemy_died_sound.emit(death_sound)
