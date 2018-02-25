extends Node

var current_level = 1

onready var water = $water
onready var level_root = $level_root
onready var scroll_tween = $level_root/scroll_tween
onready var sail_distance = get_viewport().size.y
var old_level_node
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
	level_node.position.y = -level_root.position.y - sail_distance
	level_root.add_child(level_node)
	
	scroll_tween.interpolate_method(self, "set_level_y",
		level_root.position.y, level_root.position.y + sail_distance,
		2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	scroll_tween.start()
	
	level_node.connect("solved", self, "level_solved")

func set_level_y(value):
	level_root.position.y = value
	water.region_rect = Rect2(Vector2(0, -value), get_viewport().size)

func _on_scroll_tween_tween_completed(object, key):
	if old_level_node:
		level_root.remove_child(old_level_node)
		old_level_node.queue_free()
		old_level_node = null
	if level_node and not level_node.is_solved:
		level_node.show_instructions()

func switch_level(level_number):
	current_level = level_number
	old_level_node = level_node
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