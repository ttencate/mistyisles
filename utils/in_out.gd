extends Tween

export (Vector2) var offset

onready var target = get_node("..")
onready var visible_y = target.position.y
onready var hidden_y = visible_y + offset.y

signal moved_in
signal moved_out

func _ready():
	update_y_in(hidden_y)

func move_in():
	interpolate_method(self, "update_y_in", target.position.y, visible_y, 0.5, TRANS_QUAD, EASE_OUT)
	start()

func move_out():
	interpolate_method(self, "update_y_out", target.position.y, hidden_y, 0.5, TRANS_QUAD, EASE_IN)
	start()

func update_y_in(value):
	target.position.y = value

func update_y_out(value):
	target.position.y = value

func _on_in_out_tween_completed(object, key):
	match key:
		@":update_y_in":
			emit_signal("moved_in")
		@":update_y_out":
			emit_signal("moved_out")