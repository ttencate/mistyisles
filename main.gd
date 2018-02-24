extends Node

func _ready():
	create_level("01")

func create_level(name):
	var level_area = get_node("level_area")
	
	var scene = load("res://level_" + name + ".tscn")
	var level = scene.instance()
	level_area.add_child(level)
	
	var scale = min(
		level_area.shape.extents.x * 2 / level.size.x,
		level_area.shape.extents.y * 2 / level.size.y)
	level.scale.x = scale
	level.scale.y = scale
	level.position = -level.size * level.scale / 2
	
	var island_sizes = level.get_island_sizes()
	island_sizes.sort()
	var text
	if len(island_sizes) == 1:
		text = "There is one island, of %d tiles" % island_sizes[0]
	else:
		text = "There are %d islands:" % len(island_sizes)
		for size in island_sizes:
			text += "\n— One of %d tiles" % size
	get_node("islands_count").text = text

func _input(event):
	if OS.has_feature("debug"):
		if event is InputEventKey and event.pressed:
			match event.scancode:
				KEY_ESCAPE:
					get_tree().quit()