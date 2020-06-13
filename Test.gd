extends Node

func _ready() -> void:
	$Sprite.global_rotation = 2
	Utility.ok(Gesture.connect("onZoom", self, "_onZoom"))
	Utility.ok(Gesture.connect("onRotate", self, "_onRotate"))

func _onZoom(at: Vector2, value: float) -> void:
	$Sprite.global_position = at
	if abs(value) > 0.1 and abs(value) < 20:
		var s : Vector2 = $Sprite.global_scale
		var zoom := - value * 0.02
		s.x = clamp(s.x + zoom, 1, 10)
		s.y = clamp(s.y + zoom, 1, 10)
		$Sprite.global_scale = s

func _onRotate(at: Vector2, value: float) -> void:
	$Sprite.global_position = at
	$Sprite.global_rotation += value
