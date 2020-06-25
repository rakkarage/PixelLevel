extends Node

onready var _level : Level = $Viewport

var _depth := 0
var _width := 0
var _height := 0
var _theme := 0
var _cliff := 0.0
var _wonky := false

func _ready() -> void:
	Utility.ok(_level.connect("generate", self, "_generate"))

func _generate() -> void:
	_depth += 1
	var d = 10 + _depth
	_width = d * 2 + Random.next(d)
	_height = d * 2 + Random.next(d)
	_theme = Random.next(2)
	_cliff = Random.nextFloat() < 0.2
	_wonky = Random.nextBool()
	match Random.next(8):
		0: _generateBasic()
		1: _generateDungeon()
		2: _generateCrossroad()
		3: _generateMaze()
		4: _generateBuilding()
		5: _generateCave()
		6: _generateTemplate()
		7: _generateTemplateCastle()

func _clear(wall: bool) -> void:
	for y in _height:
		for x in _width:
			_setFloor(x, y)
			if (wall):
				_setWall(x, y)

func _generateBasic() -> void:
	_clear(true)

func _generateDungeon() -> void:
	_clear(true)

func _generateCrossroad() -> void:
	_clear(true)

func _generateMaze() -> void:
	_clear(true)

func _generateBuilding() -> void:
	_clear(false)

func _generateCave() -> void:
	_clear(true)

func _generateTemplate() -> void:
	_clear(true)

func _generateTemplateCastle() -> void:
	_clear(false)

func _setFloor(x: int, y: int) -> void:
	var flipX = Random.nextBool() if _wonky else false
	var flipY = Random.nextBool() if _wonky else false
	var rot90 = Random.nextBool() if _wonky else false
	if _theme == 0:
		_level.setFloorA(x, y, flipX, flipY, rot90)
	else:
		_level.setFloorB(x, y, flipX, flipY, rot90)

func _setWall(x: int, y: int) -> void:
	var flipX = Random.nextBool() if _wonky else false
	if _theme == 0:
		_level.setWallA(x, y, flipX)
	else:
		_level.setWallB(x, y, flipX)
