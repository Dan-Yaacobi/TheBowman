@tool
extends EditorScript
## Generates the game's UI theme.
## How to run: open this script in the Script Editor, then File > Run (Ctrl+Shift+X).
## To restyle the whole game later: change the values below and run it again.

const SAVE_PATH: String = "res://UI/Theme/game_theme.tres"
## Path to your pixel font (.ttf / .otf / .fnt). Leave empty to keep Godot's default font.
const FONT_PATH: String = "res://Fonts/m6x11.ttf"
const TITLE_FONT_PATH: String = "res://Fonts/alagard.ttf"
## Use your pixel font's native size (or a whole multiple of it) so it stays crisp.
const FONT_SIZE: int = 16
const OUTLINE_SIZE: int = 2

# --- Textured buttons (9-slice) ---
# Paths to the 4 button state images. Leave "normal" empty to use the flat stone style.
const BUTTON_NORMAL: String = "res://UI/Theme/button_normal.png"
const BUTTON_HOVER: String = "res://UI/Theme/button_hover.png"
const BUTTON_PRESSED: String = "res://UI/Theme/button_pressed.png"
const BUTTON_DISABLED: String = "res://UI/Theme/button_disabled.png"
# Where Godot cuts the image: the parts inside these margins never stretch.
const BUTTON_CAP: int = 24          # width of the stone cap on each side (incl. moss and outline)
const BUTTON_EDGE_TOP: int = 5      # empty rows + outline + highlight at the top
const BUTTON_EDGE_BOTTOM: int = 7   # shadow + outline + empty row at the bottom
## Wider-than-the-art buttons: true stretches the wood, false repeats it.
const BUTTON_STRETCH_HORIZONTAL: bool = true
## Taller-than-the-art buttons: true stretches the wood, false repeats the planks.
const BUTTON_STRETCH_VERTICAL: bool = true

# --- Textured panel (9-slice) ---
## Path to the panel image. Leave empty to use the flat stone panel.
const PANEL_TEXTURE: String = "res://UI/Theme/panel.png"
# Where Godot cuts the image: corners inside these margins are never repeated.
const PANEL_MARGIN_LEFT: int = 40
const PANEL_MARGIN_RIGHT: int = 40
const PANEL_MARGIN_TOP: int = 48
const PANEL_MARGIN_BOTTOM: int = 56
## Space between the panel's outer edge and its content (keeps text off the stones).
const PANEL_PADDING: int = 24
## false repeats the stones and boards (recommended), true stretches them.
const PANEL_STRETCH: bool = false

# Palette: stone, blue runes, warm text.
const STONE_DARK: Color = Color("1b2333")
const STONE: Color = Color("2a3548")
const STONE_LIGHT: Color = Color("3d4b63")
const STONE_EDGE: Color = Color("5c6c87")
const STONE_SHADOW: Color = Color("0e131c")
const RUNE: Color = Color("6fc3ff")
const RUNE_DIM: Color = Color("3a7fb8")
const TEXT: Color = Color("f3e2c0")
const TEXT_DIM: Color = Color("bfa77f")
const GOLD: Color = Color("ffcf5a")
const OUTLINE: Color = Color("2b1a10")
const SHADOW: Color = Color(0.08, 0.04, 0.02, 0.7)

func _run() -> void:
	var theme: Theme = Theme.new()

	if FONT_PATH != "":
		var font: Font = load(FONT_PATH) as Font
		if font:
			theme.default_font = font
		else:
			push_warning("Theme builder: couldn't load font at %s" % FONT_PATH)
	theme.default_font_size = FONT_SIZE

	_build_panels(theme)
	_build_buttons(theme)
	_build_labels(theme)
	_build_misc(theme)

	DirAccess.make_dir_recursive_absolute(SAVE_PATH.get_base_dir())
	var err: Error = ResourceSaver.save(theme, SAVE_PATH)
	if err == OK:
		print("Theme saved to %s" % SAVE_PATH)
	else:
		push_error("Theme builder: save failed (%s)" % error_string(err))

