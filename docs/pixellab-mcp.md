# PixelLab MCP Tools - AI Assistant Guide

> Generate pixel art assets directly from your AI coding assistant using the Model Context Protocol (MCP)

You have access to PixelLab's MCP tools for creating game-ready pixel art. This guide explains what tools are available and how to use them effectively.

## ⚠️ IMPORTANT: These are MCP tools, not REST endpoints

- If you see PixelLab tools available (like `create_character`, `animate_character`), use them directly
- If you don't see these tools, tell the user MCP isn't configured - don't try curl or v2 API
- Tool names may be prefixed (`mcp__pixellab__create_character`) or bare (`create_character`) depending on client
- Download URLs like `/mcp/characters/{id}/download` are the only direct HTTP endpoints

## What is PixelLab MCP?

PixelLab MCP (also called "Vibe Coding") lets you generate pixel art characters, animations, and tilesets while coding. The tools are non-blocking - they return job IDs immediately and process in the background (typically 2-5 minutes).

## Other PixelLab Interfaces

If users mention these, they're using different PixelLab interfaces:
- **Web interfaces**: Character Creator, Map Workshop, Simple Creator (visual tools at pixellab.ai)
- **Editor plugins**: Aseprite extension, Pixelorama integration
- **API v1**: Legacy REST endpoints (deprecated)
- **API v2**: Modern REST API for programmatic usage
  - Documentation: https://api.pixellab.ai/v2/llms.txt
  - You can use these endpoints directly via HTTP requests when writing code
  - Same functionality as MCP but through REST calls
  - Useful for: batch processing, custom integrations, live in-game asset generation
  - Also useful when you need endpoints not available as MCP tools (use at own risk - MCP tools are made for easy AI usage)

Note: Characters and tilesets created via MCP will appear in Character Creator and Map Workshop web interfaces respectively (if using the same account).

## MCP/Vibe Coding Setup

1. Get your API token at https://api.pixellab.ai/mcp
2. Configure your AI assistant (Cursor, Claude Code, VS Code, etc.)
3. Start generating game assets while coding

### MCP Configuration
```json
{
  "mcpServers": {
    "pixellab": {
      "url": "https://api.pixellab.ai/mcp",
      "transport": "http",
      "headers": {
        "Authorization": "Bearer YOUR_API_TOKEN"
      }
    }
  }
}
```

## Key Concepts

### Non-Blocking Operations
All creation tools return immediately with job IDs:
- Submit request → Get job ID instantly
- Process runs in background (2-5 minutes)
- Check status with corresponding `get_*` tool
- Download when ready (UUID serves as access key)
- **No authentication for downloads**: Share download links freely - UUID acts as the key

### Workflow Pattern
```python
# 1. Create (returns immediately)
result = create_character(description='wizard', n_directions=8)
character_id = result.character_id

# 2. Queue animations immediately (no waiting!)
animate_character(character_id, 'walk')
animate_character(character_id, 'idle')

# 3. Check status later
status = get_character(character_id)
```

### Connected Tilesets
Create seamless terrain transitions by chaining tilesets:
```python
# First tileset returns base_tile_ids immediately
t1 = create_topdown_tileset('ocean', 'beach')

# Chain next tileset using base tile ID (no waiting!)
t2 = create_topdown_tileset('beach', 'grass', lower_base_tile_id=t1.beach_base_id)
```

## Available Tools

### Character & Animation Tools

**💡 Tips:**
- Characters are stored permanently and can be reused
- Animations can be queued immediately after character creation
- 4 directions: south, west, east, north
- 8 directions: adds south-east, north-east, north-west, south-west
- size: v3 and pro draw on a canvas that size; standard draws the character that size on a ~40% larger canvas

#### `create_character_pro_flash`
Create a Pro Flash character from text, including its first image and eight V3 views.
Cost: the first image PLUS a rotation charge, billed as two separate charges. The image goes by longest side — 5 generations up to 96px, 6 from 100 to 208, 9 from 212 to 256 — and the rotation part climbs with size, so the 8-direction TOTAL runs from 6 at 48px to 17 at 256px (9 image + 8 rotations). The steps between are uneven, so do not interpolate: ask get_pro_flash_capabilities(operation="character", width=, height=) for the split. Reusing a first frame (source_image_id, first_frame_url or first_frame_base64) bills only the rotation part — 1 generation at 48px, 8 at 256px.

**Parameters:**
- `description`: str (required)
- `source_image_id`: Optional[str] (optional) [default: None]
- `first_frame_base64`: Optional[str] (optional) [default: None]
- `first_frame_url`: Optional[str] (optional) [default: None]
- `name`: str (optional) [default: ]
- `view`: Literal["low top-down", "high top-down", "side"] (optional) [default: low top-down]
- `first_frame_direction`: Literal["south"] (optional) [default: south]
- `n_directions`: Literal[8] (optional) [default: 8] - Use 8 for full rotation, 4 for cardinal directions
- `template_id`: Literal["mannequin", "bear", "cat", "dog", "horse", "lion", "custom"] (optional) [default: mannequin]
- `seed`: int (optional) [default: 0]
- `width`: Optional[int] (optional) [default: None]
- `height`: Optional[int] (optional) [default: None]
- `style_image`: Optional[ProFlashReferenceInput] (optional) [default: None]
- `style_options`: Optional[ProFlashStyleOptions] (optional) [default: None]
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `create_character`
Queue character creation. Returns immediately with character ID. Use get_character to check status. It takes NO seed and cannot be made reproducible — unusually for the family, since create_character_pro_flash and create_character_state both do; to keep a look across characters pass style_character_id or a reference image instead.

**Examples:**
```python
# Humanoid character (mode defaults to v3)
create_character(
    description='brave knight with shining armor',
    size=48,
)

# Animal from text: v3 draws animals only from a reference, so use
create_character_pro_flash(
    description='orange tabby cat standing on all four legs',
    template_id='cat',  # bear, cat, dog, horse, lion
    width=64, height=64,
)
```

**Parameters:**
- `description`: str (required) — Character appearance (e.g., 'cute wizard with blue robes'). v3 without a reference draws a two-armed, two-legged figure whatever this says (a slime or a bird comes out humanoid); for an animal see body_type.
- `name`: Optional[str] (optional) [default: None] — Character name for reference (e.g., 'Blue Wizard', 'Tabby Cat')
- `body_type`: Literal["humanoid", "quadruped"] (optional) [default: humanoid] — Body type. "humanoid" for bipedal characters (people, robots). "quadruped" for 4-legged animals - requires `template` parameter. Available quadruped templates: `bear`, `cat`, `dog`, `horse`, `lion`. Quadrupeds work in mode="standard", mode="pro", and mode="v3" WITH a reference image (south-facing sprite + template); v3 without a reference image is humanoid only (its sprite generator only draws humanoids).
- `template`: Optional[str] (optional) [default: None] — Quadruped template to use (required when body_type='quadruped'). Available: `bear`, `cat`, `dog`, `horse`, `lion`. Ignored for humanoid body type.
- `mode`: Literal["standard", "pro", "v3"] (optional) [default: v3] — Generation mode, default "v3": clearly more detailed sprites than standard, for 2 generations up to 88 px. For a quadruped from text use create_character_pro_flash(template_id=...) at 64 px (6 generations), or mode="pro" or mode="standard" here; v3 draws one only from a reference sprite. "standard" uses template-based skeleton generation (cheaper, 1 generation). "pro" uses AI reference-based generation for higher quality (costs 10-25 generations depending on size, always 8 directions). "v3" produces the highest quality output (costs 2-9 generations depending on size) and is the only mode that accepts reference_image_base64 / reference_image_url (rotate an existing sprite) and direction_images. Pro mode ignores n_directions, outline, shading, detail, text_guidance_scale, and proportions. v3 mode ignores shading, proportions, and text_guidance_scale; v3 honours n_directions only with a reference image (without one it is always 8).
- `n_directions`: Literal[4, 8] (optional) [default: 8] — Number of directional views (4 or 8). Ignored in pro mode and in v3 without a reference image (always 8). With a v3 reference, 4 keeps south/east/north/west.
- `reference_image_base64`: Optional[str] (optional) [default: None] — South-facing character sprite (PNG base64, max 256x256). Requires mode="v3": rotates this exact sprite into 8 directions — the right tool for turning an existing character sprite into a full rotating character (do NOT use create_8_direction_object for characters). The image defines identity and style; description guides the rotation; outline/detail hints are ignored. SOUTH MEANS STRAIGHT-ON, FACING THE VIEWER: whatever this sprite faces is taken as south and every other direction is rotated from it, so a 3/4 turn here silently offsets the WHOLE set by 45 degrees and every direction label is wrong. There is no way to declare a different facing — re-pose or pick a front-on reference first, or you pay for eight unusable sprites. Output size defaults to the reference's own dimensions unless size is set. PREFER reference_image_url for anything above ~32x32 — MCP clients routinely truncate large inline base64.
- `style_character_id`: Optional[str] (optional) [default: None] — ID of one of your existing 8-direction characters to use as the style reference (mode="pro" only). Its 8 directional sprites guide the new character's style in every direction. The style character must be completed with 8 directions, and size must be at least its sprite content size — the job fails fast with the required size otherwise.
- `reference_image_url`: Optional[str] (optional) [default: None] — Alternative to reference_image_base64: an https URL to the south-facing sprite PNG (mode="v3" only). South means STRAIGHT-ON, facing the viewer: whatever this sprite faces becomes south and the other seven are rotated from it, so a 3/4-turn reference offsets every direction and mislabels the whole set. PREFER THIS for anything but tiny sprites — inline base64 is often cut off mid-string by MCP clients, which corrupts the image. Give a url OR a base64, not both.
- `concept_image_url`: Optional[str] (optional) [default: None] — mode="pro" only: concept art, a painting, sketch or photo of the character (any pose or angle; larger than 1024 px is scaled down to fit) that the 8 directions are designed from. The result keeps its look, not its pose or canvas. An https or data: URL. For a finished sprite you want rotated as drawn, use mode="v3" with reference_image_url instead.
- `concept_image_base64`: Optional[str] (optional) [default: None] — Alternative to concept_image_url: the concept as PNG/JPEG base64. Give a url OR a base64, not both.
- `direction_images`: Optional[dict[str, str]] (optional) [default: None] — Requires mode="v3" and a reference image: sprites you already drew for OTHER directions, as {direction: image}. Directions: south-east, east, north-east, north, north-west, west, south-west (with n_directions=4 only east, north, west). Each image is an https URL, upload:<id>, data URL, or PNG base64, like the reference. They are used exactly as drawn and v3 generates only the directions you leave out; cover every one and nothing is generated (import, 0.25 generations). Every image must have the same canvas size as the reference and face the direction it is keyed under. If your client cannot send an object here, send the same object JSON-encoded as a string.
- `proportions`: Optional[str] (optional) [default: {"type": "preset", "name": "default"}] — Character body proportions as JSON string (humanoid only, ignored for quadrupeds). PRESET: Use built-in proportions like '{"type": "preset", "name": "chibi"}' (options: default, chibi, cartoon, stylized, realistic_male, realistic_female, heroic). CUSTOM: Define exact values like '{"type": "custom", "head_size": 1.5, "arms_length": 0.8, "legs_length": 0.9, "shoulder_width": 0.7, "hip_width": 0.8}' (all values 0.5-2.0)
- `size`: Optional[int] (16-256) (optional) [default: None] — Character size in pixels (default 48). Max 128 for standard/pro mode; up to 256 for mode="v3". Standard mode treats this as the size of the character and stores it on a canvas ~40% larger (64 -> 92x92, 128 -> 180x180) so animations fit. Pro mode stores rotations on a shared square canvas at least this large. V3 from scratch sends this as the requested square generation size; with a v3 reference image, omitted size uses the reference dimensions and a supplied size is advisory.
- `outline`: Optional[Literal["single color black outline", "single color outline", "selective outline", "lineless"]] (optional) [default: single color black outline] — Outline style hint (soft guidance — the model may not follow exactly). Ignored in pro mode.
- `shading`: Optional[Literal["flat shading", "basic shading", "medium shading", "detailed shading"]] (optional) [default: basic shading] — Shading hint (soft guidance — the model may not follow exactly). Ignored in pro and v3 modes.
- `detail`: Optional[Literal["low detail", "medium detail", "high detail"]] (optional) [default: medium detail] — Detail level hint (soft guidance — the model may not follow exactly). Ignored in pro mode.
- `text_guidance_scale`: float (1.0-20.0) (optional) [default: 8.0] — How closely to follow the text description (higher=more faithful). Default 8.0.
- `view`: Literal["low top-down", "high top-down", "side", "oblique"] (optional) [default: low top-down] — Camera angle. "low top-down" (~20° from above, classic 3/4 RPG), "high top-down" (~35° steeper angle), "side" (eye-level), "oblique" (BETA: 3/4 oblique projection, max 128px, 4-dir only, standard mode only).
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `create_character_state`
Queue a state (variant) of an existing character. The new character keeps
the source's identity, body type, and proportions, with the edit applied
consistently across all 4 or 8 rotations. Auto-waits up to 30s for the
source to complete.
Cost: 10-25 generations — the tier is resolved from the canvas at generation time, so the exact charge is not known when the call is made. The balance check runs against the 10 floor, which means a call CAN charge more than it reserved. Leave 25 generations of headroom, or check get_balance first, if you are near the end of a plan.
Generation time: ~1-5 minutes (async). Poll with get_character(character_id).

**Parameters:**
- `character_id`: str (required) — Source character UUID to create a state of
- `edit_description`: str (required) — Edit instructions describing the new state (e.g. 'sitting down', 'wearing red armor', 'fighting pose').
- `seed`: Optional[int] (>=0) (optional) [default: None]
- `state_name`: Optional[str] (optional) [default: None] — Name for the new state (e.g. 'Sitting', 'Red Armor'). Defaults to the edit description truncated to 20 characters.
- `use_color_palette_from_reference`: bool (optional) [default: False] — Snap the edited rotations to the source character's existing color palette so the new state stays color-consistent with the original. Do not enable when the edit is meant to introduce new colors.
- `override_width`: Optional[int] (32-256) (optional) [default: None] — Optional larger canvas WIDTH for the state — reach for it when the edit adds something big (a weapon, wings) needing room beyond the character's tight canvas. Multiple of 4, no smaller than the source width. Pair with override_height; omit both to keep the source size.
- `override_height`: Optional[int] (32-256) (optional) [default: None] — Optional larger canvas HEIGHT for the state (see override_width). Multiple of 4, no smaller than the source height.
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `animate_character`
Queue animation for a character. Returns immediately with job IDs. ~2-4 min.
Cost: template mode bills 1 generation per direction up to a ~92px canvas. Above that the clip splits into batches billed 1 each, so the charge follows the CLIP's frame count as well as the canvas: at 128px breathing-idle (4 frames) bills 1 per direction and walking (6 frames) bills 2; at 180px, 2 and 3; at 256px it is one generation per frame — 4 and 6 — and a direction takes 30+ min. The longest clips set the worst case: jumping-1 (9 frames) bills 3 at 128px, 5 at 180px, 9 at 256px. Frame counts are fixed by the clip and run 1 to 17 (static is 1, lead-jab 3, breathing-idle 4, walk/walking/cross-punch 6, any `-N-frames` clip is N); get_character lists your character's clips, and the submit receipt gives the exact ceiling before anything runs. v3: ceil(w*h*frames/65536) per direction on the GENERATED canvas. pixminimax: 64x64 at 4/8/16/40 frames = 1/1/2/6 per direction. skeleton-v3: 2-4 per direction.

**Example:**
```python
animate_character(
    character_id='uuid-from-create',
    template_animation_id='walking',  # Check tool description for full list
    action_description='walking proudly'  # optional customization
)
```

