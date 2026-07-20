extends Control
## Standalone sprite-sheet animation tester (DEV TOOL — not part of the game;
## not wired into scenes/main.tscn, no simulation deps).
##
## The point: judge "does this animation read/feel right?" WITHOUT piping a sheet
## into an AnimatedSprite2D, attaching it to the game, and running the whole thing.
## Drop a spritesheet in and it plays with the SAME nearest-neighbor rendering the
## game uses, so what you see is what ships.
##
## Run it: open tools/sprite_tester/sprite_tester.tscn in the editor and press F6
## (Run Current Scene).
##
## Controls:
##   Load… / drag a PNG onto the window    load a spritesheet
##   Frame W / H spinboxes                 set the cell size (it auto-slices)
##   FPS spinbox / ↑ ↓                      playback speed
##   Space                                 play / pause
##   ← →                                    step one frame (pauses)
##   Q / E                                  previous / next PNG in the same folder
##   S                                     silhouette (fill black — silhouette test)
##   B                                     cycle background (checker / white / black / magenta)
##   mouse wheel                           zoom

var _sheet: Texture2D
var _atlas: AtlasTexture = AtlasTexture.new()
var _dir_files: PackedStringArray = []  # sibling PNGs for Q/E cycling
var _file_index: int = -1
var _loaded_path: String = ""

var _frame_w: int = 32
var _frame_h: int = 32
var _fps: float = 8.0
var _cols: int = 1
var _rows: int = 1
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

var _preview: TextureRect
var _bg: TextureRect
var _wbox: SpinBox
var _hbox: SpinBox
var _fpsbox: SpinBox
var _status: Label
var _dialog: FileDialog


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

	var load_btn := Button.new()
	load_btn.text = "Load…"
	load_btn.pressed.connect(_open_dialog)
	bar.add_child(load_btn)

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

	_dialog = FileDialog.new()
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.add_filter("*.png", "PNG images")
	_dialog.use_native_dialog = true
	_dialog.file_selected.connect(_load_path)
	add_child(_dialog)


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


func _open_dialog() -> void:
	if _loaded_path != "":
		_dialog.current_dir = _loaded_path.get_base_dir()
	_dialog.popup_centered_ratio(0.6)


func _on_files_dropped(files: PackedStringArray) -> void:
	if files.size() > 0:
		_load_path(files[0])


func _load_path(path: String) -> void:
	var img := Image.new()
	if img.load(path) != OK:
		_loaded_path = ""
		_sheet = null
		_status.text = "Could not load: " + path
		return
	_sheet = ImageTexture.create_from_image(img)
	_atlas.atlas = _sheet
	_loaded_path = path
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
	_reslice()
	_fit_zoom()


func _reslice() -> void:
	if _sheet == null:
		_count = 0
		_refresh()
		return
	_cols = maxi(1, _sheet.get_width() / _frame_w)
	_rows = maxi(1, _sheet.get_height() / _frame_h)
	_count = _cols * _rows
	_current = clampi(_current, 0, maxi(0, _count - 1))
	_update_region()


func _update_region() -> void:
	if _sheet == null or _count == 0:
		_refresh()
		return
	var col: int = _current % _cols
	var row: int = _current / _cols
	_atlas.region = Rect2(col * _frame_w, row * _frame_h, _frame_w, _frame_h)
	if _preview != null:
		_preview.custom_minimum_size = Vector2(_frame_w * _zoom, _frame_h * _zoom)
		_preview.modulate = Color.BLACK if _silhouette else Color.WHITE
	_refresh()


func _refresh() -> void:
	if _status == null:
		return
	var fname: String = _loaded_path.get_file() if _loaded_path != "" else "(drag a spritesheet PNG onto the window, or Load…)"
	_status.text = "%s   |   frame %d/%d   |   grid %d×%d @ %d×%dpx   |   %d fps   |   zoom %dx%s" % [
		fname, (_current + 1) if _count > 0 else 0, _count, _cols, _rows,
		_frame_w, _frame_h, int(_fps), _zoom,
		"   |   SILHOUETTE" if _silhouette else "",
	]


func _fit_zoom() -> void:
	var avail: Vector2 = _preview.get_parent().size
	if avail.x < 8.0 or avail.y < 8.0 or _frame_w == 0 or _frame_h == 0:
		_zoom = 4
	else:
		var zx: int = int(avail.x * 0.8 / _frame_w)
		var zy: int = int(avail.y * 0.8 / _frame_h)
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
	_load_path(_dir_files[_file_index])


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
				_update_region()
			KEY_B:
				_cycle_bg()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var button: int = (event as InputEventMouseButton).button_index
		if button == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampi(_zoom + 1, 1, 32)
			_update_region()
		elif button == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampi(_zoom - 1, 1, 32)
			_update_region()
