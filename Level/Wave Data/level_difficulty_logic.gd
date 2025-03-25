class_name LevelDifficultyLogic extends Resource

@export var max_level: int = 40
@export var max_level_birds: int = 28
@export var spawn_gap: int = 10

func calculate_logic_targets(x: int, array_size: int) -> Array[int]:
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
		enemies_spawn_chance[first_index] -= spawn_gap
		enemies_spawn_chance[first_index + 1] += spawn_gap
	print("## TARGETS ##")
	print(enemies_spawn_chance)
	return enemies_spawn_chance
	
func calculate_logic_birds(x: int, array_size: int) -> Array[int]:
	if x > max_level_birds:
		x = max_level_birds
	var enemies_spawn_chance: Array[int]
	for i in array_size:
		enemies_spawn_chance.append(0)
		if i == x/7 - 1:
			enemies_spawn_chance[i] = 100
	print("## BIRDS ##")
	print(enemies_spawn_chance)
	return enemies_spawn_chance
	
func find_first_index(array: Array[int]) -> int:
	for i in array.size():
		if array[i] != 0:
			return i
	return 0
