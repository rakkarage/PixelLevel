extends Generate

onready var _aBack : Image
onready var _aFore : Image
onready var _basicBack : Image
onready var _basicFore : Image
onready var _castleBack : Image
onready var _castleFore : Image

var _data := {
	"a": {
		"back": _aBack,
		"fore": _aFore,
		"size": 15,
		"priority": 33
	},
	"b": {
		"back": _basicBack,
		"fore": _basicFore,
		"size": 15,
		"priority": 100
	},
	"c": {
		"back": _castleBack,
		"fore": _castleFore,
		"size": 75,
		"priority": 1
	}
}

func _ready() -> void:
	_data.a.back = load("res://PixelLevel/Sprite/Template/ABack.png")
	_data.a.fore = load("res://PixelLevel/Sprite/Template/AFore.png")
	_data.b.back = load("res://PixelLevel/Sprite/Template/BasicBack.png")
	_data.b.fore = load("res://PixelLevel/Sprite/Template/BasicFore.png")
	_data.c.back = load("res://PixelLevel/Sprite/Template/CastleBack.png")
	_data.c.fore = load("res://PixelLevel/Sprite/Template/CastleFore.png")
	# _loadTemplates()
	for _i in range(33):
		print(Utility.priority(_data))

func generate() -> void:
	.generate()
	_fill(false, true)
	_stairs()
	if _stream:
		_generateStreams()
	_level.generated()

# func _loadTemplates() -> void:
# 	_aBack.lock()
# 	var size = _aBack.get_size()
# 	for y in range(size.y):
# 		for x in range(size.x):
# 			var color = _aBack.get_pixel(x, y)
# 			if color != Color(0, 0, 0, 1):
# 				print(color)
# 	_aBack.unlock()