func _build_panels(theme: Theme) -> void:
	var panel: StyleBox = null
	if PANEL_TEXTURE != "":
		panel = _textured_panel()
	if panel == null:
		# Flat fallback: dark stone with a lighter stone border.
		var flat: StyleBoxFlat = _box(STONE_DARK, STONE_EDGE, 2, 2, 2)
		flat.set_content_margin_all(10)
		panel = flat
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PanelContainer", panel)

	# Inner section, e.g. one upgrade row. Use theme_type_variation = "RowPanel".
	var row: StyleBoxFlat = _box(STONE, STONE_LIGHT, 1, 1, 1)
	row.set_content_margin_all(6)
	theme.set_type_variation("RowPanel", "PanelContainer")
	theme.set_stylebox("panel", "RowPanel", row)

func _textured_panel() -> StyleBoxTexture:
	var tex: Texture2D = load(PANEL_TEXTURE) as Texture2D
	if tex == null:
		push_error("Theme builder: couldn't load panel texture at %s" % PANEL_TEXTURE)
		return null
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = PANEL_MARGIN_LEFT
	sb.texture_margin_right = PANEL_MARGIN_RIGHT
	sb.texture_margin_top = PANEL_MARGIN_TOP
	sb.texture_margin_bottom = PANEL_MARGIN_BOTTOM
	var mode: StyleBoxTexture.AxisStretchMode = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH if PANEL_STRETCH else StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.axis_stretch_horizontal = mode
	sb.axis_stretch_vertical = mode
	sb.set_content_margin_all(PANEL_PADDING)
	return sb

func _build_buttons(theme: Theme) -> void:
	if BUTTON_NORMAL != "":
		_build_textured_buttons(theme)
	else:
		_build_flat_buttons(theme)

	# Keyboard / controller focus: just a blue outline drawn on top.
	var focus: StyleBoxFlat = _box(Color.TRANSPARENT, RUNE_DIM, 1, 1, 1)
	focus.draw_center = false
	theme.set_stylebox("focus", "Button", focus)

	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", TEXT.darkened(0.15))
	theme.set_color("font_hover_pressed_color", "Button", TEXT.darkened(0.15))
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", TEXT_DIM)
	theme.set_color("font_outline_color", "Button", OUTLINE)
	theme.set_constant("outline_size", "Button", OUTLINE_SIZE)

