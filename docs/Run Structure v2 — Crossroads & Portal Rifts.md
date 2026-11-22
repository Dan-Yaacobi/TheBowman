# Run Structure v2 — Crossroads & Portal Rifts

Replaces the earlier Run Structure doc (gates at the end of main-path stretches) and the old "3 rifts per biome" World Structure. The run follows Slay the Spire's map logic, built out of portals in a shattered world. All exploration lives inside the portals the player chooses.

## Design Goal — Player Agency Over Difficulty

The player chooses how hard their run is through the world, not through menus or settings.

1. **Visible before you commit**: every portal's danger and reward type is readable before entering.
2. **Clear thresholds**: difficulty only rises when the player deliberately picks something.
3. **Reward scales with risk, and the scale is readable.**
4. **The safe route exists and is viable**: lean, not a trap.
5. **Choices use the core verbs**: harder means more fighting or more fall risk, not stat modifiers.
6. **Choose by moving**: you pick by walking into a portal. No menus.
7. **Same exam for everyone**: the biome boss doesn't change. Agency is about *when* you pay.

## Macro Structure

- **Biome = act.** 3 biomes (earth, snow, fire), each ending in its elemental wizard. Tower biome undecided.
- **Act = a chain of nodes**, roughly 5–6 per act (to tune).
- **Loop:** crossroads → pick a portal → play that node → its end leads to the next crossroads → … → wizard boss.
- There is no "in-between" stretch. The crossroads is a short decision point; all play happens inside the chosen node.

## The Crossroads

A small, calm island holding 2–3 portals, rolled from a pool under pacing rules. Not the same room every time.

**In the world:**

- The biome wizard's fracture spreads outward like cracks in glass. Where cracks meet, portals cluster. Each crossroads is a different convergence point, and the player follows the cracks back toward their source.
- The world spirit stabilizes each convergence point with an anchor stone (a piece of himself). That's why the crossroads is safe, and it gives him a place for short lines, hints, or reactions to the player's greed.
- Crossroads decay as the act goes on: more broken islands, a cracking sky, a straining anchor. This is where the rift meter is most visible.
- The wizard's tower in the background parallax grows closer each crossroads, showing distance to the boss.

## Node Types

| Portal | StS equivalent | What it is |
| --- | --- | --- |
| Combat | Normal fight | Small hand-made rift: some exploration and parkour, an encounter set rolled from a pool, a chest at the end |
| Elite | Elite | Small arena scene, almost no exploration. A mini-boss / elite fight with its own reward |
| Event | "?" | Hand-made events (challenge shrines, Golden Apple, etc.) with their own rules |
| Rest | Campfire / shop | Cleric (heal), rogue wizard (upgrade one item), pirate (gamble for an item; player picks bow, quiver or ring, once) |

**Combat rifts:**

- Hand-made layouts per biome (Hades-style), a few islands each, often built from existing chunks stitched together. Non-linear: loops and layers, not a corridor.
- Fewer rewards than today's rifts. The chest at the end is the main payout, so full-clearing every corner is never mandatory.
- Exit is at the end and stays locked until the rift's enemies are cleared. Prevents dodge-loot-leave.

**Encounters:**

- Enemies come from hand-picked encounter sets (e.g. red apples only, green + pink apples), rolled from early and late pools per biome, like Slay the Spire's act encounter lists.
- Each layout has spawn markers placed on purpose. On entry the rift rolls an encounter set and spawns it in waves from those markers. Finite fight; the exit unlocks when it's cleared.
- This replaces the current per-chunk roll-on-entry spawner for combat rifts.
- Variety = encounter set × island layout. The same enemies play differently on tight islands than on wide ones, because falling is the threat.

**Layout principles:**

1. Start from the fight: decide what the rift tests, then shape the islands for it.
2. Gap width and island size are the difficulty dial.
3. Give a safe home island and exposed perches with better angles.
4. Loops, not branches: two routes between areas.
5. Enter at a vantage point that shows most of the layout.
6. One idea per rift.

**Layout ideas:** tall tower, stepping stones, two big islands over a void, the Bridge, the Ring, the Staircase, the Funnel, the Archipelago, the Fortress, the Crown, the Split, the Shrinking Island, the Drift.

