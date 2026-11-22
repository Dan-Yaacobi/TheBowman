class_name EncounterPool extends Resource
## Every encounter set combat rifts can roll, like Slay the Spire's act encounter lists.

@export var sets: Array[EncounterSet] = []


## A weighted set fitting this biome and act half; null if none fits.
func roll(biome: int, late: bool, rng: RandomNumberGenerator) -> EncounterSet:
	var options: Array[EncounterSet] = []
	var weights: PackedFloat32Array = PackedFloat32Array()
	for encounter: EncounterSet in sets:
		if encounter and encounter.weight > 0.0 and encounter.fits(biome, late):
			options.append(encounter)
			weights.append(encounter.weight)
	if options.is_empty():
		return null
	return options[rng.rand_weighted(weights)]
