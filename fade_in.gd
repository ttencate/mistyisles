extends Tween

func _ready():
	get_node("..").visible = true
	update_opacity(0)
	interpolate_method(self, "update_opacity", 0, 3, 1, TRANS_SINE, EASE_IN_OUT)
	start()

func update_opacity(value):
	get_node("..").modulate.a = value

func _on_Tween_tween_completed(object, key):
	queue_free()