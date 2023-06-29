extends Control

@onready var _level: Level = $Container/SubViewport
@onready var _mask: MaskTween = $Fore/MaskGate
@onready var _texture_rect: TextureRect = $Fore/MiniMap
@onready var _position: Label = $Fore/Panel/VBox/Mouse/Value
@onready var _position_map: Label = $Fore/Panel/VBox/Tile/Value
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
@onready var _save: Button = $Fore/Panel/VBox/HBoxOther/Save

const _max := Vector2i(64, 64)
const _update_map_delay := 0.1
var _update_map_timer := Timer.new()
var _ok := false
var _generating := false

func _ready() -> void:
	_level.connect("update_map", _update_map_throttle)
	add_child(_update_map_timer)
	_update_map_timer.one_shot = true
	_update_map_timer.connect("timeout", _update_map)
	_level.connect("generate", func(delta: int): await _on_generate(delta))
	_minus.connect("pressed", _on_light_minus)
	_toggle.connect("pressed", _on_light_toggle)
	_plus.connect("pressed", _on_light_plus)
	_up.connect("pressed", func(): Audio.error() if _generating or LevelStore.data.main.depth == 0 else await _on_generate(-1))
	_regen.connect("pressed", func(): Audio.error() if _generating else await _on_generate(0))
	_down.connect("pressed", func(): Audio.error() if _generating else await _on_generate(1))
	_save.connect("pressed", _on_level_save)
	_light.text = str(_level.light_radius)
	_ok = true

func _input(event: InputEvent) -> void:
	if _ok and event is InputEventMouseMotion:
		_update_text(event.position)

func _update_text(p: Vector2) -> void:
	_position.text = "({0}, {1})".format([snapped(p.x, 0.01), snapped(p.y, 0.01)])
	var map = _level.global_to_map(p)
	if _level.is_inside_map(map):
		_position_map.modulate = Color(1, 1, 1)
	else:
		_position_map.modulate = Color(1, 0, 0)
	_position_map.text = "({0}, {1})".format([map.x, map.y])
	_turns.text = str(LevelStore.data.main.turns)
	_time.text = str(snapped(LevelStore.data.main.time, 0.001))

func _update_map_throttle() -> void:
	_update_map_timer.start(_update_map_delay)

func _update_map() -> void:
	_update_text(get_global_mouse_position())
	var at = _level._hero_position()
	var original = _level.tile_rect().size
	var trim_size = original
	var offset := Vector2i.ZERO
	if trim_size.x > _max.x:
		trim_size.x = _max.x
		offset.x = at.x - int(trim_size.x / 2.0)
		if offset.x < 0: offset.x = 0
		if offset.x > original.x - trim_size.x + 1: offset.x = original.x - trim_size.x + 1
	if trim_size.y > _max.y:
		trim_size.y = _max.y
		offset.y = at.y - int(trim_size.y / 2.0)
		if offset.y < 0: offset.y = 0
		if offset.y > original.y - trim_size.y + 1: offset.y = original.y - trim_size.y + 1
	var image = Image.create(trim_size.x, trim_size.y, false, Image.FORMAT_RGBA8)
	for y in trim_size.y:
		for x in trim_size.x:
			image.set_pixel(x, y, _level.get_map_color(Vector2i(x + offset.x, y + offset.y)))
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	_texture_rect.texture = ImageTexture.create_from_image(image)

@onready var _generators := {
	GenerateBasic.new(_level): 1,
	GenerateRoom.new(_level): 1,
	GenerateDungeon.new(_level): 10,
	GenerateMaze.new(_level): 33,
	GenerateCave.new(_level): 33,
	GenerateWalker.new(_level): 50,
	GenerateTemplate.new(_level): 100,
}
var _selected: Generate

func _on_generate(delta: int) -> void:
	_generating = true
	await get_tree().process_frame
	if delta + LevelStore.data.main.depth == 0:
		GenerateTown.new(_level).generate(delta)
	else:
		await _mask.animate_in()
		if delta != 0 or _selected == null:
			_selected = Random.probability(_generators)
		_selected.generate(delta)
		await _mask.animate_out()
	_depth.text = str(LevelStore.data.main.depth)
	_light.text = str(_level.light_radius)
	_generating = false

func _on_light_minus() -> void:
	_level.light_decrease()
	_light.text = str(_level.light_radius)

func _on_light_toggle() -> void:
	_level.light_toggle()
	_update_map()

func _on_light_plus() -> void:
	_level.light_increase()
	_light.text = str(_level.light_radius)

func _on_level_save() -> void:
	_level.save_maps_texture()
