class_name Board
extends Control
## The 7 × 8 merge grid. Tap an item to inspect it; drag it onto an identical item to merge.
## Cells can start "unrendered" (static) and open up as the player discovers new items.

signal item_tapped(id: String)
signal merged(result_id: String, cell: int)
signal static_cleared(cell: int)
signal dropped_outside(cell: int, global_point: Vector2)
signal board_full

const COLS := 7
const ROWS := 8
const CELL := 140.0
const GAP := 8.0
const TILE := CELL - GAP
const DRAG_THRESHOLD := 14.0
const STATIC_ID := "static"

var locked := false
var grid_color := Color("2a2440")
var cells: Array = []    # Tile or null
var open: Array = []     # bool per cell; closed cells show static and can't hold items

var _open_order: Array = []
var _open_count := COLS * ROWS
var _press_cell := -1
var _press_pos := Vector2.ZERO
var _dragging := false
var _static_t := 0.0


func _ready() -> void:
	size = Vector2(COLS * CELL, ROWS * CELL)
	custom_minimum_size = size
	cells.resize(COLS * ROWS)
	cells.fill(null)
	open.resize(COLS * ROWS)
	open.fill(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Cells open from the middle of the board outward.
	var center := Vector2((COLS - 1) / 2.0, (ROWS - 1) / 2.0)
	for i in COLS * ROWS:
		_open_order.append(i)
	_open_order.sort_custom(func(a, b):
		var da := Vector2(a % COLS, a / COLS).distance_to(center)
		var db := Vector2(b % COLS, b / COLS).distance_to(center)
		return da < db if absf(da - db) > 0.01 else a < b)


func _process(delta: float) -> void:
	if _open_count < COLS * ROWS:
		_static_t += delta
		if _static_t > 0.09:
			_static_t = 0.0
			queue_redraw()


func _draw() -> void:
	for i in COLS * ROWS:
		var r := Rect2(cell_origin(i), Vector2(TILE, TILE))
		if open[i]:
			draw_rect(r, grid_color, false, 2.0)
		else:
			draw_rect(r, Color(grid_color, 0.25), true)
			for k in 7:
				var p := r.position + Vector2(randf() * (TILE - 10), randf() * (TILE - 4))
				draw_rect(Rect2(p, Vector2(4 + randf() * 14, 2)), Color(grid_color.lightened(0.4), 0.35 + randf() * 0.3))


func set_grid_color(c: Color) -> void:
	grid_color = c
	queue_redraw()


## Opens exactly `n` cells (from the center out) and closes the rest. Items on closed cells are kept.
func set_open_count(n: int) -> void:
	_open_count = clampi(n, 1, COLS * ROWS)
	for k in _open_order.size():
		open[_open_order[k]] = k < _open_count or cells[_open_order[k]] != null
	queue_redraw()


## Opens the next `n` closed cells. Returns how many actually opened.
func unlock(n: int) -> int:
	var opened := 0
	for k in _open_order.size():
		if opened >= n:
			break
		var i: int = _open_order[k]
		if not open[i]:
			open[i] = true
			opened += 1
	_open_count = mini(_open_count + opened, COLS * ROWS)
	queue_redraw()
	return opened


func cell_origin(i: int) -> Vector2:
	return Vector2((i % COLS) * CELL + GAP / 2, (i / COLS) * CELL + GAP / 2)


func cell_at(pos: Vector2) -> int:
	if pos.x < 0 or pos.y < 0 or pos.x >= size.x or pos.y >= size.y:
		return -1
	return int(pos.y / CELL) * COLS + int(pos.x / CELL)


func empty_cells() -> Array:
	var out: Array = []
	for i in cells.size():
		if cells[i] == null and open[i]:
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


## Places an item in `cell`, or a random empty open cell when cell is -1. Returns the cell used, or -1.
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


## Places an item that can't be moved, forcing its cell open.
func place_fixed(id: String, cell: int) -> void:
	remove_at(cell)
	open[cell] = true
	spawn(id, cell)
	cells[cell].fixed = true
	queue_redraw()


## The empty open cell closest to `cell`, or -1 if the board is full.
func nearest_empty(cell: int) -> int:
	var origin := Vector2(cell % COLS, cell / COLS)
	var best := -1
	var best_d := INF
	for i in empty_cells():
		var d := Vector2(i % COLS, i / COLS).distance_to(origin)
		if d < best_d:
			best_d = d
			best = i
	return best


func remove_at(cell: int) -> void:
	if cell >= 0 and cells[cell] != null:
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
				_drop(cell_at(event.position), get_global_transform() * event.position)
			else:
				item_tapped.emit(cells[_press_cell].id)
			_press_cell = -1
			_dragging = false
	elif event is InputEventMouseMotion and _press_cell != -1:
		var t: Tile = cells[_press_cell]
		if t.fixed:
			return
		if not _dragging and event.position.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging = true
			t.z_index = 10
			t.scale = Vector2(1.1, 1.1)
		if _dragging:
			t.position = event.position - Vector2(TILE, TILE) / 2


func _drop(target: int, global_point: Vector2) -> void:
	var from := _press_cell
	var t: Tile = cells[from]
	t.z_index = 0
	t.scale = Vector2.ONE
	if target == -1:
		t.position = cell_origin(from)
		dropped_outside.emit(from, global_point)
		return
	if target == from or not open[target] or (cells[target] != null and cells[target].fixed):
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
## Two Static cancel each other out and leave both cells empty.
func try_merge(from: int, to: int) -> bool:
	if cells[from].id == STATIC_ID and cells[to].id == STATIC_ID:
		remove_at(from)
		remove_at(to)
		static_cleared.emit(to)
		return true
	var result := ItemDB.merge_result(cells[from].id, cells[to].id)
	if result == "":
		return false
	remove_at(from)
	remove_at(to)
	spawn(result, to)
	merged.emit(result, to)
	return true


func can_merge(a: String, b: String) -> bool:
	return (a == STATIC_ID and b == STATIC_ID) or ItemDB.merge_result(a, b) != ""


## DEV: performs one available merge anywhere on the board. Returns false if nothing can merge.
func auto_merge_step() -> bool:
	for a in cells.size():
		if cells[a] == null:
			continue
		for b in range(a + 1, cells.size()):
			if cells[b] != null and can_merge(cells[a].id, cells[b].id):
				return try_merge(a, b)
	return false
