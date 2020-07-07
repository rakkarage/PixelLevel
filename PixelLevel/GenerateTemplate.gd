extends Generate

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

func _ready() -> void:
	# _loadTemplates()
	for _i in range(33):
		print(Random.priority(_data))

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
