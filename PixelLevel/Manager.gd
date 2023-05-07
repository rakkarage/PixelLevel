extends Node

@onready var _level: Level = $Level/SubViewport
@onready var _mask: AnimationPlayer = $Fore/Mask/AnimationPlayer
@onready var _textureRect: TextureRect = $Fore/MiniMap
@onready var _position: Label = $Fore/Panel/VBox/Mouse/Value
@onready var _depth: Label = $Fore/Panel/VBox/Level/Value
@onready var _up: Button = $Fore/Panel/VBox/HBoxLevel/Up
@onready var _regen: Button = $Fore/Panel/VBox/HBoxLevel/Regen
@onready var _down: Button = $Fore/Panel/VBox/HBoxLevel/Down
@onready var _light: Label = $Fore/Panel/VBox/Light/Value
@onready var _minus: Button = $Fore/Panel/VBox/HBoxLight/Minus
@onready var _toggle: Button = $Fore/Panel/VBox/HBoxLight/Toggle
@onready var _plus: Button = $Fore/Panel/VBox/HBoxLight/Plus
@onready var _imageTexture := ImageTexture.new()
@onready var _image := Image.new()
const _max := Vector2(64, 64)
var _timerUpdateMap = Timer.new()
const _updateMapDelay = 0.1

func _ready() -> void:
	_textureRect.texture = _imageTexture
	_updateMap()
	Utility.stfu(_level.connect("updateMap", Callable(self, "_limitedUpdateMap")))
	_timerUpdateMap.connect("timeout", Callable(self, "_updateMap"))
	add_child(_timerUpdateMap)
	Utility.stfu(_level.connect("generate", Callable(self, "_generate")))
	Utility.stfu(_level.connect("generateUp", Callable(self, "_levelUp")))
	Utility.stfu(_minus.connect("pressed", Callable(self, "_lightMinus")))
	Utility.stfu(_toggle.connect("pressed", Callable(self, "_lightToggle")))
	Utility.stfu(_plus.connect("pressed", Callable(self, "_lightPlus")))
	Utility.stfu(_up.connect("pressed", Callable(self, "_levelUp")))
	Utility.stfu(_regen.connect("pressed", Callable(self, "_levelRegen")))
	Utility.stfu(_down.connect("pressed", Callable(self, "_levelDown")))
	_light.text = str(_level.lightRadius)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var x := str(snapped(event.position.x, 0.01))
		var y := str(snapped(event.position.y, 0.01))
		_position.text = "({0}, {1})".format([x, y])

func _limitedUpdateMap() -> void:
	_timerUpdateMap.start(_updateMapDelay)

func _updateMap() -> void:
	var at := _level.mobPosition()
	var original := _level._back.get_used_rect().size
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
	false # _image.lock() # TODOConverter40, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	for y in range(size.y):
		for x in range(size.x):
			var actualX := int(x + offset.x)
			var actualY := int(y + offset.y)
			_image.set_pixel(x, y, _level.getMapColor(actualX, actualY))
	false # _image.unlock() # TODOConverter40, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	_image.expand_x2_hq2x()
	_image.expand_x2_hq2x()
	_imageTexture.create_from_image(_image)

@onready var _g := {
	# GenerateBasic.new(_level): 1,
	# GenerateRoom.new(_level): 1,
	GenerateDungeon.new(_level): 1,
	GenerateMaze.new(_level): 1,
	GenerateCave.new(_level): 1,
	GenerateWalker.new(_level): 1,
	GenerateTemplate.new(_level): 1,
}

var _selected: Generate

func _generate(delta: int = 1) -> void:
	await get_tree().idle_frame
	_mask.play("Mask")
	await _mask.animation_finished
	if delta != 0 or _selected == null:
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
	_updateMap()

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
