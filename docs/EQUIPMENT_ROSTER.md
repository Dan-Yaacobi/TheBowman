# Equipment Roster by Color

> Design reference. Status: **[DRAFT]**, finalized after three review passes.
> Every current item still has `color = NONE` in its `.tres`. The colors given for existing items are **proposals**.

## How items are sorted

Each color's run bonus decides where an item belongs: the item goes in the color whose bonus makes it better.

| Color | Run-level bonus (`ColorLevels`) | Items that belong here |
|---|---|---|
| **Precision** | Stronger perfect shots | Pay off on perfect shots, big single hits, focus on one target |
| **Tempo** | Faster pull | Pay off on shot volume, quick or non-perfect shots, movement, the sword loop |
| **Elemental** | Stronger and longer debuffs (bleed, burn, poison damage; all debuff durations) | Built around applying or using debuffs |

## Design constraints (from review feedback)

New ideas must respect these, on top of the GDD rules:
1. **Arrows ignore terrain.** Nothing may rely on arrows bouncing off, sticking in, or hitting islands.
2. **No knock-off dependence.** All current enemies fly.
3. **There is no "fight" state.** Nothing may trigger on the start or end of a fight.
4. **Telegraph every timed or automatic proc.** An auto-perfect shot or temporary buff needs a visible cue (bow glow, pull-bar color, pips).
5. **Don't touch the dash.** Its cooldown isn't shown on screen. Dash charges and cooldown changes can return if a dash cooldown indicator is added.
6. **The sword has one swing.** No directional or downward swings.
7. **No infinite pierce.** It makes every pierce upgrade worthless. Pierce is also a dull reward for anything that should feel special.
8. **The pull bar is hidden until you start drawing.** Cues that matter before a draw go on the player or the bow.
9. **Perfect window is a dull stat** to build an item around.
10. **Enemy targeting of the player is tightly baked in.** No decoys or target swaps.
11. **No two abilities should play the same.**

Status tags: *(existing)* in the game · *new* kept from round 1 · *reworked* changed from your notes · *replacement* new idea replacing a cut one.

---

## Precision

### Bows
| Item | Ability | Status |
|---|---|---|
| Draxx | Perfect shots turn into a dragon | *(existing)* |
| Rising Feather | Perfect shots turn into a hurricane | *(existing)* |
| Soul Harvester | Collect souls from enemies, released by a perfect shot | *(existing)* |
| **Ram's Horn** | Low damage, very high knockback. An enemy you knock back becomes a projectile itself: enemies it flies into take damage and get knocked back too, like billiard balls. No stun. | reworked |
| **Longing** | One overcharge stage. After a full draw, keep holding: a second fill takes 100% as long as the first draw. Releasing after it fills fires an overcharged shot (bigger, more damage, more knockback). Slower movement while holding. The pull bar shows the second fill in a different color. | reworked |
| **Hunter's Mark** | Non-perfect hits add Mark stacks to an enemy. A perfect shot spends them all for burst damage. | new |
| **Riftbow** | A perfect hit opens a wizard portal near the enemy. The portal flashes to show what it rolled, then fires it at that enemy: a burning fireball (reuses the FireBall), a demonic fist that punches for huge knockback, or a poison cloud (reuses the poison cloud). The portal gets the hit enemy as its target, like other after-hit effects. If the enemy died from the hit, no portal opens. | reworked |

### Quivers
| Item | Ability | Status |
|---|---|---|
| Cursed Skulls | Applies Cursed: the enemy takes more damage but also deals more | *(existing)* |
| **Echo Arrows** | A perfect shot is repeated by a faint ghost arrow 0.4s later, from the spot you released it, for 50% damage. The ghost copies on-hit effects. | replacement |
| **Heartseeker** | Perfect shots deal bonus damage based on the enemy's missing health. Good for finishing tough enemies. | replacement |
| **Long Shot** | Arrows deal more damage the farther they fly before hitting, up to +X% at long range. The arrow's trail brightens as it gains damage. Rewards shooting from a safe spot far from the enemy. | replacement |

