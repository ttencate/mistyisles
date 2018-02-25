extends Node

var LEVELS = [
	preload("res://levels/level_01.tscn"),
	preload("res://levels/level_02.tscn"),
]
var current_level = 0
var level_node

func _ready():
	create_level(current_level)

func create_level(name):
	level_node = preload("res://level.tscn").instance()
	level_node.create(LEVELS[current_level].instance())
	get_node("level_root").add_child(level_node)
	level_node.connect("solved", self, "level_solved")

func level_solved():
	get_node("level_root").remove_child(level_node)
	level_node.queue_free()
	current_level += 1
	if current_level < len(LEVELS):
		create_level(current_level)
	else:
		print("You win!") # TODO
		pass

func _input(event):
	if OS.has_feature("debug"):
		if event is InputEventKey and event.pressed:
			match event.scancode:
				KEY_ESCAPE:
					get_tree().quit()