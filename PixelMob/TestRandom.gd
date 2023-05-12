extends Control

@onready var _random := $Button
@onready var _mob := $Mob

func _ready() -> void:
	Utility.stfu(_random.connect("pressed", Callable(self, "_randomPressed")))

func _randomPressed() -> void:
	match Random.next(3):
		0: _mob.attack()
		1: _mob.walk()
		2: _mob.flip_h = not _mob.flip_h