### Rings
| Item | Ability | Status |
|---|---|---|
| **Shadow Ring** | Keeps the existing shadow look, new ability: each hit you take has an X% chance to pass through you harmlessly. On a dodge, you briefly flicker into shadow. Replaces infinite pierce. | reworked |
| **Spillover Band** | When an arrow kills an enemy, the damage left over jumps to the nearest enemy as a visible bolt. | replacement |

---

## Tempo

### Bows
| Item | Ability | Status |
|---|---|---|
| Wooden Bow | Starter bow, no ability yet (Design Rule 4 says every item needs one) | *(existing)* |
| Hanzo | Arrows become shurikens. Much faster pull, reduced damage, no knockback, only perfect shots work. | *(existing)* |
| **Hummingbird** | Releasing under ~50% fires a fan of 3 small, weak arrows. A full draw fires one normal arrow. | new |
| **Skylark** | Drawing in mid-air slows your fall. A perfect air shot pushes you away from where you aimed, like a rocket jump. | new |
| **Undertow** | Perfect shots pull the enemy toward you instead of pushing it away. Pairs with the sword. | new |

### Quivers
| Item | Ability | Status |
|---|---|---|
| Basic Quiver | Starter quiver, no ability yet | *(existing)* |
| **Seeker Darts** | Non-perfect arrows home in slightly. Perfect arrows fly straight but deal more damage. | new |
| **Splitting Tips** | On the first hit, the arrow splits into 2 smaller arrows angled forward | new |
| **Sticky Charges** | Arrows stick in enemies and explode after 1s. Perfect shots make a bigger blast. | new |

### Rings
| Item | Ability | Status |
|---|---|---|
| Fire Ring | Turns you into a fireball while dashing | *(existing)* |
| **Riposte** | A sword hit makes your next arrow within 1.5s fully drawn and perfect. The bow glows while it's ready. | new |
| **Meteor Band** | Fast-falling onto the ground or an enemy sends out a knockback shockwave | new |
| **Gust Ring** | Every jump, double jump included, releases a gust that pushes nearby enemies away. A way out of a swarm that doesn't touch the dash. | replacement |
| **Quickstep** | Perfect shots give a short burst of move speed (1.5s), shown with a wind trail on the player. | replacement |

---

## Elemental

### Bows
| Item | Ability | Status |
|---|---|---|
| Hemorrhage | Fill a blood gauge. When full, a perfect shot releases a blood explosion. | *(existing)* |
| Poison Ivy | Fill a poison gauge that releases a big gas cloud. Perfect shots also poison. | *(existing)* |
| Vulcan | Magma boulder that burns | *(existing)* |
| Winter | Arrows become a frost breath (frostbite / freeze) | *(existing)* |
| Zeus | Perfect shots and stuns fill a gauge. When full, the next perfect shot chains lightning. | *(existing)* |
| FireBall Bow | Perfect shots become a burning fireball | *(existing)* |
| **Stormcaller** | Hits plant a lightning rod on the enemy (max 3 rods; a new one replaces the oldest). **1 rod:** the enemy takes small zaps over time. **2 rods:** a lightning line links them and damages anything crossing it. **3 rods:** all three are stunned, and the lightning triangle between them stuns anything inside or crossing it. Then the rods are spent. | reworked |

### Quivers
| Item | Ability | Status |
|---|---|---|
| Blood Quiver | Applies bleed on hit | *(existing)* |
| Ice Shards | Applies frostbite on hit, and freezes enemies that already have frostbite | *(existing)* |
| Poison Darts | Non-perfect shots apply poison | *(existing)* |
| Electros | Stuns enemies at full health | *(existing)* |
| **Ember Quiver** | Applies burn. A burning enemy knocked into another enemy spreads the burn. | new |

### Rings
| Item | Ability | Status |
|---|---|---|
| Electric Ring | Summons 3 orbs around you every 5s that stun enemies | *(existing)* |
| Vampiric Ring | Bleed damage has a chance to heal you | *(existing)* |
| **Thorn Ring** | Taking damage fires a ring of arrows around you that carry your quiver's debuff. | new |

---

## Totals

