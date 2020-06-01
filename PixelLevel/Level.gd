extends Node2D
class_name Level

onready var back := $Back
onready var fore := $Back
onready var mob := $Mob
onready var target := $Target
onready var nav := $Nav

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != BUTTON_LEFT or not event.pressed:
		return
	print(back.world_to_map(event.position))
