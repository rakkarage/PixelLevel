extends Generate

const _backFloor := Color8(0, 0, 0, 0)
const _backFloorRoom := Color8(255, 255, 255, 255)
const _backWall := Color8(0, 0, 0, 255)
const _backGrass := Color8(193, 255, 113, 255)

const _colorWaterShallow := Color8(128, 255, 248, 255)
const _colorWaterDeep := Color8(128, 200, 255, 255)
const _colorWaterPurpleShallow := Color8(196, 110, 255, 255)
const _colorWaterPurpleDeep := Color8(156, 82, 255, 255)
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

func generate() -> void:
	.generate()
	_fill(false, true)
	_applyTemplate(Random.priority(_data))
	_stairs()
	if _stream:
		_generateStreams()
	_level.generated()

func _applyTemplate(template: Dictionary) -> void:
	_applyTemplateAt(template, Vector2.ZERO)

func _applyTemplateAt(template: Dictionary, p: Vector2) -> void:
	var width = template.back.size().x / template.size
	var height = template.back.size().y / template.size
	var randomX = Random.next(width)
	var randomY = Random.next(height)
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
			var wall = false
			var ignore = false
			var grass = false
			if backColor == _backFloor:
				_level.clearForeV(write)
				_level.setFloorV(write)
			elif backColor == _backWall:
				_level.clearBackV(write)
				_setWallV(write)
				wall = true
			elif backColor == _backFloorRoom:
				_level.clearForeV(write)
				_level.setFloorRoomV(write)
			elif backColor == _backGrass:
				# _setOutside()
				grass = true
# 			else if ((backColor.r == colorGrass.r) && (backColor.g == colorGrass.g) && (backColor.b == colorGrass.b) && (backColor.a == colorGrass.a))
# 			{
# 				SetOutside(writePosition);
# 				grass = true;
# 			}
# 			else ignore |= ((backColor.r == colorIgnore.r) && (backColor.g == colorIgnore.g) && (backColor.b == colorIgnore.b) && (backColor.a == colorIgnore.a));
# 			if (!ignore)
# 			{
# 				if (!wall) ClearForeground(writePosition);
# 				if (!grass)
# 				{
# 					ClearFlora(writePosition);
# 					ClearFog(writePosition);
# 					ClearWater(writePosition);
# 				}
# 			}
# 			if (!wall && (foreColor.r == colorWaterShallow.r) && (foreColor.g == colorWaterShallow.g) && (foreColor.b == colorWaterShallow.b) && (foreColor.a == colorWaterShallow.a))
# 			{
# 				SetWater(writePosition, false);
# 				SetRubble(writePosition);
# 			}
# 			else if (!wall && (foreColor.r == colorWaterDeep.r) && (foreColor.g == colorWaterDeep.g) && (foreColor.b == colorWaterDeep.b) && (foreColor.a == colorWaterDeep.a))
# 			{
# 				SetWater(writePosition, true);
# 				SetRubble(writePosition);
# 			}
# 			else if (!wall && (foreColor.r == colorWaterPurpleShallow.r) && (foreColor.g == colorWaterPurpleShallow.g) && (foreColor.b == colorWaterPurpleShallow.b) && (foreColor.a == colorWaterPurpleShallow.a))
# 			{
# 				SetWater(writePosition, false, true);
# 				SetRubble(writePosition);
# 			}
# 			else if (!wall && (foreColor.r == colorWaterPurpleDeep.r) && (foreColor.g == colorWaterPurpleDeep.g) && (foreColor.b == colorWaterPurpleDeep.b) && (foreColor.a == colorWaterPurpleDeep.a))
# 			{
# 				SetWater(writePosition, true, true);
# 				SetRubble(writePosition);
# 			}
# 			else if ((foreColor.r == colorTileRed.r) && (foreColor.g == colorTileRed.g) && (foreColor.b == colorTileRed.b) && (foreColor.a == colorTileRed.a))
# 				SetDoor(writePosition);
# 			else if ((foreColor.r == colorTilePurple.r) && (foreColor.g == colorTilePurple.g) && (foreColor.b == colorTilePurple.b) && (foreColor.a == colorTilePurple.a))
# 				SetFountain(writePosition);
# 			else if ((foreColor.r == colorTileYellow.r) && (foreColor.g == colorTileYellow.g) && (foreColor.b == colorTileYellow.b) && (foreColor.a == colorTileYellow.a))
# 				SetLoot(writePosition);
# 		}
# 	}
# }

# func _loadTemplates() -> void:
# 	_aBack.lock()
# 	var size = _aBack.get_size()
# 	for y in range(size.y):
# 		for x in range(size.x):
# 			var color = _aBack.get_pixel(x, y)
# 			if color != Color(0, 0, 0, 1):
# 				print(color)
# 	_aBack.unlock()
