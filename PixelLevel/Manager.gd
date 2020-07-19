extends Node

onready var _level : Level = $Level/Viewport
onready var _mask : AnimationPlayer = $Fore/Viewport/Mask/AnimationPlayer
onready var _textureRect : TextureRect = $Fore/Viewport/MiniMap
onready var _minus : Button = $Fore/Viewport/Panel/VBox/HBox/Minus
onready var _toggle : Button = $Fore/Viewport/Panel/VBox/HBox/Toggle
onready var _plus : Button = $Fore/Viewport/Panel/VBox/HBox/Plus
onready var _imageTexture := ImageTexture.new()
onready var _image := Image.new()
const _max := Vector2(64, 64)

func _ready() -> void:
	_textureRect.texture = _imageTexture
	_updateMap()
	Utility.ok(_level.connect("updateMap", self, "_updateMap"))
	Utility.ok(_level.connect("generate", self, "_generate"))
	Utility.ok(_minus.connect("pressed", self, "_lightMinus"))
	Utility.ok(_toggle.connect("pressed", self, "_lightToggle"))
	Utility.ok(_plus.connect("pressed", self, "_lightPlus"))

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

onready var _g := {
	GenerateBasic.new(_level): 100,
	GenerateRoom.new(_level): 100,
	GenerateDungeon.new(_level): 33,
	GenerateMaze.new(_level): 33,
	GenerateCave.new(_level): 10,
	GenerateWalker.new(_level): 10,
	GenerateTemplate.new(_level): 1,
}

func _generate() -> void:
	yield(get_tree(), "idle_frame")
	_mask.play("Mask")
	Utility.ok(_mask.connect("animation_finished", self, "_finished"))

func _finished(name: String) -> void:
	Random.priority(_g).generate()
	_mask.play_backwards(name)
	_mask.disconnect("animation_finished", self, "_finished")

func _lightMinus() -> void:
	_level.lightDecrease()

func _lightToggle() -> void:
	_level.lightToggle()

func _lightPlus() -> void:
	_level.lightIncrease()
