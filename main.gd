extends Node

var current_level = 0

onready var water = $water
onready var level_root = $level_root
onready var scroll_tween = $level_root/scroll_tween
onready var ship = $level_root/ship
onready var sail_distance = get_viewport().size.y

onready var screen_node = $level_root/start_screen
var old_screen_node

var sailing_speed = 256

func _ready():
	var path_in = screen_node.get_node("path_in")
	ship.get_parent().remove_child(ship)
	path_in.add_child(ship)
	ship.offset = 0
	ship.get_node("tween_in").interpolate_method(self, "set_ship_offset",
		0, path_in.curve.get_baked_length(),
		path_in.curve.get_baked_length() / sailing_speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	ship.get_node("tween_in").start()

func create_level(level_number):
	var level_scene = load("res://levels/level_%02d.tscn" % level_number)
	if not level_scene:
		return null
	var level_node = preload("res://level.tscn").instance()
	level_node.create(level_number, level_scene.instance())
	return level_node

func switch_screen(new_screen_node):
	old_screen_node = screen_node
	screen_node = new_screen_node
	
	screen_node.position.y = -level_root.position.y - sail_distance
	level_root.add_child(screen_node)
	
	var path_out = old_screen_node.get_node("path_out")
	ship.get_parent().remove_child(ship)
	path_out.add_child(ship)
	ship.offset = 0
	ship.get_node("tween_out").interpolate_method(self, "set_ship_offset",
		0, path_out.curve.get_baked_length(),
		path_out.curve.get_baked_length() / sailing_speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	ship.get_node("tween_out").start()
	
	screen_node.connect("solved", self, "level_solved")

func _process(delta):
	if ship.global_position.y < $scroll_edge.global_position.y and not scroll_tween.is_active():
		scroll_tween.interpolate_method(self, "set_level_y",
			level_root.position.y, level_root.position.y + sail_distance,
			1.3, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		scroll_tween.start()

func set_level_y(value):
	level_root.position.y = value
	water.region_rect = Rect2(0, -value, 1024, 1024)

func set_ship_offset(offset):
	ship.offset = offset
	var curve = ship.get_parent().curve
	var from = curve.interpolate_baked(offset - 1)
	var to = curve.interpolate_baked(offset + 1)
	var angle = Vector2(0, -1).angle_to(to - from)
	var texture
	if angle < -0.2:
		texture = preload("res://sprites/ship_left.svg")
	elif angle > 0.2:
		texture = preload("res://sprites/ship_right.svg")
	else:
		texture = preload("res://sprites/ship_up.svg")
	ship.get_node("ship_sprite").texture = texture

func level_solved():
	switch_level(current_level + 1)

func _on_ship_tween_out_tween_completed(object, key):
	var path_in = screen_node.get_node("path_in")
	ship.get_parent().remove_child(ship)
	path_in.add_child(ship)
	ship.offset = 0
	ship.get_node("tween_in").interpolate_method(self, "set_ship_offset",
		0, path_in.curve.get_baked_length(),
		path_in.curve.get_baked_length() / sailing_speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	ship.get_node("tween_in").start()

func _on_ship_tween_in_tween_completed(object, key):
	if old_screen_node:
		level_root.remove_child(old_screen_node)
		old_screen_node.queue_free()
		old_screen_node = null
	if screen_node and not screen_node.is_solved:
		screen_node.show_instructions()
	scroll_tween.remove_all()

func switch_level(level_number):
	current_level = level_number
	var next_screen = create_level(current_level)
	if not next_screen:
		next_screen = preload("res://end_screen.tscn").instance()
		sailing_speed /= 2
	switch_screen(next_screen)

func _input(event):
	if OS.has_feature("debug"):
		if event is InputEventKey and event.pressed:
			match event.scancode:
				KEY_ESCAPE:
					get_tree().quit()
					return
			if event.unicode >= 97 and event.unicode <= 122:
				switch_level(event.unicode - 97 + 1)
