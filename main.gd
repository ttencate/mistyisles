extends Node

var current_level = 1
var level_node

func _ready():
	create_level(current_level)

func create_level(name):
	var level_area = get_node("level_area")
	
	var scene = load("res://level_%02d.tscn" % current_level)
	level_node = scene.instance()
	level_area.add_child(level_node)
	
	var scale = min(
		level_area.shape.extents.x * 2 / level_node.size.x,
		level_area.shape.extents.y * 2 / level_node.size.y)
	level_node.scale.x = scale
	level_node.scale.y = scale
	level_node.position = -level_node.size * level_node.scale / 2
	
	var island_sizes = level_node.get_island_sizes()
	island_sizes.sort()
	var text
	if len(island_sizes) == 1:
		text = "There is one island, of %d tiles" % island_sizes[0]
	else:
		text = "There are %d islands:" % len(island_sizes)
		for size in island_sizes:
			text += "\n— One of %d tiles" % size
	get_node("scroll/islands_count").text = text
	
	level_node.connect("solved", self, "level_solved")

func level_solved():
	get_node("scroll/hide").start()

func _on_scroll_hide_tween_completed( object, key ):
	get_node("next_level_timer").start()

func _on_next_level_timer_timeout():
	level_node.get_parent().remove_child(level_node)
	level_node.queue_free()
	current_level += 1
	create_level(current_level)

func _input(event):
	if OS.has_feature("debug"):
		if event is InputEventKey and event.pressed:
			match event.scancode:
				KEY_ESCAPE:
					get_tree().quit()
