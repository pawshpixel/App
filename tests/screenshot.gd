extends Node
## Captures two screenshots: the tutorial (eye closed) and Millennial Childhood after the Cat (eye open).
## Run with a display:  godot --path . res://tests/screenshot.tscn -- /output/dir
## Note: resets your saved progress.

var main: Node


func _ready() -> void:
	var out_dir := "user://"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	LoopState.reset_all()
	Engine.time_scale = 30.0
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await _shot(out_dir + "/0_opening.png")
	main._on_enter()
	await _wait_ready()
	for i in 40:
		await _step()
	main._on_item_tapped("neuron_pair")
	await _shot(out_dir + "/1_tutorial.png")

	main.start_chapter(1)
	await _wait_ready()
	for i in 14:
		await _step()
	await _shot(out_dir + "/3_big_bang_board.png")

	main.start_chapter(7)
	await _wait_ready()
	for i in 400:
		await _step()
		if main.companion.eye_open:
			break
	for i in 12:
		await _step()
	Engine.time_scale = 1.0
	main._on_item_tapped("cat")
	await get_tree().create_timer(0.5).timeout
	await _shot(out_dir + "/2_cat_eye_open.png")
	LoopState.reset_all()
	get_tree().quit()


func _wait_ready() -> void:
	await get_tree().process_frame
	while main._busy:
		await get_tree().process_frame


func _step() -> void:
	await get_tree().process_frame
	if main.board.auto_merge_step():
		return
	var buttons: Array = []
	for b in main.generator_bar.get_children():
		if b is Button and not b.disabled and not b.is_queued_for_deletion():
			buttons.append(b)
	if not buttons.is_empty():
		(buttons[randi() % buttons.size()] as Button).pressed.emit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)
