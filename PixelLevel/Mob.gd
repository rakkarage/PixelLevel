extends Node2D

const _size := Vector2(16, 16)
export var start := Vector2(2, 2)
onready var _rayCast := $RayCast
onready var _tween := $Tween

func _ready() -> void:
	global_position = start * _size + _size / 2.0

func _step(direction: Vector2) -> void:
	var test := direction * _size
	_rayCast.cast_to = test
	_rayCast.force_raycast_update()
	if not _rayCast.is_colliding():
		_tween.interpolate_property(self, "global_position", global_position, global_position + test, 0.22, Tween.TRANS_LINEAR, Tween.EASE_INOUT)
		_tween.start()

func _unhandled_key_input(event: InputEventKey) -> void:
	if _tween.is_active():
		return
	if event.is_action_pressed("ui_up", false):
		_step(Vector2.UP)
	elif event.is_action_pressed("ui_right", false):
		_step(Vector2.RIGHT)
	elif event.is_action_pressed("ui_down", false):
		_step(Vector2.DOWN)
	elif event.is_action_pressed("ui_left", false):
		_step(Vector2.LEFT)
