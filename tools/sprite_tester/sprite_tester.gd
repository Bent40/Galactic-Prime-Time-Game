extends Control
## Standalone sprite animation tester (DEV TOOL — not part of the game; not wired
## into scenes/main.tscn, no simulation deps).
##
## The point: judge "does this animation read/feel right?" WITHOUT piping frames
## into an AnimatedSprite2D, attaching it to the game, and running the whole thing.
## Load art and it plays with the SAME nearest-neighbor rendering the game uses.
##
## Two input shapes, auto-detected:
##   - a single SPRITESHEET PNG  -> sliced into frames by the Frame W/H you set.
##   - a FOLDER of frame PNGs, or several PNGs dropped at once -> played in
##     filename order (this is Krita's "Render Animation -> Image Sequence" output;
##     use zero-padded names like frame_0000.png so they sort right).
##
## Run it: open tools/sprite_tester/sprite_tester.tscn and press F6 (Run Scene).
##
## Controls:
##   Load Sheet… / Load Folder… / drag files or a folder onto the window
##   Frame W / H (sheet mode only)   cell size — it auto-slices
##   FPS / ↑ ↓                        playback speed
##   Space                           play / pause
##   ← →                              step one frame (pauses)
##   Q / E                            prev / next PNG in the folder (sheet mode)
##   S                               silhouette (fill black — readability test)
##   B                               cycle background (checker / white / black / magenta)
##   mouse wheel                     zoom

enum Mode { SHEET, FRAMES }

var _mode: int = Mode.SHEET

# SHEET mode
var _sheet: Texture2D
var _atlas: AtlasTexture = AtlasTexture.new()
var _frame_w: int = 32
var _frame_h: int = 32
var _cols: int = 1
var _rows: int = 1
var _dir_files: PackedStringArray = []  # sibling PNGs for Q/E cycling
var _file_index: int = -1
var _loaded_path: String = ""

# FRAMES mode
var _frames: Array[Texture2D] = []

# shared
var _source_label: String = ""
var _fps: float = 8.0
var _count: int = 0
var _current: int = 0
var _zoom: int = 4
var _playing: bool = true
var _accum: float = 0.0
var _silhouette: bool = false
var _bg_mode: int = 0
const _BG_COLORS: Array[Color] = [
	Color(0.13, 0.13, 0.15), Color.WHITE, Color(0, 0, 0), Color(1, 0, 1),
]

# UI
var _preview: TextureRect
var _bg: TextureRect
var _wbox: SpinBox
var _hbox: SpinBox
var _fpsbox: SpinBox
var _status: Label
var _file_dialog: FileDialog
var _dir_dialog: FileDialog


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_apply_bg()
	var win: Window = get_window()
	if win != null:  # drag-and-drop; absent in headless contexts
		win.files_dropped.connect(_on_files_dropped)
	_refresh()


func _build_ui() -> void:
	_bg = TextureRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.stretch_mode = TextureRect.STRETCH_TILE
	_bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	root.add_child(bar)

	var sheet_btn := Button.new()
	sheet_btn.text = "Load Sheet…"
	sheet_btn.pressed.connect(_open_file_dialog)
	bar.add_child(sheet_btn)

	var folder_btn := Button.new()
	folder_btn.text = "Load Folder…"
	folder_btn.pressed.connect(_open_dir_dialog)
	bar.add_child(folder_btn)

	bar.add_child(_labeled("Frame W"))
	_wbox = _spin(1, 4096, _frame_w)
	_wbox.value_changed.connect(_on_w_changed)
	bar.add_child(_wbox)

	bar.add_child(_labeled("H"))
	_hbox = _spin(1, 4096, _frame_h)
	_hbox.value_changed.connect(_on_h_changed)
	bar.add_child(_hbox)

	bar.add_child(_labeled("FPS"))
	_fpsbox = _spin(1, 60, int(_fps))
	_fpsbox.value_changed.connect(_on_fps_changed)
	bar.add_child(_fpsbox)

	var play_btn := Button.new()
	play_btn.text = "Play / Pause (Space)"
	play_btn.pressed.connect(_toggle_play)
	bar.add_child(play_btn)

	var bg_btn := Button.new()
	bg_btn.text = "BG (B)"
	bg_btn.pressed.connect(_cycle_bg)
	bar.add_child(bg_btn)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)

	_preview = TextureRect.new()
	_preview.texture = _atlas
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	center.add_child(_preview)

	_status = Label.new()
	_status.add_theme_constant_override("margin_left", 6)
	root.add_child(_status)

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.add_filter("*.png", "PNG images")
	_file_dialog.use_native_dialog = true
	_file_dialog.file_selected.connect(_load_sheet)
	add_child(_file_dialog)

	_dir_dialog = FileDialog.new()
	_dir_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_dir_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dir_dialog.use_native_dialog = true
	_dir_dialog.dir_selected.connect(_load_dir_as_frames)
	add_child(_dir_dialog)


