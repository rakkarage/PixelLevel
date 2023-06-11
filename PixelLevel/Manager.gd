extends Control

@onready var _level: LevelBase = $Container/SubViewport
@onready var _mask: AnimationPlayer = $Fore/Mask/Mask/AnimationPlayer
@onready var _textureRect: TextureRect = $Fore/MiniMap
@onready var _position: Label = $Fore/Panel/VBox/Mouse/Value
@onready var _mapPosition: Label = $Fore/Panel/VBox/Tile/Value
@onready var _depth: Label = $Fore/Panel/VBox/Level/Value
@onready var _turns: Label = $Fore/Panel/VBox/Turns/Value
@onready var _time: Label = $Fore/Panel/VBox/Time/Value
@onready var _up: Button = $Fore/Panel/VBox/HBoxLevel/Up
@onready var _regen: Button = $Fore/Panel/VBox/HBoxLevel/Regen
@onready var _down: Button = $Fore/Panel/VBox/HBoxLevel/Down
@onready var _light: Label = $Fore/Panel/VBox/Light/Value
@onready var _minus: Button = $Fore/Panel/VBox/HBoxLight/Minus
@onready var _toggle: Button = $Fore/Panel/VBox/HBoxLight/Toggle
@onready var _plus: Button = $Fore/Panel/VBox/HBoxLight/Plus

const _max := Vector2i(64, 64)
const _updateMapDelay := 0.1
var _timerUpdateMap := Timer.new()
var _ok := false

func _ready() -> void: call_deferred("_readyDeferred")

func _readyDeferred() -> void:
	_updateMap()
	_level.connect("updateMap", _throttleUpdateMap)
	_timerUpdateMap.one_shot = true
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
	_ok = true

func _input(event: InputEvent) -> void:
	if _ok and event is InputEventMouseMotion:
		_updateText(event.position)

func _updateText(p: Vector2) -> void:
	_position.text = "({0}, {1})".format([snapped(p.x, 0.01), snapped(p.y, 0.01)])
	var map = _level._globalToMap(p)
	if _level.insideMap(map):
		_mapPosition.modulate = Color(1, 1, 1)
	else:
		_mapPosition.modulate = Color(1, 0, 0)
	_mapPosition.text = "({0}, {1})".format([map.x, map.y])
	_turns.text = str(_level._state.turns)
	_time.text = str(snapped(_level._state.time, 0.001))

func _throttleUpdateMap() -> void:
	_timerUpdateMap.start(_updateMapDelay)

func _updateMap() -> void:
	_updateText(get_global_mouse_position())
	var at = _level._heroPosition()
	var original = _level._tileMap.get_used_rect().size
	var trimSize = original
	var offset := Vector2i.ZERO
	if trimSize.x > _max.x:
		trimSize.x = _max.x
		offset.x = at.x - int(trimSize.x / 2.0)
		if offset.x < 0: offset.x = 0
		if offset.x > original.x - trimSize.x + 1: offset.x = original.x - trimSize.x + 1
	if trimSize.y > _max.y:
		trimSize.y = _max.y
		offset.y = at.y - int(trimSize.y / 2.0)
		if offset.y < 0: offset.y = 0
		if offset.y > original.y - trimSize.y + 1: offset.y = original.y - trimSize.y + 1
	var image = Image.create(trimSize.x, trimSize.y, false, Image.FORMAT_RGBA8)
	for y in range(trimSize.y):
		for x in range(trimSize.x):
			image.set_pixel(x, y, _level.getMapColor(Vector2i(x + offset.x, y + offset.y)))
	image.resize_to_po2(false, Image.INTERPOLATE_NEAREST)
	image.resize_to_po2(false, Image.INTERPOLATE_NEAREST)
	_textureRect.texture = ImageTexture.create_from_image(image)

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
	_mask.play("Mask")
	await _mask.animation_finished
	if delta != 0 or _selected == null:
		_selected = Random.probability(_g)
	_selected.generate(delta)
	_depth.text = str(_level._state.depth)
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
	_depth.text = str(_level._state.depth)

func _levelRegen() -> void:
	_generate(0)

func _levelDown() -> void:
	_generate()
	_depth.text = str(_level._state.depth)
