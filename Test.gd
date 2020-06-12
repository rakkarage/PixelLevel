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
	print("rot: %s"  % value)
	if abs(value) > 0.001 and abs(value) < 0.5:
		print("inside")
		var r : float = $Sprite.rotation
		print(r)
		var a := value * 10
		print(a)
		$Sprite.rotation_degrees -= rad2deg(a)
		print($Sprite.rotation_degrees)
	else: print(value)
	$Sprite.position = at
# 	print("rotate: %s" % value)
# 	$Sprite.position = at
# 	$Sprite.rotation += value
