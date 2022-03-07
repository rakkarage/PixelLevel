extends Control

onready var _random := $Button
onready var _mob := $Mob

func _ready() -> void:
	_random.connect("pressed", self, "_randomPressed")

func _randomPressed() -> void:
	match Random.next(3):
		0: _mob.attack()
		1: _mob.walk()
		2: _mob.flip_h = not _mob.flip_h
