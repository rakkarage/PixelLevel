extends Command
class_name CommandMove

enum Direction {
	North, NorthEast, East, SouthEast,
	South, SouthWest, West, NorthWest
}

const Directions := {
	Direction.North: Vector2.UP,
	Direction.NorthEast: Vector2.UP + Vector2.RIGHT,
	Direction.East: Vector2.RIGHT,
	Direction.SouthEast: Vector2.DOWN + Vector2.RIGHT,
	Direction.South: Vector2.DOWN,
	Direction.SouthWest: Vector2.DOWN + Vector2.LEFT,
	Direction.West: Vector2.LEFT,
	Direction.NorthWest: Vector2.UP + Vector2.LEFT,
}

var _d: Vector2
var _old: Vector2

func _init(mob: Mob, d: int).(mob) -> void:
	_d = Directions[d]

func execute() -> void:
	_old = _mob.global_position
	_mob.global_position += _d

func undo() -> void:
	_mob.global_position = _old

func redo() -> void:
	execute()
