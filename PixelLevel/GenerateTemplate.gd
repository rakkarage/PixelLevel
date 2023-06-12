extends Generate
class_name GenerateTemplate

const _backFloor := Color8(71, 112, 76, 0)
const _backFloorRoom := Color8(255, 255, 255, 255)
const _backWall := Color8(0, 0, 0, 255)
const _backGrass := Color8(193, 255, 113, 255)

const _colorWaterShallow := Color8(128, 255, 248, 255)
const _colorWaterDeep := Color8(128, 200, 255, 255)
const _colorWaterShallowPurple := Color8(196, 110, 255, 255)
const _colorWaterDeepPurple := Color8(156, 82, 255, 255)
const _colorTileRed := Color8(255, 41, 157, 255)
const _colorTileYellow := Color8(255, 200, 33, 255)
const _colorTilePurple := Color8(132, 41, 255, 255)

var _select = Vector2.ZERO
var _rotate = 0

var _connectAny := []
var _connectAll := [0, 1, 2, 3]
var _connectWestEast := [1, 3]
var _connectNorthSouth := [0, 2]
var _connectNorth := [0]
var _connectEast := [1]
var _connectSouth := [2]
var _connectWest := [3]
var _connectNE := [2, 3]
var _connectSE := [0, 3]
var _connectSW := [0, 1]
var _connectNW := [2, 1]

var _data := {
	"a": {
		"name": "a",
		"back": load("res://PixelLevel/Sprite/Template/ABack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/AFore.png"),
		"size": 15,
		"probability": 33
	},
	"b": {
		"name": "b",
		"back": load("res://PixelLevel/Sprite/Template/BasicBack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/BasicFore.png"),
		"size": 15,
		"probability": 100
	},
	"c": {
		"name": "c",
		"back": load("res://PixelLevel/Sprite/Template/CastleBack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/CastleFore.png"),
		"size": 75,
		"probability": 1
	}
}

func _init(level: LevelBase) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	var template = Random.probability(_data)
	var single := true
	if template.name == "c":
		_cliff = false
		single = true
	else:
		single = Random.nextBool()
	if single:
		_setLevelRect(template.size + 10, template.size + 10)
		if template.name == "c":
			_fill(false, false, true)
		else:
			_fill(true, true)
		_findTemplateWith(template, _connectAny)
		_applyTemplateAt(template, Vector2(5, 5))
	else:
		if Random.nextBool(): # crossroad
			_setLevelRect(template.size * 3 + 10, template.size * 3 + 10)
			_fill(true, true)
			for y in range(3):
				for x in range(3):
					if x == 1 or y == 1:
						if x == 1 and y == 1:
							_findTemplateWith(template, _connectAll)
						elif x == 1 and y == 0:
							_findTemplateWith(template, _connectNorth)
						elif x == 1 and y == 1:
							_findTemplateWith(template, _connectSouth)
						elif x == 0 and y == 1:
							_findTemplateWith(template, _connectEast)
						elif x == 1 and y == 1:
							_findTemplateWith(template, _connectWest)
						_applyTemplateAt(template, Vector2(x * template.size + 5, y * template.size + 5))
		else:
			match Random.next(3):
				0: # all
					var width = Random.next(7)
					var height = Random.next(7)
					_setLevelRect(template.size * width, template.size * height)
					_fill(true, true)
					for y in range(height):
						for x in range(width):
							_findTemplateWith(template, _connectAll)
							_applyTemplateAt(template, Vector2(x * template.size, y * template.size))
				1: # loop
					var width = Random.next(7)
					var height = Random.next(7)
					_setLevelRect(template.size * width, template.size * height)
					_fill(true, true)
					for y in range(height):
						for x in range(width):
							if x == 0 and y == 0:
								_findTemplateWith(template, _connectNW)
								_applyTemplateAt(template, Vector2(x * template.size, y * template.size))
							elif x == width - 1 and y == 0:
								_findTemplateWith(template, _connectNE)
								_applyTemplateAt(template, Vector2(x * template.size, y * template.size))
							elif x == width - 1 and y == height - 1:
								_findTemplateWith(template, _connectSE)
								_applyTemplateAt(template, Vector2(x * template.size, y * template.size))
							elif x == 0 and y == height - 1:
								_findTemplateWith(template, _connectSW)
								_applyTemplateAt(template, Vector2(x * template.size, y * template.size))
							elif x == 0 or x == width - 1:
								_findTemplateWith(template, _connectNorthSouth)
								_applyTemplateAt(template, Vector2(x * template.size, y * template.size))
							elif y == 0 or y == height - 1:
								_findTemplateWith(template, _connectWestEast)
								_applyTemplateAt(template, Vector2(x * template.size, y * template.size))
				2: # tunnel
					var width: int
					var height: int
					var connections: Array
					if Random.nextBool():
						width = 1
						height = 1 + Random.next(7)
						connections = _connectNorthSouth
					else:
						width = 1 + Random.next(7)
						height = 1
						connections = _connectWestEast
					_setLevelRect(template.size * width, template.size * height)
					_fill(true, true)
					for y in range(height):
						for x in range(width):
							_findTemplateWith(template, connections)
							_applyTemplateAt(template, Vector2(x * template.size, y * template.size))
	_stairs()
	if _stream:
		_generateStreams()
	_level.generated()

