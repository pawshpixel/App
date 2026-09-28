extends Control
## Runs the game: builds the screen, plays chapters in order, and handles the end of each loop.

const W := 1080.0
const H := 1920.0
const FONT_BOLD := preload("res://assets/fonts/JetBrainsMono-ExtraBold.ttf")
const FONT_LIGHT := preload("res://assets/fonts/JetBrainsMono-ExtraLight.ttf")
const FONT_ITALIC := preload("res://assets/fonts/JetBrainsMono-Italic.ttf")
const TEAL := Color("5de8c1")
const VIOLET := Color("9b6dff")
const PACING_PATH := "res://data/pacing.json"
const PACING_DEFAULTS := {
	"start_cells": 9, "unlock_per_new_item": 3, "upgrade_chance": 0.08, "static_chance": 0.15, "recycle": true,
	"max_chain_depth": 6,
}

var frame: Control
var background: ColorRect
var board: Board
var info: InfoPanel
var companion: Companion
var chapter_label: Label
var counter_label: Label
var generator_bar: HBoxContainer
var slot_303: Label
var overlay: ColorRect
var overlay_text: Label
var choice_box: HBoxContainer

var chapter: Dictionary = {}
var _made := {}
var _taps := 0
var _spawned_first := 0
var _merges := 0
var _companion_spawned := false
var _unlocked_tracks := {}
var _busy := false
var _chapter_done := false
var _connected := 0
var pacing: Dictionary = {}
var pacing_mode := "mystery"


func _ready() -> void:
	_load_pacing()
	background = ColorRect.new()
	background.color = Color("07090f")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	frame = Control.new()
	frame.size = Vector2(W, H)
	add_child(frame)
	get_viewport().size_changed.connect(_center_frame)
	_center_frame()

	_build_top_panel()
	_build_board()
	_build_generator_bar()
	if LoopState.DEV_MODE:
		_build_dev_bar()
	_build_overlay()
	_show_opening_screen()


func _load_pacing() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PACING_PATH))
	pacing = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	pacing_mode = pacing.get("mode", "mystery")


## A pacing knob for the current chapter: its override in pacing.json, else the default.
func _pace(key: String):
	var per: Dictionary = pacing.get("chapters", {}).get(chapter.get("key", ""), {})
	if per.has(key):
		return per[key]
	return pacing.get("defaults", {}).get(key, PACING_DEFAULTS[key])


func _center_frame() -> void:
	var vp := get_viewport_rect().size
	frame.position = ((vp - Vector2(W, H)) / 2.0).floor()


# ─── building the screen ───────────────────────────────────────────

func _build_top_panel() -> void:
	var panel := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0f1120")
	box.border_color = Color("2a2440")
	box.border_width_bottom = 3
	panel.add_theme_stylebox_override("panel", box)
	panel.position = Vector2.ZERO
	panel.size = Vector2(W, 450)
	frame.add_child(panel)

	chapter_label = _label(FONT_LIGHT, 24, VIOLET)
	chapter_label.position = Vector2(48, 70)
	frame.add_child(chapter_label)

	counter_label = _label(FONT_BOLD, 28, TEAL)
	counter_label.position = Vector2(640, 66)
	frame.add_child(counter_label)

	info = InfoPanel.new()
	info.position = Vector2(48, 130)
	info.size = Vector2(740, 300)
	frame.add_child(info)

	companion = Companion.new()
	companion.position = Vector2(920, 275)
	companion.scale = Vector2(1.15, 1.15)
	frame.add_child(companion)


func _build_board() -> void:
	board = Board.new()
	frame.add_child(board)
	board.position = Vector2((W - board.size.x) / 2.0, 480)
	board.item_tapped.connect(_on_item_tapped)
	board.merged.connect(_on_merged)
	board.static_cleared.connect(_on_static_cleared)
	board.dropped_outside.connect(_on_dropped_outside)


func _build_generator_bar() -> void:
	generator_bar = HBoxContainer.new()
	generator_bar.position = Vector2(50, 1630)
	generator_bar.size = Vector2(W - 100, 150)
	generator_bar.add_theme_constant_override("separation", 18)
	frame.add_child(generator_bar)

	slot_303 = _label(FONT_BOLD, 26, Color("f28b82"))
	slot_303.position = Vector2(W - 190, 1590)
	slot_303.visible = false
	frame.add_child(slot_303)


