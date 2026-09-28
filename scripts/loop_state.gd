extends Node
## Everything that carries between chapters and loops. Autoloaded as LoopState.

const SAVE_PATH := "user://progress.cfg"
## Shows the small DEV buttons (skip chapter, auto-merge, next loop, reset). Turn off for release.
const DEV_MODE := true

var loop := 1
var eye_opened := false
var chapter_index := 0
var discovered := {}


func _ready() -> void:
	load_progress()


func neuron_count() -> int:
	return 301 + loop


func descriptions_visible() -> bool:
	return loop >= 2


func discover(id: String) -> void:
	discovered[id] = true


func is_discovered(id: String) -> bool:
	return discovered.has(id)


func start_next_loop() -> void:
	loop += 1
	chapter_index = 0
	eye_opened = true
	save_progress()


func reset_all() -> void:
	loop = 1
	eye_opened = false
	chapter_index = 0
	discovered = {}
	save_progress()


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "loop", loop)
	cfg.set_value("progress", "eye_opened", eye_opened)
	cfg.set_value("progress", "chapter_index", chapter_index)
	cfg.set_value("progress", "discovered", discovered.keys())
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	loop = cfg.get_value("progress", "loop", 1)
	eye_opened = cfg.get_value("progress", "eye_opened", false)
	chapter_index = cfg.get_value("progress", "chapter_index", 0)
	discovered = {}
	for id in cfg.get_value("progress", "discovered", []):
		discovered[id] = true
