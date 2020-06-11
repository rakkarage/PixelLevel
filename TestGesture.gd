extends Node

func _ready() -> void:
	Utility.ok(Gesture.connect("onZoom", self, "_onZoom"))
	Utility.ok(Gesture.connect("onRotate", self, "_onRotate"))

func _onZoom(at: Vector2, value: float) -> void:
	print("zoom")
	$Sprite.position = at
	$Sprite.scale = Vector2(value, value)

func _onRotate(at: Vector2, value: int) -> void:
	print("rotate")
	$Sprite.position = at
	$Sprite.rotation = value
