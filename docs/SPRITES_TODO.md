# Sprites still to do

Everything that still needs PixelLab art. Style, sizes and pipeline are in `CLAUDE.md` (Art pipeline).
Tick items off as they're approved and wired in. Ask before any batch (more than 4 images).

## Enemies (designed and working, no final art)
- [ ] **Pine tree** (snow): dormant plain-pine look, awake look with arms, pinecone projectile, swipe. Folder: `Enemies/PineTree/` (no sprites yet).
- [ ] **Snowflake swarm** (snow): single flake (orbit, wind-up, ram, shatter). Folder: `Enemies/SnowflakeSwarm/` (no sprites yet).
- [ ] **Frost golem** (snow): rock golem reskin, same animations as `Enemies/RockGolem/`.
- [ ] **Hail cloud** (snow): behaviour is final, needs new art (idle, hail, freeze-strike telegraph).
- [ ] **Magma golem** (hell): rock golem reskin, cosmetic fire.
- [ ] **Obsidian spire** (hell): jagged black crystal with lava cracks; asleep, charging glow, burst; shard projectile. Folder: `Enemies/ObsidianSpire/` (no sprites yet).
- [ ] **Imp** (hell): rush, wind-up glow, lunge, grab/hold on the archer's head. Folder: `Enemies/Imp/` (no sprites yet).
- [ ] **Flaming skull** (hell): current `Enemies/Sprites/FlamingSkull.png` is a placeholder. Needs ram (x3) and dizzy animations.

## Bosses
- [ ] **Final wizard boss**: body, two elemental portals, chaos portal.

## NPCs
- [ ] **Rogue wizard**: currently the cleric sprite tinted purple (`NPC/RogueWizard/RogueWizard.tscn`). Needs its own idle sprite (and talk animation if the cleric has one). A wizard who defied the cult; see `docs/STORY_BIBLE.md` (the defector wizard).

## Tower
- [ ] Tower tiles and hazards/traps (design still **[OPEN]** in the GDD).

## Effects
- [ ] **The Maw's bite**: jaws that gape and snap shut on the bitten enemy, styled after the Maw bow (crimson gums, bone fangs). Needs its own sprite sheet (open, snap, hold). Code: `MawBite` in `Player/Abilities2.0/ShootAbilities/Maw/maw_ability.gd`.
- [ ] **Projectile shatter**: the sword cutting an enemy projectile apart (Parry). Needs its own sprite sheet (slash flash, burst, shards). Code: `Player/Abilities2.0/MilestoneAbilities/Sword/projectile_shatter.gd`.
- [ ] (optional) **Portal pointer arrow**: the off-screen arrow to the rift exit portal, drawn in code (`Objects/Portal/portal_pointer.gd`).

## Items
- [ ] Remaining placeholder items (see `docs/FINISH_PLAN.md`).
