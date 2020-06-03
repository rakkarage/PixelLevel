extends Viewport

onready var _camera := $Camera
onready var _back   := $Back
onready var _fore   := $Fore
onready var _mob    := $Mob
onready var _target := $Target
onready var _astar := AStar2D.new()
var _path := PoolVector2Array()
var _drag := false

func _tilePos(tile: Vector2) -> Vector2:
	return _back.map_to_world(_back.world_to_map(tile))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_target.global_position = _tilePos(event.global_position * _camera.zoom + _camera.global_position)
				_drag = true
			else:
				_drag = false
		elif event.button_index == BUTTON_WHEEL_UP:
			_camera.zoom -= Vector2(0.02, 0.02)
		elif event.button_index == BUTTON_WHEEL_DOWN: 
			_camera.zoom += Vector2(0.02, 0.02)
	elif event is InputEventMouseMotion:
		if _drag:
			_camera.global_position -= event.relative * _camera.zoom

func _findPath() -> void:
	pass
