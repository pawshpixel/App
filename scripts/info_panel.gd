class_name InfoPanel
extends VBoxContainer
## The info panel: item name, merge path with "?" for undiscovered tiers,
## and (Loop 2 only) the one-line description, which comes back blacked out for redacted items.
## The voice line (what an item says, or a live readout) shows in every loop.

const FONT_BOLD := preload("res://assets/fonts/JetBrainsMono-ExtraBold.ttf")
const FONT_LIGHT := preload("res://assets/fonts/JetBrainsMono-ExtraLight.ttf")
const FONT_REG := preload("res://assets/fonts/JetBrainsMono-Regular.ttf")

const VOICE_COLOR := Color("7ab4f5")

var shown_id := ""
var _name: Label
var _voice: RichTextLabel
var _desc: Label
var _hint: Label
var _path: RichTextLabel


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_name = _make_label(FONT_BOLD, 46, Color("e8e4f0"))
	_voice = RichTextLabel.new()
	_voice.bbcode_enabled = true
	_voice.fit_content = true
	_voice.scroll_active = false
	_voice.add_theme_font_override("normal_font", FONT_REG)
	_voice.add_theme_font_size_override("normal_font_size", 27)
	_voice.add_theme_color_override("default_color", VOICE_COLOR)
	_voice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_voice)
	_desc = _make_label(FONT_REG, 27, Color("8a86a8"))
	_hint = _make_label(FONT_LIGHT, 22, Color("6a6790"))
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
	shown_id = ""
	_name.text = ""
	_voice.text = ""
	_voice.visible = false
	_desc.text = ""
	_desc.visible = false
	_hint.visible = false
	_path.text = ""


## Blacks out every character except spaces, so the shape of the sentence survives.
static func redact(text: String) -> String:
	var out := ""
	for ch in text:
		out += " " if ch == " " else "█"
	return out


func show_item(id: String, voice := "") -> void:
	var data: Dictionary = ItemDB.item(id)
	if data.is_empty():
		return
	shown_id = id
	_name.text = data["name"]
	_voice.text = voice
	_voice.visible = voice != ""
	_desc.visible = LoopState.descriptions_visible()
	var redacted := LoopState.is_redacted(id)
	_desc.text = redact(data["desc"]) if redacted else data["desc"]
	_hint.visible = redacted and LoopState.restore_charges > 0
	_hint.text = "▸ tap the eye to read it"
	var parts: Array = []
	for step in data["path"]:
		if step == id:
			parts.append("[b][color=#e8e4f0]%s[/color][/b]" % ItemDB.item(step)["name"].to_lower())
		elif LoopState.is_discovered(step):
			parts.append(ItemDB.item(step)["name"].to_lower())
		else:
			parts.append("?")
	_path.text = "  [color=#9b6dff]→[/color]  ".join(PackedStringArray(parts))
