extends Generate
class_name GenerateTemplate

const _backFloor := Color8(0, 0, 0, 0)
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
		"back": load("res://PixelLevel/Sprite/Template/ABack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/AFore.png"),
		"size": 15,
		"priority": 33
	},
	"b": {
		"back": load("res://PixelLevel/Sprite/Template/BasicBack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/BasicFore.png"),
		"size": 15,
		"priority": 100
	},
	"c": {
		"back": load("res://PixelLevel/Sprite/Template/CastleBack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/CastleFore.png"),
		"size": 75,
		"priority": 1
	}
}

func _init(level: Level).(level) -> void: pass

func generate() -> void:
	.generate()
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
	var width = template.back.get_size().x / template.size
	var height = template.back.get_size().y / template.size
	# var randomX = Random.next(width)
	# var randomY = Random.next(height)
	for y in range(height):
		for x in range(width):
			var write : Vector2
			match Random.next(4):
				0: write = Vector2(p.x + x, p.y + y)
				1: write = Vector2(p.x + y, p.y + height - x - 1)
				2: write = Vector2(p.x + width - x - 1, p.y + height - y - 1)
				3: write = Vector2(p.x + width - y - 1, p.y + x)
			var backColor : Color = template.back.get_pixel(x, y)
			var foreColor : Color = template.fore.get_pixel(x, y)
			if backColor == _backFloor:
				_setFloorV(write)
			elif backColor == _backWall:
				_setWallV(write)
			elif backColor == _backFloorRoom:
				_setFloorRoomV(write)
			elif backColor == _backGrass:
				_setOutsideV(write)
			_level.clearForeV(write)
			if foreColor == _colorWaterShallow:
				_level.setWaterShallowV(write)
				_level.setRubbleV(write)
			elif foreColor == _colorWaterDeep:
				_level.setWaterDeepV(write)
				_level.setRubbleV(write)
			elif foreColor == _colorWaterShallowPurple:
				_level.setWaterShallowPurpleV(write)
				_level.setRubbleV(write)
			elif foreColor == _colorWaterDeepPurple:
				_level.setWaterDeepPurpleV(write)
				_level.setRubbleV(write)
			elif foreColor == _colorTileRed:
				_level.setDoorV(write)
				_setFloorV(write)
			elif foreColor == _colorTilePurple:
				_level.setFountainV(write)
				_setFloorV(write)
			elif foreColor == _colorTileYellow:
				_level.setLootV(write)
				_setFloorV(write)
	template.back.unlock()
	template.fore.unlock()
