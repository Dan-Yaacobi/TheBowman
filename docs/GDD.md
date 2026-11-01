# Sky Archer — Game Design Document

> Working title. Name leaning: **Please Don't Fall**.
> Status: living document. Sections marked **[DRAFT]** need Dan's confirmation. **[OPEN]** means undecided.

## How to use this document

This document describes **what the game is trying to be and why**: the intended experience, the rules every system must respect, and the reasoning behind decisions. It is not a task list (tasks live in GitHub Projects) and not a code reference.

**For agents working on the codebase:**
- Read the Pillars and Design Rules before designing or implementing any feature. If a request conflicts with them, flag it before writing code.
- When the code and this document disagree, ask. Don't silently "fix" either one.
- Items marked **[OPEN]** are undecided. Don't build assumptions about them into code.
- Exported values are first-guess placeholders. Tuning is decided by playtesting, not by this document.

---

## 1. Vision

### Pitch [DRAFT]
A fast bow roguelite on floating sky islands, where every shot is a timing test and every hit, given or taken, could send someone off the edge.

### The experience we want
- **Drawing the bow feels like a decision.** Do I snap a quick shot now, or hold for the perfect release while something closes in?
- **The edge is always present.** You're never just fighting an enemy. You're fighting an enemy *on a small island*. Knocking an enemy off feels great. Getting knocked off feels like your own mistake, not the game's.
- **Moving is a pleasure.** Getting from island to island should feel good even with no enemies around.
- **Each run has a personality.** The bow you found changes how you play, not just how hard you hit.
- **Coming back is rewarded.** A failed run still moves you forward through the hub.

### Reference points
- **Dead Cells:** tempo, gear-driven builds, meta progression that unlocks and strengthens without replacing skill.
- **Celeste:** movement feel; tight, readable, fair.
- **Slay the Spire:** meaningful picks between a small number of strong options.

---

## 2. Design Pillars

Each pillar includes what it means in practice. When two ideas compete, the one that serves more pillars wins.

### 1. The pull is the game
The bow draw is the core verb. Every system should give the player a reason to care *how* they released.
- Every release fires. There's a power floor (~0.4) so no shot ever feels like nothing.
- Partial charges scale meaningfully. The perfect release is the clear skill reward (~1.7× damage, speed, knockback).
- Effects can key off **perfect** or **non-perfect** shots. This is deliberate: gear pairings should reflect how the player actually shoots.

### 2. The edge is the enemy
Falling is the central threat and the central opportunity.
- Enemies try to knock the player off islands. The player knocks enemies away (and, with ground enemies, off).
- Falling costs a heart container for the rest of the run and respawns you on the last safe island. It never ends the run on its own.
- Every combat situation should create tension between *a good position to shoot from* and *a safe position to stand in*.

### 3. Movement is combat
Movement is a first-class system, not travel between fights.
- Snappy ground, committed air, variable jump, fast fall.
- Abilities and upgrades are allowed (encouraged) to live on the movement axis.

### 4. Gear is identity, not numbers
- Every item has a fixed, recognizable ability. Rolled stats sit on top as seasoning.
- Prefer memorable and identity-driven over balanced and forgettable.
- Acquisition is sparse and meaningful. Few items, each one a real event.

### 5. Fast, never administrative
- Dead Cells tempo. Menus are short, choices are quick, the player is back in motion fast.
- No systems that ask the player to manage, sort, or min-max between fights.

---

## 3. Core Loops

### Moment to moment (seconds)
Read threats → reposition → draw → release at the right moment. When something gets too close: sword swing for knockback → back to drawing. Dash to escape or reposition. Constantly aware of the edge.

### Run (one attempt)
Start in the hub → enter a rift → traverse islands, fight, find chests and an event portal → reach the exit portal → next rift.
- **3 rifts per biome**, boss at the end of each biome. **[DRAFT]**
- **5 bosses** total; the 5th is the final wizard boss. Killing it wins the run. (~15 rifts) **[DRAFT]**
- Bosses are drawn from a pool. The same boss never appears twice in one run.

### Meta (across runs)
Resources collected during runs are kept, even on death → spent in the hub on buildings, stat upgrades and crafting → future runs start stronger and with more options.
- Meta power is deliberately **smaller than what gear does**. Gear defines the run; meta smooths the floor.

---

## 4. Design Rules

Hard constraints. Every new feature must respect these unless the rule itself is changed here first.

1. **Every release fires.** No hard gate on the draw.
2. **Falling never ends a run by itself.** It costs a heart container. (Exception: challenge shrines, where a fall is an instant fail of *that challenge only*.)
3. **Every gauge fills through combat interaction** (hits, kills, damage taken, debuffs applied), never through something the player can do alone.
4. **Every item has an ability.** No stat-only items.
5. **Enemies drop essence, not gear.** Equipment comes from chests, NPCs, events and bosses.
6. **One event per rift**, entered through a portal into its own contained scene.
7. **No refunds, no loadouts.** Meta choices are permanent and always active. The game is about enjoying what you got, not min-maxing.
8. **DoTs (bleed, burn, poison) share one model.** Same tick, damage and duration rules. They differ in flavour and source, not mechanics. Modifiers are unified ("increase DoT damage"), not per element.
9. **Paying for something important is deliberate.** Hub purchases are mouse-click only; the interact key never spends.