func _labeled(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _spin(mn: int, mx: int, val: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = mn
	spin.max_value = mx
	spin.step = 1
	spin.value = val
	return spin


func _on_w_changed(v: float) -> void:
	_frame_w = maxi(1, int(v))
	_reslice()


func _on_h_changed(v: float) -> void:
	_frame_h = maxi(1, int(v))
	_reslice()


func _on_fps_changed(v: float) -> void:
	_fps = maxf(0.0, v)


func _set_spins_editable(on: bool) -> void:
	if _wbox != null:
		_wbox.editable = on
	if _hbox != null:
		_hbox.editable = on


func _open_file_dialog() -> void:
	if _loaded_path != "":
		_file_dialog.current_dir = _loaded_path.get_base_dir()
	_file_dialog.popup_centered_ratio(0.6)


func _open_dir_dialog() -> void:
	_dir_dialog.popup_centered_ratio(0.6)


func _on_files_dropped(files: PackedStringArray) -> void:
	if files.is_empty():
		return
	if files.size() == 1:
		var path: String = files[0]
		if DirAccess.dir_exists_absolute(path):
			_load_dir_as_frames(path)
		else:
			_load_sheet(path)
		return
	# multiple files dropped -> treat as an animation's frames, sorted by name
	var pngs: PackedStringArray = PackedStringArray()
	for f: String in files:
		if f.to_lower().ends_with(".png"):
			pngs.append(f)
	pngs.sort()
	_load_frames(pngs, "%d dropped frames" % pngs.size())


func _fail(msg: String) -> void:
	if _status != null:
		_status.text = msg


# ---------------------------------------------------------------- loading

func _load_sheet(path: String) -> void:
	var img := Image.new()
	if img.load(path) != OK:
		_fail("Could not load: " + path)
		return
	_mode = Mode.SHEET
	_sheet = ImageTexture.create_from_image(img)
	_atlas.atlas = _sheet
	_loaded_path = path
	_source_label = path.get_file()
	_dir_files = PackedStringArray()
	var dir := DirAccess.open(path.get_base_dir())
	if dir != null:
		for f: String in dir.get_files():
			if f.to_lower().ends_with(".png"):
				_dir_files.append(path.get_base_dir().path_join(f))
		_dir_files.sort()
	_file_index = _dir_files.find(path)
	_current = 0
	_accum = 0.0
	_set_spins_editable(true)
	_reslice()
	_fit_zoom()


func _load_dir_as_frames(dir_path: String) -> void:
	var pngs: PackedStringArray = PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir != null:
		for f: String in dir.get_files():
			if f.to_lower().ends_with(".png"):
				pngs.append(dir_path.path_join(f))
		pngs.sort()
	if pngs.is_empty():
		_fail("No PNG frames in: " + dir_path)
		return
	_load_frames(pngs, "folder: %s (%d frames)" % [dir_path.get_file(), pngs.size()])


func _load_frames(paths: PackedStringArray, label: String) -> void:
	var textures: Array[Texture2D] = []
	for p: String in paths:
		var img := Image.new()
		if img.load(p) == OK:
			textures.append(ImageTexture.create_from_image(img))
	if textures.is_empty():
		_fail("Could not load any frames")
		return
	_mode = Mode.FRAMES
	_frames = textures
	_dir_files = PackedStringArray()
	_loaded_path = ""
	_source_label = label
	_current = 0
	_accum = 0.0
	_set_spins_editable(false)
	_reslice()
	_fit_zoom()


# ---------------------------------------------------------------- frames / view

func _reslice() -> void:
	if _mode == Mode.FRAMES:
		_count = _frames.size()
		_current = clampi(_current, 0, maxi(0, _count - 1))
		_update_region()
		return
	if _sheet == null:
		_count = 0
		_update_region()
		return
	_cols = maxi(1, _sheet.get_width() / _frame_w)
	_rows = maxi(1, _sheet.get_height() / _frame_h)
	_count = _cols * _rows
	_current = clampi(_current, 0, maxi(0, _count - 1))
	_update_region()


func _eff_frame_size() -> Vector2i:
	if _mode == Mode.FRAMES and _count > 0:
		var t: Texture2D = _frames[_current]
		return Vector2i(t.get_width(), t.get_height())
	return Vector2i(_frame_w, _frame_h)


func _update_region() -> void:
	if _mode == Mode.FRAMES:
		if _count > 0 and _preview != null:
			_preview.texture = _frames[_current]
		_apply_preview_size()
		_refresh()
		return
	if _preview != null:
		_preview.texture = _atlas
	if _sheet == null or _count == 0:
		_refresh()
		return
	var col: int = _current % _cols
	var row: int = _current / _cols
	_atlas.region = Rect2(col * _frame_w, row * _frame_h, _frame_w, _frame_h)
	_apply_preview_size()
	_refresh()


func _apply_preview_size() -> void:
	if _preview == null:
		return
	var fs: Vector2i = _eff_frame_size()
	_preview.custom_minimum_size = Vector2(fs.x * _zoom, fs.y * _zoom)
	_preview.modulate = Color.BLACK if _silhouette else Color.WHITE


func _refresh() -> void:
	if _status == null:
		return
	var idx: int = (_current + 1) if _count > 0 else 0
	if _mode == Mode.FRAMES:
		var fs: Vector2i = _eff_frame_size()
		var src: String = _source_label if _source_label != "" else "(drop a folder or several frame PNGs)"
		_status.text = "%s   |   frame %d/%d   |   %d×%dpx frames   |   %d fps   |   zoom %dx%s" % [
			src, idx, _count, fs.x, fs.y, int(_fps), _zoom,
			"   |   SILHOUETTE" if _silhouette else "",
		]
		return
	var src_sheet: String = _source_label if _source_label != "" else "(drag a spritesheet PNG, a folder, or Load…)"
	_status.text = "%s   |   frame %d/%d   |   grid %d×%d @ %d×%dpx   |   %d fps   |   zoom %dx%s" % [
		src_sheet, idx, _count, _cols, _rows, _frame_w, _frame_h, int(_fps), _zoom,
		"   |   SILHOUETTE" if _silhouette else "",
	]


func _fit_zoom() -> void:
	var avail: Vector2 = _preview.get_parent().size if _preview != null else Vector2.ZERO
	var fs: Vector2i = _eff_frame_size()
	if avail.x < 8.0 or avail.y < 8.0 or fs.x == 0 or fs.y == 0:
		_zoom = 4
	else:
		var zx: int = int(avail.x * 0.8 / fs.x)
		var zy: int = int(avail.y * 0.8 / fs.y)
		_zoom = clampi(mini(zx, zy), 1, 32)
	_update_region()


func _toggle_play() -> void:
	_playing = not _playing


func _cycle_bg() -> void:
	_bg_mode = (_bg_mode + 1) % _BG_COLORS.size()
	_apply_bg()


func _apply_bg() -> void:
	var img: Image
	if _bg_mode == 0:
		img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		var light := Color(0.22, 0.22, 0.24)
		var dark := Color(0.15, 0.15, 0.17)
		for y: int in range(16):
			for x: int in range(16):
				img.set_pixel(x, y, light if (x / 8 + y / 8) % 2 == 0 else dark)
	else:
		img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.set_pixel(0, 0, _BG_COLORS[_bg_mode])
	_bg.texture = ImageTexture.create_from_image(img)


func _step(direction: int) -> void:
	if _count == 0:
		return
	_playing = false
	_current = (_current + direction + _count) % _count
	_update_region()


func _cycle_file(direction: int) -> void:
	if _dir_files.size() == 0:
		return
	_file_index = (_file_index + direction + _dir_files.size()) % _dir_files.size()
	_load_sheet(_dir_files[_file_index])


func _process(delta: float) -> void:
	if _playing and _count > 1 and _fps > 0.0:
		_accum += delta
		var seconds_per_frame: float = 1.0 / _fps
		var changed: bool = false
		while _accum >= seconds_per_frame:
			_accum -= seconds_per_frame
			_current = (_current + 1) % _count
			changed = true
		if changed:
			_update_region()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_SPACE:
				_toggle_play()
			KEY_LEFT:
				_step(-1)
			KEY_RIGHT:
				_step(1)
			KEY_UP:
				_fpsbox.value += 1
			KEY_DOWN:
				_fpsbox.value -= 1
			KEY_Q:
				_cycle_file(-1)
			KEY_E:
				_cycle_file(1)
			KEY_S:
				_silhouette = not _silhouette
				_apply_preview_size()
				_refresh()
			KEY_B:
				_cycle_bg()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var button: int = (event as InputEventMouseButton).button_index
		if button == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampi(_zoom + 1, 1, 32)
			_apply_preview_size()
		elif button == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampi(_zoom - 1, 1, 32)
			_apply_preview_size()
