extends Node

var current_level = 1
var level_node

func _ready():
	create_level(current_level)

func create_level(level_number):
	var level_scene = load("res://levels/level_%02d.tscn" % level_number)
	if not level_scene:
		print("You win!") # TODO
		return
	level_node = preload("res://level.tscn").instance()
	level_node.create(level_scene.instance())
	get_node("level_root").add_child(level_node)
	level_node.connect("solved", self, "level_solved")

func switch_level(level_number):
	if level_node:
		get_node("level_root").remove_child(level_node)
		level_node.queue_free()
		level_node = null
	
	current_level = level_number
	create_level(current_level)

func level_solved():
	switch_level(current_level + 1)

func _input(event):
	if OS.has_feature("debug"):
		if event is InputEventKey and event.pressed:
			match event.scancode:
				KEY_ESCAPE:
					get_tree().quit()
					return
			if event.unicode >= 97 and event.unicode <= 122:
				switch_level(event.unicode - 97 + 1)