func _build_textured_buttons(theme: Theme) -> void:
	var normal: StyleBoxTexture = _texture_box(BUTTON_NORMAL)
	var hover: StyleBoxTexture = _texture_box(BUTTON_HOVER if BUTTON_HOVER != "" else BUTTON_NORMAL)
	var pressed: StyleBoxTexture = _texture_box(BUTTON_PRESSED if BUTTON_PRESSED != "" else BUTTON_NORMAL)
	var disabled: StyleBoxTexture = _texture_box(BUTTON_DISABLED if BUTTON_DISABLED != "" else BUTTON_NORMAL)
	for sb: StyleBoxTexture in [normal, hover, pressed, disabled]:
		if sb == null:
			push_error("Theme builder: a button texture failed to load, check the paths.")
			return
	_textured_button_margins(normal, false)
	_textured_button_margins(hover, false)
	_textured_button_margins(pressed, true)
	_textured_button_margins(disabled, false)

	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("hover_pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)

func _texture_box(path: String) -> StyleBoxTexture:
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return null
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = BUTTON_CAP
	sb.texture_margin_right = BUTTON_CAP
	sb.texture_margin_top = BUTTON_EDGE_TOP
	sb.texture_margin_bottom = BUTTON_EDGE_BOTTOM
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH if BUTTON_STRETCH_HORIZONTAL else StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH if BUTTON_STRETCH_VERTICAL else StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return sb

func _textured_button_margins(sb: StyleBoxTexture, pushed_in: bool) -> void:
	# Keeps text off the stone caps; the pressed state drops the text 2px.
	sb.content_margin_left = BUTTON_CAP
	sb.content_margin_right = BUTTON_CAP
	sb.content_margin_top = BUTTON_EDGE_TOP + (2 if pushed_in else 0)
	sb.content_margin_bottom = BUTTON_EDGE_BOTTOM - (2 if pushed_in else 0)

func _build_flat_buttons(theme: Theme) -> void:
	# Stone block with a dark, thicker bottom edge for depth.
	var normal: StyleBoxFlat = _box(STONE_LIGHT, STONE_SHADOW, 1, 3, 1)
	_button_margins(normal, false)

	# Hover: lighter, with a blue rune edge.
	var hover: StyleBoxFlat = _box(STONE_LIGHT.lightened(0.12), RUNE, 1, 3, 1)
	_button_margins(hover, false)

	# Pressed: the thick edge moves to the top and the text drops 2px, so it "pushes in".
	var pressed: StyleBoxFlat = _box(STONE, RUNE, 3, 1, 1)
	_button_margins(pressed, true)

	var disabled: StyleBoxFlat = _box(STONE_DARK, STONE_SHADOW, 1, 1, 1)
	_button_margins(disabled, true)

	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("hover_pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)

func _build_labels(theme: Theme) -> void:
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", OUTLINE)
	theme.set_constant("outline_size", "Label", OUTLINE_SIZE)
	theme.set_color("font_shadow_color", "Label", SHADOW)
	theme.set_constant("shadow_offset_x", "Label", 0)
	theme.set_constant("shadow_offset_y", "Label", 2)
	theme.set_constant("shadow_outline_size", "Label", OUTLINE_SIZE)

	# Big gold headers: "PAUSED", menu titles.
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_color("font_color", "TitleLabel", GOLD)
	theme.set_font_size("font_size", "TitleLabel", FONT_SIZE * 2)

	# Section headers: "— Movement —".
	theme.set_type_variation("HeaderLabel", "Label")
	theme.set_color("font_color", "HeaderLabel", GOLD)
	if TITLE_FONT_PATH != "":
		var title_font: Font = load(TITLE_FONT_PATH) as Font
		theme.set_font("font", "TitleLabel", title_font)
		theme.set_font("font", "HeaderLabel", title_font)
		
	theme.set_type_variation("CostLabel", "Label")
	theme.set_color("font_color", "CostLabel", GOLD)

	theme.set_type_variation("DimLabel", "Label")
	theme.set_color("font_color", "DimLabel", TEXT_DIM)

	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_color("font_outline_color", "RichTextLabel", OUTLINE)
	theme.set_constant("outline_size", "RichTextLabel", OUTLINE_SIZE)
	theme.set_color("font_shadow_color", "RichTextLabel", SHADOW)
	theme.set_constant("shadow_offset_x", "RichTextLabel", 0)
	theme.set_constant("shadow_offset_y", "RichTextLabel", 2)
	
func _build_misc(theme: Theme) -> void:
	var tooltip: StyleBoxFlat = _box(STONE_DARK, RUNE_DIM, 1, 1, 1)
	tooltip.set_content_margin_all(5)
	theme.set_stylebox("panel", "TooltipPanel", tooltip)
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_color("font_outline_color", "TooltipLabel", OUTLINE)
	theme.set_constant("outline_size", "TooltipLabel", OUTLINE_SIZE)

	var line: StyleBoxLine = StyleBoxLine.new()
	line.color = STONE_EDGE
	line.thickness = 1
	theme.set_stylebox("separator", "HSeparator", line)
	theme.set_constant("separation", "HSeparator", 6)

func _box(bg: Color, border: Color, border_top: int, border_bottom: int, border_side: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_top = border_top
	sb.border_width_bottom = border_bottom
	sb.border_width_left = border_side
	sb.border_width_right = border_side
	# Small cut corners instead of round ones, and no smoothing: reads as pixel art.
	sb.set_corner_radius_all(2)
	sb.corner_detail = 1
	sb.anti_aliasing = false
	return sb

func _button_margins(sb: StyleBoxFlat, pushed_in: bool) -> void:
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 5 if pushed_in else 3
	sb.content_margin_bottom = 3 if pushed_in else 5
