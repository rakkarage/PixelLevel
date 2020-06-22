extends Node

onready var _level : Level = $Level/Viewport
onready var _textureRect : TextureRect = $Fore/Viewport/MiniMap
onready var _imageTexture := ImageTexture.new()
onready var _image := Image.new()
const _max := Vector2(64, 64)

# TODO: handle move and resize and zoom!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

func _ready() -> void:
	_textureRect.texture = _imageTexture
	_updateMap(Vector2.ZERO)
	Utility.ok(_level.connect("updateMap", self, "_updateMap"))

func _updateMap(at: Vector2) -> void:
	var original := _level.getMapRect().size
	var size := original
	var offset := Vector2.ZERO
	if size.x > _max.x:
		size.x = _max.x
		offset.x = at.x - size.x / 2.0
		if offset.x < 0: offset.x = 0
		if offset.x > original.x - size.x: offset.x = original.x - size.x
	if size.y > _max.y:
		size.y = _max.y
		offset.y = at.y - size.y / 2.0
		if offset.y < 0: offset.y = 0
		if offset.y > original.y - size.y: offset.y = original.y - size.y
	_image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	_image.lock()
	for y in range(size.y):
		for x in range(size.x):
			var actualX = x + offset.x
			var actualY = y + offset.y
			_image.set_pixel(x, y, _level.getMapColor(actualX, actualY))
	_image.unlock()
	_image.expand_x2_hq2x()
	_image.expand_x2_hq2x()
	_imageTexture.create_from_image(_image)