---

## 5. Definition of Finished [DRAFT]

The goal is a game that is **finished enough**: a complete, winnable loop with enough content to be worth replaying. Not every idea, not every gap filled. Anything not on this list is post-finish.

**The game is finished when:**
- **A full run is winnable.** ~15 rifts across biomes (3 per biome), a boss at the end of each biome, and killing the final wizard boss wins.
- **Bosses:** 5 total, drawn from a pool, the 5th being the final wizard.
- **Hub:** 3 buildings working end to end: the upgrade altar (with its milestone abilities), the quest board, and the blacksmith (recipes → craft starting gear for the next run). Unlocked through schematics handed to the guide.
- **Equipment:** a pool somewhat bigger than today's, enough that runs feel different.
- **Enemies:** a few more than today, enough that each biome has its own roster.
- **Events:** at least the ones already spawning, each giving real choices and rewards.
- **Story:** delivered in fragments, with an ending at the final boss. Gaps are fine.
- **One consistent UI look** across all menus.

**Not required to be finished:** challenge mode after winning, online saves, every biome on the planned list, every bow idea, full answers to the story's open questions.

**Rule for agents:** if a task isn't on the "finished" list and isn't a fix to something on it, ask before building it.

---

## 6. Known Problems [DRAFT]

What the game currently fails at, so new work can aim at it.

- **Rifts are mostly traversal.** Between fights there's little to do or decide.
- **No in-run engine beyond items.** Runs don't build momentum the way a Dead Cells or StS run does. A choose-3 from chests, events and rift completion is planned, at a set pacing rather than after every fight.
- **Fall danger depends heavily on traversal skill.** Weaker players fall constantly; a strong player almost never does. The edge threat needs to stay relevant for good players without crushing new ones.
- **The game is hard to describe in one sentence.** See Pitch.

---

## 7. Setting and Story

The full backstory lives in the **Story Bible** (`STORY_BIBLE.md`). This section only covers what the story means for design. The story is delivered in fragments across the rifts, never as one telling.

### Premise
You are the last archer, in a world shattered into floating islands by a collision of portals. You're trying to reach the evil wizard in his tower, leader of the Cult of the Wicked, to force him to repair the world. The rupture took part of your memory. Over the game you discover that you once sided with him, and at the end, that he was your childhood best friend.

### Story in the mechanics
Every core mechanic has a fictional reason. New mechanics should fit this table or extend it.

| Mechanic | In the fiction |
|---|---|
| Falling into the void | There is nothing below. The void spits you back into the world and damages you (= lose a heart container, respawn). |
| Dying | You're too weak to resist the void and are sent back to the safe haven (the hub). |
| Items reset on death | You become too weak to hold them. (Low priority to surface.) |
| Bows and quivers | Magical items the wizards made for the archers, later confiscated, now lost across the world. |
| Rings | Magical rings forged by the wizards, lost across the world. |
| Elements | All elemental magic comes from wizards. |
| Rifts and portals | The world has been divided by portals since the rupture. |
| Enemies | Survivors (e.g. birds), mutated creatures (e.g. winged apples), and arrivals from other dimensions. Some are hostile, some helpful. |
| Bosses | Wizards of the cult, one per element. |
| Hub guide | The spirit of the world, released by the rupture. Wants the world repaired; doesn't know your past. |
| Merchant | Sky pirates trading found artifacts for gold. |
| Healer | Surviving clerics. |

### Lore rules
Constraints for anyone adding content (items, enemies, NPCs, text):
1. **All elemental effects trace back to wizards.** An elemental item is a wizard-made artifact.
2. **Equipment is found, never made by enemies.** It's lost artifacts. This matches Design Rule 5 (enemies drop essence, not gear).
3. **Story is revealed in fragments.** No exposition dumps, no long cutscenes.
4. **The player doesn't know their own past.** Text must never reveal the two secrets early: siding with the wizard surfaces through accusers; the friendship only at the end.
5. **The spirit of the world is an essence, not a person.** It doesn't know your past and only learns what you did late in the story.

### Known gaps [OPEN]
Gaps are acceptable. The story doesn't need to explain everything for the game to be finished. Agents should not invent answers to these; leave them unexplained in content.
- Why enemies die from falling and the player doesn't (earlier idea: the world's soul blessing).
- Why meta progression persists across deaths, and what Skyshard is.
- Non-wizard bosses (giant apple, giant bird) alongside "bosses are wizards."
- Wizards in rifts summoning enemies through portals: under consideration.
- Story open questions (the ending, why you survived, the gods) are tracked in the Story Bible.

---

## 8. Sections still to write

- Player: controls, movement values, health, sword, dash
- Combat: damage model, knockback, debuffs and DoTs
- Equipment: slots, bows, quivers, rings, rarity, minor abilities, element identities
- Enemies: roles, roster per biome, ground vs. flying, elites
- Bosses and arenas
- World: rift generation, biomes, chunks, side paths
- Events: framework, challenge shrine, Golden Apple, others
- Hub and meta progression: buildings, guide NPC, schematics, upgrade altar tracks and milestones, blacksmith, quest board
- Economy: wood, essence, gold, Skyshard; sources and sinks
- Art and audio direction
- Open questions
