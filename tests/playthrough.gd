extends Node
## Automated playthrough: taps generators and merges until each loop ends.
## Run:  godot --headless --path . res://tests/playthrough.tscn
## Note: resets your saved progress.

var main: Node
var _gen_turn := 0


func _ready() -> void:
	LoopState.reset_all()
	Engine.time_scale = 30.0
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._on_enter()

	var ok := true
	ok = await _play_loop(1) and ok
	ok = _check(LoopState.eye_opened, "eye opened during loop 1") and ok
	main._on_continue()
	ok = await _play_loop(2) and ok
	ok = _check(LoopState.is_discovered("neuron_303"), "neuron 303 appeared in loop 2") and ok
	print("RESULT: ", "PASS" if ok else "FAIL")
	LoopState.reset_all()
	get_tree().quit(0 if ok else 1)


func _play_loop(loop_number: int) -> bool:
	var seen: Array = []
	var frames := 0
	while frames < 20000:
		frames += 1
		await get_tree().process_frame
		if main.choice_box.visible:
			print("loop %d ended after chapters: %s" % [loop_number, ", ".join(PackedStringArray(seen))])
			return _check(seen.size() == 14, "loop %d played 14 chapters" % loop_number)
		if main._busy or main.board.locked or main.chapter.is_empty():
			continue
		var key: String = main.chapter["key"]
		if seen.is_empty() or seen[-1] != key:
			seen.append(key)
			print("  chapter ", key)
		if key == "c10" and main._made.has("bombed_hospital") and not main._made.has("memorial"):
			if not main.companion.covered:
				print("FAIL: companion should cover its eye during the war")
				return false
		if main.board.auto_merge_step():
			continue
		var buttons: Array = []
		for b in main.generator_bar.get_children():
			if b is Button and not b.disabled and not b.is_queued_for_deletion():
				buttons.append(b)
		if buttons.is_empty():
			continue
		_gen_turn += 1
		(buttons[_gen_turn % buttons.size()] as Button).pressed.emit()
	print("FAIL: loop %d timed out in chapter %s" % [loop_number, main.chapter.get("key", "?")])
	return false


func _check(cond: bool, what: String) -> bool:
	print(("ok   " if cond else "FAIL ") + what)
	return cond
