extends Node

onready var _level : Level = $Viewport

var _depth := 0
var _width := 0
var _height := 0
var _theme := 0
var _cliff := 0.0
var _wonky := false
var _wonkyRoom := false
var _syncWonky := false
var _syncRotate := 0
var _syncFlip := false

func _ready() -> void:
	Utility.ok(_level.connect("generate", self, "_generate"))

func _generate() -> void:
	_theme = Random.next(2)
	_cliff = Random.Next() < 0.2
	_wonky = Random.nextBool()
	_wonkyRoom = Random.nextBool()
	_syncWonky = Random.nextBool()
	_syncRotate = Random.next(4) * 90
	_syncFlip = Random.nextBool()
	match Random.next(8):
		0: _generateBasic()
		1: _generateDungeon()
		2: _generateCrossroad()
		3: _generateMaze()
		4: _generateBuilding()
		5: _generateCave()
		6: _generateTemplate()
		7: _generateTemplateCastle()

func _size() -> void:
	var d = 10 + _depth
	_width = d * 2 + Random.next(d)

func _clear(_wall: bool) -> void:
	pass
	# for y in size.y:
	# 	for x in size.x:
			# _level.set

func _generateBasic() -> void:
	_size()
	_clear(true)

func _generateDungeon() -> void:
	pass

func _generateCrossroad() -> void:
	pass

func _generateMaze() -> void:
	pass

func _generateBuilding() -> void:
	pass

func _generateCave() -> void:
	pass

func _generateTemplate() -> void:
	pass

func _generateTemplateCastle() -> void:
	pass