**Elite nodes:**

- Short, focused fight. The exit stays locked until the elite dies.
- Reward: two pedestals. **New gear** (higher rarity), or an **enchant orb** that adds one modifier to an equipped item. The player picks which item; each slot shows its rolled modifier before committing.
- Enchants are capped (1–2 extra modifiers per item) and lost when the item is swapped.

**Event and rest nodes** keep their existing rules (shrines can be declined; elite events force the kill).

## Pacing & Gate Rules

Portals are rolled from a pool, but the generator follows rules like StS's map:

- Gates have 2 or 3 portals. Sometimes all three are the same type, including **forced combat gates**. The game is about combat, and sometimes the player must fight.
- Event and rest nodes can't be chained forever; the act guarantees enough combat.
- Candidate rules (to tune): first crossroads of the first biome is calm; a rest portal appears before the boss; at most one elite per gate; occasional hidden "?" portal.

**Telegraphing:** danger = portal color + particle intensity / size (never color alone). Reward type = icon above the portal.

## The Rift Meter — The World as a Character

- **Rises** when picking dangerous portals; **lowers** at rest portals.
- **Effects:** raises enemy pressure in combat rifts, and improves their rewards, so a high meter is a choice, not just punishment.
- **Resets per biome** when the wizard dies; the sky clears.
- Shown in the world first (crossroads decay, sky cracks), with HUD pips as backup. Every level must be noticeable.

## Lookahead

No full map. Choices are tactical, like Hades' doors.

- **Always shown:** how many nodes remain before the boss (tower in the parallax, plus pause-menu backup).
- **Learned:** predictable gate rules let players plan greed.
- **Unlockable:** deeper lookahead (e.g. seeing the next crossroads' portals) as a hub construction or rare reward.

## Healing & Economy

- Healing is scarce: cleric, every 3rd scroll (+1 heart container and heal), rare vampire builds. No potions.
- Most reward value comes from the node type; loot inside combat rifts is a bonus.

## Known Risks

- **Combat has to carry it.** Most nodes are fights. The structure amplifies good combat; it can't fix weak combat.
- **Full-clear tedium.** If combat rifts hide too much optional loot, players feel obliged to search everything. Keep rifts small and rewards concentrated at the end.
- **Elite vs combat must feel different**, not just harder numbers.
- **Content load.** Every node needs content; hand-made combat layouts with rolled encounter sets carry the bulk.
- **Learning curve.** Introduce signals gradually: plain portals first, then elites and events, then the meter.

## Build Order

1. **Systems:** crossroads scene, portal pool and gate rules, node transitions, combat rift setup (spawn markers, encounter sets, wave spawning), exit locks, elite reward pedestals, meter as plain HUD pips.
2. **Greybox playtest** with existing content and placeholder colors.
3. **Content:** more events, elites, combat rift layouts.
4. **Tune pacing and balance.**

**First test:** hand-make 5 rough combat layouts, as different as possible (e.g. the Bridge, the Crown, the Archipelago, the Split, one big-island fight). Not balanced, just enough to feel the whole loop and learn which layout types suit the combat.

## Open Questions (after the system works)

**Structure & pacing**

- Nodes per act: 5? 6?
- Exact gate composition rules and how often forced or same-type gates appear.
- Combat rift size: small enough to stay snappy, big enough for parkour and exploration.
- Tower biome structure.
- Is distance-to-boss plus learned rules enough without a map?

**Meter**

- What each level does to spawns and rewards.
- How much each portal type raises it and rest lowers it.
- Exact visual: sky crack, storm, or eye.

**Rewards & economy**

- Reward scaling per portal danger.
- Scroll frequency vs. heart-every-3rd-scroll: does healing stay scarce?
- Enchant modifier pool depth and socket cap.
- Where schematics and lore artifacts spawn now that rifts are nodes.
- Boss transition: what does the post-wizard reward look like?

**Content**

- How many events and elites before runs feel repetitive?
- Telegraph difference between lock-in and back-out-able portals.

**Playtest signals**

- Do players improve across a session (longer runs, more perfect shots)?
- Do they blame themselves or the game on death?
- Do they start another run unprompted?
- Do they pick the dangerous portals when the reward is clearly worth it?
