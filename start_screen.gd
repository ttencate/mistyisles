extends Node2D

signal solved

var is_solved = false

func _ready():
	$hint_bg.modulate.a = 0
	$fade_tween.interpolate_method(self, "set_hint_alpha", 0, 1, 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 1)
	$fade_tween.start()

func set_hint_alpha(value):
	$hint_bg.modulate.a = value

func _input(event):
	if event is InputEventMouseButton and event.pressed and not is_solved:
		is_solved = true
		$solved_timer.start()
		$fade_tween.interpolate_method(self, "set_alpha", 1, 0, 0.5, Tween.TRANS_SINE, Tween.EASE_OUT)
		$fade_tween.start()

func set_alpha(value):
	$title.modulate.a = value
	$author.modulate.a = value
	$hint_bg.modulate.a = value

func _on_solved_timer_timeout():
	emit_signal("solved")

func show_instructions():
	pass # dummy