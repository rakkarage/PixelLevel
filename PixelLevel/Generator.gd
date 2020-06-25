extends Node

onready var _level : Level = $Viewport

var _depth := 0
var _width := 0
var _height := 0
var _theme := 0
var _cliff := 0.0
var _torch := 0.0
var _wonky := false

func _ready() -> void:
	Utility.ok(_level.connect("generate", self, "_generate"))

func _generate() -> void:
	_clear()
	_depth += 1
	var d = 10 + _depth
	_width = d * 2 + Random.next(d)
	_height = d * 2 + Random.next(d)
	_theme = Random.next(2)
	_cliff = Random.nextFloat() < 0.2
	_torch = Random.nextFloat() < 0.1
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

func _clear() -> void:
	_level.clear()

func _fill(wall: bool) -> void:
	for y in _height:
		for x in _width:
			_setFloor(x, y)
			if (wall):
				_setWall(x, y)

func _generateBasic() -> void:
	_fill(false)
	_level.generated()

func _generateDungeon() -> void:
	_fill(false)
	_level.generated()

func _generateCrossroad() -> void:
	_fill(false)
	_level.generated()

func _generateMaze() -> void:
	_fill(false)
	_level.generated()

func _generateBuilding() -> void:
	_fill(false)
	_level.generated()

func _generateCave() -> void:
	_fill(false)
	_level.generated()

func _generateTemplate() -> void:
	_fill(false)
	_level.generated()

func _generateTemplateCastle() -> void:
	_fill(false)
	_level.generated()

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
	var torch = Random.nextFloat() < _torch
	if _theme == 0:
		if torch:
			_level.setTorchA(x, y, flipX)
		else:
			_level.setWallA(x, y, flipX)
	else:
		if torch:
			_level.setTorchB(x, y, flipX)
		else:
			_level.setWallB(x, y, flipX)