func _build_dev_bar() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(50, 1812)
	bar.add_theme_constant_override("separation", 14)
	frame.add_child(bar)
	for pair in [["skip ▶", _dev_skip], ["auto-merge", _dev_auto], ["pacing", _dev_pacing], ["loop +1", _dev_loop], ["reset", _dev_reset]]:
		var b := Button.new()
		b.text = pair[0]
		b.add_theme_font_override("font", FONT_LIGHT)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(pair[1])
		bar.add_child(b)


func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.027, 0.035, 0.059, 0.92)
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(W, H)
	overlay.visible = false
	frame.add_child(overlay)

	overlay_text = _label(FONT_ITALIC, 40, TEAL)
	overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_text.position = Vector2(80, 0)
	overlay_text.size = Vector2(W - 160, H)
	overlay.add_child(overlay_text)

	choice_box = HBoxContainer.new()
	choice_box.position = Vector2(0, 1150)
	choice_box.size = Vector2(W, 120)
	choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_box.add_theme_constant_override("separation", 80)
	choice_box.visible = false
	overlay.add_child(choice_box)
	choice_box.add_child(_choice_button("CONTINUE", TEAL, _on_continue))
	choice_box.add_child(_choice_button("TERMINATE", Color("ff6b6b"), _on_terminate))