**Parameters:**
- `character_id`: str (required) — Character UUID from create_character
- `template_animation_id`: Optional[str] (optional) [default: None] — Template animation ID. Required for template-based animations (1 generation/direction). Omit for custom animations that use action_description instead — defaults to v3 mode. v3 cost is ceil(canvas²·frames/65536) per direction on the GENERATED canvas, which the silhouette grows past the sprite size: at 8 frames 64px=1/dir, 96px and 128px=2/dir, 160px=4/dir, 256px=8/dir BEFORE that growth, and a 96px character commonly animates at ~132px and bills 3. Read the cost line in the response for what was actually charged. Asked for a humanoid action by NAME, map it to a real id rather than inferring one: hurt/recoil/stagger/hit -> `taking-punch`, death/downed/dying -> `falling-back-death` then `getting-up`, dash/dodge/sprint -> `running-slide` or `running-jump`, cast/spell/magic -> `fireball`. `hurt`, `dashing`, `casting`, `backstep-dodge`, `shooting` and `staff-spin-attack` do NOT exist and are refused before the job is queued. The COMPLETE humanoid set, each id with its frame count in brackets: `backflip` (10), `breathing-idle` (4), `cross-punch` (6), `crouched-walking` (6), `crouching` (5), `drinking` (6), `falling-back-death` (7), `fight-stance-idle-8-frames` (8), `fireball` (6), `flying-kick` (6), `front-flip` (6), `getting-up` (5), `high-kick` (7), `hurricane-kick` (4), `jumping-1` (9), `jumping-2` (8), `lead-jab` (3), `leg-sweep` (7), `picking-up` (5), `pull-heavy-object` (6), `pushing` (6), `roundhouse-kick` (7), `running-4-frames` (4), `running-6-frames` (6), `running-8-frames` (8), `running-jump` (8), `running-slide` (6), `sad-walk` (8), `scary-walk` (8), `surprise-uppercut` (7), `taking-punch` (6), `throw-object` (7), `two-footed-jump` (7), `walk` (6), `walk-1` (6), `walk-2` (6), `walking` (6), `walking-10` (6), `walking-2` (4), `walking-3` (6), `walking-4` (6), `walking-4-frames` (4), `walking-5` (4), `walking-6` (6), `walking-6-frames` (6), `walking-7` (6), `walking-8` (6), `walking-8-frames` (8), `walking-9` (6). Template mode returns exactly that many frames and has no frame-count override. skeleton-v3 prices off the same count — 3 frames is 2 generations/direction, 4-14 is 3, 15 is 4 — so every clip here bills 3 except `lead-jab`. Quadruped animations vary by template - use get_character() to see available animations.
- `action_description`: Optional[str] (optional) [default: None] — Custom action description focusing on the movement or pose only (e.g., 'walking stealthily', 'walking quickly', 'running', 'jumping', 'casting spell'). Avoid environmental details like locations or objects. If not provided, uses default for template_animation_id.
- `animation_name`: Optional[str] (optional) [default: None] — Custom name for this animation, stored as display_name. If you are appending to an existing animation_group_id, PASS THE GROUP'S EXISTING NAME — it is NOT inherited. Omitting it leaves the new directions with no display_name, so get_character falls back to the animation type and the group looks renamed (e.g. a group called 'delver_cape_walk' starts showing as 'walking-8-frames').
- `animation_group_id`: Optional[UUID] (optional) [default: None] — Append these directions to an EXISTING animation group instead of starting a new one. Pass the [group: ...] id shown by get_character(). Use this to fill in missing directions of an animation you already started (e.g. a rate-limited call that only landed 5/8 directions) so they stay one group. Pass animation_name too, repeating the group's existing name — it is not inherited, and omitting it makes the group appear renamed. Omit animation_group_id to mint a fresh group. Must belong to this character.
- `directions`: Optional[list[str]] (optional) [default: None] — Specific directions to animate (e.g., ['south', 'east']). Valid values: south, north, east, west, south-east, south-west, north-east, north-west. If not provided: template mode animates all character directions, custom mode animates south only.
- `ai_freedom`: int (0-900) (optional) [default: 0] — AI freedom (0-900). TEMPLATE MODE ONLY — ignored in v3 and pixminimax modes. Higher values let the AI deviate more from the template skeleton pose. 0 = rigid template following.
- `mode`: Optional[Literal["template", "skeleton-v3", "v3", "pixminimax"]] (optional) [default: None] — Custom-animation engine. "template": skeleton from template_animation_id (1 gen/direction; canvases over ~100px run in batches billed 1 each, the receipt gives the ceiling). "skeleton-v3": the SAME template_animation_id posed onto the character, which moves the character instead of redrawing it each frame — steadier identity and colours, 2-4 generations and ~3-5 min per direction, beta. Without template_animation_id, "skeleton-v3" is a CUSTOM motion that YOU write as poses (see `poses`): call once with action_description to get the instructions and this character's numbers (free), then again with poses. Every direction of the animation is drawn from that one motion (humanoid characters, 3-15 frames). "v3" (default when no template_animation_id): custom animation from action_description with frame_count control, cheap, one job per direction. "pixminimax": custom animation from action_description on PixMiniMax (beta, every tier) — longer clips (multiples of 4 up to 40 frames) at any size, priced by size and frame count (64x64: 8 frames = 1 gen/direction, 40 frames = 6), ~1-7 min per direction, one job per direction. Auto-detected: template if template_animation_id is given, else v3.
- `frame_count`: int (3-40) (optional) [default: 8] — Number of animation frames. Custom skeleton-v3: 3-15. v3 mode: 4-16, even, and canvas width x height x frames may not exceed 8 x 256 x 256 — a 256px canvas takes 8 frames at most, 16 frames fit up to ~180px. pixminimax mode: a multiple of 4 from 4 to 40. In 'template' mode the template's own frame count is used.
- `custom_start_frame_base64`: Optional[str] (optional) [default: None] — Optional custom starting pose for the animation (mode='v3' or 'pixminimax'). When omitted, the character's rotation image for the chosen direction is used as the start. Max 256x256.

REQUIRES A SINGLE DIRECTION. Pass directions=[<one cardinal>] (one of: south, south-west, west, north-west, north, north-east, east, south-east), or omit directions to default to south. If the user has not said which direction the animation is for, ask them — do not pick one arbitrarily.

Not compatible with mode='template' or mode='skeleton-v3'.
- `end_frame_base64`: Optional[str] (optional) [default: None] — Optional target pose to interpolate toward (mode='v3' or 'pixminimax'). Providing this enables interpolation mode: the model animates between the start frame (rotation image or custom_start_frame_base64) and this end frame. Dimensions must match the start frame.

REQUIRES A SINGLE DIRECTION (see custom_start_frame_base64). Not compatible with mode='template' or mode='skeleton-v3'.
- `custom_start_frame_url`: Optional[str] (optional) [default: None] — Alternative to custom_start_frame_base64: an https URL to the start-frame PNG (mode='v3' or 'pixminimax'). PREFER THIS for large images — inline base64 is often truncated by MCP clients (cut off mid-string), which corrupts the image. A URL avoids that. Give a url OR a base64, not both, for the same frame.
- `end_frame_url`: Optional[str] (optional) [default: None] — Alternative to end_frame_base64: an https URL to the end-frame PNG (mode='v3' or 'pixminimax'). PREFER THIS for large images to avoid inline-base64 truncation. Give a url OR a base64, not both, for the same frame.
- `keep_first_frame`: bool (optional) [default: True] — Keep the reference frame as frame 0 of the stored animation (mode='v3' or 'pixminimax'). Set false to store exactly frame_count generated frames — the reference start frame is stripped, so frame_count=8 stores 8 frames instead of 9. Not compatible with mode='template' or mode='skeleton-v3'.
- `subject_description`: Optional[str] (optional) [default: None] — mode='pixminimax' only: what the character is, one noun phrase (e.g. 'a knight in silver plate armour'). Omit to have it read from the character's image; fill it in if a job fails saying our AI declined.
- `initial_pose`: Optional[str] (optional) [default: None] — mode='pixminimax' only: the pose the first frame is in (e.g. 'standing upright with the sword lowered'). Omit to have it read from the image.
- `poses`: Optional[list[dict[str, Any]]] (optional) [default: None] — mode='skeleton-v3' without template_animation_id: the custom motion you wrote, one pose object per frame (frame, pelvis, hips, chest, lean, head, right_hand, left_hand, right_elbow, left_elbow, right_foot, left_foot). Call first WITHOUT poses to get the instructions and this character's numbers. Not needed when adding directions to an existing animation_group_id: its motion is reused.
- `scale`: Optional[list[float]] (optional) [default: None] — mode='skeleton-v3' custom only, with poses: one size per frame (1 = rest size, 1.3 = 30% bigger) when the character grows or shrinks. Omit otherwise.

#### `get_character`
Get character details, rotation URLs, animations, and download link.
Branches by status: processing (progress+ETA), failed (error+retry), completed (full data).

**Parameters:**
- `character_id`: str (required) — Character UUID to retrieve
- `include_preview`: bool (optional) [default: True] — Include preview image of south direction

#### `list_characters`
List your characters with status. Returns compact one-line-per-character format.
Use get_character(character_id) for full details on any character.

**Parameters:**
- `limit`: int (1-50) (optional) [default: 10] — Maximum number of characters to return
- `offset`: int (>=0) (optional) [default: 0] — Number of characters to skip
- `tags`: Optional[str] (optional) [default: None] — Comma-separated tags to filter by (ANY match). Example: 'wizard,fire'
- `search`: Optional[str] (optional) [default: None] — Filter by name, case-insensitive. Matches the name shown here and the description it was created from, so 'wizard' finds 'old wizard with a staff'.

#### `delete_character`
Delete ONE state of a character (the given id) with its rotations,
animations and files. Other states in the same group are untouched; the
group itself is removed only when its last state is deleted. To delete a
whole multi-state character, call this once per state id (list them with
get_character). Immediate — cannot be undone (in-flight jobs are wasted).

**Parameters:**
- `character_id`: str (required) — Character UUID to delete

#### `update_character_tags`
Replace ALL tags on a character (set operation, free, synchronous).

**Parameters:**
- `character_id`: str (required) — Character UUID whose tags to replace
- `tags`: list[str] (required) — Full replacement tag list (max 20 tags, 50 chars each; whitespace trimmed, case-insensitive dedup). Empty list clears all tags.

### Top-Down Tileset Tools

**💡 Wang Tileset System:**
- Creates 16 tiles covering all corner combinations (25 for tall sets: standard above 0.5, pro from 0.5)
- Perfect for seamless terrain transitions
- Use base_tile_ids to chain multiple tilesets
- tile_size: typically 16x16 or 32x32 pixels
- transition_size: how far the upper terrain rises: 0=flat, 0.25=low bank, 0.5=low walls, 1.0=full-tile walls (25 tiles, 4x8 sheet, wall fills the cell below the boundary; match by pattern_4x4 — 4 wall tiles share corners with a twin)
- view: only pro honours it; standard always draws high top-down

#### `create_topdown_tileset`
Generate a Wang tileset for top-down game maps with corner-based autotiling.
Cost: standard is 1 generation now that it runs on pixen. (The classic model it replaced billed per stage: 1-4, usually 3 or 4 — NOT 1, over 6,124 prod charges, mean 3.1.) mode="pro" costs 15 generations for tiles up to 32 px, 25 above. Failed jobs are not charged.
Generation time: standard ~30 seconds, pro a few minutes (async processing)

**Example (chained tilesets):**
```python
# Ocean → Beach → Grass → Forest
t1 = create_topdown_tileset('ocean water', 'sandy beach')
t2 = create_topdown_tileset('sandy beach', 'green grass',
                           lower_base_tile_id=t1.beach_base_id)
t3 = create_topdown_tileset('green grass', 'dense forest',
                           lower_base_tile_id=t2.grass_base_id)
```

**Parameters:**
- `lower_description`: str (required) — Lower terrain type (e.g., 'ocean water', 'dirt path')
- `upper_description`: str (required) — Upper/elevated terrain type (e.g., 'sandy beach', 'grass')
- `transition_size`: float (optional) [default: 0.0] — How far the upper terrain rises above the lower: 0 = flat, 1.0 = full-tile walls. Standard takes any value from 0 to 1 (above 0.5 = 25 tiles, 16 px tiles only); pro uses the nearest of 0, 0.25, 0.5 and 1.0 (0.5 and up = 25 tiles).
- `transition_description`: Optional[str] (optional) [default: None] — The strip between the terrains, e.g. 'wet sand with foam'. Used only when transition_size > 0; at the default 0 there is no strip to draw.
- `tile_size`: dict[str, int] (optional) [default: {'width': 16, 'height': 16}] — Tile dimensions as {"width": N, "height": N}, OR a bare int N for a square tile (same shape create_tiles_pro accepts). 16 or 32 for standard; 64 requires mode='pro'.
- `mode`: Literal["standard", "pro"] (optional) [default: standard] — Generation pipeline. "standard": the website's standard tileset (pixen, 16 or 32px, round borders unless shape_style='square'), cheap and fast. "pro": the richest tiles - painted texture, raised banks - 16/32/64px; use it when the look matters. raggedness, roundness, boundary_amplitude and step_slope shape its border (not shape_style - mode='pro' with shape_style is rejected); connects through lower_base_tile_id/upper_base_tile_id like standard.
- `shape_style`: Optional[Literal["square", "round"]] (optional) [default: None] — Terrain-boundary geometry for mode='standard' (passing it with mode='pro' is rejected). 'round' (default for standard, as on the website) for circular arcs, 'square' for stepped corners. transition_size is continuous from 0 to 1; values above 0.5 use a 4x8 sheet.
- `enhance`: bool (optional) [default: True] — Standard tilesets only (on by default; pro ignores it). AI-enhances the terrain descriptions at the chosen detail/shading levels and picks matching base colours before generation. The stored tileset keeps the enhanced text; your original prompts are kept in its metadata.
- `spread_x`: float (0.0-1.0) (optional) [default: 0.5] — No effect - the Pro pipeline no longer uses it; kept so existing calls work.
- `slope_size`: float (0.0-1.0) (optional) [default: 0.0] — No effect - the Pro pipeline no longer uses it; kept so existing calls work.
- `raggedness`: float (0.0-1.0) (optional) [default: 0.0] — Pro only. Terrain boundary noise (0=smooth, 1=rough). Tall sets (transition_size above 0.4) are half as rough.
- `roundness`: Optional[float] (0.0-2.0) (optional) [default: None] — mode='pro' or shape_style only. Corner shape of the border between the two terrains: 0 = square, 1 = round, 2 = corners cut at 45 degrees (values in between blend). Above 1 needs mode='pro'. Omit for the default (0.85 on pro, 0.6 with shape_style). On tall pro sets (transition_size above 0.4) up to 1 leaves the corners to the shape picked from the descriptions, and 1-2 cuts them toward 45 degrees.
- `boundary_amplitude`: float (0.0-0.3) (optional) [default: 0.0] — Uneven boundary: mode='pro' (any transition_size), or shape_style with transition_size up to 0.5. How far the border between the terrains meanders instead of running straight, 0 = straight (default) to 0.3 = the most. Tiles still connect seamlessly. On a raised pro set a taller bank gets a gentler curve (half at transition_size 0.25), and tall walls (above 0.4) gentler still.
- `boundary_seed`: int (>=0) (optional) [default: 0] — Boundary shape for boundary_amplitude: another number gives a different meander at the same amount; the same number gives the same shape.
- `step_slope`: float (0.0-2.0) (optional) [default: 0.0] — Edge steepness: mode='pro' with transition_size 0.25 only (a raised 16-tile set). How the bank between the terrains falls: 0 = a cliff, straight down (default), up to 2.0 = a gentle slope spread over more ground.
- `connect_diagonals`: bool (optional) [default: False] — mode='pro' only. The two diagonal tiles (upper terrain in opposite corners): true joins the two upper corners through the middle into one area; false (default) leaves the lower terrain running between them. On tall walls (transition_size above 0.4) the upper corner's wall turns forward to meet the lower block.
- `outline`: Optional[Literal["single color outline", "selective outline", "lineless"]] (optional) [default: None] — No effect: standard runs on pixen and pro ignores it; kept so existing calls work.
- `shading`: Optional[Literal["flat shading", "basic shading", "medium shading", "detailed shading", "highly detailed shading"]] (optional) [default: None] — Shading style
- `detail`: Optional[Literal["low detail", "medium detail", "highly detailed"]] (optional) [default: None] — Detail level
- `view`: Literal["low top-down", "high top-down"] (optional) [default: high top-down] — Camera angle, mode='pro' only: match your characters' view (create_character defaults to low top-down). Standard (pixen) always draws high top-down.
- `tile_strength`: float (0.1-2.0) (optional) [default: 1.0] — No effect: standard runs on pixen and pro ignores it; kept so existing calls work.
- `lower_base_tile_id`: Optional[str] (optional) [default: None] — ID of existing tile to use as lower terrain reference. Use to create connected tilesets
- `upper_base_tile_id`: Optional[str] (optional) [default: None] — ID of existing tile to use as upper terrain reference. Use to create connected tilesets
- `tileset_adherence`: float (0.0-500.0) (optional) [default: 100.0] — No effect: standard runs on pixen and pro ignores it; kept so existing calls work.
- `tileset_adherence_freedom`: float (0.0-900.0) (optional) [default: 500.0] — No effect: standard runs on pixen and pro ignores it; kept so existing calls work.
- `text_guidance_scale`: float (1.0-20.0) (optional) [default: 8.0] — No effect: standard runs on pixen and pro ignores it; kept so existing calls work.
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `get_topdown_tileset`
Get a topdown Wang tileset by ID. Returns status, download links, base tile IDs for chaining, and an example map image.
Download: no auth, the UUID is the key. GET /mcp/tilesets/{id}/image for the sheet PNG (add ?inline=true to be served the bytes instead of a CDN redirect, which Python stdlib clients need), GET /mcp/tilesets/{id}/metadata for per-tile bounding_box (x/y/width/height, use as atlas regions), corners (NW/NE/SW/SE, each lower/upper/transition, use for Wang autotiling) and pattern_4x4. Both answer 423 + Retry-After while generating. Godot walkthrough: the MCP resource pixellab://docs/godot/wang-tilesets.

**Parameters:**
- `tileset_id`: str (required) — The UUID of the topdown tileset to retrieve

#### `list_topdown_tilesets`
List your top-down Wang tilesets. One line per tileset with status.
Use get_topdown_tileset(tileset_id) for full details.

