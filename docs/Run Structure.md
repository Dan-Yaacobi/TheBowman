# Run Structure — Acts, Gates & The Rift Meter

Replaces the "rifts" structure in the World Structure section of the main Game design doc. Rifts become **sections** inside a biome; a biome becomes an **act** (Slay the Spire style).

---

## Design Goal — Player Agency Over Difficulty

The player chooses how hard their run is, through the world, not through menus or settings.

**Guidelines:**
1. **Visible before you commit** — every risk and reward is readable before engaging.
2. **Clear thresholds** — difficulty only rises when the player deliberately crosses something (a portal, a jump). Never silently behind their back.
3. **Reward scales with risk, and the scale is readable.**
4. **The safe route always exists and is viable** — lean, not a trap.
5. **Choices use the core verbs** — harder means more fall risk or more fighting, not stat modifiers.
6. **Choose by moving** — no menus; you pick by walking into it.
7. **Same exam for everyone** — the boss doesn't change. Agency is *when* you pay: easy now = weaker at the boss, risk now = stronger later.

---

## Structure

- **Biome = act.** One continuous journey per biome. The old "3 rifts per biome" model is gone; no rift-to-rift transitions inside a biome.
- **Act = sequence of sections.** Biome length is controlled by the number of sections.
- **Section = short main-path stretch + gate.**
  - Main path: combat, breakable objects, small nooks with minor loot. The tension of fighting on islands lives here.
  - Ends in a **gate**: a choice of portals (usually 3). Picking one is the only way forward.
- **Last section → biome boss.** Killing the boss resets the rift meter and the sky clears.
- 3 biomes (earth, ice, fire) + the tower biome (undecided).

---

## Portals — Node Types (StS mapping)

| Portal | StS equivalent | Content |
|---|---|---|
| Combat | Normal fight | Generated mini-rift (few chunks), enemies, reward at the end |
| Elite | Elite | Harder side scene / elite event, better reward |
| Event | "?" node | Hand-made events (challenge shrine, golden apple, etc.) |
| Rest site | Campfire / shop | Cleric (heal), wizard (pay to upgrade one equipped item), pirate (gamble for an item; player picks bow, quiver or ring — once) |

**Side scene rules:**
- Entering a portal commits you to the scene.
- Combat/elite side scenes: the exit is at the end, and it stays **locked until all enemies are dead**. Side scenes use a finite enemy set, not the continuous spawner. (This replaces the "can't open chests near enemies" rule — exit lock handles the dodge-loot-leave exploit at the source.)
- Events keep their own rules: shrine events can be declined and exited immediately; elite events force the kill.
- Commit level should be telegraphed (portals that lock you in look different from ones you can back out of).
- The main path is frozen while you're in a side scene and unfreezes exactly as you left it on return. Entering a portal mid-fight is allowed — a deliberate agency moment (risk the portal, come back stronger for the fight waiting outside).

**Telegraphing:**
- Danger = portal color + particle intensity / size (never color alone).
- Reward = icon above the portal.
- Harder portals can also be harder to reach: guarded by visible enemies, behind difficult jumps.

**Gate variety** (to avoid a metronome rhythm): usually 3 portals; sometimes 2; occasionally 1 (forced); sometimes all high-danger with different rewards; rare hidden "?" portal.

---

## Lookahead — No Map

Unlike StS, there is no map showing the whole act. Choices are tactical (what do I need now) rather than strategic route planning — closer to Hades' reward doors, which work without a map. Concern noted: the system may feel weaker without route planning.

Mitigations:
- **Show distance, not content.** The player knows how many sections remain before the boss. Diegetic option: the boss's tower / lair in the background parallax grows closer each section. Backup: "section 3/5" in the pause menu.
- **Predictable gate rules the player learns** (e.g. a rest site always appears before the boss), so players can plan greed around them.
- **Optional lookahead as a reward** — a rare event, ring, or meta milestone that reveals the next gate.

---

## The Rift Meter — The World as a Character

The rift reacts to the player's greed. Unique mechanic; ties into the fractured-world narrative and the portal-themed final wizard.

- **Rises** when picking dangerous portals (higher danger = bigger rise).
- **Lowers** at rest-site portals (resting = trading greed for safety).
- **Effects:** raises main-path spawn intensity / pressure (maybe elite chance), **and** improves main-path rewards — so a high meter is a choice, not just punishment.
- **Resets per biome** at the boss. Narrative: the biome's wizard holds the fracture open; killing him calms the sky.
- **Displayed in the world first:** sky reacts — a growing crack in the background parallax / darkening clouds / storm, or a giant eye slowly opening ("the rift is watching you"). Rumble + short shake when it rises on exiting a side scene.
- **HUD backup:** small icon with pips (e.g. 0–5) so the exact level is always clear.
- Each pip must be **perceptible** — if a level change can't be felt, the character becomes a number.

---

## Healing & Economy Context

- Healing is scarce: cleric, every 3rd scroll (+1 heart container and heal), rare vampire builds. No potions.
- Scarce healing makes attrition a real cost of greed.
- Scrolls (color scaling) are guaranteed a minimum per run; extras come from portals.

---

## Learning Curve & Onboarding

The system has many signals (portal colors, gate types, meter, sky). Introduce them gradually:
- First gate(s) of the first biome: calm portals only.
- Introduce elite / event portals next, then the meter.
- World spirit can explain mechanics once in the hub.

Calm route doubles as a learning route: players can learn the combat without being punished for it.

---

## Build Order

1. **Build the systems** — sections, gates, portal types, side-scene exit lock, freeze/unfreeze, meter (plain HUD pips first). Write gate rules as generator constraints during this step.
2. **Greybox playtest** with existing content (placeholder colors, no sky art). Validate the structure before investing in content.
3. **Add content** — more side scenes / events / elites. Generated mini-rifts carry the bulk; hand-made events mixed in.
4. **Tune pacing and balance** (questions below).

---

## Open Questions (for after the system works)

**Structure & pacing**
- How many sections per biome?
- Gate composition rules, e.g.: first gate all calm? Rest site guaranteed before the boss? Max one elite per gate? How often 2-portal / forced / all-red / hidden-"?" gates appear?
- Main-path stretch length per section — short enough not to be a corridor, long enough to carry combat.
- What is the tower biome's structure?
- Does the lack of a map hurt? Is distance-to-boss + learned gate rules enough, or is some lookahead needed by default?

**Meter**
- What does each meter level do to spawns (intensity, pressure, elite chance)?
- How much does each portal danger level raise it? How much does a rest site lower it?
- How do main-path rewards scale with the meter?
- Does lingering on the main path raise it over time? (Prevents camping, but pulls against exploring nooks.)
- Exact sky visual: crack, storm, or eye?

**Rewards & economy**
- Reward scaling per portal danger level.
- Scroll guarantee — verify the current amount (2 per run?) and whether it's enough of a floor for players who always pick calm.
- Is healing scarce enough that greed carries real cost, or too scarce?

**Content**
- How many distinct side scenes / events are needed before runs feel repetitive?
- Portal commit-level telegraph — exact visual difference between lock-in and back-out-able portals.

**Playtest signals** (since the core loop can't be judged from the inside)
- Do players improve across a session (longer runs, more perfect shots)? → learning curve, good.
- Who do they blame on death — themselves ("mistimed that") or the game ("cheap")?
- Do they start another run without being asked?
- Do they mention perfect shots unprompted?
- Do they avoid optional fights even when the reward is clearly worth it? → combat issue, not structure.
