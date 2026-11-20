# Sprites still to do

Everything that still needs PixelLab art. Style, sizes and pipeline are in `CLAUDE.md` (Art pipeline).
Tick items off as they're approved and wired in. Ask before any batch (more than 4 images).

## Enemies (designed and working, no final art)
- [x] **Pine tree** (snow): `Enemies/PineTree/Sprites/PineTree.png` (11x5, 64px: dormant hat-down, wake, idle, throw, swipe). Pinecone projectile: `Enemies/PineTree/Sprites/PineCone.png` (10x14, hand-pixeled from the throw-frame cone palette; Sprite2D scale 2.5 to cancel the bullet root's 0.3).
- [x] **Snowflake swarm** (snow): `Enemies/SnowflakeSwarm/Sprites/Snowflake.png` (9x3, 32px: spin = candidate #25 rotated locally + edge-cleaned, windup, shatter). Windup is stretched to `windup_time`; shatter plays on self-shatter and on kill, then frees.
- [x] **Frost golem** (snow): `Enemies/RockGolem/Sprites/FrostGolem.png` (local palette remap of RockGolem.png: moss → snow caps, vines → ice veins, eyes → ice cyan; same 13x5 layout). Data: `EnemyValues/FrostGolem/FrostGolem.tres` (RockGolem stats). Spawns via `frost_golem_entry.tres` (Snow, from biome rift 2, cost 3, weight 8; in `Rift.tscn` enemy_pool).
- [x] **Hail cloud** (snow): `Enemies/Cloud/Sprites/HailCloud.png` (6x3, 48px: idle = local 2px float with lagging icicles, hail shudder, freeze telegraph that holds its last frame through the strike). Also the `skin` in `regular_cloud.tres`.
- [x] **Magma golem** (hell): `Enemies/RockGolem/Sprites/MagmaGolem.png` (same local remap: basalt body, moss → molten lava, vines → deep-red cracks, eyes → fiery yellow). Data: `EnemyValues/MagmaGolem/MagmaGolem.tres` (RockGolem stats). Spawns via `magma_golem_entry.tres` (Hell, from biome rift 2, cost 3, weight 8). Cosmetic fire (flicker/particles) still to do.
- [x] **Obsidian spire** (hell): `Enemies/ObsidianSpire/Sprites/ObsidianSpire.png` (8x1, 64px lava pulse; Dormant holds dim frame 7, Idle ping-pongs). Charge glow stays in code. Shard projectile: `Enemies/ObsidianSpire/Sprites/ObsidianShard.png` (18x7, hand-pixeled, points right; Sprite2D scale 2.5, purple modulate removed).
- [x] **Imp** (hell): `Enemies/Imp/Sprites/Imp.png` (8x2, 48px: hover, lunge). Lunge holds its last frame through the grab; wind-up glow stays in code.
- [x] **Flaming skull** (hell): `Enemies/Sprites/FlamingSkull.png` (8x3, 48px: move, ram, dizzy). Dizzy plays via `apple_ram_state.gd`'s `Dizzy` animation.

## Bosses
- [ ] **Final wizard boss**: body, two elemental portals, chaos portal.

## NPCs
- [x] **Rogue wizard**: `NPC/RogueWizard/Sprites/RogueWizard.png` (cleric 15x3 layout: idle, interacted, action/reforge). Edited from the cult wizard reference, hood down.

## Tower
- [ ] Tower tiles and hazards/traps (design still **[OPEN]** in the GDD).

## Effects
- [x] **The Maw's bite**: `Player/Abilities2.0/ShootAbilities/Maw/Sprites/MawBite.png` (PixelLab effect 'Maw Bite'). Code: `MawBite` in `Player/Abilities2.0/ShootAbilities/Maw/maw_ability.gd`.
- [x] **Projectile shatter**: `Player/Abilities2.0/MilestoneAbilities/Sword/Sprites/ProjectileShatter.png` (PixelLab effect 'Projectile Shatter'). Code: `Player/Abilities2.0/MilestoneAbilities/Sword/projectile_shatter.gd`.
- [ ] (optional) **Portal pointer arrow**: the off-screen arrow to the rift exit portal, drawn in code (`Objects/Portal/portal_pointer.gd`).

## Items
- [x] Remaining placeholder items: the Nov 2026 bows that borrowed other bows' sprites. `Items/Equipments/Bows/Sprites/` Janus.png (double-faced crowned mask), HornetsNest.png (slim striped limbs, small nest), Orrery.png (orbit loops + sun sphere), Lanternbow.png (pale limbs, blue wisp lantern). Quivers, Contagion Band and The Maw were done on 2026-11-12.
- [ ] (optional) **The Maw stage sprites**: the roster calls for 4 bow sprites (Starving/Fed/Gorged/Awakened); only one exists and no per-stage swap is coded yet.
