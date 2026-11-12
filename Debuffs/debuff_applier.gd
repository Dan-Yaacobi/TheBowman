class_name DebuffApplier
## One place that applies the player's debuffs with the player's debuff stats, so items, scroll
## procs and spreads all build them the same way (GDD rule 8: DoTs share one model).
## power scales DoT damage and debuff duration (an item's color level); 1.0 = plain stats.

enum Kind { BLEED, BURN, POISON, FROSTBITE, STUN, CURSE }

## The elemental ones (wizard magic). Bleed, Stun and Curse aren't elemental.
const ELEMENTAL: Array[Kind] = [Kind.BURN, Kind.POISON, Kind.FROSTBITE]

const BLEED_PATH: String = "res://Debuffs/Bleed/BleedDebuff.tscn"
const BURN_PATH: String = "res://Debuffs/Burned/BurnDebuff.tscn"
const POISON_PATH: String = "res://Debuffs/Poisoned/PoisonDebuff.tscn"
const FROSTBITE_PATH: String = "res://Debuffs/FrostBite/FrostBiteDebuff.tscn"
const STUN_PATH: String = "res://Debuffs/Stun/StunDebuff.tscn"
const CURSE_PATH: String = "res://Debuffs/Cursed/CursedDebuff.tscn"
## Same as Cursed Skulls.
const CURSE_DURATION: float = 5.0

static func id_of(kind: Kind) -> int:
	match kind:
		Kind.BLEED: return CustomVariables.BLEED_DEBUFF_ID
		Kind.BURN: return CustomVariables.BURN_DEBUFF_ID
		Kind.POISON: return CustomVariables.POISON_DEBUFF_ID
		Kind.FROSTBITE: return CustomVariables.FROSTBITE_DEBUFF_ID
		Kind.STUN: return CustomVariables.STUN_DEBUFF_ID
	return CustomVariables.CURSED_DEBUFF_ID

## Applies one debuff to target. Skips what can't apply (stun on stun-immune enemies, frostbite on
## frozen ones). Returns true if a debuff was added.
static func apply(target: Enemy, kind: Kind, power: float = 1.0) -> bool:
	if not is_instance_valid(target) or target.is_dead:
		return false
	var stats: PlayerStats = PlayerManager.player.stats
	match kind:
		Kind.BLEED:
			var bleed: BleedDebuff = load(BLEED_PATH).instantiate()
			bleed.bleed_damage = maxi(1, roundi(stats.bleed_damage.value() * power))
			target.apply_debuff(bleed, id_of(kind), stats.bleed_duration.value(), stats.dot_ticks("bleed"))
		Kind.BURN:
			var burn: BurnDebuff = load(BURN_PATH).instantiate()
			burn.set_damage(maxi(1, roundi(stats.burn_damage.value() * power)))
			target.apply_debuff(burn, id_of(kind), stats.burn_duration.value(), stats.dot_ticks("burn"))
		Kind.POISON:
			var poison: Debuff = load(POISON_PATH).instantiate()
			poison.poison_damage = maxi(1, roundi(stats.poison_damage.value() * power))
			target.apply_debuff(poison, id_of(kind), stats.poison_duration.value(), stats.dot_ticks("poison"))
		Kind.FROSTBITE:
			if target.has_debuff(CustomVariables.FREEZE_DEBUFF_ID):
				return false
			var frostbite: Debuff = load(FROSTBITE_PATH).instantiate()
			target.apply_debuff(frostbite, id_of(kind), stats.frostbite_duration.value() * power, 1)
		Kind.STUN:
			if not target.can_be_stunned():
				return false
			var stun: Debuff = load(STUN_PATH).instantiate()
			target.apply_debuff(stun, id_of(kind), stats.stun_duration.value() * power, 1)
		Kind.CURSE:
			var curse: CursedDebuff = load(CURSE_PATH).instantiate()
			curse.damage_taken_bonus *= power
			target.apply_debuff(curse, id_of(kind), CURSE_DURATION, 1)
	return true

## The kinds currently on an enemy, from the given list.
static func kinds_on(target: Enemy, kinds: Array[Kind]) -> Array[Kind]:
	var found: Array[Kind] = []
	for kind: Kind in kinds:
		if target.has_debuff(id_of(kind)):
			found.append(kind)
	return found
