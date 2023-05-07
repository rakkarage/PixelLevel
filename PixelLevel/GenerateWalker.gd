extends Generate
class_name GenerateWalker

# Thanks! https://www.youtube.com/watch?v=2nk6bJBTtlA

const _stepsMax := 500
const _stepsChange := 5
const _changeChance := 0.25
const _directions := [Vector2.UP, Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN]
var _position := Vector2.ZERO
var _direction := Vector2.UP
var _steps := []
var _stepCount := 0

func _init(level: Level) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	_fill(true, false)
	_drawWalk()
	_stairs()
	if _stream:
		_generateStreams()
	_level.generated()

func _drawWalk() -> void:
	var steps := _walk(_stepsMax)
	for step in steps:
		_setFloorV(step)
		_level.clearForeV(step)

func _walk(steps: int) -> Array:
	_steps.clear()
	for _step in range(steps):
		if Random.nextFloat() <= _changeChance or _stepCount > _stepsChange:
			_changeDirection()
		if _step():
			_steps.append(_position)
		else:
			_changeDirection()
	return _steps

func _step() -> bool:
	var newPosition := _position + _direction
	if _level.insideMapV(newPosition):
		_stepCount += 1
		_position = newPosition
		return true
	else:
		return false

func _changeDirection() -> void:
	_stepCount = 0
	_direction = _directions[Random.next(_directions.size())]
