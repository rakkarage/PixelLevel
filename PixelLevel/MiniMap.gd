extends Node

onready var _level : Level = $Level/Viewport
onready var _textureRect : TextureRect = $Fore/Viewport/MiniMap
onready var _imageTexture := ImageTexture.new()
onready var _image := Image.new()
const _max := Vector2(32, 32)

func _ready() -> void:
	_textureRect.texture = _imageTexture
	_updateMap()
	Utility.ok(_level.connect("updateMap", self, "_updateMap"))

func _updateMap() -> void:
	var at := _level.mobPosition()
	var original := _level.rect.size
	var size := original
	var offset := Vector2.ZERO
	if size.x > _max.x:
		size.x = _max.x
		offset.x = at.x - size.x / 2.0
		if offset.x < 0: offset.x = 0
		if offset.x > original.x - size.x + 1: offset.x = original.x - size.x + 1
	if size.y > _max.y:
		size.y = _max.y
		offset.y = at.y - size.y / 2.0
		if offset.y < 0: offset.y = 0
		if offset.y > original.y - size.y + 1: offset.y = original.y - size.y + 1
	_image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	_image.lock()
	for y in range(size.y):
		for x in range(size.x):
			var actualX := int(x + offset.x)
			var actualY := int(y + offset.y)
			_image.set_pixel(x, y, _level.getMapColor(actualX, actualY))
	_image.unlock()
	_image.expand_x2_hq2x()
	_image.expand_x2_hq2x()
	_imageTexture.create_from_image(_image)
