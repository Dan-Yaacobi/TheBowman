# Sky Archer — Claude Code Instructions

Fast, snappy archer roguelite on floating sky islands. Godot 4 + GDScript, solo project.

---

## How to work with me
- Workflow: design first → build a skeleton → implement step by step. Confirm each step works before the next. No big multi-file dumps.
- Design discussions stay design-only — don't write code unless I ask for implementation.
- When iterating on a shader, always give the complete shader, never partial diffs.
- Prefer empirical testing: get it running, let results decide.
- Minimal structural changes — don't add nodes or new systems unless architecturally necessary.
- Ask before: creating new autoloads, changing project settings, deleting files, or spending PixelLab credits on batches.
- Don't commit. I review diffs and commit in GitHub Desktop.

---

## Design docs
- Read `docs/GDD.md` before designing or implementing any gameplay feature. Follow its Design Rules and Definition of Finished.
- Read `docs/STORY_BIBLE.md` before writing any in-game text, lore, item descriptions or NPC dialogue.

---

## Commands
| What | Command |
|---|---|
| Godot executable | `C:\Users\User\Desktop\Apps\Godot 4.7.2.exe` |
| Import new assets (headless) | `"<godot>" --headless --import --path .` |
| Run project | via Godot MCP, or `"<godot>" --path .` |
| Run a specific scene | `"<godot>" --path . res://path/to/Scene.tscn` |

---

## GDScript rules
- Tabs for indentation, never spaces.
- Every new variable has an explicit type (`var speed: float = 0.0`, `var targets: Array[Enemy] = []`).
- Typed function signatures and return types.
- Files: scripts lowercase `snake_case.gd`; scenes `PascalCase.tscn`, no spaces (`TypeOfScene.tscn`). One folder per feature (scene + script + Sprites/ + Resource/).
- Classes: `class_name PascalCase`; hand-state prefixes `m_h_` / `o_h_` (main/off hand) in file names.
- Constants: `UPPER_SNAKE` with explicit type (`const BURN_DEBUFF_ID: int = 107`).
- Signals: `snake_case`, past tense or noun (`buff_added`, `boss_spawned`, `arrow_missed`); typed args.
- Connections: mostly in code via `.connect()`; handlers named `_on_<source>_<signal>`.

---

## Architecture
- Data-driven: exported resources drive behavior (e.g. `EnemyData`); state nodes are logic-only.
- Condition-driven over timer-driven: timers only guard state exits, they don't make decisions.
- Each class owns its own lifecycle; orchestration lives at coordinator level (e.g. `EquipmentInteractedState`).
- EventBus for decoupling — all HUD communication goes through EventBus, never direct node refs.
- Inspector-driven config over code defaults; exported tuning values are first-guess placeholders.

### Key systems (where things live)
| System | Path | Notes |
|---|---|---|
| Player / state machine | `Player/Player.tscn`, `Player/player.gd`, `Player/Player2.0/` | Body + MainHand/OffHand, each with its own state machine; legacy states in `Player/States/` |
| Pull / bow system | `Player/Player2.0/MainHand/States/`, `HUD/PullBar/` | `PullingMainHandState`, max-pull state, `PullBar` UI |
| Stats / Buffs (`Stat`, `Buff`, `BuffHandler`) | `StatClass/stat.gd`, `General Nodes/BuffHandler/`, `Player/Buffs/` | `Stat` resource; `Buff` + `BuffHandler` nodes |
| Equipment (bows, quivers, rings) | `Items/Equipments/` (Bows, Quivers, Rings, Swords, StateMachine) | `Equipment` + `EquipmentData`; `.tres` per item in `*/Resource/` |
| Debuffs | `Debuffs/`, `General Nodes/DebuffHandler/` | `Debuff` base, one folder per debuff |
| EventBus | `00 Globals/event_bus.gd` | ~85 signals, autoload |
| Rift generator / chunks | `Rifts/RiftGeneration/`, `Rifts/Chunks/` | `RiftGenerator`, `RiftChunk`, `ChunkData`, `RiftChunkLibrary` |
| Enemy spawning (`RiftEnemySpawner`) | `Rifts/RiftEnemySpawner/`, `Rifts/Chunks/Utility/Markers/` | `RiftEnemySpawner` + `EnemyEntry`; spawn/entry/exit markers |
| Enemies + `EnemyData` | `Enemies/Scripts/`, `Enemies/EnemyData/` | `Enemy` (extends `GameEntity`), per-enemy `.tres` in `EnemyValues/` |
| Abilities | `Player/Abilities2.0/` | Active/Dash/Passive/Shoot/Sword ability types |
| Loot | `Items/LootManager/` | Item pools |