| | Bows | Quivers | Rings | Total |
|---|---|---|---|---|
| **Precision** | 7 | 4 | 2 | **13** |
| **Tempo** | 5 | 4 | 5 | **14** |
| **Elemental** | 7 | 5 | 3 | **15** |

---

## Minor abilities on items (not colored)

| Ability | Status |
|---|---|
| **Telegraphed shot**: every Xth arrow is automatically perfect. When the next arrow is the charged one, the bow on the player glows and sparks, visible before you draw. Once you draw, the pull bar turns gold too. | reworked |
| **Perfect streak**: after 3 perfect shots in a row, your next arrow explodes on hit (reuses the explode-on-kill explosion). Streak pips show progress. X = explosion damage. | reworked |
| Air shots: shots fired in mid-air deal +X% damage. | new |
| **Dash draw**: your first draw after a dash is X% faster. No time limit, so there's no timer to miss. Doesn't change the dash itself. | reworked |
| **Air kill lift**: a kill while airborne gives you a small upward boost. | replacement |
| **Sword opener**: enemies hit by your sword take +X% arrow damage for 2s, shown with a slash mark on the enemy. | replacement |
| Debuff knockback: enemies with a debuff take +X% knockback. | new |
| Crit the helpless: hits on stunned or frozen enemies always crit. | new |
| Pain draw: taking damage gives +X% pull speed for 3s. | new |
| Landing shot: your first shot after landing has a X% wider perfect window. | new |
| DoT extend: non-perfect hits extend DoTs already on the enemy by X seconds. | new |
| Burn spread on death: burning enemies spread burn when they die. | new |
| Shatter: frozen enemies shatter into X shards when killed. | new |
| Follow-up: enemies take +X% damage while still flying back from a knockback. | new |

## Altar milestones

### Power (every 5 levels)
| Milestone | Status |
|---|---|
| Piercing Shot: arrows pierce 1 additional enemy | *(existing)* |
| Steady Hands: each perfect shot widens the window a bit until you miss | new |
| **Clean Kill**: killing an enemy with a perfect shot makes your next arrow automatically perfect. The bow glows while it's ready. Replaces Opening Shot, which needed a "fight start" that doesn't exist. | reworked |
| Opportunist: +damage against debuffed enemies | new |
| Twin Fletch: every 10th arrow fires a second arrow | new |

### Sword (every 5 levels)
| Milestone | Status |
|---|---|
| **Parry**: your sword destroys enemy projectiles. Moves today's built-in projectile destruction out of the base sword and into this milestone. A true deflect (sending projectiles back) could be an upgrade later. | reworked |
| **Cleave Wave**: each sword swing sends out a crescent that travels about one extra sword length past the blade. Replaces Uppercut, since the sword already knocks enemies back. | replacement |
| Coated Blade: the sword applies your quiver's debuff | new |
| Reload: sword hits give a short pull-speed boost | new |

### Health (different structure)
Hearts are expensive and the track is short, so a milestone every 5 levels doesn't work. Proposal: **a milestone pick on every heart purchased** (or every 2nd, if there are many levels), from a small pool:

| Milestone | Status |
|---|---|
| Safety Net: your first fall each biome costs no heart | new |
| Cleric's Blessing: heal 1 when you exit a rift | new |
| Adrenaline: +pull speed while at 1 heart | new |
| **Second Skin**: a visible shield bubble blocks one hit, then recharges after 30s without taking damage. No longer tied to "a fight." | reworked |

### Mobility (every 5 levels)
| Milestone | Status |
|---|---|
| Double Jump (the passive already exists) | new |
| **Air Draw**: you draw 30% faster while airborne | replacement |
| **Second Dash**: one extra dash before the cooldown starts. Assumes the dash cooldown cue below gets built. | new |
| **Steady Footing**: you take 40% less knockback while airborne. | replacement |

---

## Planned additions (agreed Nov 2026, not built yet)

Bows also have a fixed **draw time** now (light 0.45s, standard 0.55s, heavy 0.8s, siege 1.2s); slower bows hit harder.

