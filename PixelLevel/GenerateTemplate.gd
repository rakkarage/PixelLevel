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

var _data := {
	"a": {
		"name": "a",
		"back": load("res://PixelLevel/Sprite/Template/ABack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/AFore.png"),
		"size": 15,
		"priority": 33
	},
	"b": {
		"name": "b",
		"back": load("res://PixelLevel/Sprite/Template/BasicBack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/BasicFore.png"),
		"size": 15,
		"priority": 100
	},
	"c": {
		"name": "c",
		"back": load("res://PixelLevel/Sprite/Template/CastleBack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/CastleFore.png"),
		"size": 75,
		"priority": 1
	}
}

func _init(level: Level).(level) -> void: pass

func generate() -> void:
	.generate()
	_cliff = false
	_fill(true, true)
	_applyTemplate(Random.priority(_data))
	_stairs()
	if _stream:
		_generateStreams()
	_level.generated()

func _applyTemplate(template: Dictionary) -> void:
	_applyTemplateAt(template, Vector2.ZERO)

func _applyTemplateAt(template: Dictionary, p: Vector2) -> void:
	template.back.lock()
	template.fore.lock()
	var width: int = template.back.get_size().x
	var height: int = template.back.get_size().y
	var countX := int(width / template.size)
	var countY := int(height / template.size)
	var readX := Random.next(countX)
	var readY := Random.next(countY)
	var rotate := Random.next(4)
	for y in range(template.size):
		for x in range(template.size):
			var write: Vector2
			match rotate:
				0: write = Vector2(p.x + x, p.y + y)
				1: write = Vector2(p.x + y, p.y + template.size - x - 1)
				2: write = Vector2(p.x + template.size - x - 1, p.y + template.size - y - 1)
				3: write = Vector2(p.x + template.size - y - 1, p.y + x)
			var backColor: Color = template.back.get_pixel(readX * template.size + x, readY * template.size + y)
			var foreColor: Color = template.fore.get_pixel(readX * template.size + x, readY * template.size + y)
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
