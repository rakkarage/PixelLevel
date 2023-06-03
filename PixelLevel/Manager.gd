extends Node

@onready var _level: Level = $Level/SubViewport
@onready var _mask: AnimationPlayer = $Fore/Mask/Mask/AnimationPlayer
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
const _max := Vector2i(64, 64)
var _timerUpdateMap = Timer.new()
const _updateMapDelay = 0.1

func _ready() -> void:
	_textureRect.texture = _imageTexture
	_updateMap()
	_level.connect("updateMap", _limitedUpdateMap)
	_timerUpdateMap.connect("timeout", _updateMap)
	add_child(_timerUpdateMap)
	_level.connect("generate", _generate)
	_level.connect("generateUp", _levelUp)
	_minus.connect("pressed", _lightMinus)
	_toggle.connect("pressed", _lightToggle)
	_plus.connect("pressed", _lightPlus)
	_up.connect("pressed", _levelUp)
	_regen.connect("pressed", _levelRegen)
	_down.connect("pressed", _levelDown)
	_light.text = str(_level.lightRadius)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var x := str(snapped(event.position.x, 0.01))
		var y := str(snapped(event.position.y, 0.01))
		_position.text = "({0}, {1})".format([x, y])

func _limitedUpdateMap() -> void:
	_timerUpdateMap.start(_updateMapDelay)

func _updateMap() -> void:
	var at := Vector2i(_level.mobPosition()) # TODO: make mob return int
	var original := _level._back.get_used_rect().size
	var size := original
	var offset := Vector2i.ZERO
	if size.x > _max.x:
		size.x = _max.x
		offset.x = at.x - int(size.x / 2.0)
		if offset.x < 0: offset.x = 0
		if offset.x > original.x - size.x + 1: offset.x = original.x - size.x + 1
	if size.y > _max.y:
		size.y = _max.y
		offset.y = at.y - int(size.y / 2.0)
		if offset.y < 0: offset.y = 0
		if offset.y > original.y - size.y + 1: offset.y = original.y - size.y + 1
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in range(size.y):
		for x in range(size.x):
			image.set_pixel(x, y, _level.getMapColor(Vector2i(x + offset.x, y + offset.y)))
	image.resize_to_po2(false, Image.INTERPOLATE_NEAREST)
	image.resize_to_po2(false, Image.INTERPOLATE_NEAREST)
	_imageTexture = ImageTexture.create_from_image(image)

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
	await get_tree().process_frame
	_mask.play("Go")
	await _mask.animation_finished
	if delta != 0 or _selected == null:
		_selected = Random.probability(_g)
	_selected.generate(delta)
	_depth.text = str(_level.state.depth)
	_light.text = str(_level.lightRadius)
	_mask.play_backwards("Go")

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
