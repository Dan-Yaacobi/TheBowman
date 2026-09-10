extends Node

enum stats {Strength, Agility, Stamina}

enum directions {Up, Left ,Down ,Right}

const ENEMY_DMG_TAKEN_MULT_ID: int = 99
const ENEMY_DMG_DEALT_MULT_ID: int = 98

const FROSTBITE_DEBUFF_ID: int = 105
const FREEZE_DEBUFF_ID: int = 106
const BURN_DEBUFF_ID: int = 107
const BLEED_DEBUFF_ID: int = 108
const POISON_DEBUFF_ID: int = 109
const STUN_DEBUFF_ID: int = 110


var rarity_colors: Array[Color] = [
	#Color(0.62, 0.62, 0.62),  # 1 - Common (gray)
	Color(1.0, 1.0, 1.0),     # 2 - Uncommon (white)
	Color(0.30, 0.69, 0.31),  # 3 - Rare (green)
	Color(0.13, 0.59, 0.95),  # 4 - Epic (blue)
	Color(0.61, 0.15, 0.69),  # 5 - Legendary (purple)
	Color(0.96, 0.26, 0.21),  # 6 - Mythic (red)
	Color(1.0, 0.60, 0.0),    # 7 - Ancient (orange)
	Color(1.0, 0.84, 0.0),    # 8 - Gold
	#Color(0.0, 0.90, 1.0),    # 9 - Prismatic (electric cyan)
	#Color(1.0, 1.0, 1.0),     # 10 - Celestial (placeholder — animate this one)
]

var MAX_RARITY: int = rarity_colors.size()

func rarity_color(rarity: float) -> Color:
	var colors: Array[Color] = CustomVariables.rarity_colors

	if rarity > CustomVariables.MAX_RARITY:
		var overflow = clampf(rarity - CustomVariables.MAX_RARITY, 0.0, 1.0)
		return Color.ORANGE.lerp(Color(0.0, 0.90, 1.0), overflow)

	return colors[clampi(roundi(rarity) - 1, 0, colors.size() - 1)]
