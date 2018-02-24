extends Tween

onready var target = get_node("..")

func _ready():
	print("HIDING SCROLL")
	interpolate_method(self, "update_y", target.position.y, get_viewport().size.y + target.texture.get_height() / 2, 1, TRANS_QUAD, EASE_IN)

func update_y(value):
	target.position.y = value