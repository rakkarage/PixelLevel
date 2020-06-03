extends Viewport

onready var _camera       := $Camera
onready var _back: TileMap = $Back
onready var _fore: TileMap = $Fore
onready var _mob          := $Mob
onready var _target       := $Target
onready var _astar        := AStar2D.new()
var _path := PoolVector2Array()
var _drag := false

func _tilePos(tile: Vector2) -> Vector2:
	return _back.map_to_world(_back.world_to_map(tile))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				# if target already here???
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
	# from mob to target and draw it with effect
	pass

func _ready() -> void:
	_addPoints();

func _addPoints() -> void:
	var size = _back.get_used_rect().size
	for y in range(size.y):
		for x in range(size.x):
			_astar.add_point(x + (y * size.x), Vector2(x, y))
