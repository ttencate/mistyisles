extends Node

var n

var land
var clues
var grid
var mist
var guesses
var cursor
var is_solved

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
		
	static func is_land(tile, tile_set):
		if tile < 0:
			return false
		return "land" in tile_set.tile_get_name(tile)
	
	func matches(coords, guesses):
		var tile_set = guesses.tile_set
		if is_land(guesses.get_cell(coords.x, coords.y), tile_set) != self.land:
			return false
		var land_count = 0
		if is_land(guesses.get_cell(coords.x - 1, coords.y), tile_set): land_count += 1
		if is_land(guesses.get_cell(coords.x + 1, coords.y), tile_set): land_count += 1
		if is_land(guesses.get_cell(coords.x, coords.y - 1), tile_set): land_count += 1
		if is_land(guesses.get_cell(coords.x, coords.y + 1), tile_set): land_count += 1
		return land_count == self.neighbours

var CLUES = {
	lighthouse = ClueType.new(true, 1, "A lighthouse means ONE out of four neighbours is land"),
	castle = ClueType.new(true, 2, "A castle means TWO out of four neighbours are land"),
	harbour = ClueType.new(true, 3, "A harbour means THREE out of four neighbours are land"),
	whale = ClueType.new(false, 1, "A whale means ONE out of four neighbours is land"),
	fish = ClueType.new(false, 2, "Fish mean TWO out of four neighbours are land"),
	seagulls = ClueType.new(false, 3, "Seagulls mean THREE out of four neighbours are land"),
}

func create(level_node):
	land = level_node.get_node("land")
	clues = level_node.get_node("clues")
	grid = level_node.get_node("grid")
	level_node.remove_child(land)
	level_node.remove_child(clues)
	level_node.remove_child(grid)
	level_node.free()
	
	n = grid.get_used_rect().size
	var margin = Vector2(0.5, 0.5) * grid.cell_size
	var size = n * grid.cell_size + 2 * margin
	var level_root = $level_area/level_root
	var scale = min(
		$level_area.shape.extents.x * 2 / size.x,
		$level_area.shape.extents.y * 2 / size.y)
	level_root.scale = Vector2(scale, scale)
	level_root.position = -n * grid.cell_size * scale / 2
	
	land.visible = false
	level_root.add_child(land)
	
	mist = create_tile_map()
	level_root.add_child(mist)
	update_mist()
	
	guesses = create_tile_map()
	level_root.add_child(guesses)
	init_guesses()
	
	level_root.add_child(clues)
	
	cursor = Sprite.new()
	cursor.visible = false
	cursor.texture = load("res://sprites/cursor.svg")
	level_root.add_child(cursor)
	
	grid.modulate = Color(1, 1, 1, 0.3)
	level_root.add_child(grid)
	
	var island_sizes = get_island_sizes()
	var size_counts = {}
	for size in island_sizes:
		if not size_counts.has(size):
			size_counts[size] = 0
		size_counts[size] += 1
	var unique_sizes = size_counts.keys()
	unique_sizes.sort()
	var text
	if len(unique_sizes) == 1:
		text = (plural(
				len(island_sizes),
				'There is %s island of %d %s',
				'There are %s islands of %d %s each') %
			[
				count_word(len(island_sizes)),
				unique_sizes[0],
				plural(unique_sizes[0], 'tile', 'tiles'),
			])
	else:
		text = plural(len(island_sizes), 'There is %s island:', 'There are %s islands:') % count_word(len(island_sizes))
		for size in unique_sizes:
			var count = size_counts[size]
			text += "\n— %s of %d %s" % [count_word(count), size, plural(size, 'tile', 'tiles')]
	get_node("scroll/islands_count").text = text

func plural(count, singular, plural):
	if count == 1:
		return singular
	else:
		return plural

func count_word(count):
	return ['none', 'one', 'two', 'three', 'four', 'five'][count]

func _ready():
	$scroll/hint_bg.visible = false

func show_instructions():
	$scroll/in_out.move_in()

func _input(event):
	if event is InputEventMouse:
		var coords = (grid.to_local(event.position) / grid.cell_size).floor()
		if not grid.get_used_rect().has_point(coords):
			coords = null
		if event is InputEventMouseMotion:
			update_cursor(coords)
		elif event is InputEventMouseButton and event.pressed and coords != null:
			match event.button_index:
				BUTTON_LEFT: toggle_guess(coords)
				BUTTON_RIGHT: erase_guess(coords)

func update_cursor(coords):
	var help_text = ""
	if coords == null:
		if cursor != null:
			cursor.visible = false
	else:
		if cursor != null:
			cursor.visible = true
			cursor.position = grid.position + (coords + Vector2(0.5, 0.5)) * grid.cell_size
			var cursor_texture = preload("res://sprites/cursor.svg")
			var clue_tile = clues.get_cell(coords.x, coords.y)
			if clue_tile >= 0:
				var clue_tile_name = clues.tile_set.tile_get_name(clue_tile)
				if clue_tile_name in CLUES:
					var clue = CLUES[clue_tile_name]
					help_text = clue.help_text
					if clue.matches(coords, guesses):
						cursor_texture = preload("res://sprites/correct.svg")
					else:
						cursor_texture = preload("res://sprites/incorrect.svg")
			cursor.texture = cursor_texture
	$scroll/hint_bg/help_text.text = help_text
	$scroll/hint_bg.visible = help_text != ""

func create_tile_map():
	var tile_map = TileMap.new()
	tile_map.tile_set = clues.tile_set
	tile_map.cell_size = clues.cell_size
	return tile_map

func init_guesses():
	var tile_set = guesses.tile_set
	for y in range(n.y):
		for x in range(n.x):
			var tile = clues.get_cell(x, y)
			if tile < 0:
				continue
			var tile_name = tile_set.tile_get_name(tile)
			if not CLUES.has(tile_name):
				continue
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

func erase_guess(coords):
	if clues.get_cell(coords.x, coords.y) >= 0:
		return # Filled by init_guesses() already
	guesses.set_cell(coords.x, coords.y, -1)
	check_solved()

func check_solved():
	if is_solved:
		return
	var land_tile = guesses.tile_set.find_tile_by_name("guess_land")
	var water_tile = guesses.tile_set.find_tile_by_name("guess_water")
	for y in range(n.y):
		for x in range(n.x):
			var guess = guesses.get_cell(x, y) == land_tile
			var actual = land.get_cell(x, y) != -1
			if guess != actual:
				return
	is_solved = true
	complete_level()

func complete_level():
	land.visible = true
	
	mist.add_child(preload("res://utils/fade_out.tscn").instance())
	
	guesses.add_child(preload("res://utils/fade_out.tscn").instance())
	
	grid.add_child(preload("res://utils/fade_out.tscn").instance())
	
	cursor.get_parent().remove_child(cursor)
	cursor.queue_free()
	cursor = null
	
	$scroll/in_out.move_out()
	
	$solved_timer.start()

func _on_solved_timer_timeout():
	emit_signal("solved")

func update_mist():
	for y in range(-1, n.y + 1):
		for x in range(-5, n.x + 5):
			var mist_name = "mist_lr"
			# if x >= 0: mist_name += "l"
			# if x < n.x: mist_name += "r"
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