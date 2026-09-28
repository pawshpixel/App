class_name Board
extends Control
## The 7 × 8 merge grid. Tap an item to inspect it; drag it onto an identical item to merge.

signal item_tapped(id: String)
signal merged(result_id: String, cell: int)
signal board_full

const COLS := 7
const ROWS := 8
const CELL := 140.0
const GAP := 8.0
const TILE := CELL - GAP
const DRAG_THRESHOLD := 14.0

var locked := false
var grid_color := Color("2a2440")
var cells: Array = []   # tile Control or null

var _press_cell := -1
var _press_pos := Vector2.ZERO
var _dragging := false


func _ready() -> void:
	size = Vector2(COLS * CELL, ROWS * CELL)
	custom_minimum_size = size
	cells.resize(COLS * ROWS)
	cells.fill(null)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	for i in COLS * ROWS:
		var r := Rect2(cell_origin(i), Vector2(TILE, TILE))
		draw_rect(r, grid_color, false, 2.0)


func set_grid_color(c: Color) -> void:
	grid_color = c
	queue_redraw()


func cell_origin(i: int) -> Vector2:
	return Vector2((i % COLS) * CELL + GAP / 2, (i / COLS) * CELL + GAP / 2)


func cell_at(pos: Vector2) -> int:
	if pos.x < 0 or pos.y < 0 or pos.x >= size.x or pos.y >= size.y:
		return -1
	return int(pos.y / CELL) * COLS + int(pos.x / CELL)


func empty_cells() -> Array:
	var out: Array = []
	for i in cells.size():
		if cells[i] == null:
			out.append(i)
	return out


func clear_board() -> void:
	for i in cells.size():
		if cells[i] != null:
			cells[i].queue_free()
			cells[i] = null


func count_of(id: String) -> int:
	var n := 0
	for t in cells:
		if t != null and t.id == id:
			n += 1
	return n


func find_cell(id: String) -> int:
	for i in cells.size():
		if cells[i] != null and cells[i].id == id:
			return i
	return -1


## Places an item in `cell`, or a random empty cell when cell is -1. Returns the cell used, or -1.
func spawn(id: String, cell := -1) -> int:
	if cell == -1:
		var free := empty_cells()
		if free.is_empty():
			board_full.emit()
			return -1
		cell = free[randi() % free.size()]
	var t := Tile.new()
	add_child(t)
	t.setup(id, TILE, float(cell) * 0.8)
	t.position = cell_origin(cell)
	cells[cell] = t
	t.pop()
	return cell


func remove_at(cell: int) -> void:
	if cells[cell] != null:
		cells[cell].queue_free()
		cells[cell] = null


func _gui_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_cell = cell_at(event.position)
			_press_pos = event.position
			_dragging = false
			if _press_cell == -1 or cells[_press_cell] == null:
				_press_cell = -1
		elif _press_cell != -1:
			if _dragging:
				_drop(cell_at(event.position))
			else:
				item_tapped.emit(cells[_press_cell].id)
			_press_cell = -1
			_dragging = false
	elif event is InputEventMouseMotion and _press_cell != -1:
		var t: Tile = cells[_press_cell]
		if not _dragging and event.position.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging = true
			t.z_index = 10
			t.scale = Vector2(1.1, 1.1)
		if _dragging:
			t.position = event.position - Vector2(TILE, TILE) / 2


func _drop(target: int) -> void:
	var from := _press_cell
	var t: Tile = cells[from]
	t.z_index = 0
	t.scale = Vector2.ONE
	if target == -1 or target == from:
		t.position = cell_origin(from)
		return
	if cells[target] == null:
		cells[target] = t
		cells[from] = null
		t.position = cell_origin(target)
		return
	if not try_merge(from, target):
		var other: Tile = cells[target]
		cells[target] = t
		cells[from] = other
		t.position = cell_origin(target)
		other.position = cell_origin(from)


## Merges the items in two cells if they combine. The result lands in `to`.
func try_merge(from: int, to: int) -> bool:
	var result := ItemDB.merge_result(cells[from].id, cells[to].id)
	if result == "":
		return false
	remove_at(from)
	remove_at(to)
	spawn(result, to)
	merged.emit(result, to)
	return true


## DEV: performs one available merge anywhere on the board. Returns false if nothing can merge.
func auto_merge_step() -> bool:
	for a in cells.size():
		if cells[a] == null:
			continue
		for b in range(a + 1, cells.size()):
			if cells[b] != null and ItemDB.merge_result(cells[a].id, cells[b].id) != "":
				return try_merge(a, b)
	return false