### Autoloads (`00 Globals/` unless noted)
PlayerManager, EventBus, CombatTextSpawner, SoundManager (.tscn), CustomVariables, Islands,
GameWorlds, GameObjects, GeneralFunctions, ItemDropManager, SettingsManager, GameStateManager,
SaveService, MetaProgress, SceneTransition (`HUD/Scene Transition/`)

### Folder layout
```
res://
├── 00 Globals/      # autoload scripts
├── Player/          # player, Player2.0 hands/body, Abilities2.0, Buffs
├── Enemies/         # one folder per enemy + Scripts/, EnemyData/, abilities/effects
├── Items/           # Equipments/, LootManager/, pickups, currencies
├── Debuffs/         # one folder per debuff
├── Rifts/           # rift scenes, generator, chunks, enemy spawner
├── Level/           # islands, events, boss arena, Testing/
├── General Nodes/   # reusable components (HitBox, HurtBox, Buff/DebuffHandler)
├── HUD/, UI/        # HUD widgets, theme
├── NPC/, Objects/, Quests/, MainGame/, MainMenu/, StartMenu/
├── docs/            # GDD, story bible, PixelLab reference
└── assets/reference/  # PixelLab style references
```

---

## Godot gotchas (learned the hard way)
- No top-level `const X = preload(...)` in heavily-depended-on classes — compile-order deadlock. Use `load()` inside functions.
- No cyclic `preload` in `@export` defaults — leave exports null, assign in inspector.
- Removing an `@export`: clear its inspector value first, then remove the property (avoids orphaned `ext_resource` in `.tscn`).
- Check `is_inside_tree()` after every `await` in nodes that can be freed mid-coroutine.
- Prefer signal-based cleanup owned by the target node over coroutine cleanup tied to a parent.
- Stored lambdas that outlive their creator: use `weakref` + `is_instance_valid`.
- After `reparent()`: disable `CollisionShape2D`, await `physics_frame`, re-enable.
- Typed arrays: use `is_empty()`, not `== null`.
- Prefer tween-based arcs over RigidBody2D for drops/items.
- Async world changes need an `_is_transitioning` guard.
- Distinct random rolls: sample without replacement, not retry loops.

---

## Editing .tscn / .tres files
- Direct edits are fine. Before editing a scene, confirm with me that it's closed in the Godot editor.
- Read the full scene file before editing; keep `ext_resource` / `sub_resource` ids consistent and unique.
- Never invent or change `uid://` values. Reference newly generated assets by `res://` path only — Godot adds the uid on the next editor save.
- Don't touch `.godot/` or `*.import` files.

---

## Art pipeline (PixelLab MCP)
PixelLab is the only art source. Full tool reference: `docs/pixellab-mcp.md` (local copy of https://api.pixellab.ai/mcp/docs) — read it before the first art task in a session.

### Style
- Style: match `archer_reference.png` — 1px near-black outline, simple 2–3-tone shading, muted earthy colors, chunky readable silhouettes.
- View: side
- Reference images (view these before any generation):
	- `assets/reference/archer_reference.png` — player
	- `assets/reference/apple reference.png`, `evil bird reference.png`, `frozen orb reference.png`, `wizard reference.png`, `Red Wizard Reference.png` — enemies
	- `assets/reference/island reference.png` — islands
	- `assets/reference/coin ref.png` — pickups
	- `assets/reference/world soul head ref.png` — spirit of the world, main hub NPC (see `docs/STORY_BIBLE.md`)

### Sizes & output
- Sizes: 64×64 px
- Save to: the `Sprites/` folder of the object's type (e.g. enemy sprites → `Enemies/.../Sprites/`).
- File naming: no fixed convention — name it for what it represents.
- Animations: sprite sheet on a `Sprite2D` (`hframes`/`vframes`) + `AnimationPlayer`; key `frame` plus extra tracks as needed (e.g. `modulate` hit flash). Snap step 0.05s.
- Import settings: texture filter Nearest, TODO anything else

### Rules
- PixelLab cannot read local files. Upload references (POST /v2/uploads → `upload:<id>`) or use base64 only for tiny sprites — large inline base64 gets truncated.
- Use a fixed seed and palette when generating variants of the same thing.
- Preferred tools: `create_image_pro` (new sprites from references), `animate_image` (frames), `edit_image` (variants), `create_sidescroller_tileset` (islands), `reduce_colors` (palette lock).
- State the generation cost before calling any tool costing more than 1 generation.
- Always show me generated images and get approval before saving them into the project.
- Ask before any batch generation (more than 4 images).

---

## Single-step asset flow
Generate → show me → save to project → wire into scene (path-only reference) → run headless import → run project → check debug output → report.

---

## Running & testing (Godot MCP)
- Main scene: `res://StartMenu/StartMenu.tscn`
- Test scenes for isolated testing: `res://Level/Testing/TestingArea.tscn`
- After code or asset changes: run headless import, run the project, check debug output for errors before reporting done.

---

## Current focus
_(set as we go)_
