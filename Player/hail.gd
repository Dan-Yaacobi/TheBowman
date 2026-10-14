extends CPUParticles2D

func _process(_delta: float) -> void:
	if get_rift_type() == Rift.Type.SNOW:
		emitting = true
	else:
		emitting = false
		
func get_rift_type() -> Rift.Type:
	var lvl: int = PlayerManager.player.stats.rift_level
	if lvl < 1 or CustomVariables.RIFTS_PER_TYPE <= 0:
		return Rift.Type.DIRT

	@warning_ignore("integer_division")
	var index: int = (lvl - 1) / CustomVariables.RIFTS_PER_TYPE
	
	if index >= Rift.Type.size():
		return Rift.Type.DIRT
	return index as Rift.Type
