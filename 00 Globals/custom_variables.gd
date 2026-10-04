extends Node

enum stats {Strength, Agility, Stamina}

enum directions {Up, Left ,Down ,Right}

enum items{COIN,POTION, ESSENCE, WOOD, SKYSHARD}

const HP_PER_HEART: int = 4
const RIFTS_PER_TYPE: int = 2

const ENEMY_DMG_TAKEN_MULT_ID: int = 99
const ENEMY_DMG_DEALT_MULT_ID: int = 98

const CURSED_DEBUFF_ID: int = 104
const FROSTBITE_DEBUFF_ID: int = 105
const FREEZE_DEBUFF_ID: int = 106
const BURN_DEBUFF_ID: int = 107
const BLEED_DEBUFF_ID: int = 108
const POISON_DEBUFF_ID: int = 109
const STUN_DEBUFF_ID: int = 110
const ARROW_PIERCE_ID: int = 5
const PULL_SPEED_BUFF_ID: int = 77

var buff_id_counter: int = 0

var rarity_colors: Array[Color] = [
	Color(1.0, 1.0, 1.0),     # 1 - Common (white)
	Color(0.13, 0.59, 0.95),  # 2 - Rare (blue)
	Color(0.61, 0.15, 0.69),  # 3 - Epic (purple)
	Color(1.0, 0.60, 0.0),    # 4 - Legendary (orange)
]

var rarity_names: Array[String] = [
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic"
]
var MAX_RARITY: int = rarity_colors.size()

func rarity_name(rarity: float) -> String:
	if rarity > CustomVariables.MAX_RARITY:
		return rarity_names[-1]
	return rarity_names[roundi(rarity)]
	
func rarity_color(rarity: float) -> Color:
	var colors: Array[Color] = CustomVariables.rarity_colors
	if rarity > CustomVariables.MAX_RARITY:
		var overflow = clampf(rarity - CustomVariables.MAX_RARITY, 0.0, 1.0)
		return Color.ORANGE.lerp(Color(0.0, 0.90, 1.0), overflow)
	return colors[clampi(roundi(rarity), 0, colors.size())]

func get_buff_id() -> int:
	buff_id_counter += 1
	return buff_id_counter
