extends Tween

func _ready():
	get_node("..").visible = true
	interpolate_method(self, "update_opacity", get_node("..").modulate.a, 0, 2, TRANS_SINE, EASE_IN_OUT)
	start()

func update_opacity(value):
	get_node("..").modulate.a = value

func _on_Tween_tween_completed(object, key):
	get_node("..").visible = false
	queue_free()