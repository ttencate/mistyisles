extends Node

var TILE_SIZE = 256

var n
var size

onready var land = get_node("land")
onready var clues = get_node("clues")
onready var grid = get_node("grid")
var mist
var guesses
var cursor

signal help_text
signal solved

class ClueType:
	var land
	var neighbours
	var help_text
	func _init(land, neighbours, help_text):
		self.land = land
		self.neighbours = neighbours
		self.help_text = help_text

var CLUES = {
	lighthouse = ClueType.new(true, 1, "A lighthouse means ONE out of four neighbours is land"),
	castle = ClueType.new(true, 2, "A castle means TWO out of four neighbours are land"),
	harbour = ClueType.new(true, 3, "A harbour means THREE out of four neighbours are land"),
	whale = ClueType.new(false, 1, "A whale means ONE out of four neighbours is land"),
	fish = ClueType.new(false, 2, "Fish mean TWO out of four neighbours are land"),
	seagulls = ClueType.new(false, 3, "Seagulls mean THREE out of four neighbours are land"),
}

func _ready():
	land.visible = false
	n = grid.get_used_rect().size
	size = (n + Vector2(1, 1)) * grid.cell_size
	
	var offset = grid.cell_size / 2
	land.position = offset
	clues.position = offset
	grid.position = offset
	grid.modulate = Color(1, 1, 1, 0.3)
	
	guesses = create_tile_map()
	init_guesses()
	guesses.transform = clues.transform
	
	mist = create_tile_map()
	update_mist()
	mist.transform = clues.transform
	
	cursor = Sprite.new()
	cursor.visible = false
	cursor.texture = load("res://sprites/cursor.svg")
	cursor.modulate = Color(0.7, 1, 0.7, 0.3)
	
	remove_child(land)
	remove_child(clues)
	remove_child(grid)
	
	add_child(land)
	add_child(mist)
	add_child(guesses)
	add_child(cursor)
	add_child(clues)
	add_child(grid)

func _input(event):
	if event is InputEventMouse:
		var coords = (grid.to_local(event.position) / grid.cell_size).floor()
		if not grid.get_used_rect().has_point(coords):
			coords = null
		if event is InputEventMouseMotion:
			update_cursor(coords)
		elif event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
			if coords != null:
				toggle_guess(coords)

func update_cursor(coords):
	var help_text = ""
	if coords == null:
		if cursor != null:
			cursor.visible = false
	else:
		if cursor != null:
			cursor.visible = true
			cursor.position = grid.position + (coords + Vector2(0.5, 0.5)) * grid.cell_size
			var clue_tile = clues.get_cell(coords.x, coords.y)
			if clue_tile >= 0:
				var clue_tile_name = clues.tile_set.tile_get_name(clue_tile)
				if clue_tile_name in CLUES:
					var clue = CLUES[clue_tile_name]
					help_text = clue.help_text
	emit_signal("help_text", help_text)

func create_tile_map():
	var tile_map = TileMap.new()
	tile_map.tile_set = clues.tile_set
	tile_map.cell_size = clues.cell_size
	return tile_map

func init_guesses():
	var tile_set = guesses.tile_set
	for y in range(n.y):
		for x in range(n.x):
			var tile_name = tile_set.tile_get_name(clues.get_cell(x, y))
			if CLUES.has(tile_name):
				var clue = CLUES[tile_name]
				if clue.land:
					guesses.set_cell(x, y, tile_set.find_tile_by_name("guess_land"))
				else:
					guesses.set_cell(x, y, tile_set.find_tile_by_name("guess_water"))
	return guesses

func toggle_guess(coords):
	if clues.get_cell(coords.x, coords.y) >= 0:
		return # Filled by init_guesses() already
	var land_tile = guesses.tile_set.find_tile_by_name("guess_land")
	var water_tile = guesses.tile_set.find_tile_by_name("guess_water")
	var tile = guesses.get_cell(coords.x, coords.y)
	var next_tile = -1
	match tile:
		land_tile: next_tile = water_tile
		water_tile: next_tile = -1
		_: next_tile = land_tile
	guesses.set_cell(coords.x, coords.y, next_tile)
	
	check_solved()

func check_solved():
	var land_tile = guesses.tile_set.find_tile_by_name("guess_land")
	var water_tile = guesses.tile_set.find_tile_by_name("guess_water")
	for y in range(n.y):
		for x in range(n.x):
			var guess = guesses.get_cell(x, y) == land_tile
			var actual = land.get_cell(x, y) != -1
			if guess != actual:
				return
	complete_level()

func complete_level():
	land.visible = true
	mist.add_child(preload("res://fade_out.tscn").instance())
	guesses.add_child(preload("res://fade_out.tscn").instance())
	grid.add_child(preload("res://fade_out.tscn").instance())
	remove_child(cursor)
	cursor.queue_free()
	cursor = null
	emit_signal("solved")

func update_mist():
	for y in range(-1, n.y + 1):
		for x in range(-1, n.x + 1):
			var mist_name = "mist_"
			if x >= 0: mist_name += "l"
			if x < n.x: mist_name += "r"
			if y >= 0: mist_name += "t"
			if y < n.y: mist_name += "b"
			mist.set_cell(x, y, mist.tile_set.find_tile_by_name(mist_name))

func get_island_sizes():
	var grid = []
	for y in range(n.y):
		var row = []
		for x in range(n.x):
			row.append(land.get_cell(x, y) >= 0)
		grid.append(row)
	
	var sizes = []
	for y in range(n.y):
		for x in range(n.x):
			if grid[y][x]:
				sizes.append(count_and_erase(grid, x, y))
	return sizes

func count_and_erase(grid, x, y):
	var size = 0
	var queue = [Vector2(x, y)]
	while len(queue) > 0:
		var cell = queue.pop_back()
		if cell.x < 0 or cell.x >= n.x or cell.y < 0 or cell.y >= n.y:
			continue
		if not grid[cell.y][cell.x]:
			continue
		size += 1
		grid[cell.y][cell.x] = false
		queue.append(cell + Vector2(-1, 0))
		queue.append(cell + Vector2(+1, 0))
		queue.append(cell + Vector2(0, -1))
		queue.append(cell + Vector2(0, +1))
	return size