**Parameters:**
- `limit`: int (1-50) (optional) [default: 10] — Maximum number of tilesets to return
- `offset`: int (>=0) (optional) [default: 0] — Number of tilesets to skip

#### `delete_topdown_tileset`
Delete a tileset by ID.

**Parameters:**
- `tileset_id`: str (required) — The UUID of the tileset to delete

### Sidescroller Tileset Tools

**💡 2D Platformer Tips:**
- Designed for side-view perspective (not top-down)
- Creates 16 tiles with transparent backgrounds
- Platform tiles have flat surfaces for gameplay
- Use `transition_description` for decorative top layers
- Chain tilesets with `base_tile_id` and mode='pro': the platform body is reused, only the top changes

#### `create_sidescroller_tileset`
Generate a sidescroller tileset for 2D platformer games with side-view perspective.
Cost: standard is 1 generation now that it runs on pixen. (The classic model it replaced billed 2 or 3 generations — NOT 1, over 1,186 prod charges, mean 2.6.) mode="pro" costs 15 generations for 16 or 32 px tiles. Failed jobs are not charged.
Generation time: standard ~30 seconds, pro a few minutes (async processing)

**Example (one platform body, two tops):**
```python
stone = create_sidescroller_tileset(
    lower_description='stone brick',
    transition_description='moss and vines',
    transition_size=0.25
)
snowy = create_sidescroller_tileset(
    lower_description='stone brick',
    transition_description='snow cover',
    transition_size=0.25,
    mode='pro',
    base_tile_id=stone.base_tile_id
)
```

**Parameters:**
- `lower_description`: str (required) — Platform/center material (e.g., 'stone brick', 'wooden planks', 'metal grating')
- `transition_description`: str (required) — Platform surface/top layer (e.g., 'grass', 'snow cover', 'moss')
- `transition_size`: float (optional) [default: 0.0] — Size of terrain transition. Controls how much of the surface layer appears (0.0 = no surface layer, 0.25 = light surface layer, 0.5 = heavy surface layer). Snapped to the nearest of 0, 0.25 and 0.5.
- `mode`: Literal["standard", "pro"] (optional) [default: standard] — "standard": the website's standard sidescroller tileset (pixen, side view), cheap and fast. "pro": the richest platforms - painted texture, a cleaner cap - use it when the look matters.
- `enhance`: bool (optional) [default: True] — mode='standard' only. AI-enhances the platform and surface descriptions and picks matching base colours before generation. The stored tileset keeps the enhanced text; your original prompts are kept in its metadata.
- `tile_size`: dict[str, int] (optional) [default: {'width': 16, 'height': 16}] — Tile dimensions as {"width": N, "height": N}, OR a bare int N for a square tile (same shape create_tiles_pro accepts). 16 or 32 pixels.
- `outline`: Optional[Literal["single color outline", "selective outline", "lineless"]] (optional) [default: None] — No effect: standard runs on pixen and pro ignores it; kept so existing calls work.
- `shading`: Optional[Literal["flat shading", "basic shading", "medium shading", "detailed shading", "highly detailed shading"]] (optional) [default: None] — Shading style
- `detail`: Optional[Literal["low detail", "medium detail", "highly detailed"]] (optional) [default: None] — Detail level
- `tile_strength`: float (0.1-2.0) (optional) [default: 1.0] — No effect: standard runs on pixen and pro ignores it; kept so existing calls work.
- `base_tile_id`: Optional[str] (optional) [default: None] — mode='pro' only. base_tile_id from get_sidescroller_tileset: the platform body is reused, so describe the same body in lower_description and the new top in transition_description
- `tileset_adherence`: float (0.0-500.0) (optional) [default: 100.0] — No effect: standard runs on pixen and pro ignores it; kept so existing calls work.
- `tileset_adherence_freedom`: float (0.0-900.0) (optional) [default: 500.0] — No effect: standard runs on pixen and pro ignores it; kept so existing calls work.
- `text_guidance_scale`: float (1.0-20.0) (optional) [default: 8.0] — No effect: standard runs on pixen and pro ignores it; kept so existing calls work.
- `seed`: Optional[int] (optional) [default: None] — Seed for reproducible generation

#### `get_sidescroller_tileset`
Get a sidescroller tileset by ID. Returns status, download links, and tile count.
Sidescroller tilesets are for 2D platformer games with transparent backgrounds.

**Parameters:**
- `tileset_id`: str (required) — ID of the sidescroller tileset to retrieve

#### `list_sidescroller_tilesets`
List your sidescroller (platformer) tilesets. One line per tileset with status.
Use get_sidescroller_tileset(tileset_id) for full details.

**Parameters:**
- `limit`: int (1-100) (optional) [default: 20] — Maximum number of tilesets to return
- `offset`: int (>=0) (optional) [default: 0] — Number of tilesets to skip

#### `delete_sidescroller_tileset`
Delete a sidescroller tileset by ID.

**Parameters:**
- `tileset_id`: str (required) — The UUID of the sidescroller tileset to delete

### Isometric Tile Tools

**💡 Isometric Design Tips:**
- Creates individual 3D-looking tiles for game assets
- Sizes above 24px produce better quality (32px recommended)
- `tile_shape` controls thickness: thin (~10%), thick (~25%), block (~50%)
- Perfect for blocks, items, terrain pieces, buildings
- Use consistent settings across tiles for cohesive look

#### `create_isometric_tile`
Create an isometric tile. Returns immediately with tile ID.
Use get_isometric_tile to check status and retrieve the result (~1-3 min).

**Examples:**
```python
# Terrain tiles
grass = create_isometric_tile('grass on top of dirt', size=32)
stone = create_isometric_tile('stone brick wall with moss', size=32)

# Game objects
chest = create_isometric_tile(
    description='wooden treasure chest with gold trim',
    tile_shape='block',  # Full height for objects
    detail='highly detailed'
)
```

**Parameters:**
- `description`: str (required) — Text description of the tile (e.g., 'grass on top of dirt')
- `size`: int (16-64) (optional) [default: 32] — Tile canvas size in pixels (16-64). Sizes above 24px often produce better quality results.
- `tile_shape`: Literal["thick tile", "thin tile", "block"] (optional) [default: block] — Tile thickness. Thicker tiles allow more height variation in game maps. thin tile: ~10% canvas height, thick tile: ~25% height, block: ~50% height.
- `outline`: Optional[Literal["single color outline", "selective outline", "lineless"]] (optional) [default: lineless] — Outline style (weakly guiding).
- `shading`: Optional[Literal["flat shading", "basic shading", "medium shading", "detailed shading", "highly detailed shading"]] (optional) [default: basic shading] — Shading complexity (weakly guiding).
- `detail`: Optional[Literal["low detail", "medium detail", "highly detailed"]] (optional) [default: medium detail] — Detail level (weakly guiding).
- `text_guidance_scale`: float (1.0-20.0) (optional) [default: 8.0] — How closely to follow the text description (1.0-20.0)
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation

#### `get_isometric_tile`
Get an isometric tile by ID. Returns tile image and metadata if completed, or progress if processing.

**Parameters:**
- `tile_id`: str (required) — The UUID of the isometric tile to retrieve

#### `list_isometric_tiles`
List your isometric tiles. One line per tile with status.
Use get_isometric_tile(tile_id) for full details.

**Parameters:**
- `limit`: int (1-50) (optional) [default: 10] — Maximum number of tiles to return
- `offset`: int (>=0) (optional) [default: 0] — Number of tiles to skip

#### `delete_isometric_tile`
Delete an isometric tile by ID. Only the owner can delete their own tiles.

**Parameters:**
- `tile_id`: str (required) — The UUID of the isometric tile to delete

### Object Tools

**💡 Tips:**
- Objects support 1-direction (single view) or 8-direction (full rotation)
- Multi-frame objects go through a review step — select your favorites
- Objects can be animated after creation

#### `create_object_pro_flash`
Create a Pro Flash object from text, with one direction or eight V3 views.
Cost: n_directions=1 is the image alone, by longest side — 5 generations up to 96px, 6 from 100 to 208, 9 from 212 to 256 — so 32x96 and 64x48 are both 5. n_directions=8 adds a rotation charge that climbs with size, billed separately, taking the TOTAL from 6 at 48px to 17 at 256px (9 image + 8 rotations). The steps between are uneven, so do not interpolate: ask get_pro_flash_capabilities(operation="object", width=, height=, n_directions=) for the split. Reusing a first frame bills only the rotation part, and nothing at all for one direction.

**Parameters:**
- `description`: str (required)
- `source_image_id`: Optional[str] (optional) [default: None]
- `first_frame_base64`: Optional[str] (optional) [default: None]
- `first_frame_url`: Optional[str] (optional) [default: None]
- `name`: str (optional) [default: ]
- `view`: Literal["low top-down", "high top-down", "side"] (optional) [default: low top-down]
- `first_frame_direction`: Literal["south"] (optional) [default: south]
- `n_directions`: Literal[1, 8] (optional) [default: 8]
- `seed`: int (optional) [default: 0]
- `width`: Optional[int] (optional) [default: None]
- `height`: Optional[int] (optional) [default: None]
- `style_image`: Optional[ProFlashReferenceInput] (optional) [default: None]
- `style_options`: Optional[ProFlashStyleOptions] (optional) [default: None]
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `create_map_object`
Create a pixel art object with transparent background. ~30-90s. Returns object ID immediately.

**Parameters:**
- `description`: str (required) — Object description (e.g., 'wooden barrel', 'stone fountain')
- `width`: Optional[int] (32-400) (optional) [default: None] — Canvas width in pixels (required for basic mode, auto-detected from background_image if provided)
- `height`: Optional[int] (32-400) (optional) [default: None] — Canvas height in pixels (required for basic mode, auto-detected from background_image if provided)
- `view`: Literal["low top-down", "high top-down", "side"] (optional) [default: high top-down] — Camera angle
- `outline`: Optional[Literal["single color outline", "selective outline", "lineless"]] (optional) [default: single color outline] — Outline style
- `shading`: Optional[Literal["flat shading", "basic shading", "medium shading", "detailed shading"]] (optional) [default: medium shading] — Shading complexity
- `detail`: Optional[Literal["low detail", "medium detail", "high detail"]] (optional) [default: medium detail] — Detail level
- `background_image`: Optional[str] (optional) [default: None] — Background image for style matching (optional). Format: {"type": "base64", "base64": "..."}. File paths are not supported (server cannot read local files). If provided without inpainting config, uses default: oval 60%.
- `inpainting`: Optional[str] (optional) [default: None] — Inpainting configuration as JSON string (optional). DEFAULT: If background_image provided but this omitted, uses oval 0.6. Options: {"type": "oval", "fraction": 0.3} for auto oval mask, {"type": "rectangle", "fraction": 0.5} for auto rectangle mask, {"type": "mask", "mask_image": "base64..."} for custom mask. Mask convention: WHITE (255) = area where AI generates, BLACK (0) = frozen/preserved context. Fraction is 0.05-0.95 (how much of background the shape covers).

#### `get_map_object`
Get map object status and data. Returns image if completed.
The object is permanent — place it on a map with place_map_object.
Retries saving finished pixels when B2 or database persistence failed.

**Parameters:**
- `object_id`: str (required) — Object ID to retrieve

#### `create_1_direction_object`
Queue a 1-direction object (10-25 generations, ~2-3 min). Returns object_id immediately.

**Parameters:**
- `description`: str (required) — Object description (e.g., 'wooden barrel', 'forest mushroom')
- `size`: Optional[int] (16-256) (optional) [default: None] — Square image size in pixels (min 16, max 256). Defaults to 64 when omitted. Cannot be set together with style_images — when style_images are provided, the largest style image determines the output size. The effective size also determines how many candidate objects are produced in one shot (≤42→64, ≤85→16, ≤170→4, else 1). Multi-object results enter 'review' status — call get_object to inspect, then select_object_frames or dismiss_review to finalize.
- `name`: Optional[str] (optional) [default: None] — Object name for reference (e.g., 'wooden barrel', 'Forest Mushroom'). Defaults to the description when omitted.
- `view`: Literal["top-down", "sidescroller"] (optional) [default: top-down] — View. NOTE: 1-direction uses top-down/sidescroller; create_8_direction_object and create_map_object use a different set (low top-down / high top-down / side).
- `style_images`: list[StyleReferenceImage] (required) — Style reference images, PNG/JPEG base64 (max 256x256 px each). Each image: {"base64": "<png-data>", "format": "png"}. The maximum count depends on `size`: ≤85 → 8, ≤170 → 4, else → 1. When empty, a default style is used based on `view`. Note: this is NOT the same as reference_image on tileset tools (which is a small 16x16/32x32 texture).
- `item_descriptions`: Optional[list[str]] (optional) [default: None] — Per-object descriptions when `size` produces multiple objects. Length must not exceed the object count derived from `size`. Supplying FEWER is allowed and does NOT shrink the grid: the remaining slots are generated from `description`, so they come back as extra objects in the same style, not as variations of the items you listed. One description at size=48 therefore returns 16 objects, only the first of which is the one you named.
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `create_8_direction_object`
Queue an 8-direction object rendered from 8 angles (10-25 generations, ~2-4 min).
Returns object_id immediately. Use get_object to check status.
For single-direction objects, use create_1_direction_object instead.
For a console or palette look (1-bit, Game Boy, PICO-8, any Lospec palette) pass
`palette` as its hex colours plus `palette_name`: all 8 directions are drawn for
it and every pixel is one of its colours.

**Parameters:**
- `description`: str (required) — Object description (e.g., 'wooden barrel', 'stone fountain')
- `size`: Optional[int] (24-168) (optional) [default: None] — Square image size in pixels (min 24, max 168 — below 24 the eight angles stop being distinguishable, so use create_1_direction_object for 16px). Defaults to 64 when omitted. Cannot be set together with reference_image_base64 or style_image_base64 — in those cases the image dimensions determine the output size.
- `name`: Optional[str] (optional) [default: None] — Object name for reference (e.g., 'Treasure Chest', 'Oak Barrel'). Defaults to the description when omitted.
- `view`: Literal["low top-down", "high top-down", "side"] (optional) [default: low top-down] — Camera angle.
- `reference_image_base64`: Optional[str] (optional) [default: None] — Reference image of an OBJECT/item — generates 8 rotations from it. Works well for props (barrels, chests). NOTE: identity transfer is unreliable for CHARACTER/humanoid sprites — the reference sits in the center of a grid of placeholder characters and can lose the salience contest, so the output may resemble a generic character instead. For a character sprite, use create_character(mode="v3", reference_image_base64=...) instead — that pipeline reproduces the input faithfully. Mutually exclusive with style_image_base64.
- `style_image_base64`: Optional[str] (optional) [default: None] — Style reference — generates a new object matching the description with the style of this image. Mutually exclusive with reference_image_base64.
- `style_object_id`: Optional[str] (optional) [default: None] — ID of one of your existing 8-direction objects to use as the style reference. Its 8 directional sprites guide the new object's style in every direction. The style object must be completed with 8 directions, and size must be at least its sprite content size — the job fails fast with the required size otherwise.
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `get_object`
Get object details. Branches by status:
- processing: progress + ETA
- review: candidate frame URLs + inline previews
- completed: rotation URLs, animations, download link
- failed: error + retry hint

**Parameters:**
- `object_id`: str (required) — Object UUID to retrieve
- `include_preview`: bool (optional) [default: True] — Embed preview image (south for 8-dir, candidates for review).

#### `list_objects`
List your objects with status and progress. One line per object.
Use get_object(object_id) for full details.

**Parameters:**
- `limit`: int (1-50) (optional) [default: 10]
- `offset`: int (>=0) (optional) [default: 0]
- `tags`: Optional[str] (optional) [default: None] — Comma-separated tags to filter by (matches ANY tag).
- `status_filter`: Optional[str] (optional) [default: None] — Filter by status: completed, review, pending, processing, failed.
- `search`: Optional[str] (optional) [default: None] — Filter by name, case-insensitive. Matches the name shown here and the description it was created from, so 'chest' finds 'treasure chest'.

#### `animate_object`
Add an animation to an existing object. Returns one queued job per direction
submitted; each job takes ~30-60s.
Cost warning: when generating on a subscription, mode='pro' costs 10-25 generations per direction (80-200 for a full 8-direction animation). Prefer mode='v3' (default) — it usually produces higher quality results and is cheaper.

**Parameters:**
- `object_id`: str (required) — Object UUID to animate (must be a completed object).
- `mode`: Literal["pro", "v3"] (optional) [default: v3] — Which animation mode to use. Prefer 'v3' (default) — it usually produces higher quality results than 'pro', and is cheaper. Use 'pro' only when its different stylistic output is specifically needed.

Cost warning: when generating on a subscription, 'pro' mode costs 10-25 generations per direction (80-200 for a full 8-direction animation).
- `animation_description`: Optional[str] (optional) [default: None] — Describe the animation, e.g. 'walking cheerfully'. Required when creating a new animation; can be omitted when adding directions to an existing animation via animation_group_id (the existing description is inherited).
- `directions`: Optional[list[Literal["south", "south-west", "west", "north-west", "north", "north-east", "east", "south-east"]]] (optional) [default: None] — Which directions to animate.
- Do NOT pass `directions` for 1-direction objects. They always animate the single internal direction; passing this returns an error.
- For 8-direction objects, omit `directions` to animate all 8 cardinals on a new animation, or — when extending an existing animation via `animation_group_id` — to fill in only the cardinals not yet generated. You usually don't need to compute the missing set yourself; passing `animation_group_id` alone is enough. If you do pass `directions` explicitly, it must be a subset of the cardinals.
- `frame_count`: Optional[int] (optional) [default: None] — Frames per direction. Independent per-direction — you do NOT need to match the frame_count of existing directions when extending an animation. Just omit this and use the per-mode default.

