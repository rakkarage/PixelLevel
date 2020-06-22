extends Node

onready var _level : Level = $Level/Viewport
onready var _textureRect : TextureRect = $Fore/Viewport/MiniMap
onready var _imageTexture := ImageTexture.new()
onready var _image := Image.new()
const _max := Vector2(64, 64)

func _ready() -> void:
	_textureRect.texture = _imageTexture
	_updateMap()
	Utility.ok(_level.connect("updateMap", self, "_updateMap"))

func _updateMap() -> void:
	var size := _level.getMapRect().size
	_image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	_image.lock()
	for y in range(size.y):
		for x in range(size.x):
			_image.set_pixel(x, y, _level.getMapColor(x, y))
	_image.unlock()
	_image.expand_x2_hq2x()
	_image.expand_x2_hq2x()
	_image.expand_x2_hq2x()
	_imageTexture.create_from_image(_image)
