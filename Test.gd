extends Node

func _ready() -> void:
	$Sprite.rotation_degrees = 90
	Utility.ok(Gesture.connect("onZoom", self, "_onZoom"))
	Utility.ok(Gesture.connect("onRotate", self, "_onRotate"))

func _onZoom(at: Vector2, value: float) -> void:
	if abs(value) > 0.1 and abs(value) < 20:
		var s : Vector2 = $Sprite.scale
		var zoom := - value * 0.02
		s.x = clamp(s.x + zoom, 1, 10)
		s.y = clamp(s.y + zoom, 1, 10)
		$Sprite.scale = s
	# print("zoom: %s" % value)
	$Sprite.position = at
	# $Sprite.scale *= Vector2(value, value)

func _onRotate(at: Vector2, value: float) -> void:
	$Sprite.rotation += value
	$Sprite.position = at
