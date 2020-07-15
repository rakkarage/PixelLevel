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

var _connectAll := [0, 1, 2, 3]
var _connectWestEast := [1, 3]
var _connectNorthSouth := [0, 2]
var _connectNorh := [0]
var _connectEast := [1]
var _connectSouth := [2]
var _connectWest := [3]

var _data := {
	# "a": {
	# 	"name": "a",
	# 	"back": load("res://PixelLevel/Sprite/Template/ABack.png"),
	# 	"fore": load("res://PixelLevel/Sprite/Template/AFore.png"),
	# 	"size": 15,
	# 	"priority": 33
	# },
	"b": {
		"name": "b",
		"back": load("res://PixelLevel/Sprite/Template/BasicBack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/BasicFore.png"),
		"size": 15,
		"priority": 100
	},
	# "c": {
	# 	"name": "c",
	# 	"back": load("res://PixelLevel/Sprite/Template/CastleBack.png"),
	# 	"fore": load("res://PixelLevel/Sprite/Template/CastleFore.png"),
	# 	"size": 75,
	# 	"priority": 1
	# }
}

func _init(level: Level).(level) -> void:
	print(_applyRotate(2, 0, 5, 0)) # north
	print(_applyRotate(2, 0, 5, 1)) # east
	print(_applyRotate(2, 0, 5, 2)) # south
	print(_applyRotate(2, 0, 5, 3)) # west
	# (1, 0)
	# -x-
	# ---
	# ---
	# (2, 1)
	# ---
	# --x
	# ---
	# (1, 2)
	# ---
	# ---
	# -x-
	# (0, 1)
	# ---
	# x--
	# ---
	pass

func generate() -> void:
	.generate()
	var template = Random.priority(_data)
	var single := true
	if template.name == "c":
		_cliff = false
		single = true
	else:
		single = true#Random.nextBool()
	if single:
		_setLevelRect(template.size + 10, template.size + 10)
		_fill(true, true)
		_findTemplateWith(template, _connectSouth)
		_applyTemplateAt(template, Vector2(5, 5))
	else:
		if true:#Random.nextBool():
			_setLevelRect(template.size * 3 + 10, template.size * 3 + 10)
			_fill(true, true)
			for y in range(3):
				for x in range(3):
					if x == 1 or y == 1:
						if x == 1 and y == 1:
							_findTemplateWith(template, _connectAll)
						elif x == 1 and y == 0:
							_findTemplateWith(template, _connectNorh)
						elif x == 1 and y == 1:
							_findTemplateWith(template, _connectSouth)
						elif x == 0 and y == 1:
							_findTemplateWith(template, _connectEast)
						elif x == 1 and y == 1:
							_findTemplateWith(template, _connectWest)
						_applyTemplateAt(template, Vector2(x * template.size + 5, y * template.size + 5))
		else: # TODO: how to connect this big? loop!!! or crossroad or walker?
			var width = Random.next(7)
			var height = Random.next(7)
			_setLevelRect(template.size * width, template.size * height)
			_fill(true, true)
			for y in range(width):
				for x in range(height):
					_applyTemplateAt(template, Vector2(x * template.size, y * template.size))
	_stairs()
	# if _stream:
	# 	_generateStreams()
	_level.generated()

func _applyTemplateAt(template: Dictionary, p: Vector2) -> void:
	template.back.lock()
	template.fore.lock()
	for y in range(template.size):
		for x in range(template.size):
			var write := p + _applyRotate(x, y, template.size, _rotate)
			var backColor: Color = template.back.get_pixel(_select.x * template.size + x, _select.y * template.size + y)
			var foreColor: Color = template.fore.get_pixel(_select.x * template.size + x, _select.y * template.size + y)
			if backColor == _backFloor:
				_setFloorV(write)
			elif backColor == _backWall:
				if template.name == "b":
					_setWallPlainV(write)
				else:
					_setWallV(write)
			elif backColor == _backFloorRoom:
				_setFloorRoomV(write)
			elif backColor == _backGrass:
				_setOutsideV(write)
			if foreColor == _colorWaterShallow:
				_level.setWaterShallowV(write)
			elif foreColor == _colorWaterDeep:
				_level.setWaterDeepV(write)
			elif foreColor == _colorWaterShallowPurple:
				_level.setWaterShallowPurpleV(write)
			elif foreColor == _colorWaterDeepPurple:
				_level.setWaterDeepPurpleV(write)
			elif foreColor == _colorTileRed:
				_setFloorRoomV(write)
				_level.setDoorV(write)
			elif foreColor == _colorTilePurple:
				if Random.nextBool():
					if Random.nextBool():
						_level.setBanner0V(write)
					else:
						_level.setBanner1V(write)
				else:
					_level.setFountainV(write)
			elif foreColor == _colorTileYellow:
				if Random.nextBool():
					_level.setLootV(write)
	template.back.unlock()
	template.fore.unlock()

func _findTemplateWith(template: Dictionary, connections: Array) -> void:
	template.back.lock()
	var size: int = template.size
	var countX := int(template.back.get_size().x / size)
	var countY := int(template.back.get_size().y / size)
	_select = Vector2(Random.next(countX), Random.next(countY))
	_rotate = 0#Random.next(4)
	# TODO: check rotate by selecting 0,0 and see how it rotates
	print(template.name)
	var up := Vector2(int(_select.x * size + size / 2.0), int(_select.y * size))
	print(up)
	up = _applyRotateV(up, size, _rotate)
	print(up)
	var right := Vector2(int(_select.x * size + size), int(_select.y * size + size / 2.0))
	right = _applyRotateV(right, size, _rotate)
	var down := Vector2(int(_select.x * size + size / 2.0), int(_select.y * size + size))
	down = _applyRotateV(down, size, _rotate)
	var left := Vector2(int(_select.x * size), int(_select.y * size + size / 2.0))
	left = _applyRotateV(left, size, _rotate)
	var upColor: Color = template.back.get_pixelv(up)
	print(upColor)
	var connectUp: bool = upColor != Color.black
	print(connectUp)
	var rightColor: Color = template.back.get_pixelv(right)
	var connectRight: bool = rightColor != Color.black
	var downColor: Color = template.back.get_pixelv(down)
	var connectDown: bool = downColor != Color.black
	var leftColor: Color = template.back.get_pixelv(left)
	var connectLeft: bool = leftColor != Color.black
	while ((connections.has(0) and not connectUp) or
		(connections.has(1) and not connectRight) or
		(connections.has(2) and not connectDown) or
		(connections.has(3) and not connectLeft)):
		_select = Vector2(Random.next(countX), Random.next(countY))
		_rotate = 0#Random.next(4)
		up = Vector2(int(_select.x * size + size / 2.0), int(_select.y * size))
		up = _applyRotateV(up, size, _rotate)
		right = Vector2(int(_select.x * size + size), int(_select.y * size + size / 2.0))
		right = _applyRotateV(right, size, _rotate)
		down = Vector2(int(_select.x * size + size / 2.0), int(_select.y * size + size))
		down = _applyRotateV(down, size, _rotate)
		left = Vector2(int(_select.x * size), int(_select.y * size + size / 2.0))
		left = _applyRotateV(left, size, _rotate)
	template.back.unlock()

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
