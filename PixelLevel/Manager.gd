extends Node

onready var _level : Level = $Level/Viewport
onready var _mask : AnimationPlayer = $Fore/Viewport/Mask/AnimationPlayer
onready var _textureRect : TextureRect = $Fore/Viewport/MiniMap
onready var _depth : Label = $Fore/Viewport/Panel/VBox/Level/Value
onready var _up : Button = $Fore/Viewport/Panel/VBox/HBoxLevel/Up
onready var _regen : Button = $Fore/Viewport/Panel/VBox/HBoxLevel/Regen
onready var _down : Button = $Fore/Viewport/Panel/VBox/HBoxLevel/Down
onready var _light : Label = $Fore/Viewport/Panel/VBox/Light/Value
onready var _minus : Button = $Fore/Viewport/Panel/VBox/HBoxLight/Minus
onready var _toggle : Button = $Fore/Viewport/Panel/VBox/HBoxLight/Toggle
onready var _plus : Button = $Fore/Viewport/Panel/VBox/HBoxLight/Plus
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
	Utility.ok(_up.connect("pressed", self, "_levelUp"))
	Utility.ok(_regen.connect("pressed", self, "_levelRegen"))
	Utility.ok(_down.connect("pressed", self, "_levelDown"))
	_light.text = str(_level.lightRadius)

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
	GenerateBasic.new(_level): 7,
	GenerateRoom.new(_level): 6,
	GenerateDungeon.new(_level): 5,
	GenerateMaze.new(_level): 4,
	GenerateCave.new(_level): 3,
	GenerateWalker.new(_level): 2,
	GenerateTemplate.new(_level): 1,
}

var _selected: Generate

func _generate(delta: int = 1) -> void:
	yield(get_tree(), "idle_frame")
	_mask.play("Mask")
	yield(_mask, "animation_finished")
	if delta != 0:
		_selected = Random.priority(_g)
	_selected.generate(delta)
	_depth.text = str(_level.state.depth)
	_light.text = str(_level.lightRadius)
	_mask.play_backwards("Mask")

func _lightMinus() -> void:
	_level.lightDecrease()
	_light.text = str(_level.lightRadius)

func _lightToggle() -> void:
	_level.lightToggle()

func _lightPlus() -> void:
	_level.lightIncrease()
	_light.text = str(_level.lightRadius)

func _levelUp() -> void:
	_generate(-1)
	_depth.text = str(_level.state.depth)

func _levelRegen() -> void:
	_generate(0)

func _levelDown() -> void:
	_generate()
	_depth.text = str(_level.state.depth)
