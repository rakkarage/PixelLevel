extends Node

onready var _level : Level = $Viewport
onready var _g := {
	GenerateBasic.new(_level): 1,
	GenerateRoom.new(_level): 1,
	GenerateDungeon.new(_level): 1,
	GenerateMaze.new(_level): 1,
	GenerateCave.new(_level): 1,
	GenerateWalker.new(_level): 1,
	GenerateTemplate.new(_level): 1,
	GenerateTemplateCrossroad.new(_level): 1,
	GenerateTemplateCastle.new(_level): 1,
}

func _ready() -> void:
	Utility.ok(_level.connect("generate", self, "_generate"))

func _generate() -> void:
	Random.priority(_g).generate()