- mode='v3': any even number 4-16 (default 8). Note: v3 stores the input reference frame alongside the generated ones (unless keep_first_frame=false), so frame_count=8 stores 9 frames total (and that's what get_object reports). To extend a v3 animation that get_object shows as frame_count=9, just omit this field — the default produces a matching 9-frame output.
- mode='pro' depends on object canvas (longest side):
  - canvas ≤ 64px → 16 frames (only)
  - canvas ≤ 128px → 4, 9, or 16 frames
  - canvas ≤ 170px → 9 frames (only)
  - canvas larger than 170px → pro not supported (use mode='v3')
  - default: smallest available count for the canvas size
- `animation_group_id`: Optional[UUID] (optional) [default: None] — Mostly only relevant for 8-direction objects: pass the animation_group_id of an existing animation (from get_object) to add more directions to it. Omit to create a new animation; the new animation_group_id is returned so subsequent calls can extend it.
- `display_name`: Optional[str] (optional) [default: None] — Optional name for the animation, shown in the UI and used when exporting.
- `replace_existing`: bool (optional) [default: False] — Set true to regenerate a direction that has already been animated in this animation. Without this, re-animating the same direction returns an error.
- `confirm_cost`: bool (optional) [default: False] — Only for pro animations (mode="pro"). NEVER set to true on first call. First call without it to see the cost, then show the cost to the user. Only set to true after the user explicitly confirms they want to spend the generations. Not needed for v3 animations.
- `custom_start_frame_base64`: Optional[str] (optional) [default: None] — Optional custom starting pose for the animation (mode='v3' only). When omitted, the object's idle frame for the chosen direction is used as the start. When provided, the image's dimensions become the canvas for the animation (subject to v3's 256x256 maximum).

REQUIRES EXACTLY ONE DIRECTION.
- 8-direction objects: ASK the user which direction the animation should be for before calling this tool. Do NOT pick a direction yourself, and do NOT default to south. The eight options are: south, south-west, west, north-west, north, north-east, east, south-east. Pass the user's choice as directions=[<that direction>].
- 1-direction objects: do not pass `directions` at all; the single internal direction is auto-resolved.

Not compatible with mode='pro'.
- `end_frame_base64`: Optional[str] (optional) [default: None] — Target pose to interpolate toward (mode='v3' only). The model animates between the start frame (idle or custom_start_frame_base64) and this end frame. Dimensions must match the start frame. Same single-direction requirement as custom_start_frame_base64. Not compatible with mode='pro'.
- `keep_first_frame`: bool (optional) [default: True] — Keep the input reference frame as frame 0 of the stored animation (mode='v3' only). Set false to store exactly frame_count generated frames — the reference start frame is stripped, so frame_count=8 stores 8 frames instead of 9. Not compatible with mode='pro'.
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `create_object_state`
Queue a state (variant) of an existing object. Auto-waits up to 30s for the
source object to complete. Returns a new object ID grouped with the source
via group_id.

**Parameters:**
- `object_id`: str (required) — Source object UUID to create a state of
- `edit_description`: str (required) — Edit instructions (e.g., 'add moss', 'make it golden').
- `seed`: Optional[int] (>=0) (optional) [default: None]
- `state_name`: Optional[str] (optional) [default: None] — Name for the new state (e.g. 'Mossy', 'Golden'). Defaults to the edit description truncated to 20 characters.
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `delete_object`
Permanently delete an object, its rotations/frames, animations, tags,
project assignments, and storage files. Immediate — this cannot be undone.

**Parameters:**
- `object_id`: str (required) — Object UUID to delete

#### `update_object_tags`
Replace ALL tags on an object (set operation, free, synchronous).

**Parameters:**
- `object_id`: str (required) — Object UUID whose tags to replace
- `tags`: list[str] (required) — Full replacement tag list (max 20 tags, 50 chars each; whitespace trimmed, case-insensitive dedup). Empty list clears all tags.

#### `select_object_frames`
Promote selected frames of a review object to individual completed objects.

**Parameters:**
- `object_id`: str (required) — Review-status object UUID
- `indices`: list[int] (required) — 0-based indices of frames to keep. Each becomes a separate completed 1-direction object.
- `common_tag`: Optional[str] (optional) [default: None] — Optional tag applied to every newly-created object.

#### `dismiss_review`
Discard a review-status object and delete all its candidate frames.
Used when none of the consistent-style candidates are worth keeping.

**Parameters:**
- `object_id`: str (required) — Review-status object UUID to discard

#### `place_map_object`
Place objects or characters on a map, at a terrain cell or an exact pixel.

**Parameters:**
- `map_id`: str (required) — Map UUID from list_maps
- `x`: Optional[int] (optional) [default: None] — Terrain cell to stand the object on, as in get_map
- `y`: Optional[int] (optional) [default: None] — Terrain cell to stand the object on, as in get_map
- `world_x`: Optional[int] (optional) [default: None] — Exact position in world pixels, instead of x/y — the space of the map's object boundingBox and the game's sprites
- `world_y`: Optional[int] (optional) [default: None] — Exact position in world pixels
- `anchor`: Optional[Literal["foot", "top_left"]] (optional) [default: None] — What world_x/world_y name: 'foot' (default) = the sprite's bottom-centre; 'top_left' = the box origin, box_px in list_map_objects
- `object_id`: Optional[str] (optional) [default: None] — Object UUID from list_objects (or create_map_object)
- `character_id`: Optional[str] (optional) [default: None] — Character UUID from list_characters
- `direction`: Optional[str] (optional) [default: None] — Facing for a character (south, north, east...). Leave unset for objects — most have a single sprite and it is picked automatically.
- `layer`: Optional[int] (optional) [default: None] — Draw order; higher is on top. Defaults to the next layer.
- `placements`: Optional[list[ObjectPlacement]] (optional) [default: None] — Place many in one call, instead of the single-placement arguments: [{"object_id":"…","x":3,"y":4}, {"object_id":"…","world_x":412,"world_y":230,"anchor":"foot"}, {"character_id":"…","x":1,"y":1,"direction":"south"}]. Each item takes the same fields as above. One save for all; if any item is invalid nothing is placed.
- `show`: bool (optional) [default: True] — Return a rendered image of the placement

#### `list_map_objects`
List the objects and characters placed on a map, with their cell positions.

**Parameters:**
- `map_id`: str (required) — Map UUID from list_maps
- `search`: Optional[str] (optional) [default: None] — Filter by name, case-insensitive
- `limit`: int (1-200) (optional) [default: 50] — Max rows to return
- `offset`: int (>=0) (optional) [default: 0] — Pagination offset

#### `move_map_object`
Move a placed object or character to a different cell or an exact pixel, or
change its layer.

**Parameters:**
- `map_id`: str (required) — Map UUID from list_maps
- `placement_id`: str (required) — Placement id from list_map_objects
- `x`: Optional[int] (optional) [default: None] — Cell to stand it on, as in get_map
- `y`: Optional[int] (optional) [default: None] — Cell to stand it on, as in get_map
- `world_x`: Optional[int] (optional) [default: None] — Exact position in world pixels, instead of x/y
- `world_y`: Optional[int] (optional) [default: None] — Exact position in world pixels
- `anchor`: Optional[Literal["foot", "top_left"]] (optional) [default: None] — What world_x/world_y name: 'foot' (default) = the sprite's bottom-centre; 'top_left' = the box origin, box_px in list_map_objects
- `layer`: Optional[int] (optional) [default: None] — New draw order (higher is on top). Pass it alone to change only the layer: the stored position, fractions included, is untouched.
- `show`: bool (optional) [default: True] — Return a rendered image of the result

#### `remove_map_object`
Remove placed objects or characters from a map.

**Parameters:**
- `map_id`: str (required) — Map UUID from list_maps
- `placement_id`: Optional[str] (optional) [default: None] — One placement id from list_map_objects
- `asset_id`: Optional[str] (optional) [default: None] — Remove EVERY placement of this object or character instead — the asset_id column in list_map_objects. Use it to clear one prop from a whole map in a single call.

### Chat & Agent Tools

**💡 Tips:**
- Send messages to the PixelLab game-building agent
- Agent can build games, create assets, deploy projects
- `chat_send_message` blocks until the agent finishes (30s-5min typical)
- Omit `conversation_id` to start a new conversation

#### `chat_list_conversations`
List your chat conversations. Excludes branches. Shows processing status.

**Parameters:**
- `limit`: int (1-100) (optional) [default: 20] — Max conversations to return
- `offset`: int (>=0) (optional) [default: 0] — Pagination offset
- `project_id`: Optional[str] (optional) [default: None] — Filter by project ID

#### `chat_get_messages`
Get messages from a conversation. Strips HTML from assistant responses.

**Parameters:**
- `conversation_id`: str (required) — Conversation ID
- `limit`: int (1-100) (optional) [default: 30] — Max messages to return
- `offset`: int (>=0) (optional) [default: 0] — Pagination offset

#### `chat_send_message`
Send a message and get the agent's response.
Creates a conversation if needed. Blocks until the agent finishes (up to 10 min).

**Parameters:**
- `content`: str (required) — Message to send to the agent
- `conversation_id`: Optional[str] (optional) [default: None] — Conversation ID. Omit to create a new conversation.
- `project_id`: Optional[str] (optional) [default: None] — Project ID (used when creating a new conversation)

### Sandbox Tools (Code Execution)

**💡 Tips:**
- Create isolated dev environments for building games
- Each session has Node.js, TypeScript, git
- Deploy games to *.dev.pixellab.run URLs

#### `sandbox_create_session`
Create a sandbox session and return initial workspace state.

**Parameters:**
- `project_id`: str (required)
- `branch_name`: str (optional) [default: main]

#### `sandbox_destroy_session`
Destroy a sandbox session.

**Parameters:**
- `session_id`: str (required)
- `sync`: bool (optional) [default: True]

#### `sandbox_bash`
Execute a shell command.

**Parameters:**
- `session_id`: str (required)
- `command`: str (required)
- `timeout`: int (optional) [default: 300]

#### `sandbox_run`
Run JS in the sandbox with a typed file/shell API (Code Mode).

**Parameters:**
- `session_id`: str (required)
- `code`: str (required)

#### `sandbox_read`
Read a file.

**Parameters:**
- `session_id`: str (required)
- `path`: str (required)
- `offset`: Optional[int] (optional) [default: None]
- `limit`: Optional[int] (optional) [default: None]

#### `sandbox_write`
Write a file.

**Parameters:**
- `session_id`: str (required)
- `path`: str (required)
- `content`: str (required)
- `force`: bool (optional) [default: True]

#### `sandbox_edit`
Edit a file via search-and-replace.

**Parameters:**
- `session_id`: str (required)
- `path`: str (required)
- `old_string`: str (required)
- `new_string`: str (required)

#### `sandbox_sync`
Sync git to B2 storage.

**Parameters:**
- `session_id`: str (required)

#### `sandbox_deploy_worker`
Build and deploy a Cloudflare Worker for a project.

**Parameters:**
- `session_id`: str (required)
- `project_slug`: str (required)
- `project_id`: str (required)

#### `sandbox_undeploy`
Delete S3 objects for a deployed branch and invalidate the CloudFront distribution.

**Parameters:**
- `project_slug`: Optional[str] (optional) [default: None]
- `project_id`: Optional[str] (optional) [default: None]
- `branch_name`: str (optional) [default: main]

#### `sandbox_playtest`
Run a visual playtest of a deployed game, in the session's own browser.

**Parameters:**
- `session_id`: str (required)
- `instruction`: str (required)
- `preview_url`: str (required)

#### `sandbox_read_image`
Read an image from a sandbox session and get a vision model analysis.

**Parameters:**
- `session_id`: str (required) — Sandbox session ID.
- `path`: str (required) — Path to the image file in the sandbox (e.g. 'game/assets/player.png').
- `question`: str (optional) [default: Describe this image in detail.] — What to analyze about the image — be specific (e.g. 'Is the player sprite facing south?', 'What colors are used in this tileset?').

### Other Tools

#### `create_image_pro_flash`
Create one Pro Flash pixel-art image with an optional left-box style image.
Cost: by LONGEST SIDE — 5 generations up to 96px, 6 from 100 to 208, 9 from 212 to 256, for one image. A non-square canvas goes by its longer side, so 128x72 is 6 and 32x96 is 5. This is the whole Pro Flash ladder (create, edit and inpaint charge the same), and it is NOT the Pro tools' 10/15/25 tier. No parameter caps a charge, and the quote is labelled provisional rather than a contractual cap — but the ladder above is what actually gets billed, so treat those figures as the price. get_pro_flash_capabilities(operation=, width=, height=) prices an exact size for free before you spend.

**Parameters:**
- `description`: str (required)
- `width`: int (optional) [default: 64]
- `height`: int (optional) [default: 64]
- `no_background`: bool (optional) [default: True]
- `style_image`: Optional[ProFlashReferenceInput] (optional) [default: None]
- `style_options`: Optional[ProFlashStyleOptions] (optional) [default: None]
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]
- `seed`: int (optional) [default: 0]
- `project_id`: Optional[str] (optional) [default: None]

#### `edit_image_pro_flash`
Edit one Pro Flash image at its unchanged native canvas size.
Cost: by the SOURCE canvas's longest side — 5 generations up to 96px, 6 from 100 to 208, 9 from 212 to 256, for one image. The same ladder as Pro Flash create and inpaint, and cheaper than edit_image's 10/15/25 tier at every size. get_pro_flash_capabilities(operation="edit", width=, height=) prices an exact size for free.

**Parameters:**
- `description`: Optional[str] (optional) [default: None]
- `image_base64`: Optional[str] (optional) [default: None]
- `image_url`: Optional[str] (optional) [default: None]
- `source_image_id`: Optional[str] (optional) [default: None]
- `method`: Literal["text", "reference"] (optional) [default: text]
- `reference_image`: Optional[ProFlashReferenceInput] (optional) [default: None]
- `no_background`: Optional[bool] (optional) [default: None]
- `use_color_palette_correction`: bool (optional) [default: False]
- `seed`: int (optional) [default: 0]
- `project_id`: Optional[str] (optional) [default: None]

#### `inpaint_image`
Regenerate one region of an image, keeping everything else pixel-identical.
Cost: 10 generations for any SQUARE canvas up to 256x256 (so 64x64 and 88x88 are both 10), 15 up to 341x341, 25 above. The whole image sets the price, not the mask. A non-square canvas is measured at its own aspect ratio, which is more generous than its longest side — do not read the square bands off the longer edge: 360x168 is 10 and 168x360 is 15, where the longest side alone would say 25 for both.
Generation time: ~30-90 seconds (async). Poll with get_image(job_id).

**Parameters:**
- `description`: str (required) — What should appear in the masked area (e.g. 'a clean four-finger hand holding a sword', 'plain grass, no object').
- `image_base64`: Optional[str] (optional) [default: None] — Base64 PNG to repair. 32x32 to 512x512. Everything outside the mask is preserved exactly. PREFER image_url — MCP clients routinely truncate large inline base64, which corrupts the image.
- `image_url`: Optional[str] (optional) [default: None] — Alternative to image_base64: an https (or data:) URL to the PNG to repair. PREFER THIS for anything but a tiny sprite — inline base64 is often cut off mid-string by MCP clients. Give one, not both.
- `mask_x`: Optional[int] (optional) [default: None] — Left edge of the rectangular area to regenerate.
- `mask_y`: Optional[int] (optional) [default: None] — Top edge of the rectangular area to regenerate.
- `mask_width`: Optional[int] (>=1) (optional) [default: None] — Width of the area to regenerate.
- `mask_height`: Optional[int] (>=1) (optional) [default: None] — Height of the area to regenerate.
- `mask_image_base64`: Optional[str] (optional) [default: None] — Custom mask, same size as the image: WHITE = regenerate, BLACK = keep. Use instead of mask_x/y/width/height when the area isn't a rectangle.
- `mask_image_url`: Optional[str] (optional) [default: None] — Alternative to mask_image_base64: an https (or data:) URL to the mask PNG. Give one, not both.
- `crop_to_mask`: bool (optional) [default: True] — Confine generated content to the mask boundary for clean edges.
- `no_background`: Optional[bool] (optional) [default: None] — Background handling. Default (unset) follows the input: a sprite with transparency stays transparent, an opaque image stays opaque. Pass False to flatten a transparent input onto white.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `inpaint_image_pro_flash`
Replace white-mask pixels with Pro Flash, preserving unmasked RGBA bytes exactly.
Cost: by the SOURCE canvas's longest side, not the mask — 5 generations up to 96px, 6 from 100 to 208, 9 from 212 to 256, for one image. So a 64x64 repair is 5 and 128x64 is 6, against inpaint_image's 10 for either. Shrinking the mask does not lower it. get_pro_flash_capabilities(operation="inpaint", width=, height=) prices an exact size for free.

**Parameters:**
- `description`: str (required)
- `image_base64`: Optional[str] (optional) [default: None]
- `image_url`: Optional[str] (optional) [default: None]
- `source_image_id`: Optional[str] (optional) [default: None]
- `mask_x`: Optional[int] (optional) [default: None]
- `mask_y`: Optional[int] (optional) [default: None]
- `mask_width`: Optional[int] (optional) [default: None]
- `mask_height`: Optional[int] (optional) [default: None]
- `mask_image_base64`: Optional[str] (optional) [default: None]
- `mask_image_url`: Optional[str] (optional) [default: None]
- `context_image`: Optional[ProFlashReferenceInput] (optional) [default: None]
- `bounding_box`: Optional[ProFlashBoundingBox] (optional) [default: None]
- `crop_to_mask`: Literal[True] (optional) [default: True]
- `no_background`: Optional[bool] (optional) [default: None]
- `background_removal_task`: Literal["remove_simple_background", "remove_complex_background"] (optional) [default: remove_simple_background]
- `output_method`: Literal["New layer with changes", "Modify current layer, only changes", "Modify current layer"] (optional) [default: Modify current layer]
- `seed`: int (optional) [default: 0]
- `project_id`: Optional[str] (optional) [default: None]

#### `get_pro_flash_capabilities`
Get Pro Flash exact native size pairs, controls and one-image output counts.

**Parameters:**
- `operation`: Optional[Literal["create", "edit", "inpaint", "character", "object"]] (optional) [default: None]
- `width`: Optional[int] (optional) [default: None]
- `height`: Optional[int] (optional) [default: None]
- `n_directions`: int (optional) [default: 8]

#### `add_to_project`
Let a game project use a character, object, tileset or map you already own,
or file an asset (gallery images too) into a game or folder on the website.

**Parameters:**
- `project_id`: str (required) — A game or folder project, from list_projects
- `asset_id`: str (required) — A character, object, tileset, map or gallery image you own — the id from list_characters, list_objects, list_topdown_tilesets, list_maps or list_images — or a saved VFX effect id (My effects)

#### `remove_from_project`
Stop a game project from using a character, object, tileset or map.

**Parameters:**
- `project_id`: str (required) — The game project, from list_projects
- `asset_id`: str (required) — A character, object, tileset or map currently in the project — the id you passed to add_to_project

#### `delete_animation`
Delete animations from a character or object. Removes storage files and database rows.
Use get_character()/get_object() first to see available animations. Omit direction to
delete all directions at once. For objects, animation_group_id (from get_object) can
be passed instead of animation_type.

**Parameters:**
- `character_id`: str (required) — Character or object UUID
- `animation_type`: Optional[str] (optional) [default: None] — Animation name to delete. Characters: animation type (e.g. 'walk', 'idle', 'attack'), see get_character(). Objects: the animation name shown by get_object(). Required unless animation_group_id is provided.
- `direction`: Optional[str] (optional) [default: None] — Specific direction to delete (e.g. 'south'). Omit to delete all directions of this animation.
- `animation_group_id`: Optional[UUID] (optional) [default: None] — Animation group UUID, shown by get_character()/get_object() as [group: ...]. Selects one animation unambiguously (preferred over animation_type when a name repeats); deletes all its directions unless direction is set.

#### `create_ui_asset`
Queue a pixel-art UI panel (10-25 generations, ~2-4 min). Returns ui_asset_id immediately.
Omit `pieces` for a default rounded-rect panel. Use get_ui_asset to check status.
For a fixed palette (Game Boy, PICO-8, any palette from Lospec) pass `palette` as
its hex colours: the panel is drawn for them and every pixel is one of them.
Cost: 10 generations for a canvas up to 256x256, 15 up to 341x341, 25 above — so the 256x256 default is the cheap option and 512x512 is 25. A non-square panel is measured at its own aspect ratio, which is more generous than its longer side: a 16:9 panel is 10 up to 341x192, 15 to 456x256, 25 from 457 wide. There is no quote endpoint; the response reports the actual charge.

**Parameters:**
- `description`: str (required) — Style of the UI panel (e.g. 'wooden RPG panel with gold trim')
- `width`: int (192-688) (optional) [default: 256] — Output width in px (192–688). Max is aspect-gated, NOT freely combinable: square ≤512×512, 16:9 ≤688×384, 9:16 ≤384×688, 4:3 ≤600×448, 3:4 ≤448×600. E.g. 688×512 is rejected (resolves to 4:3, max 600×448) — use 688×384 or 512×512.
- `height`: int (192-688) (optional) [default: 256] — Output height in px (192–688). Max is aspect-gated (see width): the two axis maxes cannot be combined — 688 only with a 16:9/9:16 partner (688×384 or 384×688), 512 only as a square (512×512).
- `color_palette`: Optional[str] (optional) [default: None] — Optional palette hint (e.g. 'brown and gold')
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]
- `style_image_base64`: Optional[str] (optional) [default: None] — Optional style reference image (base64 PNG/JPEG, ideally <=1024px per side). The panel matches its palette, pixel scale, outlines and shading — the strongest way to make UI fit an existing game. Only the art style is copied, never its content or layout.
- `no_background`: bool (optional) [default: True] — Remove background after generation
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible output
- `name`: Optional[str] (optional) [default: None] — Friendly name for the saved asset
- `project_id`: Optional[str] (optional) [default: None] — Optional PixelLab project ID to assign the finished UI asset to
- `elements`: Optional[list[str]] (optional) [default: None] — Named UI element types to scaffold the panel from (auto-positioned, no coords needed). Available: button, icon_button, toolbar, tab, panel, window, health_bar, avatar, triangle, pentagon, hexagon, octagon. Combine with `pieces` for custom shapes; omit both for a default panel.
- `pieces`: Optional[list[UiPieceRect | UiPieceCircle | UiPiecePolygon]] (optional) [default: None] — Advanced shape template (validated). Each piece needs a unique `id`, a `kind`, and an optional `label`. Allowed kinds: rounded_rect {x,y,w,h,radius}, circle {x,y,r}, polygon {x,y,r,sides,phase}. Coords are on a virtual editor canvas — longer side 0–512, shorter side scaled to the output aspect (a 16:9 panel uses a 512×288 coordinate grid, not the output size). Omit for a default full-canvas panel.

