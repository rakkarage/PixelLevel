extends Generate

onready var _ABack : Image
onready var _AFore : Image
onready var _BasicBack : Image
onready var _BasicFore : Image
onready var _CastleBack : Image
onready var _CastleFore : Image

func _ready() -> void:
	_ABack = load("res://PixelLevel/Sprite/Template/ABack.png")
	_AFore = load("res://PixelLevel/Sprite/Template/AFore.png")
	_BasicBack = load("res://PixelLevel/Sprite/Template/BasicBack.png")
	_BasicFore = load("res://PixelLevel/Sprite/Template/BasicFore.png")
	_CastleBack = load("res://PixelLevel/Sprite/Template/CastleBack.png")
	_CastleFore = load("res://PixelLevel/Sprite/Template/CastleFore.png")
	_loadTemplates()

func generate() -> void:
	.generate()
	_fill(false, true)
	_stairs()
	if _stream:
		_generateStreams()
	_level.generated()

func _loadTemplates() -> void:
	_ABack.lock()
	var size = _ABack.get_size()
	for y in range(size.y):
		for x in range(size.x):
			var color = _ABack.get_pixel(x, y)
			if color != Color(0, 0, 0, 1):
				print(color)
	_ABack.unlock()
