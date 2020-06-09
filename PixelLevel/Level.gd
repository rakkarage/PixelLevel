extends Camera2D

onready var _back:    TileMap = $Back
onready var _fore:    TileMap = $Fore
onready var _mob             := $Mob
onready var _target          := $Target
onready var _tween:     Tween = $Tween
onready var _astar        := AStar2D.new()
var _rect := Rect2()
var _path := PoolVector2Array()
var _dragLeft := false
const _duration := 0.22
const _zoomMin := Vector2(0.1, 0.1)
const _zoomMinMin := Vector2(0.05, 0.05)
const _zoomMax := Vector2(1.0, 1.0)
const _zoomMaxMax := Vector2(1.2, 1.2)
const _zoomIn := 0.90
const _zoomOut := 1.10

func _ready() -> void:
	zoom = Vector2(0.75, 0.75)
	_rect = _back.get_used_rect()
	_targetToMob()
	_cameraCenter()
	_addPoints()
	# Utility.ok(Gesture.connect("onZoom", self, "_zoom"))

func _tileIndex(p: Vector2) -> int:
	return int(p.x + (p.y * _rect.size.x))

func _tilePosition(i: int) -> Vector2:
	var y := i / _rect.size.x
	var x := i - _rect.size.x * y
	return Vector2(x, y)

func _addPoints() -> void:
	for y in range(_rect.size.y):
		for x in range(_rect.size.x):
			var p := Vector2(x, y)
			_astar.add_point(_tileIndex(p), p)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_targetTo(event.global_position)
				_dragLeft = true
			else:
				_targetUpdate()
				_cameraUpdate()
				_dragLeft = false
		elif event.button_index == BUTTON_WHEEL_UP:
			_zoom(event.global_position, _zoomIn)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_zoom(event.global_position, _zoomOut)
	elif event is InputEventMouseMotion:
		if _dragLeft:
			offset -= event.relative * zoom

func _world(tile: Vector2) -> Vector2:
	return _back.map_to_world(tile)

func _worldSize() -> Vector2:
	return get_viewport_rect().size * zoom

func _worldBounds() -> Rect2:
	return Rect2(Vector2.ZERO, _worldSize())

func _map(position: Vector2) -> Vector2:
	return _back.world_to_map(position)

func _mapSize() -> Vector2:
	return _rect.size * _back.cell_size

func _mapBounds() -> Rect2:
	return Rect2(-offset, _mapSize())

func _center() -> Vector2:
	return -(_worldSize() / 2.0) + _mapSize() / 2.0

func _cameraCenter() -> void:
	_cameraTo(_center())

func _cameraTo(to: Vector2) -> void:
	offset = to

func _cameraBy(by: Vector2) -> void:
	_cameraTo(offset + by)

func _cameraUpdate() -> void:
	var map := _mapBounds()
	var world := _worldBounds().grow(-_back.cell_size.x)
	if not world.intersects(map):
		_snapCamera(offset + _constrainRect(world, map))

static func _constrainRect(world: Rect2, map: Rect2) -> Vector2:
	return _constrain(world.position, world.end, map.position, map.end)

static func _constrain(minWorld: Vector2, maxWorld: Vector2, minMap: Vector2, maxMap: Vector2) -> Vector2:
	var delta := Vector2.ZERO
	if minWorld.x > minMap.x: delta.x += minMap.x - minWorld.x
	if maxWorld.x < maxMap.x: delta.x -= maxWorld.x - maxMap.x
	if minWorld.y > minMap.y: delta.y += minMap.y - minWorld.y
	if maxWorld.y < maxMap.y: delta.y -= maxWorld.y - maxMap.y
	return delta

func _snapCamera(to: Vector2) -> void:
	Utility.stfu(_tween.stop(self, "offset"))
	Utility.stfu(_tween.interpolate_property(self, "offset", null, to, _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT))
	Utility.stfu(_tween.start())

func _zoom(at: Vector2, factor: float) -> void:
	var z0 := zoom
	var z1 := _zoomClamp(z0 * factor)
	var c0 := offset
	var c1 := c0 + at * (z0 - z1)
	zoom = z1
	offset = c1
	_cameraUpdate()

func _zoomClamp(z: Vector2) -> Vector2:
	return _zoomMin if z < _zoomMin else _zoomMax if z > _zoomMax else z

func _targetToMob() -> void:
	_targetTo(_mob.global_position)

func _targetTo(to: Vector2) -> void:
	_target.global_position = _world(_map(to * zoom + offset))

func _targetUpdate() -> void:
	_targetSnapClosest(_map(_target.global_position))

func _targetSnapClosest(tile: Vector2) -> void:
	_targetSnap(_astar.get_point_position(_astar.get_closest_point(tile)))

func _targetSnap(tile: Vector2) -> void:
	_snapTo(_target, tile)

func _snapTo(node: Node2D, tile: Vector2) -> void:
	var p := _world(tile)
	if not node.global_position.is_equal_approx(p):
		Utility.stfu(_tween.stop(node, "global_position"))
		Utility.stfu(_tween.interpolate_property(node, "global_position", null, p, _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT))
		Utility.stfu(_tween.start())
