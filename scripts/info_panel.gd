class_name InfoPanel
extends VBoxContainer
## The info panel: item name, merge path with "?" for undiscovered tiers,
## and (Loop 2 only) the one-line description.

const FONT_BOLD := preload("res://assets/fonts/JetBrainsMono-ExtraBold.ttf")
const FONT_LIGHT := preload("res://assets/fonts/JetBrainsMono-ExtraLight.ttf")
const FONT_REG := preload("res://assets/fonts/JetBrainsMono-Regular.ttf")

var _name: Label
var _desc: Label
var _path: RichTextLabel


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	_name = _make_label(FONT_BOLD, 46, Color("e8e4f0"))
	_desc = _make_label(FONT_REG, 27, Color("8a86a8"))
	_path = RichTextLabel.new()
	_path.bbcode_enabled = true
	_path.fit_content = true
	_path.scroll_active = false
	_path.add_theme_font_override("normal_font", FONT_LIGHT)
	_path.add_theme_font_override("bold_font", FONT_BOLD)
	_path.add_theme_font_size_override("normal_font_size", 26)
	_path.add_theme_font_size_override("bold_font_size", 26)
	_path.add_theme_color_override("default_color", Color("6a6790"))
	_path.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_path)
	clear_panel()


func _make_label(font: Font, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)
	return l


func clear_panel() -> void:
	_name.text = ""
	_desc.text = ""
	_desc.visible = false
	_path.text = ""


func show_item(id: String) -> void:
	var data: Dictionary = ItemDB.item(id)
	if data.is_empty():
		return
	_name.text = data["name"]
	_desc.visible = LoopState.descriptions_visible()
	_desc.text = data["desc"]
	var parts: Array = []
	for step in data["path"]:
		if step == id:
			parts.append("[b][color=#e8e4f0]%s[/color][/b]" % ItemDB.item(step)["name"].to_lower())
		elif LoopState.is_discovered(step):
			parts.append(ItemDB.item(step)["name"].to_lower())
		else:
			parts.append("?")
	_path.text = "  [color=#9b6dff]→[/color]  ".join(PackedStringArray(parts))
