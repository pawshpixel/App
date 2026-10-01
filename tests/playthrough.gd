extends Node
## Automated playthrough: taps generators and merges until each loop ends.
## Run:  godot --headless --path . res://tests/playthrough.tscn
## Note: resets your saved progress.

var main: Node
var _gen_turn := 0
var _saw_chatbot_silenced := false
var _saw_rival := false
var _saw_machine_static := false


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
	ok = _check(LoopState.machine_built, "the data center stayed built") and ok
	print("  water used in loop 1: ", main.format_gallons(LoopState.gallons))
	ok = _check(LoopState.gallons > 0.0, "the machine used water") and ok
	ok = _check(_saw_chatbot_silenced, "the chatbot stopped answering after Breaking News") and ok
	ok = _check(_saw_rival, "the rival bar climbed in The Race") and ok
	ok = _check(_saw_machine_static, "the machine filled cells with static") and ok
	main._on_continue()
	ok = _check(not LoopState.machine_built and LoopState.gallons == 0.0, "the machine resets with the loop") and ok
	ok = await _play_loop(2) and ok
	ok = _check(LoopState.is_discovered("neuron_303"), "neuron 303 appeared in loop 2") and ok
	ok = _check(LoopState.is_redacted("bunker") or LoopState.restored.has("bunker"), "loop 2 redacts the bunker") and ok
	LoopState.restore_charges = 1
	ok = _check(LoopState.restore("bunker") and not LoopState.is_redacted("bunker"), "the companion can restore a redaction") and ok
	print("RESULT: ", "PASS" if ok else "FAIL")
	LoopState.reset_all()
	get_tree().quit(0 if ok else 1)


func _play_loop(loop_number: int) -> bool:
	var seen: Array = []
	var actions := {}
	var frames := 0
	while frames < 20000:
		frames += 1
		await get_tree().process_frame
		if main.choice_box.visible:
			print("loop %d ended after chapters: %s" % [loop_number, ", ".join(PackedStringArray(seen))])
			print("  taps + merges per chapter: ", actions)
			return _check(seen.size() == 15, "loop %d played 15 chapters" % loop_number)
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
		if key == "c8" and main._made.has("breaking_news") and main._silenced.has("ai_chatbot"):
			_saw_chatbot_silenced = true
		if key == "race" and main._rival > 30.0 and main.counter_label.text.begins_with("RIVAL"):
			_saw_rival = true
		if main._machine_running() and main._machine_taps >= int(main._pace("machine_every")):
			_saw_machine_static = true
		if main.board.auto_merge_step():
			actions[key] = actions.get(key, 0) + 1
			continue
		if main.board.empty_cells().is_empty():
			var junk: int = main.board.find_cell("static")
			if junk != -1:
				main.board.remove_at(junk)
				continue
		var buttons: Array = []
		for b in main.generator_bar.get_children():
			if b is Button and not b.disabled and not b.is_queued_for_deletion():
				buttons.append(b)
		if buttons.is_empty():
			continue
		_gen_turn += 1
		(buttons[_gen_turn % buttons.size()] as Button).pressed.emit()
		actions[key] = actions.get(key, 0) + 1
	print("FAIL: loop %d timed out in chapter %s" % [loop_number, main.chapter.get("key", "?")])
	return false


func _check(cond: bool, what: String) -> bool:
	print(("ok   " if cond else "FAIL ") + what)
	return cond
