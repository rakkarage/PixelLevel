extends Viewport

onready var _camera       := $Camera
onready var _back: TileMap = $Back
onready var _fore: TileMap = $Fore
onready var _mob          := $Mob
onready var _target       := $Target
onready var _astar        := AStar2D.new()
var _path := PoolVector2Array()
var _drag := false
var _rect := Rect2()

func _ready() -> void:
	_rect = _back.get_used_rect()
	print("rect: %s" % _rect)
	_addPoints();

func _index(p: Vector2) -> int:
	return int(p.x + (p.y * _rect.size.x))

func _addPoints() -> void:
	for y in range(size.y):
		for x in range(size.x):
			var p = Vector2(x, y)
			_astar.add_point(_index(p), p)

func _tilePosition(tile: Vector2) -> Vector2:
	return _back.map_to_world(tile)

func _tileAt(position: Vector2) -> Vector2:
	return _back.world_to_map(position)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				# if target already here???
				var tile = _tileAt(event.global_position * _camera.zoom + _camera.global_position)
				_target.global_position = _tilePosition(tile)
				if _rect.has_point(tile):
					print("in")
				else:
					print("out")
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
