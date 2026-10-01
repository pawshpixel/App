extends Node
## Everything that carries between chapters and loops. Autoloaded as LoopState.

const SAVE_PATH := "user://progress.cfg"
## Shows the small DEV buttons (skip chapter, auto-merge, next loop, reset). Turn off for release.
const DEV_MODE := true

var loop := 1
var eye_opened := false
var chapter_index := 0
var discovered := {}
## The machine: once the Data Center is built it stays on every board until the loop ends.
var machine_built := false
var gallons := 0.0
## The Town Hall Chair: built hope slows the machine down for the rest of the loop.
var hope_built := false
## Loop 2+ redactions the companion has restored, and the charges it has to restore more.
var restored := {}
var restore_charges := 0
var _merges_toward_charge := 0


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


func is_redacted(id: String) -> bool:
	return loop >= 2 and ItemDB.item(id).get("redact", false) and not restored.has(id)


## Counts merges toward the next restore charge. Returns true when a charge is earned.
func count_merge_for_charge(every: int) -> bool:
	_merges_toward_charge += 1
	if _merges_toward_charge >= every:
		_merges_toward_charge = 0
		restore_charges += 1
		return true
	return false


func restore(id: String) -> bool:
	if restore_charges <= 0 or not is_redacted(id):
		return false
	restore_charges -= 1
	restored[id] = true
	save_progress()
	return true


func start_next_loop() -> void:
	loop += 1
	chapter_index = 0
	eye_opened = true
	machine_built = false
	gallons = 0.0
	hope_built = false
	save_progress()


func reset_all() -> void:
	loop = 1
	eye_opened = false
	chapter_index = 0
	discovered = {}
	machine_built = false
	gallons = 0.0
	hope_built = false
	restored = {}
	restore_charges = 0
	_merges_toward_charge = 0
	save_progress()


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "loop", loop)
	cfg.set_value("progress", "eye_opened", eye_opened)
	cfg.set_value("progress", "chapter_index", chapter_index)
	cfg.set_value("progress", "discovered", discovered.keys())
	cfg.set_value("progress", "machine_built", machine_built)
	cfg.set_value("progress", "gallons", gallons)
	cfg.set_value("progress", "hope_built", hope_built)
	cfg.set_value("progress", "restored", restored.keys())
	cfg.set_value("progress", "restore_charges", restore_charges)
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
	machine_built = cfg.get_value("progress", "machine_built", false)
	gallons = cfg.get_value("progress", "gallons", 0.0)
	hope_built = cfg.get_value("progress", "hope_built", false)
	restored = {}
	for id in cfg.get_value("progress", "restored", []):
		restored[id] = true
	restore_charges = cfg.get_value("progress", "restore_charges", 0)
