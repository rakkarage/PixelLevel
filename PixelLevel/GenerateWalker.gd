extends Generate
class_name GenerateWalker

# Thanks! https://www.youtube.com/watch?v=2nk6bJBTtlA

const _steps_max := 500
const _steps_change := 5
const _change_chance := 0.25
const _directions := [Vector2.UP, Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN]
var _position := Vector2.ZERO
var _direction := Vector2.UP
var _steps := []
var _step_count := 0

func _init(level: Level) -> void:
	super(level)

func generate(delta: int) -> void:
	super.generate(delta)
	_fill(true, false)
	_draw_walk()
	_stairs()
	if not _cliff and _stream:
		_generate_streams()
	_level.generated()

func _draw_walk() -> void:
	var steps := _walk(_steps_max)
	for step in steps:
		_set_floor(step)
		_level.clear_fore(step)

func _walk(steps: int) -> Array:
	_steps.clear()
	for step in range(steps):
		if Random.next_float() <= _change_chance or _step_count > _steps_change:
			_change_direction()
		if _step():
			_steps.append(_position)
		else:
			_change_direction()
	return _steps

func _step() -> bool:
	var new_position := _position + _direction
	if _level.is_inside_map(new_position):
		_step_count += 1
		_position = new_position
		return true
	else:
		return false

func _change_direction() -> void:
	_step_count = 0
	_direction = _directions[Random.next(_directions.size())]
