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
- [ ] **Flaming skull** (hell): has `Enemies/Sprites/FlamingSkull.png` frames; confirm it's final or redo (ram, dizzy).

## Bosses
- [ ] **Final wizard boss**: body, two elemental portals, chaos portal.

## NPCs
- [ ] **Rogue wizard**: currently the cleric sprite tinted purple (`NPC/RogueWizard/RogueWizard.tscn`). Needs its own idle sprite (and talk animation if the cleric has one). A wizard who defied the cult; see `docs/STORY_BIBLE.md` (the defector wizard).

## Tower
- [ ] Tower tiles and hazards/traps (design still **[OPEN]** in the GDD).

## Effects drawn in code for now (optional sprite upgrades)
These work without art; a sprite sheet would just make them nicer.
- [ ] **The Maw's bite**: jaws that gape and snap shut on the bitten enemy, styled after the Maw bow (crimson gums, bone fangs). Now drawn in `MawBite` (`Player/Abilities2.0/ShootAbilities/Maw/maw_ability.gd`). A 4–6 frame open/snap sheet would replace `_draw()`.
- [ ] **Portal pointer arrow**: the off-screen arrow to the rift exit portal (`Objects/Portal/portal_pointer.gd`).
- [ ] **Projectile shatter**: sword cutting a projectile (Parry) (`Player/Abilities2.0/MilestoneAbilities/Sword/projectile_shatter.gd`).

## Items
- [ ] Remaining placeholder items (see `docs/FINISH_PLAN.md`).