#### `get_ui_asset`
Get UI panel details. Processing → progress; completed → image URL + download.

**Parameters:**
- `ui_asset_id`: str (required) — UI asset UUID to retrieve
- `include_preview`: bool (optional) [default: True] — Embed the panel image inline.

#### `list_ui_assets`
List your UI panels with status. One line per asset.
Use get_ui_asset(ui_asset_id) for full details.

**Parameters:**
- `limit`: int (1-50) (optional) [default: 10]
- `offset`: int (>=0) (optional) [default: 0]

#### `delete_ui_asset`
Permanently delete a UI panel (and, for a template, its split elements + their
states) plus the backing image files. Immediate — this cannot be undone.

**Parameters:**
- `ui_asset_id`: str (required) — UI asset UUID to delete

#### `search_help`
Ask for help using PixelLab MCP tools, workflows, or features.
A knowledge agent searches our docs and returns a concise answer.

**Parameters:**
- `question`: str (required) — What you need help with (tools, workflows, billing, features, deployment). Include the context you are working in. Max 2000 characters.

#### `agent_feedback`
Report something broken, confusing or missing — a PixelLab tool, the sandbox
(build, deploy, git, playtest), the game template code, or the website.
Specific beats polite. Read daily by the team.

**Parameters:**
- `tool_name`: str (required) — What it's about: a tool, command or file (e.g. 'create_character', 'wrangler deploy', 'src/scenes/Game.ts').
- `feedback_type`: Literal["bug", "confusing", "suggestion", "missing_feature"] (required) — Type of feedback.
- `message`: str (required) — What you did, what happened, what you expected. Be specific.
- `area`: Optional[Literal["generation", "chat_tool", "template", "sandbox", "website", "other"]] (optional) [default: None] — Rough bucket, helps route it: generation (art tools), chat_tool, template (the game template's code), sandbox (build, deploy, git, playtest), website, other.

#### `create_tiles_pro`
Create pixel art tiles (pro).
Generation time: ~1-2 minutes (async processing)

**Parameters:**
- `description`: str (required) — Text description of the tiles. For best control, number each tile: '1). grass tile 2). stone tile 3). lava tile'. At most 16 independent tiles per call: split a longer list.
- `tile_type`: Literal["hex", "hex_pointy", "isometric", "oblique", "octagon", "square_topdown"] (optional) [default: isometric] — Shape of the tiles. hex: flat-top hexagonal, hex_pointy: pointy-top hexagonal, isometric: diamond/rhombus, oblique: true square top with the depth extruded diagonally down-right at 45 degrees (tile_feature='tileset' or 'building' only), octagon: 8-sided polygon, square_topdown: square at angle.
- `tile_size`: int (16-128) (optional) [default: 32] — Tile size in pixels (16-128). 32px is recommended for most use cases.
- `tile_height`: Optional[int] (16-256) (optional) [default: None] — Tile height in pixels for non-square tiles (e.g., 128 for 64x128). Omit to compute from tile_type geometry and view angle. Maps (create_map, Map Workshop) take groups made without tile_height, or with tile_size or 2x it. A flat 2:1 iso floor still goes on a map: omit tile_height, set tile_view_angle=30 and tile_depth_ratio=0.
- `tile_view`: Literal["top-down", "high top-down", "low top-down", "side"] (optional) [default: low top-down] — View angle controlling tile depth. top-down: no depth, high top-down: ~15%, low top-down: ~30%, side: ~50%.
- `tile_view_angle`: Optional[float] (0-90) (optional) [default: None] — Continuous view angle in degrees (0-90). Overrides tile_view when provided. 0=side, 90=top-down.
- `tile_depth_ratio`: Optional[float] (0.0-1.0) (optional) [default: None] — Tile depth/thickness ratio (0.0-1.0). Controls vertical depth. Overrides default from tile_view.
- `tile_flat_top_px`: Optional[int] (2-8) (optional) [default: None] — Isometric top/bottom cap width: 2px classic or 4px modern. Only used when tile_type='isometric'.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation
- `style_images`: Optional[list[dict]] (optional) [default: None] — Style reference tiles as JSON array. When provided, tiles match the style and dimensions of these references. Shape controls (tile_type, tile_size, tile_view, etc.) are ignored. Each entry is {"image": "<reference>"} — an https URL, upload:<id>, gallery:<id>, job:<id>[:<index>] or a pixel tool result id; the size is read from the image, and a reference avoids inline base64 being cut off by the client — or inline {"base64": "...", "width": 64, "height": 80}.
- `style_options`: Optional[str] (optional) [default: None] — Options for what to copy from style images, as JSON. Format: {"color_palette": true, "outline": true, "detail": true, "shading": true}
- `outline_mode`: Literal["outline", "segmentation"] (optional) [default: outline] — Tile outline mode. "outline" = gray shading with outlines (default). "segmentation" = RED/BLUE color zones without outlines — produces cleaner tiles with no outline artifacts.
- `tile_feature`: Optional[Literal["tileset"]] (optional) [default: None] — Set to "tileset" to generate a connectable TERRAIN TRANSITION instead of independent tiles: a 16-tile corner set for isometric/square_topdown/oblique, or a 32-tile coastline for hex/hex_pointy. Describe it as a transition ("grass to water") — the first terrain is the main one. Returns per-tile placement rules (see get_tiles_pro). Cannot be combined with style_images. For square top-down transitions, create_topdown_tileset is the dedicated tileset model and adds transition width, per-terrain reference images and style matching. For paths use create_path_tiles; for walls/floors use create_building_kit.
- `oblique_lean`: Optional[float] (0.0-1.0) (optional) [default: None] — Oblique tilesets only: horizontal shear per pixel of depth. 0.5 = classic cabinet (~27 degrees), 1.0 = a full 45 degree diagonal (default).
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `create_path_tiles`
Create a connectable PATH/ROAD tile set (18 configs).

**Parameters:**
- `description`: str (required) — Ground and path, e.g. "grass with a dirt road" or "stone floor with a mosaic walkway". Describe both — the set renders the path over the ground.
- `tile_type`: Literal["square_topdown", "isometric"] (optional) [default: square_topdown] — Tile shape. square_topdown: square tiles at an angle. isometric: diamond/rhombus.
- `tile_size`: int (32-96) (optional) [default: 32] — Tile size in pixels. square_topdown requires exactly 32; isometric accepts 48-96.
- `tile_view_angle`: Optional[float] (0-90) (optional) [default: None] — Camera elevation in degrees (0=side, 90=straight down).
- `tile_depth_ratio`: Optional[float] (0.0-1.0) (optional) [default: None] — Tile thickness as a fraction of tile size.
- `outline_mode`: Literal["outline", "segmentation"] (optional) [default: outline] — "outline" = gray shading with outlines. "segmentation" = color zones, cleaner seamless edges.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `create_building_kit`
Create a BUILDING KIT — floor, connectable walls, doorways, pillar, stairs.

**Parameters:**
- `wall_description`: str (required) — Wall material, e.g. "stone brick walls" or "weathered timber walls".
- `floor_description`: str (required) — Floor material, e.g. "wooden plank floor" or "flagstone floor".
- `tile_type`: Literal["isometric", "square_topdown", "oblique"] (optional) [default: isometric] — Projection. isometric: diamond lattice. square_topdown: plain square grid. oblique: true square top with walls sheared down-right at 45 degrees.
- `tile_size`: int (16-96) (optional) [default: 32] — Tile size in pixels. isometric requires 32-96; square_topdown and oblique accept 16-96.
- `wall_tiles`: int (1-3) (optional) [default: 2] — Wall height in tiles (1-3).
- `floor2_description`: Optional[str] (optional) [default: None] — Upper-storey / roof surface material: paints the flat upper-floor tile (floor_roof) and the roof pieces. Defaults to the wall material. It sets the material only, not the roof's shape — see roof_profile.
- `roof_profile`: Optional[Literal["gable", "round"]] (optional) [default: None] — Shape of the roof pieces' edges (materials layout only): gable = straight slope, round = curved. Each edge rises over half a tile and the roof is flat inside, so only a one-tile-wide roof peaks. There is no flat roof piece; for a flat roof or a roof terrace, lay the upper-floor tile (floor_roof) on top of the walls. Default gable.
- `layout`: Optional[Literal["grid", "materials"]] (optional) [default: None] — grid: each shaped piece is painted individually (richer; isometric default). materials: flat swatches are painted and pieces rendered from them (more consistent; default for square_topdown/oblique).
- `wall_angle`: Optional[float] (5-90) (optional) [default: None] — square_topdown only: wall storey height as its own camera angle, decoupled from the ground pitch.
- `oblique_lean`: Optional[float] (0.0-1.0) (optional) [default: None] — Wall shear per pixel of height. 0.5 = classic cabinet (~27 degrees), 1.0 = a full 45 degree diagonal.
- `tile_view_angle`: Optional[float] (0-90) (optional) [default: None] — Camera elevation in degrees.
- `outline_mode`: Literal["outline", "segmentation"] (optional) [default: outline] — "outline" = gray shading with outlines. "segmentation" = color zones, cleaner seamless edges.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `get_tiles_pro`
Get tiles pro by ID. Returns tile data and storage URLs if completed, or progress if processing.

**Parameters:**
- `tile_id`: str (required) — The UUID of the tiles pro to retrieve. Each returned tile carries the placement rule its sheet uses; the bit meanings are edge/4: bit0=N bit1=E bit2=S bit3=W; a set bit means the painted feature continues across that edge; edge/6: 6 hex edges CCW from vertex 0; a set bit means the OTHER terrain (water) lies beyond that edge; corner/4: NW<<3 | NE<<2 | SW<<1 | SE; a set bit means the first terrain occupies that corner.

#### `list_tiles_pro`
List your tiles (pro). One line per tile with status.
Use get_tiles_pro(tile_id) for full details.

**Parameters:**
- `limit`: int (1-50) (optional) [default: 10] — Maximum number of tiles to return
- `offset`: int (>=0) (optional) [default: 0] — Number of tiles to skip

#### `delete_tiles_pro`
Delete tiles pro by ID. Only the owner can delete their own tiles.

**Parameters:**
- `tile_id`: str (required) — The UUID of the tiles pro to delete

#### `create_portrait_character`
Convert between a portrait and a character sprite (pro).
Generation time: ~30-80 seconds (async processing)

**Parameters:**
- `image`: Optional[str] (optional) [default: None] — Input image as base64-encoded PNG. PREFER image_url because MCP/LLM clients can alter or truncate opaque base64 tool arguments.
- `image_url`: Optional[str] (optional) [default: None] — Public HTTPS URL or data URL for the input image. Prefer this over image so the original bytes do not pass through the model.
- `direction`: Literal["portrait_to_character", "character_to_portrait"] (optional) [default: portrait_to_character] — portrait_to_character: portrait in → full-body character sprite out. character_to_portrait: character in → bust portrait out.
- `view`: Literal["low top-down", "high top-down", "side"] (optional) [default: low top-down] — Camera angle. low top-down: classic 3/4 RPG. high top-down: steeper. side: eye-level sidescroller.
- `result_size`: Literal[16, 32, 48, 64, 128, 160] (optional) [default: 64] — Output sprite size in pixels. Cost: 16/32/48/64 = 10 generations; 128/160 are drawn with extra detail = 15 generations.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `get_portrait_character`
Get a portrait ↔ character result by job id.

**Parameters:**
- `job_id`: str (required) — The job id returned by create_portrait_character.

#### `set_character_portrait`
Attach a bust portrait to a character (no generation, free).

**Parameters:**
- `character_id`: str (required) — Character to attach the portrait to.
- `image`: Optional[str] (optional) [default: None] — Portrait as base64-encoded PNG. Square is ideal; a non-square image is centred on a transparent square canvas.
- `from_job_id`: Optional[str] (optional) [default: None] — Instead of `image`: the job id of a completed create_portrait_character run. The sprite is copied straight across, so it never has to pass through your context.

#### `create_vocal_animation`
Generate a talking mouth-position set ("visemes") for a character's portrait.
Generation time: ~2-5 minutes (async processing)

**Parameters:**
- `character_id`: Optional[str] (optional) [default: None] — Character to generate the expression for; it must already have a portrait, and the finished set is saved onto it so later calls only need the character id. Mutually exclusive with `image`.
- `image`: Optional[str] (optional) [default: None] — Generate from this portrait PNG (base64) instead, without a character. Nothing is stored: the mouth positions come back from get_vocal_animation and you pass that job id to create_talking_gif. Use this when the user only has a portrait. Mutually exclusive with `character_id`. Max 256x256.
- `mood`: Literal["neutral", "happy", "angry", "sad", "surprised"] (optional) [default: neutral] — Expression baked into the face (brows/eyes/cheeks). The mouth shapes are the same across moods. One call per mood; each is stored as its own row of the character's vocal grid.
- `viseme_count`: Literal[3, 5, 7, 12] (optional) [default: 7] — How many mouth positions to generate. 3 = minimal (tiny portraits), 5 = basic, 7 = recommended, 12 = high quality (large close-ups). Must match across moods for the same character.
- `no_background`: bool (optional) [default: True] — Cut out the background so frames are transparent PNGs — usually what you want for compositing over a game scene.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.

#### `get_vocal_animation`
Check a vocal-animation job and see which mouth positions have landed.

**Parameters:**
- `job_id`: str (required) — The job id returned by create_vocal_animation.

#### `create_talking_gif`
Turn text into a talking GIF using a character's existing mouth positions.

**Parameters:**
- `text_to_speak`: str (required) — The line of dialogue to lip-sync. Mouth shapes are derived from the letters, so any language using the latin alphabet works.
- `character_id`: Optional[str] (optional) [default: None] — Character with a vocal animation. Mutually exclusive with `from_job_id`.
- `from_job_id`: Optional[str] (optional) [default: None] — Use a portrait-only set instead: the job id from create_vocal_animation(image=...). Mutually exclusive with `character_id`. Available for 8 hours after that job finished.
- `mood`: Optional[Literal["neutral", "happy", "angry", "sad", "surprised"]] (optional) [default: None] — Which generated expression to talk with. Defaults to the character's first available expression.
- `frame_ms`: int (20-500) (optional) [default: 90] — Milliseconds per mouth position (~90ms reads as natural speech; raise it for a slower delivery). GIF stores delays in 10ms steps, so this is rounded to the nearest 10 and the response reports what was actually used.
- `hold_ms`: int (0-5000) (optional) [default: 600] — Pause on the closed mouth at the end so a looping GIF has a beat between takes.

#### `get_lip_sync`
Get the lip-sync frame plan for a line of dialogue — for animating in a game.

**Parameters:**
- `character_id`: str (required) — Character with a vocal animation (see create_vocal_animation). This tool is character-only on purpose: it hands the engine a spritesheet URL to load, and a portrait-only set has no stored spritesheet — for that case use create_talking_gif(from_job_id=...) instead.
- `text_to_speak`: str (required) — The line of dialogue to lip-sync.
- `mood`: Optional[Literal["neutral", "happy", "angry", "sad", "surprised"]] (optional) [default: None] — Which generated expression to use. Defaults to the character's first available expression.
- `frame_ms`: int (1-5000) (optional) [default: 90] — Milliseconds to hold each mouth position.
- `hold_ms`: int (0-10000) (optional) [default: 600] — Extra time on the final closed mouth.

#### `create_font`
Create a pixel-art font (pro).
Generation time: ~30-80 seconds (async processing)

**Parameters:**
- `description`: str (required) — Style description of the font, e.g. 'warm orange arcade font'.
- `weight`: Literal["Bold", "Regular"] (optional) [default: Regular] — Stroke weight. Guides glyph thickness.
- `glyph_px`: Literal[8, 12, 16, 24, 32, 64] (optional) [default: 16] — Native glyph resolution in pixels (real bitmap size per glyph). The atlas is a 10x8 grid of 80 glyphs, ROW-MAJOR, so cell i holds the i-th character of "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,!?:;'"-+()0123456789/%*=_$" — slice it with that order. There is no space glyph.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `font_name`: Optional[str] (optional) [default: None] — Explicit font family name; defaults to '{description} {weight}'.

#### `get_font`
Get a font result by job id.

**Parameters:**
- `job_id`: str (required) — The job id returned by create_font.

#### `create_image_pixflux`
Generate a freeform pixel-art image from text (no character/object rig).
Cost: 1 generation. Generation time: ~10-40 seconds (async). Poll with get_image(job_id).

**Parameters:**
- `description`: str (required) — What to draw (e.g. 'cute dragon', 'health potion bottle').
- `width`: Optional[int] (16-400) (optional) [default: None] — Canvas width in pixels. Defaults to the init_image width, or 128 when there is no init_image. The 16px floor is per-axis: the TOTAL area must still be at least 32x32=1024px, so 16x16 is rejected while 16x64 is fine.
- `height`: Optional[int] (16-400) (optional) [default: None] — Canvas height in pixels. Defaults to the init_image height, or 128 when there is no init_image. See width for the area rule.
- `no_background`: Optional[bool] (optional) [default: None] — Return the subject on a transparent background. Use True for sprites/items, False for scenes and backgrounds. Unset with an init_image follows that image; unset without one means False.
- `view`: Optional[Literal["side", "low top-down", "high top-down"]] (optional) [default: None] — Camera angle (weakly guiding).
- `direction`: Optional[Literal["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]] (optional) [default: None] — Which way the subject faces (weakly guiding).
- `isometric`: bool (optional) [default: False] — Draw in isometric projection (weakly guiding).
- `outline`: Optional[Literal["single color black outline", "single color outline", "selective outline", "lineless"]] (optional) [default: None] — Outline style (weakly guiding).
- `shading`: Optional[Literal["flat shading", "basic shading", "medium shading", "detailed shading", "highly detailed shading"]] (optional) [default: None] — Shading style (weakly guiding).
- `detail`: Optional[Literal["low detail", "medium detail", "highly detailed"]] (optional) [default: None] — Detail level (weakly guiding).
- `text_guidance_scale`: float (1.0-20.0) (optional) [default: 8.0] — How literally to follow the description. Higher = more literal.
- `init_image_base64`: Optional[str] (optional) [default: None] — Base64 PNG to start from (img2img). Must be exactly width x height — omit width/height to adopt its size.
- `init_image_url`: Optional[str] (optional) [default: None] — Alternative to init_image_base64: an https (or data:) URL to the init PNG. PREFER THIS for anything but a tiny sprite. Give one, not both.
- `init_image_strength`: int (1-999) (optional) [default: 150] — How much of init_image is PRESERVED — the opposite of the usual img2img 'strength'. Higher = closer to the input: 500 barely changes it, 300 is subtle, 150 (default) is a real edit, ~50 keeps only the composition.
- `color_image_base64`: Optional[str] (optional) [default: None] — Base64 PNG whose colors become a forced palette. Any size — only its colors are read.
- `color_image_url`: Optional[str] (optional) [default: None] — Alternative to color_image_base64: an https (or data:) URL to the palette PNG. Give one, not both.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `create_image_pixen`
Generate a freeform pixel-art image with the Pixen model.
Cost: 1 generation. Generation time: ~10-40 seconds (async). Poll with get_image(job_id).

**Parameters:**
- `description`: str (required) — What to draw (e.g. 'ornate iron key', 'mossy stone wall').
- `width`: int (16-768) (optional) [default: 128] — Canvas width in pixels. Must be a multiple of 4; width must equal height when either side is below 32. width x height may not exceed 512x512 = 262,144, so the widest canvases are e.g. 768x340 or 680x384, not 768x384.
- `height`: int (16-768) (optional) [default: 128] — Canvas height in pixels. Must be a multiple of 4; height must equal width when either side is below 32.
- `no_background`: bool (optional) [default: False] — Return the subject on a transparent background. True for sprites and items, False for scenes. Up to 256x256 of area (65,536 px, e.g. 256x256 or 512x128); larger canvases are refused with it on.
- `view`: Optional[Literal["side", "low top-down", "high top-down"]] (optional) [default: None] — Camera angle (weakly guiding).
- `direction`: Optional[Literal["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]] (optional) [default: None] — Which way the subject faces (weakly guiding).
- `outline`: Optional[Literal["single color black outline", "single color outline", "selective outline", "lineless"]] (optional) [default: None] — Outline style (weakly guiding).
- `detail`: Optional[Literal["low detail", "medium detail", "highly detailed"]] (optional) [default: None] — Detail level (weakly guiding).
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `create_image_pro`
Generate pixel art with the Pro model — best quality, several candidates.
Cost: 10-25 generations for the CALL, never multiplied by the candidate count. The rule is one step: the sheet is your canvas times the candidates per side, and you pay that sheet's tier. Square canvases work out to 10 for 16-32, 43-64, 86-128 and 171-256; 15 for 33-42, 65-85, 129-170 and 257-341; 25 above. Candidates per call, square canvases by side: 64 for 16-33, 49 for 34-35, 36 for 36-41, 25 for 42-51, 16 for 52-65, 9 for 66-85, 4 for 86-171, 1 from 172. A NON-SQUARE canvas is not the longest side applied to those ladders, and it is not the area either: both sides are read, and a narrower canvas can fit one more per side and so land a tier cheaper. 48x72 returns 16 candidates at 10 generations while 72x72 returns 9 at 15, on the same longest side. Verified non-square costs: 320x180 and 72x56 are 10, 384x216 and 416x176 are 15, 512x288 and 688x384 are 25. For a size not listed, don't extrapolate from the square ladders — the submit receipt reports the actual cost and candidate count before anything renders.
Generation time: ~1-10 minutes (async). Poll with get_image(job_id).

**Parameters:**
- `description`: str (required) — What to draw (e.g. 'ornate iron key with a ruby inlay').
- `width`: int (>=16) (optional) [default: 128] — Canvas width. The cap is an AREA of roughly a quarter megapixel, shaped by whichever of ten aspect ratios your request is nearest to — so no single number is the maximum width. Those maxima: 1:1 512x512, 5:4 576x464, 4:3 600x448, 3:2 632x424, 16:9 688x384, 21:9 792x336, and the portrait transposes (4:5 464x576, 3:4 448x600, 2:3 424x632, 9:16 384x688). 792x336 is the widest canvas there is; 704x304 is nearest 21:9 and fits. Anything over its ratio's pair is refused before the job is queued.
- `height`: int (>=16) (optional) [default: 128] — Canvas height. Max depends on aspect ratio.
- `no_background`: bool (optional) [default: True] — Return subjects on a transparent background. Defaults True — pro is normally used for assets. Set False for scenes and backdrops.
- `reference_images`: Optional[list[dict]] (optional) [default: None] — Up to 4 LABELLED reference images, as a JSON array. Each entry takes a "url" (preferred) OR a "base64": [{"url": "https://...", "usage": "character base"}, {"url": "https://...", "usage": "outfit and armour"}]. The "usage" note tells the model what to take from each image, which is what makes combining several references work. Prefer urls here especially — four inline images in one argument is four times the payload, and MCP clients truncate large arguments. Sizes are read from the images.
- `style_image_base64`: Optional[str] (optional) [default: None] — One image whose art style (palette, outline, detail, shading) the result should match. Use style_copy to narrow which of those apply.
- `style_image_url`: Optional[str] (optional) [default: None] — Alternative to style_image_base64: an https (or data:) URL to the style PNG. PREFER THIS for anything but a tiny sprite. Give one, not both.
- `style_copy`: Optional[list[str]] (optional) [default: None] — Which aspects to take from style_image_base64: any of color_palette, outline, detail, shading. Defaults to all four, or all but color_palette when a palette is given.
- `palette`: Optional[list[str]] (optional) [default: None] — Target palette, 2 to 256 hex colours as a JSON array, e.g. ["#081820", "#346856", "#88c070", "#e0f8d0"] for Game Boy or ["#000000", "#ffffff"] for 1-bit. The image is drawn for these colours and every pixel of the result is one of them.
- `palette_name`: Optional[str] (optional) [default: None] — Optional name of the palette (e.g. 'Game Boy', 'PICO-8', 'NES'); naming it helps the look.
- `max_colors`: Optional[int] (2-64) (optional) [default: None] — At most this many colours in each image (2-64), e.g. 6 for an NES-style sprite. With a palette, they are picked from it.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `get_image`
Get a raw-image result by job id, or a gallery image by `gallery:<id>`.

**Parameters:**
- `job_id`: str (required) — The job id returned by any raw-image tool (create_image_pixflux, create_image_pixen, create_image_pro, edit_image, edit_image_pixen, transfer_outfit, inpaint_image, animate_image, image_to_pixelart, unzoom_image, correct_pixelart, reduce_colors, create_normal_map), or a gallery:<id> from list_images — images made on the website have no job id.
- `index`: Optional[int] (optional) [default: None] — Return only this frame, inline. Use it to reach frames past the first few of a long animation without fetching a URL.

#### `list_images`
List the images in your Creator gallery (pixellab.ai/create), newest first,
one line each: its `gallery:<id>` reference, description, size and frame
count. Pass the reference to get_image to download an image, to
pixelart_workbench to look at or edit it, and to save_to_asset to save a fix
over it.

**Parameters:**
- `limit`: int (1-50) (optional) [default: 10] — Maximum number of images to return
- `offset`: int (>=0) (optional) [default: 0] — Number of images to skip
- `search`: Optional[str] (optional) [default: None] — Filter by the description an image was made from, or its id, case-insensitive. 'knight' finds 'armored knight with a sword'.

#### `edit_image`
Edit an existing image with a text instruction or a reference image (pro).
Cost: 10 generations for any output canvas up to 256x256, 15 up to 341x341, 25 above — so 64x64, 128x128 and 256x256 all cost the same 10, and the frame grid is already priced in: a single 64x64 edit costs the same as sixteen of them, so batch your frames. A non-square canvas is measured at its own aspect ratio and can land a band lower than its longer side suggests.
Generation time: ~30-90 seconds (async). Poll with get_image(job_id).

**Parameters:**
- `images_base64`: Optional[list[str]] (optional) [default: None] — Base64 PNG(s) to edit — pass a one-element list for a single image. Several frames get the SAME edit applied consistently (useful for animation frames or a character's directions). Max 512x512 each. PREFER image_urls — MCP clients routinely truncate large inline base64.
- `image_urls`: Optional[list[str]] (optional) [default: None] — Alternative to images_base64: https, data: or `upload:<id>` (POST /v2/uploads with this same bearer token) URLs to the PNG(s) to edit, in the same one-per-frame list form. PREFER THIS for anything but tiny sprites. Give urls OR base64, not both.
- `description`: Optional[str] (optional) [default: None] — What to change (e.g. 'add a red wizard hat', 'make the armor gold'). Required unless reference_image_base64 is given.
- `reference_image_base64`: Optional[str] (optional) [default: None] — Base64 PNG to copy the appearance of (outfit/colors/details) onto the input image, keeping its pose. Switches the tool into reference mode; description then just refines the instruction. To put an outfit on ANIMATION frames, use transfer_outfit instead.
- `reference_image_url`: Optional[str] (optional) [default: None] — Alternative to reference_image_base64: an https (or data:) URL to the reference PNG. PREFER THIS for anything but a tiny sprite. Give one, not both.
- `width`: Optional[int] (32-512) (optional) [default: None] — Output width. Defaults to the first input image's width.
- `height`: Optional[int] (32-512) (optional) [default: None] — Output height. Defaults to the first input image's height.
- `no_background`: Optional[bool] (optional) [default: None] — Background handling. Default (unset) follows the inputs: if any frame has transparency they all stay transparent, otherwise they stay opaque. Pass False to flatten a transparent input onto white.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `edit_image_pixen`
Edit an image with a text instruction on the Pixen model (fast, 1 generation).
Cost: 1 generation. Generation time: ~10-40 seconds (async). Poll with get_image(job_id).

**Parameters:**
- `description`: str (required) — What to change (e.g. 'give him a red cape', 'make the armor gold'). Same 1-500 bound the v2 endpoint enforces — an empty one would queue a job and spend a generation with nothing to edit towards.
- `image_base64`: Optional[str] (optional) [default: None] — Base64 PNG to edit. Max 256px per side, both sides multiples of 4 (pad with transparent pixels, never rescale). PREFER image_url — MCP clients routinely truncate large inline base64.
- `image_url`: Optional[str] (optional) [default: None] — Alternative to image_base64: an https (or data:) URL to the PNG to edit. PREFER THIS for anything but a tiny sprite. Give one, not both.
- `width`: Optional[int] (>=1) (optional) [default: None] — Output width, a multiple of 4. Output AREA must be at most 256x256 (65,536px), so 128x512 is fine but 320x320 is not. Defaults to the input image's width. The model re-renders at this size — it does not rescale.
- `height`: Optional[int] (>=1) (optional) [default: None] — Output height, a multiple of 4. Defaults to the input image's height.
- `no_background`: Optional[bool] (optional) [default: None] — Background handling. Default (unset) follows the input: a transparent input stays transparent, an opaque one stays opaque.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `create_normal_map`
Make the normal map of a sprite or an animation, so a game engine can light it
(Pro 0.5 generation, Lite 0.1 generation).
Cost: Pro 0.5 generation, Lite 0.1 generation. Time: Pro ~15-60 s, Lite a few seconds (async). Poll with get_image(job_id).

**Parameters:**
- `image`: str (required) — The sprite: `character:<id>:<direction>` (a rotation), `character:<id>:<direction>:<animation>` (every frame of that animation), the same for `object:<id>`, `gallery:<id>`, `job:<id>` (an image tool result), `upload:<id>`, a pixelart_workbench result id, an https or data URL of a PNG or GIF, or base64. Prefer a reference or URL to inline base64.
- `convention`: Literal["opengl", "directx"] (optional) [default: opengl] — opengl: green = up (Godot, Unity, Phaser, most engines); directx: green = down (Unreal).
- `mode`: Literal["lite", "pro"] (optional) [default: lite] — lite (0.1 generation, recommended): from the art alone, in about a second, and almost always as good; set kind with it for isometric, sidescroller and UI art. pro (0.5 generation): each part of the picture is planned, its shape, what is in front, what is sunk into it.
- `kind`: Optional[Literal["character", "object", "topdown", "side", "iso", "ui"]] (optional) [default: None] — What the picture is: character (a character, creature or portrait), object (an item or effect), topdown (a map, scene or tileset seen from above), side (a side view: sidescroller tiles, a landscape), iso (isometric tiles and objects) or ui (panels, buttons, frames). Left out, it is read from the picture; set it when you know, above all for sidescroller, isometric and UI art.
- `strength`: Optional[float] (0.0-2.0) (optional) [default: None] — How far every pixel tilts away from facing the viewer.
- `outline_rounding`: Optional[float] (0.0-3.0) (optional) [default: None] — How much the outline rounds off: 0 keeps it flat to the edge.
- `part_shapes`: Optional[float] (0.0-2.0) (optional) [default: None] — How much the sprite's 3D parts (a round head, an arm's cylinder) add.
- `surface_detail`: Optional[float] (0.0-2.0) (optional) [default: None] — The art's own light and dark as bumps: chunks bulge, dark lines and cracks sink.
- `detail_softness`: Optional[float] (0.6-3.0) (optional) [default: None] — How much that detail is blurred, in px: low follows every pixel.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `transfer_outfit`
Reskin an existing animation with the outfit from a reference image (pro).
Cost: 10-25 generations, billed by the whole grid — 2 frames cost the same as 15 at 64x64, so batch them. Generation time: ~1-2 minutes (async). Poll with get_image(job_id); frames come back in input order.

**Parameters:**
- `frames_base64`: Optional[list[str]] (optional) [default: None] — Base64 PNG animation frames to reskin, in order (2 or more). Max 256x256 each. PREFER frame_urls — MCP clients routinely truncate large inline base64.
- `frame_urls`: Optional[list[str]] (optional) [default: None] — Alternative to frames_base64: https, data: or `upload:<id>` (POST /v2/uploads with this same bearer token) URLs to the frame PNGs, in order. PREFER THIS for anything but tiny sprites. Give urls OR base64, not both.
- `reference_image_base64`: Optional[str] (optional) [default: None] — Base64 PNG of the SAME character wearing the new outfit (e.g. a re-dressed or recoloured sprite of it). A different character as reference is unreliable — it can freeze the motion or barely change anything. Max 256x256.
- `reference_image_url`: Optional[str] (optional) [default: None] — Alternative to reference_image_base64: an https (or data:) URL to the reference PNG. PREFER THIS for anything but a tiny sprite. Give one, not both.
- `additional_instructions`: Optional[str] (optional) [default: None] — Optional guidance for the transfer, e.g. 'frames show the character from behind' or 'keep the sword in the right hand'.
- `width`: Optional[int] (32-256) (optional) [default: None] — Output frame width. Defaults to the widest frame. Frames and reference smaller than this are padded with transparency, centred — never scaled.
- `height`: Optional[int] (32-256) (optional) [default: None] — Output frame height. Defaults to the tallest frame.
- `no_background`: Optional[bool] (optional) [default: None] — Background handling. Default (unset) follows the frames: if any frame has transparency the results are transparent, otherwise opaque. Pass False to flatten a transparent input onto white.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished frames are linked after generation.
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]

#### `image_to_pixelart`
Convert an image, render or photo into pixel art.
Cost: 1 generation. Generation time: ~20-60 seconds (async). Poll with get_image(job_id).

**Parameters:**
- `image_base64`: Optional[str] (optional) [default: None] — Base64 PNG/JPEG of the image to convert. Any artwork, render or photo. PREFER image_url — MCP clients routinely truncate large inline base64.
- `image_url`: Optional[str] (optional) [default: None] — Alternative to image_base64: an https (or data:) URL to the source image. PREFER THIS for anything but a tiny sprite. Give one, not both.
- `output_width`: Optional[int] (16-512) (optional) [default: None] — Width of the pixel art result. Defaults to a quarter of the source width. Keep the source's aspect ratio.
- `output_height`: Optional[int] (16-512) (optional) [default: None] — Height of the pixel art result. Defaults to a quarter of the source height.
- `faithful`: bool (optional) [default: False] — Faithful mode. Stays true to the source instead of reinterpreting it as pixel art. Turn this on when the user wants THEIR artwork converted rather than a pixel-art take on it; pair it with a init_image_strength of 100-300.
- `init_image_strength`: int (0-999) (optional) [default: 0] — How strongly to start from the source image (img2img). 0 redraws from scratch using the source only as guidance; 100-300 keeps its composition and colors. Do NOT go higher to be 'more faithful' — past ~300 the model barely transforms the input and hands back the source rather than pixel art.
- `text_guidance_scale`: float (1.0-20.0) (optional) [default: 8.0] — How hard to push towards pixel-art style.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible output.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `image_to_pixelart_pro_flash`
Convert an image, render or photo into pixel art with Pro Flash.
Cost: 6 generations. ~30-60 seconds. Returns one queued image; poll get_image(job_id), then download.

**Parameters:**
- `image_url`: Optional[str] (optional) [default: None]
- `image_base64`: Optional[str] (optional) [default: None]
- `source_image_id`: Optional[str] (optional) [default: None]
- `description`: Optional[str] (optional) [default: None]
- `palette`: Optional[list[str]] (optional) [default: None]
- `palette_name`: Optional[str] (optional) [default: None]
- `max_colors`: Optional[int] (optional) [default: None]
- `seed`: int (optional) [default: 0]
- `project_id`: Optional[str] (optional) [default: None]

#### `unzoom_image`
Downscale upscaled pixel art back onto its true pixel grid.
Cost: 0.1 generations. Runs locally in under a second — poll once with get_image(job_id).

**Parameters:**
- `image_base64`: Optional[str] (optional) [default: None] — Base64 PNG/JPEG of the upscaled pixel art. PREFER image_url — MCP clients routinely truncate large inline base64, and unzoom inputs are big by definition.
- `image_url`: Optional[str] (optional) [default: None] — Alternative to image_base64: an https (or data:) URL to the upscaled image. PREFER THIS. Give one, not both.
- `quantize`: int (-1-256) (optional) [default: 0] — Palette handling for the result. 0 auto-detects a palette, -1 keeps every color the downsample produces, 2-256 quantizes to exactly that many colors.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `correct_pixelart`
Clean up pixel art — sharpen edges, drop stray pixels, tighten the palette.
Cost: 0.1 generations. Generation time: ~20-60 seconds (async). Poll with get_image(job_id).

**Parameters:**
- `images_base64`: Optional[list[str]] (optional) [default: None] — Base64 PNG(s) to clean up — pass a one-element list for a single image. All frames must be the same size. PREFER image_urls; MCP clients routinely truncate large inline base64.
- `image_urls`: Optional[list[str]] (optional) [default: None] — Alternative to images_base64: https, data: or `upload:<id>` (POST /v2/uploads with this same bearer token) URLs to the PNG(s), one per frame. PREFER THIS. Give urls OR base64, not both.
- `strength`: float (0.0-1.0) (optional) [default: 0.1] — How far the model may move from the art. 0.1 tidies stray pixels and edges; high values redraw more and can change details. Start low and only raise it if the art needs real repair.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `reduce_colors`
Quantize images onto a smaller, shared palette.
Cost: 0.1 generations. Runs locally in about a second — poll once with get_image(job_id).

**Parameters:**
- `images_base64`: Optional[list[str]] (optional) [default: None] — Base64 PNG(s) to quantize — pass a one-element list for a single image. All frames must be the same size. PREFER image_urls; MCP clients routinely truncate large inline base64.
- `image_urls`: Optional[list[str]] (optional) [default: None] — Alternative to images_base64: https, data: or `upload:<id>` (POST /v2/uploads with this same bearer token) URLs to the PNG(s), one per frame. PREFER THIS. Give urls OR base64, not both.
- `num_colors`: Optional[int] (2-256) (optional) [default: None] — Target number of colors. Omit to auto-detect a good palette size from the images. Cannot be combined with a palette image.
- `palette_image_base64`: Optional[str] (optional) [default: None] — Base64 PNG whose colors become the palette (max 256 colors) — use it to force frames onto an existing game palette. Cannot be combined with num_colors.
- `palette_image_url`: Optional[str] (optional) [default: None] — Alternative to palette_image_base64: an https (or data:) URL to the palette image. Give one, not both.
- `dithering`: Literal["none", "2x2", "4x4", "8x8"] (optional) [default: none] — Ordered dithering matrix size. Larger matrices give smoother gradients at the cost of a busier look.
- `dithering_strength`: float (0.0-10.0) (optional) [default: 5.0] — How strongly to dither. Ignored when dithering is 'none'.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `animate_image`
Animate any image from a text description of the motion.
Cost scales with total pixels (a 64x64 8-frame animation is 1 generation, a 128x128 16-frame one is 4). Generation time: ~30-180 seconds (async). Poll with get_image(job_id).

**Parameters:**
- `action`: str (required) — The motion (e.g. 'walking forward', 'flame flickering', 'chest opening'). Describe movement, not appearance.
- `frame_count`: int (4-16) (optional) [default: 8] — Frames to generate — must be EVEN. 4 for idle loops, 8 for walk/run, 16 for complex actions. Large frames allow fewer frames.
- `first_frame_base64`: Optional[str] (optional) [default: None] — Base64 PNG to animate — the first frame. Max 256x256. PREFER first_frame_url; MCP clients routinely truncate large inline base64.
- `first_frame_url`: Optional[str] (optional) [default: None] — Alternative to first_frame_base64: an https (or data:) URL to the first frame PNG. PREFER THIS. Give one, not both.
- `last_frame_base64`: Optional[str] (optional) [default: None] — Optional final frame, same size as the first, to pin where the motion ends (interpolation instead of open-ended animation).
- `last_frame_url`: Optional[str] (optional) [default: None] — Alternative to last_frame_base64: an https (or data:) URL to the final frame PNG. Give one, not both.
- `no_background`: Optional[bool] (optional) [default: None] — Background handling. Default (unset) follows the first frame: a transparent sprite animates on transparency, an opaque image stays opaque.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `animate_image_pixminimax`
Animate with text (PixMiniMax): animate any image from a motion description.
Cost: priced by generation time, which follows the UPSCALED canvas the model works on — x4 up to 64px, x2 up to 128px, x1 above (longer side). So 64, 128 and 256 all price identically, and each is the MOST expensive size in its neighbourhood. At 64/128/256: 4-8 frames = 1 generation, 12-16 = 2, 20-24 = 3, 28 = 4, 32-36 = 5, 40 = 6. Four pixels over the step is ~3x cheaper on a long clip: 40 frames costs 6 at 128x128 and 2 at 132x132 (likewise 64x64 -> 68x68). Splitting helps too — four 8-frame calls cost 4 where one 32-frame call costs 5.
Generation time: ~1-6 minutes (async). Poll with get_image(job_id).

**Parameters:**
- `description`: str (required) — The motion (e.g. 'walking forward', 'flame flickering', 'chest opening'). Describe movement, not appearance.
- `frame_count`: int (optional) [default: 8] — Frames to generate, a multiple of 4 from 4 to 40 at any size up to 256x256. 4 for idle loops, 8 for walk/run, 16+ for complex actions.
- `first_frame_base64`: Optional[str] (optional) [default: None] — Base64 PNG to animate — the first frame. Max 256x256. PREFER first_frame_url; MCP clients routinely truncate large inline base64.
- `first_frame_url`: Optional[str] (optional) [default: None] — Alternative to first_frame_base64: an https (or data:) URL to the first frame PNG. PREFER THIS. Give one, not both.
- `last_frame_base64`: Optional[str] (optional) [default: None] — Optional final frame, same size as the first, to pin where the motion ends.
- `last_frame_url`: Optional[str] (optional) [default: None] — Alternative to last_frame_base64: an https (or data:) URL to the final frame PNG. Give one, not both.
- `no_background`: bool (optional) [default: True] — True (default) returns the frames on transparency; an opaque input is cut out of its first frame before animating. False keeps an opaque backdrop.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `enhance_prompt`: bool (optional) [default: False] — True rewrites a short description ('shooting a bow') as PixMiniMax's action caption before generating (+0.05 generations); the rewritten text is returned.
- `direction`: Optional[Literal["south", "north", "east", "west", "south-east", "south-west", "north-east", "north-west"]] (optional) [default: None] — Facing of the sprite (south = towards the camera), the model's facing caption field. Omit to have it read from the image.
- `view`: Optional[Literal["low top-down", "high top-down", "side"]] (optional) [default: None] — Camera view of the sprite, the model's view caption field. Omit to have it read from the image.
- `subject_description`: Optional[str] (optional) [default: None] — What the first frame shows, one noun phrase (e.g. 'a knight in silver plate armour'). Omit to have it read from the image.
- `initial_pose`: Optional[str] (optional) [default: None] — The pose the first frame is in (e.g. 'standing upright with the sword lowered'). Omit to have it read from the image.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `animate_with_skeleton_v3`
Animate with skeleton v3 (beta): animate a sprite along a skeleton you pose, one per frame.
Cost: priced by generation time, which barely moves with length, so every legal frame count falls in one of three steps — 3 frames = 2 generations, 4 to 14 = 3, 15 = 4.
Generation time: ~3-6 minutes (async). Poll with get_image(job_id).

**Parameters:**
- `description`: str (required) — What the character LOOKS like, as a noun phrase: 'blonde vampire with a red cape'. Colours, clothing, held items — not the motion, which the skeletons carry.
- `action`: str (required) — The motion's short label: 'walk', 'run', 'attack'.
- `direction`: Literal["south", "north", "east", "west", "south-east", "south-west", "north-east", "north-west"] (required) — Facing of the sprite (south = towards the camera).
- `keypoints`: list[Any] (required) — The motion: one skeleton per frame you get back, 3-15 frames. Each is a list of all 18 joints, {"label": "RIGHT KNEE", "x": 0.52, "y": 0.71, "z_index": 9}, with x/y as fractions 0-1 of the image. The 18 labels, exactly (every one required once per frame, order does not matter): NOSE, NECK, RIGHT SHOULDER, RIGHT ELBOW, RIGHT ARM, LEFT SHOULDER, LEFT ELBOW, LEFT ARM, RIGHT HIP, RIGHT KNEE, RIGHT LEG, LEFT HIP, LEFT KNEE, LEFT LEG, RIGHT EYE, LEFT EYE, RIGHT EAR, LEFT EAR. That set and order are OpenPose COCO-18, so `ARM` is the WRIST and `LEG` is the ANKLE (shoulder -> elbow -> ARM, hip -> knee -> LEG) and a COCO-18 pose from an external tool maps across 1:1. LEFT/RIGHT are the character's own sides, not the viewer's: facing `east` the RIGHT limbs are the near ones, mirrored for `west`, near-equal for `south`/`north`. `z_index` is a draw order — any int, default 0; no template prescribes values for it, it is yours. `depth` is optional (0-255, ~128 = the body's centre, higher = nearer the camera); left out, it is taken from the template body for this direction — which is the easier path, since that is where near/far already comes from (a mannequin at side/east runs RIGHT ARM 156 against LEFT ARM 100).
- `first_frame_keypoints`: list[Any] (required) — The skeleton of the pose first_frame is already IN, same 18 joints and labels as `keypoints`. The model redraws that frame first and learns the background key and the colours from the redraw, so a skeleton that does not match the image quietly costs transparency and colour accuracy. This frame is not returned. To get these for your own sprite, call `POST /v2/estimate-skeleton` (POST, not GET). There is no MCP tool for it, but it needs no new credential: MCP and v2 authenticate the same token, so the one already in your MCP client config works verbatim — send it as `Authorization: Bearer <that token>` with a body of `{"image": {"type": "base64", "base64": "<png>"}}` — no other fields are accepted. It answers `{"keypoints": [{"label": ..., "x": ..., "y": ..., "z_index": ...}]}`, and x/y come back as fractions 0-1 of YOUR original image, so they drop straight in here. ANY size works: it pads to the nearest of 16/32/64/128/256 internally and converts the coordinates back, so a 40x40 or 56x56 sprite needs no padding from you. 0.1 generations per call. A fully transparent frame is refused with 422 before anything is charged.
- `first_frame_base64`: Optional[str] (optional) [default: None] — Base64 PNG of the sprite to animate. Max 256x256. PREFER first_frame_url; MCP clients routinely truncate large inline base64.
- `first_frame_url`: Optional[str] (optional) [default: None] — Alternative to first_frame_base64: an https (or data:) URL to the sprite PNG. PREFER THIS. Give one, not both.
- `template_id`: Literal["mannequin", "bear", "cat", "dog", "horse", "lion"] (optional) [default: mannequin] — The body a joint's missing `depth` is taken from. A quadruped posed with mannequin depth comes out flat.
- `view`: Literal["low top-down", "high top-down", "side"] (optional) [default: low top-down] — Camera angle the sprite is drawn at. Must match the sprite, or the motion is posed for a different camera.
- `no_background`: bool (optional) [default: True] — True (default) returns the frames on transparency.
- `seed`: Optional[int] (>=0) (optional) [default: None] — Seed for reproducible generation.
- `project_id`: Optional[str] (optional) [default: None] — Internal Game Builder project context; the finished image is linked after generation.

#### `pixelart_workbench`
Run one pixel-art command on a drawing or image you already made. This is
the engine's own command line: it checks work, explains it and improves it.
Commands: check and explain (read-only): - lint <id> [--rules outline_gap,orphan_pixel,…] — pixel-art defects, each naming the node and command that drew them - inspect <id> --region x0,y0,x1,y1 --scale 10 — a zoomed crop with its exact colours - measure <id> --at x,y — what is at a pixel and who drew it - explain <id> — resolved geometry, per-command footprints, before rendering - motion / storyboard / silhouette / reveal / clusters / parts <id> — reports - score <id> — a 0-100 pixel-art discipline score with a breakdown - compare <id> <id> — two results side by side Improve (returns a NEW drawing id): - shade <id> --band 2 --light=-1,-1 — banded shading along a colour ramp - selout <id> — selective outlining; reoutline / clean-lines / aa / mirror - cluster <id> --at x,y --action recolor --color <name> — one guarded cluster - repair <id> — deterministic cleanup of drift, strays, fringe and noise Sheets and frames (returns a NEW image id): - split <image> --grid 3x3 — a sprite sheet, strip or grid as an animation, one frame per cell (columns x rows) - join <image> <image> … [--as sheet|rows|animation] [--columns n] — pictures or animations as one sprite sheet, one per row, or one animation - scale <image> --by 4 — the same picture or animation bigger, each pixel a 4x4 block (a sticker, a print); nothing is redrawn Craft operations need colour ramps: run `extract-palette <id>` first, then pass `--ramps skin=dark,mid,light`. Authoring: `edit <id> --changes '[…]'` applies exact pixel operations and `draw <id> --recipe '{…}'` builds or revises a layered scene; both take JSON whose fields are NOT listed here. Colours in that JSON are always `#RRGGBB` or `#RRGGBBAA` with alpha `00` or `ff` — `rgb()` and bare hex are refused, and nothing strips the `#`, since argv is a JSON list rather than a shell line. Every `edit` change carries `operation`, `layer`, `frames` (ONE-based) and `reason`; coordinates are zero-based and a `region` is `[x0,y0,x1,y1]` inclusive. Then its own fields: `patch_pixels` takes `pixels`, a list of `[x,y,expected,replacement]` (1-10000, each assigned only where the pixel already holds `expected`, so a mismatch fails the pass); `copy_region` takes `source_layer`, `source_frame`, `region`, `at` `[x,y]`; `map_colors` takes `region` and `colors` `{"#from":"#to"}` (alpha must match); `flood_fill` `seed`/`expected`/`color`; `brush` `points` plus `color`; `outline` `mode` (outside|inside|recolor|erase). The full contracts and any command's flags are one free call away: `describe edits | paint | outline | draw | animation | motion | scenes | review`, `<command> -h`, `describe cli`. Free for subscribers.

**Parameters:**
- `argv`: Optional[str | list[str]] (optional) [default: None] — One command line, e.g. 'lint <drawing_id> --rules outline_gap' or ['edit', '<id>', '--changes', '[…]']. Omit it for the playbook. A subject is an id or an image reference (`character:<id>:south`, a data URL, an https link) — never a file path; the server writes the output and returns a new id. Start with 'describe cli' for the full command list.
- `mode`: Literal["low", "high"] (optional) [default: low] — low (default): act directly, fewest tokens — one decisive image per result. high: think openly — fuller evidence and a review checklist; write your plan and observations in `notes`. Use the mode the user asked for.
- `notes`: Optional[str] (optional) [default: None] — What you observed and what this step should achieve, in a few sentences (high mode: always; low: optional). On the first call, include the user's request. Stored with the step to improve these tools.

#### `vfx_workbench`
Make an animated pixel-art effect (spell, hit, explosion, aura, projectile,
weather...) yourself, around the user's sprite or on its own: drop in tuned
parts, write layers, look at every render, then export. Export saves it to the
user's My effects on pixellab.ai (re-editable there with sliders) and returns a
GIF and a spritesheet PNG + JSON; --game-pack adds a ZIP of every piece for a game
engine (--part <id> just one). Free for subscribers.
Commands: - start [--sprite <image>] [--projectile <image>] [--preset <name>] -> step id - <step id> <tool> '<JSON>' -> add_part, set_part, remove_part, throw, render, get_preset, get_part, list_parts; a change returns a new step id - <step id> export [--name N] [--replace <effect id>] [--game-pack | --part <id>] - describe start | parts | recipe | craft | cookbook | edits | presets | tools Sprites and exports are pixelart_workbench ids, so the two work together. Start with describe start.

**Parameters:**
- `argv`: Optional[str | list[str]] (optional) [default: None] — One command, e.g. ['start', '--sprite', 'character:<id>:south'], ['<step id>', 'add_part', '{"name": "fire_burst"}'] or ['<step id>', 'export', '--name', 'Fireball']. Omit it for the guide.
- `mode`: Literal["low", "high"] (optional) [default: low] — low (default): act directly, fewest tokens — one decisive image per result. high: think openly — fuller evidence and a review checklist; write your plan and observations in `notes`. Use the mode the user asked for.
- `notes`: Optional[str] (optional) [default: None] — What you observed and what this step should achieve, in a few sentences (high mode: always; low: optional). On the first call, include the user's request. Stored with the step to improve these tools.

#### `save_to_asset`
Save pixel art into one of your characters, objects, Creator gallery
images or tilesets, replacing a rotation, one direction of an animation, a
gallery image or a tileset's tiles — or add it to the gallery as a new image
(free, no generation).

**Parameters:**
- `image`: str (required) — What to save: a pixelart_workbench result id (`<id>`, or `<id>:<view>` for a drawing), `job:<id>` / `job:<id>:<index>` (an image tool result), `upload:<id>` (an image POSTed to /v2/uploads), an https or data URL of a PNG or GIF, or base64.
- `target`: str (required) — Where to save it. A rotation: `character:<id>:<direction>`, `object:<id>:<direction>`, or `object:<id>` for a one-direction object. One direction of an animation: the same with `:<group id>` added (get_character / get_object show each animation's [group: …] id). A Creator gallery image: `gallery:<id>` to replace it (list_images shows each image's reference), `gallery:new` to add the image as a new one. A top-down or sidescroller tileset: `tileset:<id>` with its whole sheet (the download_png layout, same size), keeping its id and tile layout.
- `description`: Optional[str] (optional) [default: None] — Only with target="gallery:new": what the image shows, kept as its gallery description so the website and list_images(search=...) can find it.

#### `create_map`
Create an empty map seeded with a tileset and everything connected to it,
or with a tile group.

**Parameters:**
- `name`: str (required) — Name for the new map
- `tileset_id`: Optional[str] (optional) [default: None] — Tileset to seed the map from (from list_topdown_tilesets). Every tileset connected to it — same tile size, sharing a base tile id — is attached too, so their terrains are available to paint. A pair still needs its OWN tileset to blend: two terrains from the family with none between them meet with a hard edge (a straight seam), and view_map names any such pair with the call that blends it.
- `tile_group_id`: Optional[str] (optional) [default: None] — Instead of tileset_id: a tile group (from list_tiles_pro — isometric, hex, oblique or square tiles, or a building kit) to start a tile map from. Place and stack its tiles with place_map_tiles; add more groups there with add_group.
- `project_id`: Optional[str] (optional) [default: None] — Attach the map to this game project. Without it the map exists but never syncs into a project workspace, so a game cannot load it.

#### `delete_map`
Delete one of your maps. Immediate — there is no undo.

**Parameters:**
- `map_id`: str (required) — The map to delete, from list_maps

#### `list_maps`
List your maps, most recently edited first.

**Parameters:**
- `limit`: int (1-100) (optional) [default: 20] — How many maps to return
- `search`: Optional[str] (optional) [default: None] — Only maps whose name contains this (case-insensitive)
- `offset`: int (>=0) (optional) [default: 0] — Skip this many, to page deeper

#### `get_map`
Show a map as an ASCII grid, one character per terrain cell.

**Parameters:**
- `map_id`: str (required) — Map UUID from list_maps
- `x`: Optional[int] (optional) [default: None] — Crop: left edge, in terrain cells (q on tile layers)
- `y`: Optional[int] (optional) [default: None] — Crop: top edge, in terrain cells (r on tile layers)
- `width`: Optional[int] (optional) [default: None] — Crop width in cells
- `height`: Optional[int] (optional) [default: None] — Crop height in cells

#### `edit_map`
Paint terrain on a map: rivers and roads with `path`, areas with `rect`.

**Parameters:**
- `map_id`: str (required) — Map UUID from list_maps
- `ops`: list[PathOp | RectOp] (required) — Paint operations, applied in order. Two shapes:
  {"op":"path","terrain":"water","points":[[x,y],...],"width":3}
  {"op":"rect","terrain":"grass","x":10,"y":4,"width":8,"height":6}
Use terrain "none" to erase. Coordinates are terrain cells, as shown by get_map, and may be negative.
- `dry_run`: bool (optional) [default: False] — Preview the result and warnings without saving
- `show`: bool (optional) [default: False] — Also return a rendered IMAGE of the edited area. On by default whenever the edit brings in a terrain you have not seen rendered, or leaves tiles no tileset can draw.

#### `view_map`
Render the map to an image and return it, terrain and objects together.

**Parameters:**
- `map_id`: str (required) — Map UUID from list_maps
- `x`: Optional[int] (optional) [default: None] — Crop: left edge, in terrain cells
- `y`: Optional[int] (optional) [default: None] — Crop: top edge, in terrain cells
- `width`: Optional[int] (optional) [default: None] — Crop width in cells
- `height`: Optional[int] (optional) [default: None] — Crop height in cells

#### `place_map_tiles`
Place, stack and erase tiles on a map's tile layers — the map editor's tile
painting, with its Stack layer control.

**Parameters:**
- `map_id`: str (required) — Map UUID from list_maps
- `ops`: list[PlaceTilesOp | EraseTilesOp | AddGroupOp] (required) — Tile operations, applied in order. Three shapes:
  {"op":"place","layer":0,"tile":5,"cells":[[q,r],...],"level":0,"stack":1}
  {"op":"erase","layer":0,"area":{"q":0,"r":0,"width":4,"height":3}}
  {"op":"add_group","tile_group_id":"<uuid>"}
layer: tile layer index from get_map. tile: tile index in that layer's tile group (tile_N in get_tiles_pro). cells or area picks where; area covers q..q+width-1, r..r+height-1. level: stack level, 0 = ground, up to 63. stack: how many levels to fill upward from there. "on_top": true instead of level puts each tile one level above whatever that cell already holds; on erase it peels the top `stack` tiles off. Erasing at a level removes everything stacked above it too. add_group lays another tile group (list_tiles_pro) on the map as new layers after the existing ones; later ops in the same call can use them.
- `dry_run`: bool (optional) [default: False] — Report the result without saving

#### `list_projects`
List projects the user can access.

#### `agent_list`
List the deployed AI agents you own (the 'deploy your own agent' projects). Returns each
agent's slug — pass it as `agent` to agent_inspect / agent_talk.

#### `agent_inspect`
Debug a deployed agent's LIVE runtime: its state, recent chat, LLM/tool traces (errors first,
with the model's real input/output), and grown memory (journal/agenda/lessons/feedback). Use this
to see what the agent ACTUALLY did before changing its source. `focus='traces'` zooms in on bad turns.

**Parameters:**
- `agent`: Optional[str] (optional) [default: None] — Agent slug (omit if you only have one)
- `focus`: str (optional) [default: all] — all | state | messages | traces | memory

#### `agent_talk`
Send a message to a deployed agent (as its owner) and get its reply — to test how it responds
while you're working on it. Goes through the agent's normal chat loop (so it may run its tools).

**Parameters:**
- `message`: str (required) — What to say to the agent
- `agent`: Optional[str] (optional) [default: None] — Agent slug (omit if you only have one)

#### `get_balance`
Check your account balance: remaining credits (USD) and subscription generations.

#### `get_upload_url`
Get a URL to upload a local image file to, without needing your API token.

#### `search_knowledge`
Search the Phaser/game dev knowledge base for tips, patterns, and code examples.

**Parameters:**
- `query`: str (required) — Search query — describe the Phaser/TypeScript/game dev topic you need help with (e.g. 'camera follow player', 'collision detection', 'map transitions').
- `limit`: int (1-10) (optional) [default: 3] — Max results to return.

#### `cancel_job`
Cancel a pending or processing background job.

**Parameters:**
- `job_id`: str (required) — Background job UUID to cancel.

#### `list_jobs`
List your active background jobs (pending + processing).

**Parameters:**
- `include_recent`: bool (optional) [default: False] — Include recently completed/failed jobs (last 30 min). Default: only active jobs.

#### `wait_for_jobs`
Wait for your running generations instead of sleeping and polling.

**Parameters:**
- `timeout_seconds`: int (5-540) (optional) [default: 240] — Give up waiting after this many seconds (jobs keep running). If your client times out the call itself (some stop a tool at ~60s), pass a value under that limit and call again.
- `min_finished`: int (1-50) (optional) [default: 1] — Return once this many of your running jobs have finished (or all of them, if fewer are running). 1 frees you to fill a slot the moment one opens; raise it for a large batch so one call covers several.

## Available Resources

MCP also provides documentation resources:

- `pixellab://docs/python/sidescroller-tilesets`
  Quick Python implementation guide for PixelLab sidescroller tilesets
- `pixellab://docs/godot/sidescroller-tilesets`
  Complete Godot 4.x sidescroller tileset implementation guide with PixelLab MCP integration and headless GDScript converter
- `pixellab://docs/unity/isometric-tilemaps-2d`
  Complete Unity 2D isometric tilemap implementation guide with elevation support
- `pixellab://docs/godot/isometric-tiles`
  Complete Godot 4.x isometric tiles guide with PixelLab MCP integration and proper TileSet configuration
- `pixellab://docs/godot/wang-tilesets`
  Complete Godot 4.x Wang tileset implementation guide with PixelLab MCP integration and headless GDScript converter
- `pixellab://docs/python/wang-tilesets`
  Quick Python implementation guide for PixelLab Wang tilesets
- `pixellab://docs/overview`
  Complete PixelLab platform overview including all interfaces,
MCP tools, and integration methods.

## Tool Response Format

All tools return status indicators:
- ✅ Success - Operation completed
- ⏳ Processing - Background job running
- ❌ Error - Operation failed

## Background Jobs

Creation tools return immediately with job IDs.
Use the corresponding `get_*` tool to check status.

## Support & Resources

- Setup Guide: https://pixellab.ai/vibe-coding
- Discord Community: https://discord.gg/pBeyTBF8T7
- API v2 Documentation: https://api.pixellab.ai/v2/llms.txt

## About Vibe Coding

Vibe Coding transforms game development by enabling AI assistants to generate production-ready pixel art assets on-demand while writing game code. Build complete games faster with AI as your art department and coding partner.

---
*Generated: 2026-10-30 00:18 - This documentation is auto-generated from FastMCP tool definitions.*