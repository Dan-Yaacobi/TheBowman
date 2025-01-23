class_name EnemyDeath extends EnemyAbility

const DEATH_PARTICLES = preload("res://Enemies/EnemyAbilities/DeathAbility/DeathParticles.tscn")

func activate_ability(_enemy) -> void:
	var death_particles: CPUParticles2D = DEATH_PARTICLES.instantiate()
	death_particles.global_position = _enemy.global_position
	death_particles.emitting = true
	_enemy.get_parent().add_child(death_particles)