func _applyTemplateAt(template: Dictionary, p: Vector2) -> void:
	for y in range(template.size):
		for x in range(template.size):
			var write := p + _applyRotate(x, y, template.size, _rotate)
			var backColor: Color = template.back.get_pixel(_select.x * template.size + x, _select.y * template.size + y)
			var foreColor: Color = template.fore.get_pixel(_select.x * template.size + x, _select.y * template.size + y)
			if backColor == _backFloor:
				_setFloor(write)
			elif backColor == _backWall:
				if template.name == "b":
					_setWallPlain(write)
				else:
					_setWall(write)
			elif backColor == _backFloorRoom:
				_setFloorRoom(write)
			elif backColor == _backGrass:
				_setOutside(write)
			if foreColor == _colorWaterShallow:
				_level.setWaterShallow(write)
			elif foreColor == _colorWaterDeep:
				_level.setWaterDeep(write)
			elif foreColor == _colorWaterShallowPurple:
				_level.setWaterShallowPurple(write)
			elif foreColor == _colorWaterDeepPurple:
				_level.setWaterDeepPurple(write)
			elif foreColor == _colorTileRed:
				_setFloorRoom(write)
				_level.setDoor(write)
			elif foreColor == _colorTilePurple:
				if Random.nextBool():
					if Random.nextBool():
						_level.setBanner0(write)
					else:
						_level.setBanner1(write)
				else:
					_level.setFountain(write)
			elif foreColor == _colorTileYellow:
				if Random.nextBool():
					_level.setLoot(write)

func _findTemplateWith(template: Dictionary, connections: Array) -> void:
	var size: int = template.size
	var countX := int(template.back.get_size().x / size)
	var countY := int(template.back.get_size().y / size)
	_select = Vector2(Random.next(countX), Random.next(countY))
	_rotate = Random.next(4)
	var offset := Vector2(_select.x * size, _select.y * size)
	var up := offset + _applyRotateBackV(Vector2(size / 2.0, 0), size, _rotate)
	var right := offset + _applyRotateBackV(Vector2(size - 1, size / 2.0), size, _rotate)
	var down := offset + _applyRotateBackV(Vector2(size / 2.0, size - 1), size, _rotate)
	var left := offset + _applyRotateBackV(Vector2(0, size / 2.0), size, _rotate)
	var connectUp: bool = template.back.get_pixel(up) != _backWall
	var connectRight: bool = template.back.get_pixel(right) != _backWall
	var connectDown: bool = template.back.get_pixel(down) != _backWall
	var connectLeft: bool = template.back.get_pixel(left) != _backWall
	while (connections.size() and
		(connections.has(0) and not connectUp) or
		(connections.has(1) and not connectRight) or
		(connections.has(2) and not connectDown) or
		(connections.has(3) and not connectLeft)):
		_select = Vector2(Random.next(countX), Random.next(countY))
		_rotate = Random.next(4)
		offset = Vector2(_select.x * size, _select.y * size)
		up = offset + _applyRotateBackV(Vector2(size / 2.0, 0), size, _rotate)
		right = offset + _applyRotateBackV(Vector2(size - 1, size / 2.0), size, _rotate)
		down = offset + _applyRotateBackV(Vector2(size / 2.0, size - 1), size, _rotate)
		left = offset + _applyRotateBackV(Vector2(0, size / 2.0), size, _rotate)
		connectUp = template.back.get_pixelv(up) != _backWall
		connectRight = template.back.get_pixelv(right) != _backWall
		connectDown = template.back.get_pixelv(down) != _backWall
		connectLeft = template.back.get_pixelv(left) != _backWall

func _applyRotateV(p: Vector2, size: int, rotate: int) -> Vector2:
	return _applyRotate(int(p.x), int(p.y), size, rotate)

func _applyRotate(x: int, y: int, size: int, rotate: int) -> Vector2:
	var value: Vector2
	match rotate:
		0: value = Vector2(x, y) # north
		1: value = Vector2(size - y - 1, x) # east
		2: value = Vector2(size - x - 1, size - y - 1) # south
		3: value = Vector2(y, size - x - 1) # west
	return value

func _applyRotateBackV(p: Vector2, size: int, rotate: int) -> Vector2:
	return _applyRotateBack(int(p.x), int(p.y), size, rotate)

func _applyRotateBack(x: int, y: int, size: int, rotate: int) -> Vector2:
	var value: Vector2
	match rotate:
		0: value = Vector2(x, y) # north
		1: value = Vector2(y, size - x - 1) # west
		2: value = Vector2(size - x - 1, size - y - 1) # south
		3: value = Vector2(size - y - 1, x) # east
	return value
