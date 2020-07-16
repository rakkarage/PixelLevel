extends Node

onready var _level : Level = $Viewport
onready var _g := {
	GenerateBasic.new(_level): 100,
	GenerateRoom.new(_level): 100,
	GenerateDungeon.new(_level): 33,
	GenerateMaze.new(_level): 33,
	GenerateCave.new(_level): 10,
	GenerateWalker.new(_level): 10,
	GenerateTemplate.new(_level): 1,
}

func _ready() -> void:
	Utility.ok(_level.connect("generate", self, "_generate"))

func _generate() -> void:
	Random.priority(_g).generate()
