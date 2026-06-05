extends Node

enum stats {Strength, Agility, Stamina}

enum directions {Up, Left ,Down ,Right}



var rarity_colors: Array[Color] = [
	Color.WHITE,
	Color.GREEN,
	Color.CYAN,
	Color.PURPLE,
	Color.ORANGE]

var MAX_RARITY: int = rarity_colors.size()

func rarity_color(rarity: float) -> Color:
	var colors: Array[Color] = CustomVariables.rarity_colors

	if rarity > CustomVariables.MAX_RARITY:
		var overflow = clampf(rarity - CustomVariables.MAX_RARITY, 0.0, 1.0)
		return Color.ORANGE.lerp(Color(1.0, 0.84, 0.0), overflow)

	return colors[clampi(roundi(rarity) - 1, 0, colors.size() - 1)]
