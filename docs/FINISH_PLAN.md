# Finish Plan

Everything left before the game counts as finished (see GDD §5 Definition of Finished). Ordered from least to most effort. Tick items off as they land.

**Effort:** S = a few hours · M = 1–2 days · L = several days · XL = a week or more

---

## Open decisions
- [ ] **Tower design:** layout, hazards and traps, and how falls work there. Left open for now.

## S
- [ ] Prune `fixes and bugs.txt` down to what's still open.
- [ ] Hell bird: eggs pass through islands and scorch each island's top for 3–4s (one patch per island).
- [ ] Win plumbing: emit `EventBus.run_won`, win screen, credits, return to hub. Use a placeholder trigger until the final boss exists.
- [ ] Hub flow after the hell boss: its portal leads to the Tower instead of another rift.
- [ ] Cleric in the Tower: place the existing `Cleric` NPC (extra heart for coins) partway up. If a separate heal-for-a-price option is wanted, that's a small addition to `cleric.gd`.

## M
- [ ] Flaming skull sniper.
- [ ] Pine tree (sets up the rooted-turret pattern).
- [ ] Obsidian spire (reuses the turret pattern).
- [ ] Snowflake swarm.
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

## Dependencies
- Win plumbing is only complete once the final boss exists.
- The batch 8 artifacts need the Tower scene.
- Art can run alongside everything else.
- The full-run playthrough is always last.

## Not in scope (post-finish)
Controller support, new items, an unlock for winning, challenge mode, more biomes, online saves.
