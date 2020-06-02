extends Node

onready var _back   := $Container/Viewport/Back
onready var _fore   := $Container/Viewport/Fore
onready var _mob    := $Container/Viewport/Mob
onready var _target := $Container/Viewport/Target
onready var _nav    := $Container/Viewport/Nav
var _path := PoolVector2Array()
var _drag := false
var _t : Transform2D
var _scale := 2.0

# get_viewport_rect().size

func _ready() -> void:
	_t = get_viewport().get_canvas_transform()
	_t = _t.scaled(Vector2(_scale, _scale))
	get_viewport().set_canvas_transform(_t)

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
			get_viewport().set_canvas_transform(_t)

# get_simple_path from mob to target!!!