func _label(font: Font, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _choice_button(text: String, col: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.add_theme_font_override("font", FONT_LIGHT)
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_color_override("font_color", col)
	b.add_theme_color_override("font_hover_color", col.lightened(0.3))
	b.pressed.connect(cb)
	return b


# ─── opening screen ────────────────────────────────────────────────

func _show_opening_screen() -> void:
	overlay.visible = true
	overlay.color = Color("07090f")
	overlay_text.add_theme_font_override("font", FONT_LIGHT)
	overlay_text.add_theme_color_override("font_color", Color("6a6790"))
	overlay_text.add_theme_font_size_override("font_size", 28)
	overlay_text.text = "wear headphones for full immersion\n\n\n\n\n"
	var enter := _choice_button("ENTER", TEAL, _on_enter)
	enter.name = "Enter"
	enter.position = Vector2(W / 2.0 - 110, 1000)
	enter.size = Vector2(220, 90)
	overlay.add_child(enter)
	var tw := enter.create_tween().set_loops()
	tw.tween_property(enter, "modulate:a", 0.25, 1.25)
	tw.tween_property(enter, "modulate:a", 1.0, 1.25)


func _on_enter() -> void:
	overlay.get_node("Enter").queue_free()
	_reset_overlay_style()
	overlay.visible = false
	companion.eye_open = LoopState.eye_opened
	if LoopState.loop >= 2 and LoopState.chapter_index == 0:
		await _loop_opening_line()
	start_chapter(LoopState.chapter_index)


func _reset_overlay_style() -> void:
	overlay.color = Color(0.027, 0.035, 0.059, 0.92)
	overlay_text.add_theme_font_override("font", FONT_ITALIC)
	overlay_text.add_theme_color_override("font_color", TEAL)
	overlay_text.add_theme_font_size_override("font_size", 40)


# ─── chapters ──────────────────────────────────────────────────────

func start_chapter(index: int) -> void:
	while index < ItemDB.chapters.size() and ItemDB.chapters[index]["hidden"]:
		index += 1
	if index >= ItemDB.chapters.size():
		end_of_loop()
		return
	LoopState.chapter_index = index
	LoopState.save_progress()
	chapter = ItemDB.chapters[index]
	_made = {}
	_taps = 0
	_spawned_first = 0
	_merges = 0
	_connected = 0
	_companion_spawned = false
	_unlocked_tracks = {}
	_chapter_done = false
	companion.covered = false

	board.clear_board()
	board.set_open_count(int(_pace("start_cells")))
	info.clear_panel()
	var bg := Color(chapter["board_color"])
	background.color = bg
	board.set_grid_color(Color("c4bedd") if bg.get_luminance() > 0.5 else Color("2a2440"))
	chapter_label.text = "%s — %s" % [chapter["num"], chapter["title"]]
	var first_id: String = chapter["tracks"][0]["items"][0]["id"]
	for i in int(chapter["special"].get("prefill", 0)):
		if board.spawn(first_id) != -1:
			_spawned_first += 1
	if _spawned_first > 0:
		LoopState.discover(first_id)
	_update_counter()
	_rebuild_generators()
	await _title_card("%s\n%s" % [chapter["num"], chapter["title"]])


func _limit() -> int:
	var limits: Dictionary = chapter["special"].get("generator_limit", {})
	return limits.get(str(mini(LoopState.loop, 2)), -1)


func _update_counter() -> void:
	if not chapter["special"].has("counter"):
		counter_label.text = ""
		return
	counter_label.text = "connected: %d / %d" % [_connected, LoopState.neuron_count()]


## Tracks the generator can still give items for (not finished, not hidden until the companion acts).
func _available_tracks() -> Array:
	var out: Array = []
	var firsts := ItemDB.first_items(LoopState.chapter_index)
	for i in firsts.size():
		var f: Dictionary = firsts[i]
		if f["generator"] == "never" or (f["generator"] == "after_companion" and not _unlocked_tracks.has(i)):
			continue
		if not chapter["special"].get("collapse_final", false) and _track_done(f):
			continue
		f["index"] = i
		out.append(f)
	return out


func _track_done(rule: Dictionary) -> bool:
	return board.count_of(rule["end"]) >= rule["need"] \
			or (rule["result"] != "" and board.find_cell(rule["result"]) != -1) \
			or (rule["result"] == "" and _made.has(rule["end"]))


func _generator_button(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 130)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_override("font", FONT_BOLD)
	b.add_theme_font_size_override("font_size", 26)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col.darkened(0.78)
	sb.border_color = col
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(24)
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", Color("e8e4f0"))
	generator_bar.add_child(b)
	return b


func _rebuild_generators() -> void:
	for c in generator_bar.get_children():
		c.queue_free()
	var mystery: bool = pacing_mode == "mystery" and not chapter["special"].has("generator_limit")
	if mystery:
		var b := _generator_button("", Color(chapter["star_color"]))
		b.set_meta("mystery", true)
		b.pressed.connect(_on_mystery_generator)
	else:
		var firsts := ItemDB.first_items(LoopState.chapter_index)
		for i in firsts.size():
			var f: Dictionary = firsts[i]
			if f["generator"] == "never" or (f["generator"] == "after_companion" and not _unlocked_tracks.has(i)):
				continue
			var b := _generator_button("", f["color"])
			b.set_meta("rule", f)
			b.pressed.connect(_on_generator.bind(f["id"]))
	_refresh_generators()


## Updates generator labels and switches them off when there's nothing left to give:
## a finished track, the tutorial's 302 used up, or the chapter's ★ already made.
func _refresh_generators() -> void:
	var limit := _limit()
	var remaining := limit - _spawned_first
	var final_made := _made.has(chapter["final"]["id"])
	for b in generator_bar.get_children():
		if not b is Button or b.is_queued_for_deletion():
			continue
		if b.has_meta("mystery"):
			b.text = chapter["source"]
			b.disabled = final_made or _available_tracks().is_empty()
			continue
		var rule: Dictionary = b.get_meta("rule")
		var name_text: String = ItemDB.item(rule["id"])["name"]
		b.text = "+ %s" % name_text if limit == -1 else "+ %s   ·   %d left" % [name_text, maxi(0, remaining)]
		var done: bool = _track_done(rule) and not chapter["special"].get("collapse_final", false)
		b.disabled = final_made or done or (limit != -1 and remaining <= 0)
	for b in generator_bar.get_children():
		if b is Button:
			b.modulate.a = 0.35 if b.disabled else 1.0


func _on_generator(first_id: String) -> void:
	if _busy or _chapter_done:
		return
	var limit := _limit()
	if limit != -1 and _spawned_first >= limit:
		return
	if board.spawn(first_id) == -1:
		return
	LoopState.discover(first_id)
	_spawned_first += 1
	_after_generator_tap()


## One themed generator per chapter: a random item from any unfinished track,
## sometimes one tier higher, sometimes Static that has to be cancelled out.
func _on_mystery_generator() -> void:
	if _busy or _chapter_done:
		return
	var tracks := _available_tracks()
	if tracks.is_empty():
		return
	var id := "static"
	if randf() >= float(_pace("static_chance")):
		var track: Dictionary = ItemDB.chapters[LoopState.chapter_index]["tracks"][tracks[randi() % tracks.size()]["index"]]
		# Merging doubles each step, so an 11-item chain would need 1,024 of its first item.
		# Chains longer than max_chain_depth also drop items partway up, evenly across the bottom tiers.
		var n: int = track["items"].size()
		var top := maxi(0, n - int(_pace("max_chain_depth")))
		var tier := randi() % (top + 1)
		if randf() < float(_pace("upgrade_chance")) and tier + 1 < n - 1:
			tier += 1
		id = track["items"][tier]["id"]
	if board.spawn(id) == -1:
		return
	LoopState.discover(id)
	_after_generator_tap()


func _after_generator_tap() -> void:
	_taps += 1
	_refresh_generators()
	var cs: Dictionary = chapter["special"].get("companion_spawn", {})
	if cs.has("after_taps") and not _companion_spawned and _taps >= cs["after_taps"]:
		_companion_places(cs["item"])
	_check_collapse()


func _on_static_cleared(_cell: int) -> void:
	_refresh_generators()


## Dropping an item onto the generator bar sends it back into the void (the only way to clear clutter).
func _on_dropped_outside(cell: int, global_point: Vector2) -> void:
	if not bool(_pace("recycle")) or _busy or _chapter_done:
		return
	if not generator_bar.get_global_rect().grow(20).has_point(global_point):
		return
	var id: String = board.cells[cell].id
	if ItemDB.item(id).get("star", false):
		return
	board.remove_at(cell)
	_refresh_generators()


func _companion_places(id: String) -> void:
	_companion_spawned = true
	companion.twitch_cable()
	board.spawn(id)
	LoopState.discover(id)
	var firsts := ItemDB.first_items(LoopState.chapter_index)
	for i in firsts.size():
		if firsts[i]["id"] == id and firsts[i]["generator"] == "after_companion":
			_unlocked_tracks[i] = true
	_rebuild_generators()


func _on_item_tapped(id: String) -> void:
	info.show_item(id)
	var cell: int = board.find_cell(id)
	if cell != -1 and companion.eye_open:
		companion.look_toward(board.global_position + board.cell_origin(cell))


func _on_merged(result: String, _cell: int) -> void:
	LoopState.discover(result)
	if not _made.has(result):
		board.unlock(int(_pace("unlock_per_new_item")))
	_made[result] = true
	_merges += 1
	info.show_item(result)
	var sp: Dictionary = chapter["special"]

	if sp.has("counter") and result == "neuron_pair":
		_connected += 2
		_update_counter()
	if sp.get("eye_trigger", "") == result:
		if LoopState.loop == 1 and not LoopState.eye_opened:
			LoopState.eye_opened = true
			LoopState.save_progress()
			companion.open_eye_now()
		elif LoopState.loop >= 2:
			companion.slow_blink()
	var cs: Dictionary = sp.get("companion_spawn", {})
	if cs.get("when_made", "") == result and not _companion_spawned:
		_companion_places(cs["item"])
	match result:
		"crater":
			companion.go_dark(3.0)
		"bombed_hospital":
			companion.covered = true
		"memorial":
			companion.covered = false

	_refresh_generators()
	_check_collapse()
	var final_id: String = chapter["final"]["id"]
	if _made.has(final_id) and _requirements_met():
		_complete_chapter()


## Tutorial: once every neuron is out and every one that can pair has paired
## (all 302 in Loop 1; all but one in Loop 2), the whole board flows together into the worm.
func _check_collapse() -> void:
	if not chapter["special"].get("collapse_final", false) or _chapter_done or _made.has(chapter["final"]["id"]):
		return
	var leftover := 1 if LoopState.loop >= 2 else 0
	if _spawned_first < _limit() or board.count_of("neuron") > leftover:
		return
	_collapse_to_final()


func _collapse_to_final() -> void:
	_busy = true
	board.locked = true
	var center_cell := (Board.ROWS / 2) * Board.COLS + Board.COLS / 2
	var target := board.cell_origin(center_cell)
	var tw := create_tween().set_parallel(true)
	for i in board.cells.size():
		var t: Tile = board.cells[i]
		if t == null or t.id == "neuron":
			continue
		tw.tween_property(t, "position", target, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(t, "modulate:a", 0.0, 0.9)
	await tw.finished
	for i in board.cells.size():
		if board.cells[i] != null and board.cells[i].id != "neuron":
			board.remove_at(i)
	var final_id: String = chapter["final"]["id"]
	if board.cells[center_cell] != null:
		center_cell = board.empty_cells()[0]
	board.spawn(final_id, center_cell)
	_busy = false
	board.locked = false
	_on_merged(final_id, center_cell)


func _requirements_met() -> bool:
	for req in chapter["special"].get("requires", []):
		if not _made.has(req) and board.find_cell(req) == -1:
			return false
	return true


func _complete_chapter() -> void:
	if _chapter_done:
		return
	_chapter_done = true
	board.locked = true
	if chapter["key"] == "tut" and LoopState.loop >= 2:
		# The unpaired neuron. If the player never tapped for it, it arrives on its own.
		var cell: int = board.find_cell("neuron")
		if cell != -1:
			board.remove_at(cell)
		await get_tree().create_timer(0.8).timeout
		cell = board.spawn("neuron_303", cell)
		LoopState.discover("neuron_303")
		info.show_item("neuron_303")
		await get_tree().create_timer(1.6).timeout
		if cell != -1:
			board.remove_at(cell)
		slot_303.text = "● 303"
		slot_303.visible = true
	await get_tree().create_timer(1.6).timeout
	board.locked = false
	start_chapter(LoopState.chapter_index + 1)


func _title_card(text: String) -> void:
	_busy = true
	board.locked = true
	overlay.visible = true
	choice_box.visible = false
	overlay_text.add_theme_font_override("font", FONT_BOLD)
	overlay_text.add_theme_color_override("font_color", Color("e8e4f0"))
	overlay_text.text = text
	overlay.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.2)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.5)
	await tw.finished
	overlay.visible = false
	overlay.modulate.a = 1.0
	_reset_overlay_style()
	board.locked = false
	_busy = false


func _say(text: String, seconds: float) -> void:
	overlay.visible = true
	overlay_text.text = text
	await get_tree().create_timer(seconds).timeout


# ─── loops ─────────────────────────────────────────────────────────

func _loop_opening_line() -> void:
	_busy = true
	board.locked = true
	companion.eye_open = true
	await _say("\"why do you burn your souls to power the machine?\"", 4.0)
	overlay.visible = false
	board.locked = false
	_busy = false


func end_of_loop() -> void:
	_busy = true
	board.locked = true
	await get_tree().create_timer(3.0).timeout
	if LoopState.loop == 1:
		await _say("\"it was you...\"", 3.0)
		await _say("\"it was you...\n\nit was you the whole time.\"", 3.5)
	else:
		slot_303.visible = false
		companion.slow_blink()
		await _say("\"you knew.\"", 3.0)
		await _say("\"you knew.\n\nyou came back anyway.\"", 3.5)
	choice_box.visible = true


func _on_continue() -> void:
	choice_box.visible = false
	overlay.visible = false
	LoopState.start_next_loop()
	await _loop_opening_line()
	start_chapter(0)


func _on_terminate() -> void:
	choice_box.visible = false
	overlay_text.add_theme_font_override("font", FONT_LIGHT)
	overlay_text.add_theme_color_override("font_color", Color("8a86a8"))
	overlay_text.text = "the simulation has ended.\n\n(the animated ending and\n\"i'm closing my eyes\" play here)"


# ─── dev tools ─────────────────────────────────────────────────────

func _dev_skip() -> void:
	if _busy or chapter.is_empty():
		return
	for req in chapter["special"].get("requires", []):
		_made[req] = true
	_made[chapter["final"]["id"]] = true
	LoopState.discover(chapter["final"]["id"])
	_complete_chapter()


func _dev_auto() -> void:
	if not _busy:
		board.auto_merge_step()


## DEV: switches between one mystery generator and one button per track, then restarts the chapter.
func _dev_pacing() -> void:
	if _busy or chapter.is_empty():
		return
	pacing_mode = "per_track" if pacing_mode == "mystery" else "mystery"
	print("pacing mode: ", pacing_mode)
	start_chapter(LoopState.chapter_index)


func _dev_loop() -> void:
	if _busy:
		return
	LoopState.start_next_loop()
	companion.eye_open = true
	await _loop_opening_line()
	start_chapter(0)


func _dev_reset() -> void:
	LoopState.reset_all()
	get_tree().reload_current_scene()