### Bows
| Item | Color | Draw | Ability |
|---|---|---|---|
| **Janus** | Tempo | 0.45s | Every shot also fires a mirrored arrow straight behind you at half damage. |
| **Hornet's Nest** | Tempo | 0.8s | A perfect release sprays 8 small arrows over 0.5s instead of one: 20% damage each, ±12° spread, no knockback, a stream of small recoil pushes. Quiver on-hit effects only trigger on the first burst arrow to hit each enemy. |
| **The Maw** | Precision | 0.55s | Devours the souls of enemies you kill. Each soul permanently adds damage **and** permanently worsens something (downside under review). Souls are stored on the bow, so unequipping and re-equipping in the same run keeps them. |

### Quivers
| Item | Color | Ability |
|---|---|---|
| **Boomerang Quiver** | Precision | Arrows return to you at the end of their flight, hitting enemies on the way back (perfect arrows at full damage, others at 50%). |
| **Chaos Quiver** | Elemental | 50% chance on hit to apply a random debuff: Bleed, Burn, Poison, Frostbite, Stun or Curse (never Freeze). Scales with Elemental like other debuff items. |
| **Ricochet Quiver** | Tempo | Every hit bounces once to the nearest other enemy at 60% damage. With no enemy nearby, it bounces off in a random direction. |
| **Vortex Quiver** | Elemental | Perfect hits open a small vortex for 1s that pulls nearby enemies together. |

### Rings
| Item | Color | Ability |
|---|---|---|
| **Hourglass Band** | Precision | 3 perfect hits in a row slow time to half speed for 1s. Cut in round 1; back for a feel test first (global time scale, key-triggered prototype). |
| **Contagion Band** | Elemental | When an enemy with an elemental debuff dies, its debuffs jump to the nearest enemy. |

### Cut in Nov 2026 rounds
Kestrel, Cliffbreaker, Skipping Stone, Linebreaker, Fault Line, Plumb Line, Windrunner, Kite Line, Gravelbite, Duelist's Loop, Void Reaper, Unbroken Band, Cleric's Vow, Wellspring, Catalyst, Tally (reworked into The Maw), Twin Moon, Hailstorm, Glass Arrows, Skyfall, Kinbinder, Fixation Quiver.

---

## Cut in round 1
Climber's Ring, Gale Ring, Hourglass, Last Ledge, Pinning Bolts, Skipping Stones, Lead Fletching, Shadow Ring's infinite pierce (ring reworked), Air kill dash, Sword refunds dash, Air Dash+, Dash Reset, Momentum, Uppercut, Opening Shot.

## Cut in round 2
Marksman's Band, Resonance (too close to Hunter's Mark), Pogo (too close to Air kill lift), Stomp, Second Wind, Shadow Ring decoy (ring reworked).

## Cut in round 3
Combo Finisher, Air Brake.

## Cut in final pass
Glide.

## Open notes
- **Starter gear:** Wooden Bow and Basic Quiver have no ability, which breaks Design Rule 4 ("Every item has an ability").
- **Possible rule conflict:** Hanzo's "only perfect shots work" may break Design Rule 1 ("Every release fires").
- **Ram's Horn and Ember Quiver** depend on enemies colliding with each other while knocked back. Check that knocked-back enemies have collision with other enemies.
- **Parry** means removing projectile destruction from the base sword.
- **Dash cooldown cue** (Second Dash depends on it). There's no action bar, so the cue lives on the archer, the way Celeste shows a spent dash with the hair color:
  1. **Sprite tint:** a part of the archer (hood, scarf, feather or quiver) changes color while the dash is spent and returns when it refills. The main, always-visible cue.
  2. **Refill flash and sound:** a quick white flash on the player and a short sound the moment a dash comes back. The cheapest place to start.
  3. **Charge pips:** with Second Dash, two small dots under the archer's feet, shown only while a dash is spent and hidden when both are full.
  Once this exists, Air Dash+ and Dash Reset (cut in round 1 for the same reason) could come back.
- **Numbers are placeholders.** Every X, duration and percentage here is a first guess for implementation. Balancing comes later, from playtesting.
