extends Node2D
class_name Level

const tileSize = Vector2(16, 16)

func _ready() -> void:
	pass

func _process(delta) -> void:
	pass

func _unhandled_input(event) -> void:
	print(event)
	pass
	
func _unhandled_key_input(event) -> void:
	print(event)
	pass
