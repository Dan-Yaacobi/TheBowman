class_name LevelDifficultyLogic extends Resource

@export var max_level: int = 81
func calculate_logic(x: int, array_size: int) -> Array[int]:
	if x > max_level:
		x = max_level
		
	var enemies_spawn_chance: Array[int]
	
	for i in array_size:
		if i == 0:
			enemies_spawn_chance.append(100)
		else:
			enemies_spawn_chance.append(0)
	
	for i in x - 1:

		var first_index: int = find_first_index(enemies_spawn_chance)
		enemies_spawn_chance[first_index] -= 5
		enemies_spawn_chance[first_index + 1] += 5
		pass
	return enemies_spawn_chance

func find_first_index(array: Array[int]) -> int:
	for i in array.size():
		if array[i] != 0:
			return i
	return 0
