extends Viewport

onready var _back   := $Back
onready var _fore   := $Fore
onready var _mob    := $Mob
onready var _target := $Target
onready var _nav    := $Nav
var _path := PoolVector2Array()
var _drag := false
var _t : Transform2D
var _scale := 2.0

func _ready() -> void:
	_t = get_canvas_transform()
	_t = _t.scaled(Vector2(_scale, _scale))
	set_canvas_transform(_t)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				var map = _back.world_to_map(event.position)
				_target.position = _back.map_to_world(map)
				_drag = true
			else:
				_drag = false
	elif event is InputEventMouseMotion:
		if _drag:
			_t[2] = -_mob.position
			set_canvas_transform(_t)

# get_simple_path from mob to target!!!
