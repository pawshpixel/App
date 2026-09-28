extends Node
## Every chapter, chain and item, loaded from data/chapters.json. Autoloaded as ItemDB.
## That JSON is exported from tools/chapters.py, the same data the design bible is built from.

const DATA_PATH := "res://data/chapters.json"

var chapters: Array = []
var items := {}     # id -> {id, name, desc, chapter, color, star, next, path}
var recipes := {}   # "a|b" (sorted) -> result id


func _ready() -> void:
	var text := FileAccess.get_file_as_string(DATA_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Could not read %s" % DATA_PATH)
		return
	chapters = parsed["chapters"]
	for ci in chapters.size():
		_index_chapter(ci, chapters[ci])
	items["static"] = {
		"id": "static", "name": "Static", "chapter": 0, "color": Color("5a5560"), "star": false,
		"desc": "noise. the simulation hasn't decided what this is yet. two of them cancel out.",
		"next": "", "path": ["static"],
	}
	items["neuron_303"] = {
		"id": "neuron_303", "name": "Neuron 303", "chapter": 0, "color": Color("f28b82"), "star": false,
		"desc": "no pair. no place in the worm. it isn't yours. it came in with you.",
		"next": "", "path": ["neuron_303"],
	}


func _index_chapter(ci: int, ch: Dictionary) -> void:
	var final_id: String = ch["final"]["id"]
	var extra_id: String = ch["extra"]["id"] if ch.has("extra") else ""
	var extra_path: Array = []
	for track in ch["tracks"]:
		var ids: Array = []
		for it in track["items"]:
			ids.append(it["id"])
		var path := ids.duplicate()
		if extra_id != "" and ch["extra"]["recipe"].has(ids[-1]):
			path.append(extra_id)
			extra_path = path
		else:
			path.append(final_id)
		for i in ids.size():
			var it: Dictionary = track["items"][i]
			items[it["id"]] = {
				"id": it["id"], "name": it["name"], "desc": it["desc"], "chapter": ci,
				"color": Color(track["color"]), "star": false,
				"next": ids[i + 1] if i + 1 < ids.size() else "", "path": path,
			}
	for key in ["final", "extra"]:
		if not ch.has(key):
			continue
		var f: Dictionary = ch[key]
		items[f["id"]] = {
			"id": f["id"], "name": f["name"], "desc": f["desc"], "chapter": ci,
			"color": Color(ch["star_color"]), "star": key == "final", "next": "",
			"path": extra_path if key == "extra" and not extra_path.is_empty() else [f["id"]],
		}
		if f["recipe"].size() == 2:
			recipes[_pair(f["recipe"][0], f["recipe"][1])] = f["id"]


func _pair(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]


## The item two items merge into, or "" if they don't merge.
func merge_result(a: String, b: String) -> String:
	var key := _pair(a, b)
	if recipes.has(key):
		return recipes[key]
	if a == b and items.has(a):
		return items[a]["next"]
	return ""


func item(id: String) -> Dictionary:
	return items.get(id, {})


func first_items(chapter_index: int) -> Array:
	var ch: Dictionary = chapters[chapter_index]
	var out: Array = []
	for track in ch["tracks"]:
		# A track is finished once the board holds as many of its last item as the next recipe needs
		# (two Nerve Rings for the Worm, two Kittens for the Cat, one Earth for the Pale Blue Dot),
		# or once that recipe's result exists.
		var end_id: String = track["items"][-1]["id"]
		var feeds: Dictionary = ch["final"]
		if ch.has("extra") and ch["extra"]["recipe"].has(end_id):
			feeds = ch["extra"]
		out.append({
			"id": track["items"][0]["id"], "generator": track["generator"], "color": Color(track["color"]),
			"end": end_id,
			"need": maxi(1, feeds["recipe"].count(end_id)),
			"result": feeds["id"] if feeds["recipe"].has(end_id) else "",
		})
	return out
