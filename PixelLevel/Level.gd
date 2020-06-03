extends Viewport

const _duration = 0.333
onready var _camera       := $Camera
onready var _back: TileMap = $Back
onready var _fore: TileMap = $Fore
onready var _mob          := $Mob
onready var _target       := $Target
onready var _tween        := $Tween
onready var _astar        := AStar2D.new()
var _path := PoolVector2Array()
var _drag := false
var _rect := Rect2()

func _ready() -> void:
	_rect = _back.get_used_rect()
	_addPoints();
	# hide target when on mob and set target to mob pos and hide @ start@

func _index(p: Vector2) -> int:
	return int(p.x + (p.y * _rect.size.x))

func _point(i: int) -> Vector2:
	var y = i / _rect.size.x
	var x = i - _rect.size.x * y
	return Vector2(x, y);

func _addPoints() -> void:
	for y in range(_rect.size.y):
		for x in range(_rect.size.x):
			var p = Vector2(x, y)
			_astar.add_point(_index(p), p)

func _world(tile: Vector2) -> Vector2:
	return _back.map_to_world(tile)

func _map(position: Vector2) -> Vector2:
	return _back.world_to_map(position)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			# use button up? else it is a drag!!!!!!!!!!!
			if event.pressed:
				var map = _map(event.global_position * _camera.zoom + _camera.global_position)
				var target = _map(_target.global_position)
				if map.is_equal_approx(target):
					print("double")
				_target.global_position = _world(map)
				if not _rect.has_point(map):
					_targetToClosest(map)
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

func _targetToClosest(to: Vector2) -> void:
	_targetTo(_astar.get_point_position(_astar.get_closest_point(to)))

func _targetTo(to: Vector2) -> void:
	_tween.stop(_target, "position")
	_tween.interpolate_property(_target, "position", null, _world(to), _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	_tween.start()

func _findPath() -> void:
	# from mob to target and draw it with effect
	pass
