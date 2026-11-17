# Finish Plan

Everything left before the game counts as finished (see GDD §5 Definition of Finished). Ordered from least to most effort. Tick items off as they land.

**Effort:** S = a few hours · M = 1–2 days · L = several days · XL = a week or more

---

## Open decisions
- [ ] **Tower design:** layout, hazards and traps, and how falls work there. Left open for now.

## S
- [x] Prune `fixes and bugs.txt` down to what's still open.
- [x] Hell bird: eggs pass through islands and scorch each island's top for 3–4s (one patch per island).

## M
- [x] Apple rams: line telegraph that tracks, then locks before the charge.
- [x] Flaming skull: 3-ram chain (buffed apple ram, same-length lines), dizzy ~1.5s after; hits and perfect shots don't interrupt.
- [x] Pine tree (sets up the rooted-turret pattern). Placeholder art.
- [x] Obsidian spire (reuses the turret pattern). Placeholder art.
- [x] Enemy test room: debug-only hub portal, spawn any enemy entry.
- [x] Snowflake swarm. Placeholder art.
- [ ] Difficulty ramp, on two levels:
  - **Across the run:** the first rifts are gentle and each rift is harder than the one before.
  - **Within each rift:** a rift starts easier and gets harder as you go through it (fewer and weaker spawns early, building toward the exit).
  The spawner already tracks intensity and progress, so this is likely tuning those curves rather than a new system.
- [ ] Ending text (he portals out) and batch 8 artifacts placed in the Tower.
- [ ] Music: Tower and final boss.

## L
- [ ] Imps (grab and drag). First enemy that moves the player; fallback is kamikaze embers.
- [ ] Tower scene: hand-built ascending climb with hazards and traps, ending at the final room.
- [ ] Art batch: sprites and animations for the hail cloud (art fix only), frost golem, magma golem, pine tree, snowflake, flaming skull, obsidian spire, imp, Tower tiles and hazards, plus the remaining placeholder items. Spread across sessions; ask before each batch.

## XL
- [ ] Final wizard boss: rotates between two elemental portals reusing earlier wizards' abilities; each phase change uses a chaos portal that pulls everything in and rebuilds the islands in a new, smaller layout. Arena, phases, sprite.
- [ ] Full-run playthrough and balance, rift 1 to the win (last; needs everything above).
- [ ] 1.0 release on itch.

## Built with the Tower and final boss
Small, but only makes sense once those exist.
- [ ] Hell boss portal leads to the Tower instead of another rift.
- [ ] Cleric placed in the Tower (existing `Cleric` NPC, extra heart for coins). A heal-for-a-price option would be a small addition to `cleric.gd`.
- [ ] Win: killing the final wizard emits `EventBus.run_won`, then win screen, credits, back to the hub.

## Dependencies
- The batch 8 artifacts need the Tower scene.
- Art can run alongside everything else.
- The full-run playthrough is always last.

## Not in scope (post-finish)
Controller support, new items, an unlock for winning, challenge mode, more biomes, online saves.
