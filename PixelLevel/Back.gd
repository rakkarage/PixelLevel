@tool
extends Control

func _ready() -> void:
	Utility.stfu(get_node("..").connect("resized", Callable(self, "_onResized")))

func _onResized() -> void:
	var tex := size
	var win := get_viewport_rect().size
	if win.x > win.y:
		rotation = 90
		scale = Vector2(win.y / tex.x, win.x / tex.y)
	else:
		rotation = 0
		scale = Vector2(win.x / tex.x, win.y / tex.y)
