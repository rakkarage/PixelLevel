extends Viewport

const _zoomMin := Vector2.ONE
const _zoomMinMin := Vector2(0.8, 0.8)
const _zoomMax := Vector2(32.0, 32.0)
const _zoomMaxMax := Vector2(40.0, 40.0)
onready var _camera := $Camera
onready var _back   := $Back
onready var _fore   := $Fore
onready var _mob    := $Mob
onready var _target := $Target
onready var _nav    := $Nav
onready var _tween  := $Tween
onready var _size: Vector2 = _back.cell_size
var _path := PoolVector2Array()
var _drag := false

func _tilePos(tile: Vector2) -> Vector2:
	return _back.map_to_world(_back.world_to_map(tile))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_target.global_position = _tilePos(event.global_position)
				_drag = true
			else:
				_drag = false
		elif event.button_index == BUTTON_WHEEL_UP:
			_camera.zoom -= Vector2(0.2, 0.2)
		elif event.button_index == BUTTON_WHEEL_DOWN: 
			_camera.zoom += Vector2(0.2, 0.2)
	elif event is InputEventMouseMotion:
		if _drag:
			_camera.global_position -= event.relative
