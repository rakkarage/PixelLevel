extends Viewport

onready var _camera := $Camera
onready var _back   := $Back
onready var _fore   := $Fore
onready var _mob    := $Mob
onready var _target := $Target
onready var _nav    := $Nav
onready var _size: Vector2 = _back.cell_size

var _path := PoolVector2Array()
var _drag := false
var _t : Transform2D
# var _scale := 2.0

# func _ready() -> void:
	# _t = get_canvas_transform()
	# _t = _t.scaled(Vector2(_scale, _scale))
	# set_canvas_transform(_t)
	# _setLimit()

# func _setLimit() -> void:
# 	var rect = _back.get_used_rect();
# 	_camera.limit_top = 0
# 	_camera.limit_left = 0
# 	_camera.limit_right = rect.end.x * _back.cell_size.x
# 	_camera.limit_bottom = rect.end.y * _back.cell_size.y

func _tilePos(tile: Vector2) -> Vector2:
	return _back.map_to_world(_back.world_to_map(tile))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			var test = _tilePos(event.global_position)
			print(test)
			_target.global_position = test
			_drag = true
		else:
			_drag = false
	elif event is InputEventMouseMotion:
		if _drag:
			_camera.position -= event.relative
			# print(event.relative)
			# _t = _t.translated(event.relative)
			# _t = _t.scaled(Vector2(_scale, _scale))
			# print(_t[2])
			# set_canvas_transform(_t)

# get_simple_path from mob to target!!!
