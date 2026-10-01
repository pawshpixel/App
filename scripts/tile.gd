class_name Tile
extends Control
## One placeholder item on the board: a colored rounded square with the item's name.
## Swap the look for your Procreate PNGs later; the board only cares about `id`.

const FONT_BOLD := preload("res://assets/fonts/JetBrainsMono-ExtraBold.ttf")

var id := ""
var _label: Label
var _bob_phase := 0.0
var float_enabled := true
## Fixed tiles (the Data Center) can be tapped but never dragged, merged, swapped or thrown away.
var fixed := false


func setup(item_id: String, size_px: float, phase: float) -> void:
	id = item_id
	_bob_phase = phase
	custom_minimum_size = Vector2(size_px, size_px)
	size = Vector2(size_px, size_px)
	pivot_offset = size / 2
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var data: Dictionary = ItemDB.item(id)
	var col: Color = data.get("color", Color.WHITE)
	var box := StyleBoxFlat.new()
	box.bg_color = col.darkened(0.72)
	box.border_color = col
	box.set_border_width_all(6 if data.get("star", false) else 3)
	box.set_corner_radius_all(26)
	if data.get("star", false):
		box.shadow_color = Color(col, 0.55)
		box.shadow_size = 22
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	_label = Label.new()
	_label.text = data.get("name", id)
	_label.add_theme_font_override("font", FONT_BOLD)
	_label.add_theme_font_size_override("font_size", 21)
	_label.add_theme_color_override("font_color", Color("e8e4f0"))
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 8
	_label.offset_right = -8
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func pop() -> void:
	scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)
	tw.tween_property(self, "scale", Vector2.ONE, 0.1)


func _process(_delta: float) -> void:
	if float_enabled:
		var t := Time.get_ticks_msec() * 0.001
		_label.position.y = sin(t * 1.6 + _bob_phase) * 3.0
